# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# Copyright (C) 2016 Maxime Appolonia, maxime.appolonia@restena.lu, https://github.com/restena-ma/otrs-saml2sp
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Auth::SAML::Response;

use strict;
use warnings;
use utf8;

our $ObjectManagerDisabled = 1;

use Kernel::System::VariableCheck qw(:all);

use Net::SAML2;
use MIME::Base64;
use XML::LibXML;
use XML::LibXML::XPathContext;

=head1 PUBLIC INTERFACE

=head2 new()

Creates an object.

    use Kernel::System::Auth::SAML::Response;

    my $ResponseObject = Kernel::System::Auth::SAML::Response->new(
        Config => {
            # ...
        },
    );

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');

    $Self->{Count}  = $Param{Count};
    $Self->{Config} = $Param{Config};

    return $Self;
}

=head2 DecodeResponse()

Decodes SAML response.

    my $Successful = $ResponseObject->DecodeResponse(
        Response => '...',
        UnitTest => 1, # optional, enables unit test context (to avoid using signatures, validity checks, etc.)
    );

=cut

sub DecodeResponse {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    delete $Self->{Decoded};
    delete $Self->{IsValid};
    delete $Self->{Assertion};
    delete $Self->{Login};

    # One trust anchor for the POST binding and the assertion. Real logins use the
    # configured IdP certificate. Unit tests use unsigned fixtures, so only that
    # path may trust an embedded certificate.
    my %TrustParams;
    if ( $Param{UnitTest} ) {
        $TrustParams{insecure_trust_embedded_cert} = 1;
    }
    elsif ( $Self->{Config}->{IdPCACert} ) {
        $TrustParams{cacert} = $Self->{Config}->{IdPCACert};
    }
    else {
        $LogObject->Log(
            Priority => 'error',
            Message  => "IdPCACert is required to verify SAML assertion signatures (count: $Self->{Count}).",
        );
        return;
    }

    if ( $Param{UnitTest} ) {
        $Self->{XMLString} = MIME::Base64::decode_base64( $Param{Response} );
    }
    else {
        my $Post = Net::SAML2::Binding::POST->new(%TrustParams);
        return if !$Post;

        $Self->{XMLString} = $Post->handle_response(
            $Param{Response},
        );
    }

    return if !$Self->{XMLString};

    my $XMLParser = XML::LibXML->new();
    $Self->{XMLDOM} = $XMLParser->parse_string( $Self->{XMLString} );
    return if !$Self->{XMLDOM};

    # Safe to always pass, whether or not the assertion is actually encrypted:
    # Net::SAML2 only ever consults key_file when it finds an EncryptedAssertion node.
    my %DecryptParams;
    if ( $Self->{Config}->{ResponseEncryptKey} ) {
        $DecryptParams{key_file} = $Self->{Config}->{ResponseEncryptKey};
    }

    my $Assertion;
    eval {
        $Assertion = Net::SAML2::Protocol::Assertion->new_from_xml(
            xml => MIME::Base64::decode_base64( $Param{Response} ),
            %TrustParams,
            %DecryptParams,
        );
    };
    if ($@) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Error creating SAML assertion object: $@",
        );
        return;
    }
    return if !$Assertion;

    $Self->{Assertion} = $Assertion;

    $Self->{Decoded} = 1;

    return 1;
}

sub IsValid {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    return $Self->{IsValid} if exists $Self->{IsValid};

    return if !$Self->{Decoded};

    NEEDED:
    for my $Needed (qw(ExpectedSAMLRequestID)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );

        return;
    }

    my $IsValid = $Self->{Assertion}->valid(
        $Self->{Config}->{Issuer},
        $Param{ExpectedSAMLRequestID},
    );

    if ( !$IsValid ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => 'Issuer or ID in response does not match the one of the request.',
        );

        return;
    }

    $Self->{IsValid} = $IsValid;

    return if !$IsValid;

    return 1;
}

sub GetNameID {
    my ( $Self, %Param ) = @_;

    return if !$Self->IsValid();

    return $Self->{Assertion}->nameid();
}

=head2 GetLogin()

Returns the login of the user, used by the auth backends and the user sync.

This is the NameID, unless config option UserLoginAttribute is set: then it
is the value of the first of these attributes the signed assertion contains.
The attribute must have exactly one value, otherwise the login fails. There
is no fallback to the NameID, a login must never silently change its source.

    # AuthModule::SAML::UserLoginAttribute1 = 'uid';
    # or several, the first one present is used:
    # AuthModule::SAML::UserLoginAttribute1 = [ 'uid', 'mail' ];

    my $Login = $ResponseObject->GetLogin();

=cut

