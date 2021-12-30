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

use Kernel::System::VariableCheck qw(:all);

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);

my $HelperObject             = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $UnitTestWebserviceObject = $Kernel::OM->Get('Kernel::System::UnitTest::Webservice');
my $ZnunyHelperObject        = $Kernel::OM->Get('Kernel::System::ZnunyHelper');
my $ConfigObject             = $Kernel::OM->Get('Kernel::Config');
my $UserObject               = $Kernel::OM->Get('Kernel::System::User');
my $ValidObject              = $Kernel::OM->Get('Kernel::System::Valid');
my $WebserviceObject         = $Kernel::OM->Get('Kernel::System::GenericInterface::Webservice');
my $DateTimeObject           = $Kernel::OM->Create('Kernel::System::DateTime');
my $GroupObject              = $Kernel::OM->Get('Kernel::System::Group');

my %ValidIDsByName = reverse $ValidObject->ValidList();
my $ValidID        = $ValidIDsByName{valid};

my %Groups = reverse $GroupObject->GroupList();

my $Home = $ConfigObject->Get('Home');

$ZnunyHelperObject->_WebserviceCreateIfNotExists(
    Webservices => {
        OutOfOffice => $Home . '/var/webservices/examples/OutOfOffice.yml',
    },
);

# Activate out-of-office web service in case it is set to invalid.
my $Webservice = $WebserviceObject->WebserviceGet(
    Name => 'OutOfOffice',
);

$WebserviceObject->WebserviceUpdate(
    %{$Webservice},
    ValidID => $ValidID,
    UserID  => 1,
);

$DateTimeObject->Set(
    Year   => 2017,
    Month  => 10,
    Day    => 20,
    Hour   => 15,
    Minute => 28,
    Second => 0,
);

$HelperObject->FixedTimeSet($DateTimeObject);

my %UserData = $HelperObject->TestUserDataGet(
    Groups   => ['users'],
    Language => 'de'
);

my %Credentials = (
    UserLogin => $UserData{UserLogin},
    Password  => $UserData{UserLogin},
);

$Self->True(
    $UserData{UserFullname} !~ m{out \s of \s office \s until \s 2017-10-27/7 \s d}xmsi ? 1 : 0,
    'User fullname contains the information about the out-of-office notice with 7 days remaining'
);

#
# Test with missing credentials
#
$UnitTestWebserviceObject->Process(
    UnitTestObject => $Self,
    Webservice     => 'OutOfOffice',
    Operation      => 'OutOfOffice',
    Payload        => {
        OutOfOfficeEntriesCSVString => "UserEmail,StartDate,EndDate,OutOfOffice
$UserData{UserEmail},2017-10-20,2017-10-27,yes",
    },
    Response => {
        Success => 1,
        Data    => {
            Error => {
                ErrorCode    => 'OutOfOffice.AuthFail',
                ErrorMessage => 'OutOfOffice: Authentication failed.',
            },
        },
        HTTPCode => undef,
        Sort     => undef,
    },
);

#
# Test with user not in group 'admin'
#
$UnitTestWebserviceObject->Process(
    UnitTestObject => $Self,
    Webservice     => 'OutOfOffice',
    Operation      => 'OutOfOffice',
    Payload        => {
        %Credentials,
        OutOfOfficeEntriesCSVString => "UserEmail,StartDate,EndDate,OutOfOffice
$UserData{UserEmail},2017-10-20,2017-10-27,yes",
    },
    Response => {
        Success => 1,
        Data    => {
            Error => {
                ErrorCode    => 'OutOfOffice.AuthFail',
                ErrorMessage => 'OutOfOffice: User needs to be in group admin.',
            },
        },
        HTTPCode => undef,
        Sort     => undef,
    },
);

# Add user to group admin for remaining tests.
$GroupObject->PermissionGroupUserAdd(
    GID        => $Groups{admin},
    UID        => $UserData{UserID},
    Permission => {
        rw => 1,
    },
    UserID => 1,
);

