# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;

use utf8;

use vars (qw($Self));

use Kernel::System::Auth::SAML::Response;

use MIME::Base64;
use POSIX ();
use XML::Sig;
use XML::LibXML;

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

my $Issuer = 'https://example.org/znuny/';

$ConfigObject->Set(
    Key   => 'AuthModule::SAML::Issuer2',
    Value => $Issuer,
);

my $SAMLResponseObject = Kernel::System::Auth::SAML::Response->new(
    Count  => 2,
    Config => {
        Issuer => $Issuer,
    },
);

my $ExpectedSAMLRequestID = '_54c307de-960b-11f0-b741-ecb5948c096d';

# Note: without signature to make tests easier.
# Response and Assertion IDs must differ. Net::SAML2 0.89 rejects a repeated ID.
my $SAMLResponseXML = '<samlp:Response xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol"
    xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" Destination="https://example.com/znuny/index.pl?Action=Login" ID="ID_aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee" InResponseTo="'
    . $ExpectedSAMLRequestID
    . '" IssueInstant="2025-09-20T10:19:46.253Z" Version="2.0">
    <saml:Issuer>' . $Issuer . '</saml:Issuer>
    <samlp:Status>
        <samlp:StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Success"/>
    </samlp:Status>
    <saml:Assertion xmlns="urn:oasis:names:tc:SAML:2.0:assertion" ID="ID_bbbbbbbb-bbbb-cccc-dddd-eeeeeeeeeeee" IssueInstant="2025-09-20T10:19:46.253Z" Version="2.0">
        <saml:Issuer>' . $Issuer . '</saml:Issuer>
        <saml:Subject>
            <saml:NameID Format="urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress">unittest@znuny.org</saml:NameID>
            <saml:SubjectConfirmation Method="urn:oasis:names:tc:SAML:2.0:cm:bearer">
                <saml:SubjectConfirmationData InResponseTo="'
    . $ExpectedSAMLRequestID
    . '" NotOnOrAfter="2025-09-20T10:20:44.253Z" Recipient="https://example.com/znuny/index.pl?Action=Login"/>
            </saml:SubjectConfirmation>
        </saml:Subject>
        <saml:Conditions NotBefore="2025-09-20T10:19:44.253Z" NotOnOrAfter="2035-09-20T10:20:44.253Z">
            <saml:AudienceRestriction>
                <saml:Audience>' . $Issuer . '</saml:Audience>
            </saml:AudienceRestriction>
        </saml:Conditions>
        <saml:AuthnStatement AuthnInstant="2025-09-20T10:19:46.253Z" SessionIndex="aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee::ffffffff-aaaa-bbbb-cccc-dddddddddddd" SessionNotOnOrAfter="2025-09-30T10:19:46.253Z">
            <saml:AuthnContext>
                <saml:AuthnContextClassRef>urn:oasis:names:tc:SAML:2.0:ac:classes:unspecified</saml:AuthnContextClassRef>
            </saml:AuthnContext>
        </saml:AuthnStatement>
        <saml:AttributeStatement>
            <saml:Attribute FriendlyName="email" Name="email" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
                <saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema"
                    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">unittest@znuny.org</saml:AttributeValue>
            </saml:Attribute>
            <saml:Attribute Name="Role" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
                <saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema"
                    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">Reporting</saml:AttributeValue>
            </saml:Attribute>
            <saml:Attribute Name="Role" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
                <saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema"
                    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">Support</saml:AttributeValue>
            </saml:Attribute>
            <saml:Attribute Name="Role" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
                <saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema"
                    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">view-profile</saml:AttributeValue>
            </saml:Attribute>
            <saml:Attribute Name="Role" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
                <saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema"
                    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">Recruiting</saml:AttributeValue>
            </saml:Attribute>
            <saml:Attribute Name="Role" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
                <saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema"
                    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">offline_access</saml:AttributeValue>
            </saml:Attribute>
            <saml:Attribute Name="Role" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
                <saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema"
                    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">view-consent</saml:AttributeValue>
            </saml:Attribute>
            <saml:Attribute Name="Role" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
                <saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema"
                    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">uma_authorization</saml:AttributeValue>
            </saml:Attribute>
            <saml:Attribute Name="Role" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
                <saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema"
                    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">Manager</saml:AttributeValue>
            </saml:Attribute>
            <saml:Attribute Name="Role" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
                <saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema"
                    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">Sales</saml:AttributeValue>
            </saml:Attribute>
            <saml:Attribute Name="Role" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
                <saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema"
                    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">Security</saml:AttributeValue>
            </saml:Attribute>
            <saml:Attribute Name="Role" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
                <saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema"
                    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">manage-account</saml:AttributeValue>
            </saml:Attribute>
            <saml:Attribute Name="Role" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
                <saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema"
                    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">ISMS</saml:AttributeValue>
            </saml:Attribute>
            <saml:Attribute Name="Role" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
                <saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema"
                    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">Operations</saml:AttributeValue>
            </saml:Attribute>
            <saml:Attribute Name="Role" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
                <saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema"
                    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">manage-consent</saml:AttributeValue>
            </saml:Attribute>
            <saml:Attribute Name="Role" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
                <saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema"
                    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">Consulting</saml:AttributeValue>
            </saml:Attribute>
            <saml:Attribute Name="Role" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
                <saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema"
                    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">view-applications</saml:AttributeValue>
            </saml:Attribute>
            <saml:Attribute Name="Role" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
                <saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema"
                    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">manage-account-links</saml:AttributeValue>
            </saml:Attribute>
        </saml:AttributeStatement>
    </saml:Assertion>
