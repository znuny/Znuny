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

use MIME::Base64;

use Kernel::System::Auth::SAML;
use Kernel::System::Auth::Sync::SAML;

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);

my $HelperObject      = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $ConfigObject      = $Kernel::OM->Get('Kernel::Config');
my $UserObject        = $Kernel::OM->Get('Kernel::System::User');
my $GroupObject       = $Kernel::OM->Get('Kernel::System::Group');
my $ZnunyHelperObject = $Kernel::OM->Get('Kernel::System::ZnunyHelper');

$ConfigObject->Set(
    Key   => 'CheckEmailAddresses',
    Value => 0,
);

$ConfigObject->Set(
    Key   => 'CheckMXRecord',
    Value => 0,
);

# Create test groups
my %GroupIDByName;
my %GroupNameByID;
for my $Count ( 1 .. 8 ) {
    my $GroupName = "ZnunyGroup$Count";

    my $GroupID = $ZnunyHelperObject->_GroupCreateIfNotExists(
        Name => $GroupName,
    );

    $GroupIDByName{$GroupName} = $GroupID;
    $GroupNameByID{$GroupID}   = $GroupName;
}

# Create test roles
my %RoleIDByName;
my %RoleNameByID;
for my $Count ( 1 .. 8 ) {
    my $RoleName = "ZnunyRole$Count";

    my $RoleID = $ZnunyHelperObject->_RoleCreateIfNotExists(
        Name => $RoleName,
    );

    $RoleIDByName{$RoleName} = $RoleID;
    $RoleNameByID{$RoleID}   = $RoleName;
}

#
# SAML config
#
$ConfigObject->Set(
    Key   => 'AuthModule2',
    Value => 'Kernel::System::Auth::SAML',
);

$ConfigObject->Set(
    Key   => 'AuthModule::SAML::RequestLoginButtonText2',
    Value => 'Log in via SAML (test)',
);