#
# Test with missing CSV string
#
$UnitTestWebserviceObject->Process(
    UnitTestObject => $Self,
    Webservice     => 'OutOfOffice',
    Operation      => 'OutOfOffice',
    Payload        => {
        %Credentials,
    },
    Response => {
        Success      => 0,
        ErrorMessage => 'Parameter OutOfOfficeEntriesCSVString is missing.',
    },
);

#
# Test with invalid CSV string
#
$UnitTestWebserviceObject->Process(
    UnitTestObject => $Self,
    Webservice     => 'OutOfOffice',
    Operation      => 'OutOfOffice',
    Payload        => {
        %Credentials,
        OutOfOfficeEntriesCSVString => 'INVALID',
    },
    Response => {
        Success      => 0,
        ErrorMessage => 'CSV in parameter OutOfOfficeEntriesCSVString does not contain any entries.',
    },
);

#
# Test with user email address
#
$UnitTestWebserviceObject->Process(
    UnitTestObject => $Self,
    Webservice     => 'OutOfOffice',
    Operation      => 'OutOfOffice',
    Payload        => {
        %Credentials,
        OutOfOfficeEntriesCSVString => "UserEmail,StartDate,EndDate,OutOfOffice
$UserData{UserEmail},2017-10-20,2017-10-27,yes",
    },
    Response => {
        Success => 1,
        Data    => {
            'Success' => 1
        },
        HTTPCode => undef,
    },
);

%UserData = $UserObject->GetUserData(
    UserID => $UserData{UserID},
);

$Self->True(
    $UserData{UserFullname} =~ m{out \s of \s office \s until \s 2017-10-27/7 \s d}xmsi ? 1 : 0,
    'User fullname contains the information about the out-of-office notice with 7 days remaining'
);

#
# Test with user search
#
$UnitTestWebserviceObject->Process(
    UnitTestObject => $Self,
    Webservice     => 'OutOfOffice',
    Operation      => 'OutOfOffice',
    Payload        => {
        %Credentials,
        OutOfOfficeEntriesCSVString => "UserSearch,StartDate,EndDate,OutOfOffice
$UserData{UserFirstname},2017-10-20,2017-10-30,yes",
    },
    Response => {
        Success => 1,
        Data    => {
            'Success' => 1
        },
        HTTPCode => undef,
    },
);

%UserData = $UserObject->GetUserData(
    UserID => $UserData{UserID},
);

$Self->True(
    $UserData{UserFullname} =~ m{out \s of \s office \s until \s 2017-10-30/10 \s d}xmsi ? 1 : 0,
    'User fullname contains the information about the out-of-office notice with 10 days remaining'
);

#
# Test with user login
#
$UnitTestWebserviceObject->Process(
    UnitTestObject => $Self,
    Webservice     => 'OutOfOffice',
    Operation      => 'OutOfOffice',
    Payload        => {
        %Credentials,
        OutOfOfficeEntriesCSVString => "UserLogin,StartDate,EndDate,OutOfOffice
$UserData{UserLogin},2017-10-20,2017-10-27,yes",
    },
    Response => {
        Success => 1,
        Data    => {
            'Success' => 1
        },
        HTTPCode => undef,
    },
);

%UserData = $UserObject->GetUserData(
    UserID => $UserData{UserID},
);

$Self->True(
    $UserData{UserFullname} =~ m{out \s of \s office \s until \s 2017-10-27/7 \s d}xmsi ? 1 : 0,
    'User fullname contains the information about the out-of-office notice with 7 days remaining'
);

#
# Test out-of-office flag removal
#
$UnitTestWebserviceObject->Process(
    UnitTestObject => $Self,
    Webservice     => 'OutOfOffice',
    Operation      => 'OutOfOffice',
    Payload        => {
        %Credentials,
        OutOfOfficeEntriesCSVString => "UserLogin,OutOfOffice
$UserData{UserLogin},no",
    },
    Response => {
        Success => 1,
        Data    => {
            'Success' => 1
        },
        HTTPCode => undef,
    },
);

%UserData = $UserObject->GetUserData(
    UserID => $UserData{UserID},
);

$Self->True(
    $UserData{UserFullname} !~ m{out \s of \s office \s until \s 2017-10-27/7 \s d}xmsi ? 1 : 0,
    'User fullname contains no information about the out-of-office notice with 7 days remaining'
);

1;