sub GetLogin {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    return if !$Self->IsValid();

    return $Self->{Login} if exists $Self->{Login};

    my @Attributes = $Self->_LoginAttributes();
    if ( !@Attributes ) {
        $Self->{Login} = $Self->GetNameID();
        return $Self->{Login};
    }

    $Self->{Login} = undef;

    ATTRIBUTE:
    for my $Attribute (@Attributes) {
        my @Values = grep { defined $_ && length $_ } $Self->_GetSignedAssertionAttributeValues($Attribute);
        next ATTRIBUTE if !@Values;

        if ( @Values > 1 ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "SAML login attribute '$Attribute' has more than one value (count: $Self->{Count}).",
            );
            return;
        }

        $Self->{Login} = $Values[0];
        return $Self->{Login};
    }

    $LogObject->Log(
        Priority => 'error',
        Message  => 'SAML assertion contains none of the login attributes '
            . join( ', ', map {"'$_'"} @Attributes )
            . " (count: $Self->{Count}).",
    );

    return;
}

sub GetAttributeValues {
    my ( $Self, $Name ) = @_;

    return if !$Self->IsValid();

    # Note: $Self->{Assertion}->attributes() does not work here because it only
    # return the last one of attributes with the same name.

    # Deliberately not $Self->{XMLDOM} (the raw, pre-decryption response) - for an
    # encrypted assertion that only ever contains the opaque EncryptedAssertion blob.
    # $Self->{Assertion}->xpath is the context Net::SAML2 built from the *decrypted* XML.
    my $XPath = $Self->{Assertion}->xpath();
    return if !$XPath;

    $XPath->registerNs(
        'samlp',
        'urn:oasis:names:tc:SAML:2.0:protocol',
    );

    $XPath->registerNs(
        'saml',
        'urn:oasis:names:tc:SAML:2.0:assertion',
    );

    # Matches by FriendlyName too, in addition to Name - some Identity Providers (or their
    # metadata) only advertise one or the other.
    my $AttributePath = 'saml:AttributeStatement/saml:Attribute[@Name="'
        . $Name
        . '" or @FriendlyName="'
        . $Name
        . '"]/saml:AttributeValue';

    # Only the assertion directly below the response, or where Net::SAML2 puts a decrypted
    # one. Attributes anywhere else (e.g. injected into unsigned parts of the response) must
    # not be read.
    my $Query = "/samlp:Response/saml:Assertion/$AttributePath"
        . " | /samlp:Response/saml:EncryptedAssertion/saml:Assertion/$AttributePath";

    my @Entries = $XPath->findnodes($Query);
    return if !@Entries;

    my @Values = map { $_->textContent() } @Entries;

    return \@Values;
}

=head2 GetSLOData()

Returns the NameID/NameIDFormat/SessionIndex from the last successfully
decoded and validated assertion, for use with Single Logout. Returns an
empty list if there is no valid assertion.

    my %SLOData = $ResponseObject->GetSLOData();

=cut

sub GetSLOData {
    my ( $Self, %Param ) = @_;

    return if !$Self->IsValid();

    return (
        NameID       => $Self->{Assertion}->nameid(),
        NameIDFormat => $Self->{Assertion}->nameid_format(),
        SessionIndex => $Self->{Assertion}->session(),
    );
}

# Configured login attributes, as array ref or comma separated string.
sub _LoginAttributes {
    my ( $Self, %Param ) = @_;

    my $Config = $Self->{Config}->{UserLoginAttribute};
    return if !defined $Config;

    my @Attributes = ref $Config eq 'ARRAY' ? @{$Config} : split /\s*,\s*/, $Config;

    return grep { defined $_ && length $_ } map { s{\A\s+|\s+\z}{}gr } @Attributes;
}

# Values of an attribute, read only from the assertion whose signature Net::SAML2 verified.
# The response passes through the user's browser, who can add further, unsigned assertions.
# The login is taken from these values, so they must never come from such an assertion.
sub _GetSignedAssertionAttributeValues {
    my ( $Self, $Name ) = @_;

    return if !defined $Name || !length $Name;

    my $XPath = $Self->{Assertion}->xpath();
    return if !$XPath;

    $XPath->registerNs(
        'saml',
        'urn:oasis:names:tc:SAML:2.0:assertion',
    );

    # ID of the assertion the trusted signature refers to.
    my $AssertionID = $Self->{Assertion}->id();
    return if !defined $AssertionID || !length $AssertionID;

    my @AssertionNodes = grep { ( $_->getAttribute('ID') // '' ) eq $AssertionID }
        $XPath->findnodes('//saml:Assertion');

    # Net::SAML2 already rejects a signed ID that matches more than one element,
    # so anything other than exactly one match means the response was tampered with.
    return if @AssertionNodes != 1;

    my @Values;
    ATTRIBUTE:
    for my $AttributeNode (
        $XPath->findnodes( './saml:AttributeStatement/saml:Attribute', $AssertionNodes[0] )
        )
    {
        my $AttributeName         = $AttributeNode->getAttribute('Name')         // '';
        my $AttributeFriendlyName = $AttributeNode->getAttribute('FriendlyName') // '';
        next ATTRIBUTE if $AttributeName ne $Name && $AttributeFriendlyName ne $Name;

        push @Values, map { $_->textContent() } $XPath->findnodes( './saml:AttributeValue', $AttributeNode );
    }

    return @Values;
}

sub GetFirstAttributeValue {
    my ( $Self, $Name ) = @_;

    my $Values = $Self->GetAttributeValues($Name);
    return if !IsArrayRefWithData($Values);

    return $Values->[0];
}

1;