</samlp:Response>';

my $SAMLResponseXMLBase64 = MIME::Base64::encode_base64($SAMLResponseXML);

my $SAMLResponseDecoded = $SAMLResponseObject->DecodeResponse(
    Response => $SAMLResponseXMLBase64,
    UnitTest => 1,
);
$Self->True(
    scalar $SAMLResponseDecoded,
    'DecodeResponse() must be successful.',
);

$Self->True(
    $SAMLResponseObject->IsValid( ExpectedSAMLRequestID => $ExpectedSAMLRequestID ),
    'IsValid() must be successful.',
);

my $EmailAddress = $SAMLResponseObject->GetFirstAttributeValue('email');
$Self->Is(
    scalar $EmailAddress,
    'unittest@znuny.org',
    'GetFirstAttributeValue() must return expected value.',
);

my $NameID = $SAMLResponseObject->GetNameID();
$Self->Is(
    scalar $NameID,
    'unittest@znuny.org',
    'GetNameID() must return expected value.',
);

# Attributes may only be read from the assertion itself. A decrypted assertion stays inside
# its EncryptedAssertion element (see XML::Enc), attributes anywhere else must be ignored.
{
    no warnings 'once';    ## no critic
    *UnitTest::SAMLAssertionStub::xpath = sub { return $_[0]->{XPath} };
    *UnitTest::SAMLAssertionStub::id    = sub { return $_[0]->{ID} };
}

my $GetAttributeValues = sub {
    my ( $XML, $Name ) = @_;

    my $ResponseObject = Kernel::System::Auth::SAML::Response->new(
        Count  => 2,
        Config => {
            Issuer => $Issuer,
        },
    );

    my $XPath = XML::LibXML::XPathContext->new( XML::LibXML->load_xml( string => $XML ) );

    $ResponseObject->{IsValid}   = 1;
    $ResponseObject->{Assertion} = bless {
        XPath => $XPath,
        ID    => 'ID_bbbbbbbb-bbbb-cccc-dddd-eeeeeeeeeeee',
        },
        'UnitTest::SAMLAssertionStub';

    return $ResponseObject->GetAttributeValues($Name) || [];
};

my $InjectedAttributeXML = $SAMLResponseXML;
$InjectedAttributeXML
    =~ s{(<samlp:Status>)}{<samlp:Extensions><saml:Attribute Name="Role"><saml:AttributeValue>Admin</saml:AttributeValue></saml:Attribute></samlp:Extensions>$1};

