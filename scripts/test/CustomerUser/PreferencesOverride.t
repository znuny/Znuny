# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
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

my $CustomerUserObject = $Kernel::OM->Get('Kernel::System::CustomerUser');

$Kernel::OM->Get('Kernel::Config')->Set(
    Key   => 'CheckEmailAddresses',
    Value => 0,
);

my $RandomID = $HelperObject->GetRandomID();

my $UserID = $CustomerUserObject->CustomerUserAdd(
    Source         => 'CustomerUser',
    UserFirstname  => 'Firstname Test',
    UserLastname   => 'Lastname Test',
    UserCustomerID => $RandomID . '-Customer-Id',
    UserLogin      => $RandomID,
    UserEmail      => $RandomID . '-Email@example.com',
    UserPassword   => 'some_pass',
    ValidID        => 1,
    UserID         => 1,
);

my %CustomerData = $CustomerUserObject->CustomerUserDataGet(
    User => $UserID,
);

KEY:
for my $Key ( sort keys %CustomerData ) {

    # Skip some data that comes from default values.
    next KEY if $Key =~ m/Config$/smx;
    next KEY if $Key =~ m/RefreshTime$/smx;
    next KEY if $Key =~ m/ShowTickets$/smx;
    next KEY if $Key eq 'Source';
    next KEY if $Key eq 'CustomerCompanyValidID';
    next KEY if $Key eq 'UserLanguage';

    # Skip dropdown-values of last views
    next KEY if $Key =~ m{\AUserLastViews};

    $Self->False(
        $CustomerUserObject->SetPreferences(
            Key    => $Key,
            Value  => '1',
            UserID => $UserID,
        ),
        "Preference for $Key not updated"
    );

    my %NewCustomerData = $CustomerUserObject->CustomerUserDataGet(
        User => $UserID,
    );
    $Self->Is(
        $NewCustomerData{$Key},
        $CustomerData{$Key},
        "Customer data $Key unchanged"
    );
}

# cleanup is done by RestoreDatabase

1;