$ConfigObject->Set(
    Key   => 'AuthModule::SAML::RequestAssertionConsumerURL2',
    Value => ( $ConfigObject->Get('HttpType') // '' ) . '://'
        . $ConfigObject->Get('FQDN') . '/'
        . $ConfigObject->Get('ScriptAlias')
        . 'index.pl?Action=Login',
);

$ConfigObject->Set(
    Key   => 'AuthModule::SAML::RequestMetaDataXML2',
    Value => '<md:EntitiesDescriptor xmlns="urn:oasis:names:tc:SAML:2.0:metadata"
    xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata"
    xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
    xmlns:ds="http://www.w3.org/2000/09/xmldsig#" Name="urn:keycloak">
    <md:EntityDescriptor xmlns="urn:oasis:names:tc:SAML:2.0:metadata"
        xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata"
        xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
        xmlns:ds="http://www.w3.org/2000/09/xmldsig#" entityID="https://example.org/auth/realms/master">
        <md:IDPSSODescriptor WantAuthnRequestsSigned="true" protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
            <md:KeyDescriptor use="signing">
                <ds:KeyInfo>
                    <ds:KeyName>8FWM0j6Eg-sBQ25fxpQQ1ZDiDSpPRnOG9fa4iUzx_Z8</ds:KeyName>
                    <ds:X509Data>
                        <ds:X509Certificate>...</ds:X509Certificate>
                    </ds:X509Data>
                </ds:KeyInfo>
            </md:KeyDescriptor>
            <md:SingleLogoutService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST" Location="https://example.org/auth/realms/master/protocol/saml"/>
            <md:SingleLogoutService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect" Location="https://example.org/auth/realms/master/protocol/saml"/>
            <md:NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:persistent</md:NameIDFormat>
            <md:NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:transient</md:NameIDFormat>
            <md:NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified</md:NameIDFormat>
            <md:NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress</md:NameIDFormat>
            <md:SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST" Location="https://example.org/auth/realms/master/protocol/saml"/>
            <md:SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect" Location="https://example.org/auth/realms/master/protocol/saml"/>
            <md:SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP" Location="https://example.org/auth/realms/master/protocol/saml"/>
        </md:IDPSSODescriptor>
    </md:EntityDescriptor>
</md:EntitiesDescriptor>',
);

my $Issuer = 'https://example.org/znuny/';

$ConfigObject->Set(
    Key   => 'AuthModule::SAML::Issuer2',
    Value => $Issuer,
);

$ConfigObject->Set(
    Key   => 'AuthSyncModule2',
    Value => 'Kernel::System::Auth::Sync::SAML',
);

# references to the Name attribute like <saml:Attribute FriendlyName="email" Name="email">
$ConfigObject->Set(
    Key   => 'AuthSyncModule::SAML::UserSyncMap2',
    Value => {
        UserFirstname => 'firstname',
        UserLastname  => 'lastname',
        UserEmail     => 'email',
    },
);

$Self->{'AuthSyncModule::SAML::UserSyncInitialGroups2'} = [
    'users',
    'stats',
];

$ConfigObject->Set(
    Key   => 'AuthSyncModule::SAML::UserSyncGroupsDefinition::Attribute2',
    Value => 'MemberOf',
);

$ConfigObject->Set(
    Key   => 'AuthSyncModule::SAML::UserSyncGroupsDefinition2',
    Value => {
        SomeGroup => {
            ZnunyGroup6 => {
                ro => 1,
            },
        },
        Support => {
            ZnunyGroup1 => {
                rw => 1,
            },
            ZnunyGroup2 => {
                ro   => 1,
                note => 1,
            },
        },
    },
);

$ConfigObject->Set(
    Key   => 'AuthSyncModule::SAML::UserSyncAttributeGroupsDefinition2',
    Value => {
        SomeAttribute1 => {
            'Value 1' => {
                admin => {
                    rw => 1,
                },
                ZnunyGroup3 => {
                    ro => 1,
                },
            },
        },
        SomeAttribute2 => {
            'Value 2' => {
                ZnunyGroup4 => {
                    rw => 1,
                },
            },
            'Value 1' => {
                ZnunyGroup5 => {
                    ro => 1,
                },
            },
        },
    },
);

$ConfigObject->Set(
    Key   => 'AuthSyncModule::SAML::UserSyncRolesDefinition::Attribute2',
    Value => 'Role',
);

$ConfigObject->Set(
    Key   => 'AuthSyncModule::SAML::UserSyncRolesDefinition2',
    Value => {
        Operations => {
            ZnunyRole1 => 1,
            ZnunyRole2 => 0,
        },
    },
);

$ConfigObject->Set(
    Key   => 'AuthSyncModule::SAML::UserSyncAttributeRolesDefinition2',
    Value => {
        SomeAttribute1 => {
            'Value 1' => {
                ZnunyRole3 => 1,
                ZnunyRole4 => 1,
            },
        },
        SomeAttribute2 => {
            'Value 2' => {
                ZnunyRole5 => 0,
                ZnunyRole6 => 1,
                ZnunyRole7 => 1,
            },
        },
    },
);

#
# Create a test user, assigned only to group "users" and without roles.
#
my ( $TestUserLogin, $TestUserID ) = $HelperObject->TestUserCreate(
    Groups    => [ 'users', ],
    Language  => 'en',
    KeepValid => 1,
);

my $UserFirstname = 'John';
my $UserLastname  = 'Doe';

#
# Create test auth object with sample SAML response
#
my $SAMLAuthObject = Kernel::System::Auth::SAML->new(
    Count => 2,
);

my $ExpectedSAMLRequestID = '_54c307de-960b-11f0-b741-ecb5948c096d';

my $SAMLResponseXML = '<samlp:Response xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol"
    xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" Destination="https://example.com/znuny/index.pl?Action=Login" ID="ID_aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee" InResponseTo="'
    . $ExpectedSAMLRequestID
    . '" IssueInstant="2025-09-20T10:19:46.253Z" Version="2.0">
    <saml:Issuer>' . $Issuer . '</saml:Issuer>
    <samlp:Status>
        <samlp:StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Success"/>
    </samlp:Status>
    <saml:Assertion xmlns="urn:oasis:names:tc:SAML:2.0:assertion" ID="ID_aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee" IssueInstant="2025-09-20T10:19:46.253Z" Version="2.0">
        <saml:Issuer>' . $Issuer . '</saml:Issuer>
        <saml:Subject>
            <saml:NameID Format="urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress">'
    . $TestUserLogin
    . '</saml:NameID>
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
                    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">'
    . $TestUserLogin
    . '</saml:AttributeValue>
            </saml:Attribute>
            <saml:Attribute FriendlyName="firstname" Name="firstname" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
                <saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema"
                    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">'
    . $UserFirstname
    . '</saml:AttributeValue>
            </saml:Attribute>
            <saml:Attribute FriendlyName="lastname" Name="lastname" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
                <saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema"
                    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">'
    . $UserLastname
    . '</saml:AttributeValue>
            </saml:Attribute>
            <saml:Attribute FriendlyName="city" Name="city" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
                <saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema"
                    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">Berlin</saml:AttributeValue>
            </saml:Attribute>
            <saml:Attribute Name="MemberOf" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
                <saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema"
                    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">Reporting</saml:AttributeValue>
            </saml:Attribute>
            <saml:Attribute Name="MemberOf" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
                <saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema"
                    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">Support</saml:AttributeValue>
            </saml:Attribute>
            <saml:Attribute Name="MemberOf" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
                <saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema"
                    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">Admin</saml:AttributeValue>
            </saml:Attribute>
            <saml:Attribute Name="MemberOf" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
                <saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema"
                    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">SomeGroup</saml:AttributeValue>
            </saml:Attribute>
            <saml:Attribute Name="MemberOf" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
                <saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema"
                    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">Users</saml:AttributeValue>
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

            <saml:Attribute Name="SomeAttribute1" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
                <saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema"
                    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">Value 1</saml:AttributeValue>
            </saml:Attribute>
            <saml:Attribute Name="SomeAttribute2" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
                <saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema"
                    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">Value 1</saml:AttributeValue>
            </saml:Attribute>
            <saml:Attribute Name="SomeAttribute2" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
                <saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema"
                    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">Value 2</saml:AttributeValue>
            </saml:Attribute>
        </saml:AttributeStatement>
    </saml:Assertion>
</samlp:Response>';

my $SAMLResponseXMLBase64 = MIME::Base64::encode_base64($SAMLResponseXML);

$SAMLAuthObject->{Response}->DecodeResponse(
    Response => $SAMLResponseXMLBase64,
    UnitTest => 1,
);

$Self->True(
    $SAMLAuthObject->{Response}->IsValid( ExpectedSAMLRequestID => $ExpectedSAMLRequestID ),
    'IsValid() must be successful.',
);

my $SAMLAuthSyncObject = Kernel::System::Auth::Sync::SAML->new(
    Count        => 2,
    AuthBackend2 => $SAMLAuthObject,
);

#
# Check that test user only has group 'users' and no roles
#
my %GroupsByType;
for my $Type ( @{ $ConfigObject->Get('System::Permission') } ) {
    my %Data = $GroupObject->PermissionUserGroupGet(
        UserID => $TestUserID,
        Type   => $Type,
    );

    $GroupsByType{$Type} = { map { $_ => 1 } values %Data };
}

my %ExpectedGroupsByType = (
    create => {
        users => 1,
    },
    move_into => {
        users => 1,
    },
    note => {
        users => 1,
    },
    owner => {
        users => 1,
    },
    priority => {
        users => 1,
    },
    ro => {
        users => 1,
    },
    rw => {
        users => 1,
    },
);

$Self->IsDeeply(
    \%GroupsByType,
    \%ExpectedGroupsByType,
    'Test user is assigned to group "users".',
);

#
# Check that test user has no roles
#
my %Roles = $GroupObject->PermissionUserRoleGet(
    UserID => $TestUserID,
);
%Roles = map { $_ => 1 } values %Roles;

my %ExpectedRoles;

$Self->IsDeeply(
    \%Roles,
    \%ExpectedRoles,
    'Test user has no roles assigned.',
);

$SAMLAuthSyncObject->Sync(
    User => $TestUserLogin,
);

#
# Check that name has been set
#
my %TestUser = $UserObject->GetUserData(
    User => $TestUserLogin,
);

$Self->Is(
    scalar $TestUser{UserFirstname},
    $UserFirstname,
    "User's first name must match expected one.",
);

$Self->Is(
    scalar $TestUser{UserLastname},
    $UserLastname,
    "User's last name must match expected one.",
);

#
# Check that assigned groups match config
#
for my $Type ( @{ $ConfigObject->Get('System::Permission') } ) {
    my %Data = $GroupObject->PermissionUserGroupGet(
        UserID => $TestUserID,
        Type   => $Type,
    );

    $GroupsByType{$Type} = { map { $_ => 1 } values %Data };
}

%ExpectedGroupsByType = (
    create => {
        ZnunyGroup1 => 1,
        ZnunyGroup4 => 1,
        admin       => 1
    },
    move_into => {
        ZnunyGroup1 => 1,
        ZnunyGroup4 => 1,
        admin       => 1
    },
    note => {
        ZnunyGroup1 => 1,
        ZnunyGroup2 => 1,
        ZnunyGroup4 => 1,
        admin       => 1
    },
    owner => {
        ZnunyGroup1 => 1,
        ZnunyGroup4 => 1,
        admin       => 1
    },
    priority => {
        ZnunyGroup1 => 1,
        ZnunyGroup4 => 1,
        admin       => 1
    },
    ro => {
        ZnunyGroup1 => 1,
        ZnunyGroup2 => 1,
        ZnunyGroup3 => 1,
        ZnunyGroup4 => 1,
        ZnunyGroup5 => 1,
        ZnunyGroup6 => 1,
        admin       => 1
    },
    rw => {
        ZnunyGroup1 => 1,
        ZnunyGroup4 => 1,
        admin       => 1
    }
);

$Self->IsDeeply(
    \%GroupsByType,
    \%ExpectedGroupsByType,
    'Test user is assigned to expected groups.',
);

#
# Check that assigned roles match config
#
%Roles = $GroupObject->PermissionUserRoleGet(
    UserID => $TestUserID,
);
%Roles = map { $_ => 1 } values %Roles;

%ExpectedRoles = (
    ZnunyRole1 => 1,
    ZnunyRole3 => 1,
    ZnunyRole4 => 1,
    ZnunyRole6 => 1,
    ZnunyRole7 => 1,
);

$Self->IsDeeply(
    \%Roles,
    \%ExpectedRoles,
    'Test user is assigned to expected roles.',
);

1;