my $DecryptedAssertionXML = $SAMLResponseXML;
$DecryptedAssertionXML
    =~ s{(<saml:Assertion\b.*</saml:Assertion>)}{<saml:EncryptedAssertion>$1</saml:EncryptedAssertion>}s;

my $FriendlyNameXML = $SAMLResponseXML;
$FriendlyNameXML =~ s{FriendlyName="email" Name="email"}{FriendlyName="email" Name="urn:oid:0.9.2342.19200300.100.1.3"};

my @AttributeTests = (
    {
        Name      => 'attribute of the assertion',
        XML       => $SAMLResponseXML,
        Attribute => 'Role',
        Value     => 'Support',
        Expected  => 1,
    },
    {
        Name      => 'attribute outside of the assertion',
        XML       => $InjectedAttributeXML,
        Attribute => 'Role',
        Value     => 'Admin',
        Expected  => 0,
    },
    {
        Name      => 'attribute of a decrypted assertion',
        XML       => $DecryptedAssertionXML,
        Attribute => 'email',
        Value     => 'unittest@znuny.org',
        Expected  => 1,
    },
    {
        Name      => 'attribute by FriendlyName',
        XML       => $FriendlyNameXML,
        Attribute => 'email',
        Value     => 'unittest@znuny.org',
        Expected  => 1,
    },
);

for my $Test (@AttributeTests) {
    my $Values = $GetAttributeValues->( $Test->{XML}, $Test->{Attribute} );
    my $Found  = grep { $_ eq $Test->{Value} } @{$Values};

    $Self->Is(
        $Found ? 1 : 0,
        $Test->{Expected},
        "GetAttributeValues() - $Test->{Name}.",
    );
}

# Real logins do not set UnitTest. Without IdPCACert the response must be rejected
# before Net::SAML2 is asked to verify it.
my $MissingCertDecoded = $SAMLResponseObject->DecodeResponse(
    Response => $SAMLResponseXMLBase64,
);
$Self->False(
    $MissingCertDecoded,
    'DecodeResponse() without IdPCACert must fail.',
);

my $IdPCACert           = '/some/path/cert.pem';
my $TrustResponseObject = Kernel::System::Auth::SAML::Response->new(
    Count  => 2,
    Config => {
        Issuer    => $Issuer,
        IdPCACert => $IdPCACert,
    },
);

my %SeenAssertionParams;
{
    no warnings 'redefine';    ## no critic

    local *Net::SAML2::Binding::POST::new = sub {
        my ( $Class, %Param ) = @_;
        return bless \%Param, $Class;
    };
    local *Net::SAML2::Binding::POST::handle_response = sub {
        return $SAMLResponseXML;
    };
    local *Net::SAML2::Protocol::Assertion::new_from_xml = sub {
        my ( $Class, %Param ) = @_;
        %SeenAssertionParams = %Param;
        return bless {}, $Class;
    };

    my $TrustDecoded = $TrustResponseObject->DecodeResponse(
        Response => $SAMLResponseXMLBase64,
    );
    $Self->True(
        $TrustDecoded,
        'DecodeResponse() with IdPCACert must be successful.',
    );
}

$Self->Is(
    $SeenAssertionParams{cacert},
    $IdPCACert,
    'Assertion must be created with the configured IdPCACert.',
);
$Self->Is(
    $SeenAssertionParams{insecure_trust_embedded_cert},
    undef,
    'Assertion must not trust an embedded certificate.',
);

#
# Attributes must only be read from the signed assertion.
#
# The SAML response passes through the user's browser (HTTP-POST binding), so a user
# can add further, unsigned assertions to a validly signed response. These must not
# contribute attribute values (e.g. groups/roles for the user sync).
#
my $SampleDirectory = $ConfigObject->Get('Home') . '/scripts/test/sample/SAML';
my $IdPSigningKey   = "$SampleDirectory/IdPSigningKey.pem";
my $IdPSigningCert  = "$SampleDirectory/IdPSigningCertificate.pem";

