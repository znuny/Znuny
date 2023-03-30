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

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);

my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
my $UserObject   = $Kernel::OM->Get('Kernel::System::User');
my $GroupObject  = $Kernel::OM->Get('Kernel::System::Group');

#
# TODO
# Tests are deactivated for now  because of problems in CI environment.
#

# #
# # Prepare groups
# #
# GROUP:
# for my $Group (qw( 1st 2nd )) {
#     my $GroupID = $GroupObject->GroupLookup( Group => $Group );
#     next GROUP if $GroupID;

#     $GroupObject->GroupAdd(
#         Name    => $Group,
#         ValidID => 1,
#         UserID  => 1,
#     );
# }

# #
# # LDAP for nested groups testing
# #

# # Note that host and credentials have to be configured in environment variables.
# $ConfigObject->{'AuthModule2'}                      = 'Kernel::System::Auth::LDAP';
# $ConfigObject->{'AuthModule::LDAP::Host2'}          = $ENV{OPENLDAP_HOST};
# $ConfigObject->{'AuthModule::LDAP::BaseDN2'}        = 'dc=planetexpress,dc=com';
# $ConfigObject->{'AuthModule::LDAP::UID2'}           = 'uid';
# $ConfigObject->{'AuthModule::LDAP::SearchUserDN2'}  = $ENV{OPENLDAP_USERDN};
# $ConfigObject->{'AuthModule::LDAP::SearchUserPw2'}  = $ENV{OPENLDAP_USERPASSWORD};
# $ConfigObject->{'AuthModule::LDAP::UserLowerCase2'} = 1;
# $ConfigObject->{'AuthModule::LDAP::Params2'}        = {
#     timeout => 4,
# };

# $ConfigObject->{'AuthSyncModule2'}                     = 'Kernel::System::Auth::Sync::LDAP';
# $ConfigObject->{'AuthSyncModule::LDAP::Host2'}         = $ENV{OPENLDAP_HOST};
# $ConfigObject->{'AuthSyncModule::LDAP::BaseDN2'}       = 'dc=planetexpress,dc=com';
# $ConfigObject->{'AuthSyncModule::LDAP::SearchUserDN2'} = $ENV{OPENLDAP_USERDN};
# $ConfigObject->{'AuthSyncModule::LDAP::SearchUserPw2'} = $ENV{OPENLDAP_USERPASSWORD};
# $ConfigObject->{'AuthSyncModule::LDAP::UID2'}          = 'uid';
# $ConfigObject->{'AuthSyncModule::LDAP::AccessAttr2'}   = 'member';
# $ConfigObject->{'AuthSyncModule::LDAP::UserAttr2'}     = 'DN';
# $ConfigObject->{'AuthSyncModule::LDAP::Params2'}       = {
#     timeout => 4,
# };

# $ConfigObject->{'AuthSyncModule::LDAP::UserSyncMap2'} = {

#     # DB -> LDAP
#     UserFirstname => 'givenName',
#     UserLastname  => 'sn',
#     UserEmail     => 'mail',
# };

# $ConfigObject->{'AuthSyncModule::LDAP::UserSyncGroupsDefinition2'} = {
#     'cn=1st Level,ou=people,dc=planetexpress,dc=com' => {
#         '1st' => { 'rw' => 1 },
#     },
#     'cn=2nd Level,ou=people,dc=planetexpress,dc=com' => {
#         '2nd' => { 'rw' => 1 },
#     },
#     'cn=fallback,ou=people,dc=planetexpress,dc=com' => {
#         'users' => { 'rw' => 1 },
#     },
# };

# # Login uid = password
# # amy, zoidberg, hermes, fry

# # Auth object must be initialized after changes to config above.
# my $AuthObject = $Kernel::OM->Get('Kernel::System::Auth');

# my @Tests = (
#     {
#         NestedGroupSearchActive => 0,
#         User                    => 'amy',
#         ExpectedUser            => 'Amy',
#         ExpectedUserData        => {
#             UserLastname  => 'Kroker',
#             UserEmail     => 'amy@planetexpress.com',
#             UserFirstname => 'Amy',
#         },
#         ExpectedGroups => [ 'users', ],
#     },
#     {
#         NestedGroupSearchActive => 1,
#         User                    => 'amy',
#         ExpectedUser            => 'Amy',
#         ExpectedUserData        => {
#             UserLastname  => 'Kroker',
#             UserEmail     => 'amy@planetexpress.com',
#             UserFirstname => 'Amy',
#         },
#         ExpectedGroups => [ '1st', 'users', ],
#     },
#     {
#         NestedGroupSearchActive => 0,
#         User                    => 'fry',
#         ExpectedUser            => 'fry',
#         ExpectedUserData        => {
#             UserLastname  => 'Fry',
#             UserEmail     => 'fry@planetexpress.com',
#             UserFirstname => 'Philip',
#         },
#         ExpectedGroups => [ 'users', ],
#     },
#     {
#         NestedGroupSearchActive => 1,
#         User                    => 'fry',
#         ExpectedUser            => 'fry',
#         ExpectedUserData        => {
#             UserLastname  => 'Fry',
#             UserEmail     => 'fry@planetexpress.com',
#             UserFirstname => 'Philip',
#         },
#         ExpectedGroups => [ '1st', '2nd', 'users', ],
#     },
# );

# for my $Test (@Tests) {
#     $ConfigObject->{'AuthSyncModule::LDAP::NestedGroupSearch2'} = $Test->{NestedGroupSearchActive};

#     # Re-initialize auth object because it stored the config in itself.
#     $Kernel::OM->ObjectsDiscard(
#         Objects => [ 'Kernel::System::Auth::Sync::LDAP', 'Kernel::System::Auth', ],
#     );
#     $AuthObject = $Kernel::OM->Get('Kernel::System::Auth');

#     my $TestUser = $Test->{User};

#     my $User = $AuthObject->Auth(
#         User => $TestUser,
#         Pw   => $TestUser,
#     );

#     $Self->Is(
#         scalar $User,
#         $Test->{ExpectedUser},
#         "User '$TestUser' must have successfully been authenticated via LDAP.",
#     );

#     my %User = $UserObject->GetUserData(
#         User => $User,
#     );

#     $Self->True(
#         scalar %User,
#         "User '$TestUser' must have been created/updated locally."
#     );

#     for my $UserDataField ( sort keys %{ $Test->{ExpectedUserData} } ) {
#         my $ExpectedValue = $Test->{ExpectedUserData}->{$UserDataField};

#         $Self->Is(
#             scalar $User{$UserDataField},
#             scalar $ExpectedValue,
#             "Field '$UserDataField' must contain expected value.",
#         );
#     }

#     my %Groups = $GroupObject->PermissionUserGroupGet(
#         UserID => $User{UserID},
#         Type   => 'rw',
#     );
#     my @Groups = sort values %Groups;

#     $Self->IsDeeply(
#         \@Groups,
#         $Test->{ExpectedGroups},
#         "User '$User' must be assigned to the expected groups.",
#     );

# }

1;
