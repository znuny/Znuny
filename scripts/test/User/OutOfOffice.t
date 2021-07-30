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

my $HelperObject   = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $SessionObject  = $Kernel::OM->Get('Kernel::System::AuthSession');
my $UserObject     = $Kernel::OM->Get('Kernel::System::User');
my $ConfigObject   = $Kernel::OM->Get('Kernel::Config');
my $DateTimeObject = $Kernel::OM->Create('Kernel::System::DateTime');

# Set some out-of-office message.
$ConfigObject->Set(
    Key   => 'OutOfOffice::DisplayAgentLoggedInMessage',
    Value => '*** logged in ***',
);
$ConfigObject->Set(
    Key   => 'OutOfOffice::DisplayAgentLoggedOutMessage',
    Value => '*** logged out ***',
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
    Groups   => [ 'admin', 'users' ],
    Language => 'de'
);

$Self->True(
    $UserData{UserFullname} =~ m{logged \s out}xmsi ? 1 : 0,
    'user fullname contains the information about the logged out user'
);

# create new session id
my $NewSessionID = $SessionObject->CreateSessionID(
    %UserData,
    UserLastRequest => $Kernel::OM->Create('Kernel::System::DateTime')->ToEpoch(),
    UserType        => 'User',
);

my $TrueResult = $Self->True(
    $NewSessionID,
    'created session for test user',
);

%UserData = $UserObject->GetUserData(
    UserID => $UserData{UserID},
);

$Self->True(
    $UserData{UserFullname} =~ m{logged \s in}xmsi ? 1 : 0,
    'user fullname contains the information about the logged in user'
);

$SessionObject->RemoveSessionID( SessionID => $NewSessionID );

%UserData = $UserObject->GetUserData(
    UserID => $UserData{UserID},
);

$Self->True(
    $UserData{UserFullname} =~ m{logged \s out}xmsi ? 1 : 0,
    'user fullname contains the information about the logged out user'
);

$UserObject->SetPreferences(
    Key    => 'OutOfOffice',
    Value  => 1,
    UserID => $UserData{UserID},
);
$UserObject->SetPreferences(
    Key    => 'OutOfOfficeStartYear',
    Value  => '2017',
    UserID => $UserData{UserID},
);
$UserObject->SetPreferences(
    Key    => 'OutOfOfficeStartMonth',
    Value  => '10',
    UserID => $UserData{UserID},
);
$UserObject->SetPreferences(
    Key    => 'OutOfOfficeStartDay',
    Value  => '20',
    UserID => $UserData{UserID},
);
$UserObject->SetPreferences(
    Key    => 'OutOfOfficeEndYear',
    Value  => '2017',
    UserID => $UserData{UserID},
);
$UserObject->SetPreferences(
    Key    => 'OutOfOfficeEndMonth',
    Value  => '10',
    UserID => $UserData{UserID},
);
$UserObject->SetPreferences(
    Key    => 'OutOfOfficeEndDay',
    Value  => '27',
    UserID => $UserData{UserID},
);

%UserData = $UserObject->GetUserData(
    UserID => $UserData{UserID},
);

$Self->True(
    $UserData{UserFullname} =~ m{logged \s out}xmsi ? 1 : 0,
    'User fullname contains the information about the logged out user'
);

$Self->True(
    $UserData{UserFullname} =~ m{out \s of \s office \s until \s 2017-10-27/7 \s d}xmsi ? 1 : 0,
    'User fullname contains the information about the out of office notice with 7 days remaining'
);

$HelperObject->FixedTimeUnset();

1;
