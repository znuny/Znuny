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

    my $Assertion;
    eval {
        $Assertion = Net::SAML2::Protocol::Assertion->new_from_xml(
            xml => MIME::Base64::decode_base64( $Param{Response} ),
            %TrustParams,
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
        $Param{ExpectedRequestID},
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

sub GetAttributeValues {
    my ( $Self, $Name ) = @_;

    return if !$Self->IsValid();

    # Note: $Self->{Assertion}->attributes() does not work here because it only
    # return the last one of attributes with the same name.

    my $XPath = XML::LibXML::XPathContext->new( $Self->{XMLDOM} );
    return if !$XPath;

    $XPath->registerNs(
        'samlp',
        'urn:oasis:names:tc:SAML:2.0:protocol',
    );

    $XPath->registerNs(
        'saml',
        'urn:oasis:names:tc:SAML:2.0:assertion',
    );

    my $Query = '/samlp:Response/saml:Assertion/saml:AttributeStatement/saml:Attribute[@Name="'
        . $Name
        . '"]/saml:AttributeValue';

    my @Entries = $XPath->findnodes($Query);
    return if !@Entries;

    my @Values = map { $_->textContent() } @Entries;

    return \@Values;
}

sub GetFirstAttributeValue {
    my ( $Self, $Name ) = @_;

    my $Values = $Self->GetAttributeValues($Name);
    return if !IsArrayRefWithData($Values);

    return $Values->[0];
}

1;