my $Now          = time();
my $NotBefore    = POSIX::strftime( '%Y-%m-%dT%H:%M:%SZ', gmtime( $Now - 300 ) );
my $NotOnOrAfter = POSIX::strftime( '%Y-%m-%dT%H:%M:%SZ', gmtime( $Now + 300 ) );
my $IdPEntityID  = 'https://idp.example.org/';

my $BuildAssertion = sub {
    my %Param = @_;

    # Two separate "Group" attributes, as e.g. Keycloak sends multi-valued attributes.
    my $GroupAttributes = join '', map {
        '<saml:Attribute Name="Group"><saml:AttributeValue>' . $_ . '</saml:AttributeValue></saml:Attribute>'
    } @{ $Param{Groups} };

    return '<saml:Assertion xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" ID="'
        . $Param{ID}
        . '" IssueInstant="' . $NotBefore . '" Version="2.0">'
        . '<saml:Issuer>' . $IdPEntityID . '</saml:Issuer>'
        . '<saml:Subject><saml:NameID>' . $Param{NameID} . '</saml:NameID>'
        . '<saml:SubjectConfirmation Method="urn:oasis:names:tc:SAML:2.0:cm:bearer">'
        . '<saml:SubjectConfirmationData InResponseTo="' . $ExpectedSAMLRequestID
        . '" NotOnOrAfter="' . $NotOnOrAfter
        . '" Recipient="https://example.com/znuny/index.pl?Action=Login"/>'
        . '</saml:SubjectConfirmation></saml:Subject>'
        . '<saml:Conditions NotBefore="' . $NotBefore . '" NotOnOrAfter="' . $NotOnOrAfter . '">'
        . '<saml:AudienceRestriction><saml:Audience>' . $Issuer . '</saml:Audience></saml:AudienceRestriction>'
        . '</saml:Conditions>'
        . '<saml:AuthnStatement AuthnInstant="' . $NotBefore . '" SessionIndex="_session"/>'
        . '<saml:AttributeStatement>'
        . '<saml:Attribute Name="email"><saml:AttributeValue>'
        . $Param{Email}
        . '</saml:AttributeValue></saml:Attribute>'
        . $GroupAttributes
        . '</saml:AttributeStatement>'
        . '</saml:Assertion>';
};

my $BuildResponse = sub {
    my $Content = shift;

    return '<samlp:Response xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" '
        . 'xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" ID="_response" Version="2.0" '
        . 'IssueInstant="' . $NotBefore . '" '
        . 'Destination="https://example.com/znuny/index.pl?Action=Login" '
        . 'InResponseTo="' . $ExpectedSAMLRequestID . '">'
        . '<saml:Issuer>' . $IdPEntityID . '</saml:Issuer>'
        . '<samlp:Status><samlp:StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Success"/></samlp:Status>'
        . $Content
        . '</samlp:Response>';
};

my $Sign = sub {
    my $XML = shift;

    my $SignedXML = XML::Sig->new(
        {
            key                => $IdPSigningKey,
            cert               => $IdPSigningCert,
            x509               => 1,
            no_xml_declaration => 1,
        }
    )->sign($XML);
    $SignedXML =~ s{\A<\?xml[^>]*\?>\s*}{};

    return $SignedXML;
};

my $SignedAssertion = $Sign->(
    $BuildAssertion->(
        ID     => '_signed',
        NameID => 'unittest@znuny.org',
        Email  => 'unittest@znuny.org',
        Groups => [ 'users', 'faq' ],
    )
);
my $InjectedAssertion = $BuildAssertion->(
    ID     => '_injected',
    NameID => 'unittest@znuny.org',
    Email  => 'attacker@example.com',
    Groups => ['admin'],
);
my $InjectedAssertionWithSignedID = $BuildAssertion->(
    ID     => '_signed',
    NameID => 'unittest@znuny.org',
    Email  => 'attacker@example.com',
    Groups => ['admin'],
);

# Signed whole response with an assertion added afterwards.
my $SignedResponse = $Sign->(
    $BuildResponse->(
        $BuildAssertion->(
            ID     => '_signed',
            NameID => 'unittest@znuny.org',
            Email  => 'unittest@znuny.org',
            Groups => [ 'users', 'faq' ],
        )
    )
);
( my $TamperedSignedResponse = $SignedResponse ) =~ s{</samlp:Response>\s*\z}{$InjectedAssertion</samlp:Response>};

my @Tests = (
    {
        Name     => 'Signed assertion only',
        Response => $BuildResponse->($SignedAssertion),
        Expected => {
            Decoded => 1,
            Groups  => [ 'users', 'faq' ],
            Email   => 'unittest@znuny.org',
        },
    },
    {
        Name     => 'Unsigned assertion added after the signed one',
        Response => $BuildResponse->( $SignedAssertion . $InjectedAssertion ),
        Expected => {
            Decoded => 1,
            Groups  => [ 'users', 'faq' ],
            Email   => 'unittest@znuny.org',
        },
    },
    {
        Name     => 'Unsigned assertion added before the signed one',
        Response => $BuildResponse->( $InjectedAssertion . $SignedAssertion ),
        Expected => {
            Decoded => 1,
            Groups  => [ 'users', 'faq' ],
            Email   => 'unittest@znuny.org',
        },
    },
    {
        Name     => 'Unsigned assertion with the ID of the signed one',
        Response => $BuildResponse->( $SignedAssertion . $InjectedAssertionWithSignedID ),
        Expected => {
            Decoded => 0,
        },
    },
    {
        Name     => 'Signed response with an assertion added afterwards',
        Response => $TamperedSignedResponse,
        Expected => {
            Decoded => 0,
        },
    },
);

TEST:
for my $Test (@Tests) {
    my $ResponseObject = Kernel::System::Auth::SAML::Response->new(
        Count  => 2,
        Config => {
            Issuer    => $Issuer,
            IdPCACert => $IdPSigningCert,
        },
    );

    my $Decoded = $ResponseObject->DecodeResponse(
        Response => MIME::Base64::encode_base64( $Test->{Response}, '' ),
    );

    if ( !$Test->{Expected}->{Decoded} ) {
        $Self->False(
            scalar $Decoded,
            "$Test->{Name}: DecodeResponse() must fail.",
        );
        next TEST;
    }

    $Self->True(
        scalar $Decoded,
        "$Test->{Name}: DecodeResponse() must be successful.",
    );
    $Self->True(
        scalar $ResponseObject->IsValid( ExpectedSAMLRequestID => $ExpectedSAMLRequestID ),
        "$Test->{Name}: IsValid() must be successful.",
    );
    $Self->Is(
        scalar $ResponseObject->GetNameID(),
        'unittest@znuny.org',
        "$Test->{Name}: GetNameID() must return the NameID of the signed assertion.",
    );
    $Self->IsDeeply(
        $ResponseObject->GetAttributeValues('Group'),
        $Test->{Expected}->{Groups},
        "$Test->{Name}: GetAttributeValues() must only return values of the signed assertion.",
    );
    $Self->Is(
        scalar $ResponseObject->GetFirstAttributeValue('email'),
        $Test->{Expected}->{Email},
        "$Test->{Name}: GetFirstAttributeValue() must return the value of the signed assertion.",
    );
}

# GetLogin(): NameID, or the configured login attribute of the signed assertion.
#
{
    no warnings 'once';    ## no critic
    *UnitTest::SAMLLoginAssertionStub::xpath  = sub { return $_[0]->{XPath} };
    *UnitTest::SAMLLoginAssertionStub::id     = sub { return $_[0]->{ID} };
    *UnitTest::SAMLLoginAssertionStub::nameid = sub { return $_[0]->{NameID} };
}

my $LoginAssertionXML = sub {
    my %Param = @_;

    my $Attributes = join '', map {
        my $Attribute = $_;
        '<saml:Attribute Name="'
            . $Attribute->{Name} . '"'
            . ( $Attribute->{FriendlyName} ? ' FriendlyName="' . $Attribute->{FriendlyName} . '"' : '' ) . '>'
            . join( '', map {"<saml:AttributeValue>$_</saml:AttributeValue>"} @{ $Attribute->{Values} } )
            . '</saml:Attribute>';
    } @{ $Param{Attributes} };

    return '<saml:Assertion ID="'
        . $Param{ID}
        . '"><saml:Subject><saml:NameID>persistent-id-123</saml:NameID></saml:Subject>'
        . "<saml:AttributeStatement>$Attributes</saml:AttributeStatement></saml:Assertion>";
};

my $SignedLoginAssertion = $LoginAssertionXML->(
    ID         => '_signed',
    Attributes => [
        {
            Name   => 'uid',
            Values => ['jdoe'],
        },
        {
            Name         => 'urn:oid:0.9.2342.19200300.100.1.3',
            FriendlyName => 'mail',
            Values       => ['jdoe@example.org'],
        },
        {
            Name   => 'memberOf',
            Values => [ 'staff', 'it' ],
        },
    ],
);
my $InjectedLoginAssertion = $LoginAssertionXML->(
    ID         => '_injected',
    Attributes => [
        {
            Name   => 'uid',
            Values => ['admin'],
        },
        {
            Name   => 'employeeNumber',
            Values => ['4711'],
        },
    ],
);

my $GetLogin = sub {
    my %Param = @_;

    my $XML = '<samlp:Response xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" '
        . 'xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion">'
        . $Param{Assertions}
        . '</samlp:Response>';

    my $ResponseObject = Kernel::System::Auth::SAML::Response->new(
        Count  => 2,
        Config => {
            Issuer => $Issuer,
            ( defined $Param{UserLoginAttribute} ? ( UserLoginAttribute => $Param{UserLoginAttribute} ) : () ),
        },
    );

    $ResponseObject->{IsValid}   = 1;
    $ResponseObject->{Assertion} = bless {
        XPath  => XML::LibXML::XPathContext->new( XML::LibXML->load_xml( string => $XML ) ),
        ID     => '_signed',
        NameID => 'persistent-id-123',
        },
        'UnitTest::SAMLLoginAssertionStub';

    return $ResponseObject->GetLogin();
};

my @LoginTests = (
    {
        Name     => 'without login attribute the NameID is the login',
        Expected => 'persistent-id-123',
    },
    {
        Name               => 'login attribute',
        UserLoginAttribute => 'uid',
        Expected           => 'jdoe',
    },
    {
        Name               => 'login attribute by FriendlyName',
        UserLoginAttribute => 'mail',
        Expected           => 'jdoe@example.org',
    },
    {
        Name               => 'first present attribute of a list',
        UserLoginAttribute => [ 'employeeNumber', 'mail' ],
        Expected           => 'jdoe@example.org',
    },
    {
        Name               => 'comma separated list',
        UserLoginAttribute => 'employeeNumber, uid',
        Expected           => 'jdoe',
    },
    {
        Name               => 'attribute with more than one value',
        UserLoginAttribute => 'memberOf',
        Expected           => undef,
    },
    {
        Name               => 'none of the attributes present, no fallback to the NameID',
        UserLoginAttribute => 'employeeNumber',
        Expected           => undef,
    },
    {
        Name               => 'unsigned assertion added before the signed one',
        Assertions         => $InjectedLoginAssertion . $SignedLoginAssertion,
        UserLoginAttribute => 'uid',
        Expected           => 'jdoe',
    },
    {
        Name               => 'attribute only in an unsigned assertion',
        Assertions         => $SignedLoginAssertion . $InjectedLoginAssertion,
        UserLoginAttribute => 'employeeNumber',
        Expected           => undef,
    },
);

for my $Test (@LoginTests) {
    my $Login = $GetLogin->(
        Assertions         => $Test->{Assertions} // $SignedLoginAssertion,
        UserLoginAttribute => $Test->{UserLoginAttribute},
    );

    $Self->Is(
        $Login,
        $Test->{Expected},
        "GetLogin() - $Test->{Name}.",
    );
}

1;
