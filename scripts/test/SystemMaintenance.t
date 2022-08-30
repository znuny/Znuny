# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));

use Kernel::System::VariableCheck qw(:all);

# get needed objects
my $ConfigObject            = $Kernel::OM->Get('Kernel::Config');
my $SystemMaintenanceObject = $Kernel::OM->Get('Kernel::System::SystemMaintenance');
my $DateTimeObject          = $Kernel::OM->Create('Kernel::System::DateTime');

# get helper object
$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

# initialize variables
my $RandomID = $HelperObject->GetRandomID();
my $UserID   = 1;
my $Index    = 1;

my @Tests = (

    {
        Name       => 'Test ' . $Index++ . ' - Without any data',
        SuccessAdd => 0,
    },
    {
        Name       => 'Test ' . $Index++ . ' - Without StartDate',
        SuccessAdd => 0,
        Add        => {
            StopDate         => '2014-05-02 16:01:00',
            Comment          => 'Comment',
            LoginMessage     => 'A login message.',
            ShowLoginMessage => 1,
            NotifyMessage    => 'The notification text.',
            ValidID          => 1,
            UserID           => $UserID,
        },
    },
    {
        Name       => 'Test ' . $Index++ . ' - Without StopDate',
        SuccessAdd => 0,
        Add        => {
            StartDate        => '2014-05-02 16:01:00',
            Comment          => 'Comment',
            LoginMessage     => 'A login message.',
            ShowLoginMessage => 1,
            NotifyMessage    => 'The notification text.',
            ValidID          => 1,
            UserID           => $UserID,
        },
    },
    {
        Name       => 'Test ' . $Index++ . ' - With a wrong StartDate',
        SuccessAdd => 0,
        Add        => {
            StartDate        => 'Not a date',
            Comment          => 'Comment',
            LoginMessage     => 'A login message.',
            ShowLoginMessage => 1,
            NotifyMessage    => 'The notification text.',
            ValidID          => 1,
            UserID           => $UserID,
        },
    },
    {
        Name       => 'Test ' . $Index++ . ' - With a wrong StopDate',
        SuccessAdd => 0,
        Add        => {
            StopDate         => 'AnyString',
            Comment          => 'Comment',
            LoginMessage     => 'A login message.',
            ShowLoginMessage => 1,
            NotifyMessage    => 'The notification text.',
            ValidID          => 1,
            UserID           => $UserID,
        },
    },
    {
        Name       => 'Test ' . $Index++ . '- StartDate after StopDate',
        SuccessAdd => 0,
        Add        => {
            StartDate        => '2014-05-02 14:55:01',
            StopDate         => '2014-05-02 14:55:00',
            Comment          => 'Comment',
            LoginMessage     => 'A login message.',
            ShowLoginMessage => 1,
            NotifyMessage    => 'The notification text.',
            ValidID          => 1,
            UserID           => $UserID,
        },
    },
    {
        Name       => 'Test ' . $Index++ . ' - Without ValidID',
        SuccessAdd => 0,
        Add        => {
            StartDate        => '2014-05-02 14:55:00',
            StopDate         => '2014-05-02 16:01:00',
            Comment          => 'Comment',
            LoginMessage     => 'A login message.',
            ShowLoginMessage => 1,
            NotifyMessage    => 'The notification text.',
            UserID           => $UserID,
        },
    },
    {
        Name       => 'Test ' . $Index++ . ' - Without UserID',
        SuccessAdd => 0,
        Add        => {
            StartDate        => '2014-05-02 14:55:00',
            StopDate         => '2014-05-02 16:01:00',
            Comment          => 'Comment',
            LoginMessage     => 'A login message.',
            ShowLoginMessage => 1,
            NotifyMessage    => 'The notification text.',
            ValidID          => 1,
        },
    },

    {
        Name          => 'Test ' . $Index++ . '- Without Comment',
        SuccessAdd    => 0,
        SuccessUpdate => 0,
        Add           => {
            StartDate        => '2014-05-02 14:55:00',
            StopDate         => '2014-05-02 16:01:00',
            LoginMessage     => 'A login message.',
            ShowLoginMessage => 1,
            NotifyMessage    => 'The notification text.',
            ValidID          => 1,
            UserID           => $UserID,
        },
    },
    {
        Name          => 'Test ' . $Index++ . '- Without LoginMessage',
        SuccessAdd    => 1,
        SuccessUpdate => 1,
        Add           => {
            StartDate        => '2014-05-02 14:55:00',
            StopDate         => '2014-05-02 16:01:00',
            Comment          => 'Comment' . $RandomID,
            ShowLoginMessage => 1,
            NotifyMessage    => 'The notification text.',
            ValidID          => 1,
            UserID           => $UserID,
        },
    },
    {
        Name          => 'Test ' . $Index++ . '- Without ShowLoginMessage',
        SuccessAdd    => 1,
        SuccessUpdate => 1,
        Add           => {
            StartDate     => '2014-05-02 14:55:00',
            StopDate      => '2014-05-02 16:01:00',
            Comment       => 'Comment' . $RandomID,
            LoginMessage  => 'A login message.',
            NotifyMessage => 'The notification text.',
            ValidID       => 1,
            UserID        => $UserID,
        },
    },
    {
        Name          => 'Test ' . $Index++ . '- Without NotifyMessage',
        SuccessAdd    => 1,
        SuccessUpdate => 1,
        Add           => {
            StartDate        => '2014-05-02 14:55:00',
            StopDate         => '2014-05-02 16:01:00',
            Comment          => 'Comment' . $RandomID,
            LoginMessage     => 'A login message.',
            ShowLoginMessage => 1,
            ValidID          => 1,
            UserID           => $UserID,
        },
    },
    {
        Name          => 'Test ' . $Index++ . '',
        SuccessAdd    => 1,
        SuccessUpdate => 1,
        Add           => {
            StartDate        => '2014-05-02 14:55:00',
            StopDate         => '2014-05-02 16:01:00',
            Comment          => 'Comment' . $RandomID,
            LoginMessage     => 'A login message.',
            ShowLoginMessage => 1,
            ValidID          => 1,
            UserID           => $UserID,
        },
    },
    {
        Name          => 'Test ' . $Index++ . '- LoginMessage equal 250 characters',
        SuccessAdd    => 1,
        SuccessUpdate => 0,
        Add           => {
            StartDate        => '2014-05-02 14:55:00',
            StopDate         => '2014-05-02 16:01:00',
            Comment          => 'Comment' . $RandomID,
            LoginMessage     => 'a' x 250,
            ShowLoginMessage => 1,
            ValidID          => 1,
            UserID           => $UserID,
        },
    },
    {
        Name          => 'Test ' . $Index++ . '- NotifyMessage equal 250 characters',
        SuccessAdd    => 1,
        SuccessUpdate => 0,
        Add           => {
            StartDate     => '2014-05-02 14:55:00',
            StopDate      => '2014-05-02 16:01:00',
            Comment       => 'Comment' . $RandomID,
            NotifyMessage => 'a' x 250,
            ValidID       => 1,
            UserID        => $UserID,
        },
    },
    {
        Name          => 'Test ' . $Index++ . '- LoginMessage longer then 250 characters',
        SuccessAdd    => 0,
        SuccessUpdate => 0,
        Add           => {
            StartDate        => '2014-05-02 14:55:00',
            StopDate         => '2014-05-02 16:01:00',
            Comment          => 'Comment' . $RandomID,
            LoginMessage     => 'a' x 251,
            ShowLoginMessage => 1,
            ValidID          => 1,
            UserID           => $UserID,
        },
    },
    {
        Name          => 'Test ' . $Index++ . '- NotifyMessage longer then 250 characters',
        SuccessAdd    => 0,
        SuccessUpdate => 0,
        Add           => {
            StartDate     => '2014-05-02 14:55:00',
            StopDate      => '2014-05-02 16:01:00',
            Comment       => 'Comment' . $RandomID,
            NotifyMessage => 'a' x 251,
            ValidID       => 1,
            UserID        => $UserID,
        },
    },
);

my @SystemMaintenanceIDs;
TEST:
for my $Test (@Tests) {

    for my $Date (qw(StartDate StopDate)) {
        my $ConvertionResult;
        my $DateTimeObject = $Kernel::OM->Create(
            'Kernel::System::DateTime',
            ObjectParams => {
                String => $Test->{Add}->{$Date},
            }
        );
        if ($DateTimeObject) {
            $ConvertionResult = $DateTimeObject->ToEpoch();
        }
        $Test->{Add}->{$Date} = $ConvertionResult || $Test->{Add}->{$Date};
    }

    # add system maintenance
    my $SystemMaintenanceID = $SystemMaintenanceObject->SystemMaintenanceAdd(
        Name => $Test->{Name},
        %{ $Test->{Add} }
    );
    if ( !$Test->{SuccessAdd} ) {
        $Self->False(
            $SystemMaintenanceID,
            "$Test->{Name} - SystemMaintenanceAdd()",
        );
        next TEST;
    }
    else {
        $Self->True(
            $SystemMaintenanceID,
            "$Test->{Name} - SystemMaintenanceAdd()",
        );
    }

    # remember id to delete it later
    push @SystemMaintenanceIDs, $SystemMaintenanceID;

    # get system maintenance
    my $SystemMaintenance = $SystemMaintenanceObject->SystemMaintenanceGet(
        ID     => $SystemMaintenanceID,
        UserID => $UserID,
    );

    # verify values
    $Self->True(
        $SystemMaintenanceID,
        "$Test->{Name} - SystemMaintenanceGet() - ID",
    );

    $Self->Is(
        $Test->{Add}->{StartDate},
        $SystemMaintenance->{StartDate},
        "$Test->{Name} - SystemMaintenanceGet() - StartDate",
    );

    $Self->Is(
        $Test->{Add}->{StopDate},
        $SystemMaintenance->{StopDate},
        "$Test->{Name} - SystemMaintenanceGet() - StopDate",
    );

    $Self->Is(
        $Test->{Add}->{Comment},
        $SystemMaintenance->{Comment},
        "$Test->{Name} - SystemMaintenanceGet() - Comment",
    );

    $Self->Is(
        $Test->{Add}->{LoginMessage},
        $SystemMaintenance->{LoginMessage},
        "$Test->{Name} - SystemMaintenanceGet() - LoginMessage",
    );

    $Self->Is(
        $Test->{Add}->{ShowLoginMessage},
        $SystemMaintenance->{ShowLoginMessage},
        "$Test->{Name} - SystemMaintenanceGet() - ShowLoginMessage",
    );

    $Self->Is(
        $Test->{Add}->{NotifyMessage},
        $SystemMaintenance->{NotifyMessage},
        "$Test->{Name} - SystemMaintenanceGet() - NotifyMessage",
    );

    # duplicate on update entry
    if ( !$Test->{Update} ) {
        $Test->{Update} = $Test->{Add};
    }

    # modify dates
    for my $Key (qw(StartDate StopDate)) {
        if ( defined $Test->{Update}->{$Key} && IsPositiveInteger( $Test->{Update}->{$Key} ) ) {
            $Test->{Update}->{$Key} += 30;
        }
    }

    # modify strings
    for my $Key (qw(comment LoginMessage NotifyMessage)) {
        if ( defined $Test->{Update}->{$Key} && IsString( $Test->{Update}->{$Key} ) ) {
            $Test->{Update}->{$Key} .= ' - Mod';
        }
    }

    # modify boolean
    if ( $Test->{Update}->{ShowLoginMessage} eq '1' ) {
        $Test->{Update}->{ShowLoginMessage} = '0';
    }
    elsif ( $Test->{Update}->{ShowLoginMessage} eq '0' ) {
        $Test->{Update}->{ShowLoginMessage} = '1';
    }

    # update entry
    if ( !$Test->{Update} ) {
        $Test->{Update} = $Test->{Add};
    }
    my $Success = $SystemMaintenanceObject->SystemMaintenanceUpdate(
        ID   => $SystemMaintenanceID,
        Name => $Test->{Name},
        %{ $Test->{Update} }
    );
    if ( !$Test->{SuccessUpdate} ) {
        $Self->False(
            $Success,
            "$Test->{Name} - SystemMaintenanceUpdate() False",
        );
        next TEST;
    }
    else {
        $Self->True(
            $Success,
            "$Test->{Name} - SystemMaintenanceUpdate() True",
        );
    }

    # get data
    $SystemMaintenance = $SystemMaintenanceObject->SystemMaintenanceGet(
        ID     => $SystemMaintenanceID,
        UserID => 1,
    );

    # verify values
    $Self->Is(
        $SystemMaintenanceID,
        $SystemMaintenance->{ID},
        "$Test->{Name} - SystemMaintenanceGet() - ID",
    );

    $Self->Is(
        $Test->{Update}->{StartDate},
        $SystemMaintenance->{StartDate},
        "$Test->{Name} - SystemMaintenanceGet() - StartDate",
    );

    $Self->Is(
        $Test->{Update}->{StopDate},
        $SystemMaintenance->{StopDate},
        "$Test->{Name} - SystemMaintenanceGet() - StopDate",
    );

    $Self->Is(
        $Test->{Update}->{Comment},
        $SystemMaintenance->{Comment},
        "$Test->{Name} - SystemMaintenanceGet() - Comment",
    );

    $Self->Is(
        $Test->{Update}->{LoginMessage},
        $SystemMaintenance->{LoginMessage},
        "$Test->{Name} - SystemMaintenanceGet() - LoginMessage",
    );

    $Self->Is(
        $Test->{Update}->{ShowLoginMessage},
        $SystemMaintenance->{ShowLoginMessage},
        "$Test->{Name} - SystemMaintenanceGet() - ShowLoginMessage",
    );

    $Self->Is(
        $Test->{Update}->{NotifyMessage},
        $SystemMaintenance->{NotifyMessage},
        "$Test->{Name} - SystemMaintenanceGet() - NotifyMessage",
    );

}

# list check from DB
my $SystemMaintenanceList = $SystemMaintenanceObject->SystemMaintenanceList(
    Valid  => 1,
    UserID => $UserID,
);
for my $SystemMaintenanceID (@SystemMaintenanceIDs) {

    $Self->True(
        scalar $SystemMaintenanceList->{$SystemMaintenanceID},
        "SystemMaintenanceList() from DB found SystemMaintenance $SystemMaintenanceID",
    );
}

# list check from DB
my $SystemMaintenanceListGet = $SystemMaintenanceObject->SystemMaintenanceListGet(
    Valid  => 1,
    UserID => $UserID,
);
for my $SystemMaintenanceID (@SystemMaintenanceIDs) {

    my $TestResult = grep { $_->{ID} eq $SystemMaintenanceID } @{$SystemMaintenanceListGet};

    $Self->True(

        # scalar $SystemMaintenanceList->{$SystemMaintenanceID},
        $TestResult,
        "SystemMaintenanceListGet() from DB found SystemMaintenance $SystemMaintenanceID",
    );
}

# delete system maintenance
for my $SystemMaintenanceID (@SystemMaintenanceIDs) {
    my $Success = $SystemMaintenanceObject->SystemMaintenanceDelete(
        ID     => $SystemMaintenanceID,
        UserID => 1,
    );
    $Self->True(
        $Success,
        "SystemMaintenanceDelete() deleted SystemMaintenance $SystemMaintenanceID",
    );

    $Success = $SystemMaintenanceObject->SystemMaintenanceDelete(
        ID     => $SystemMaintenanceID,
        UserID => 1,
    );
    $Self->False(
        $Success,
        "SystemMaintenanceDelete() not available SystemMaintenance $SystemMaintenanceID",
    );

    # get system maintenance
    my $SystemMaintenance = $SystemMaintenanceObject->SystemMaintenanceGet(
        ID     => $SystemMaintenanceID,
        UserID => $UserID,
    );

    $Self->False(
        $SystemMaintenance,
        "SystemMaintenanceGet() retrieve SystemMaintenance $SystemMaintenanceID",
    );

}

# Time Base Tests

$ConfigObject->Set(
    Key   => 'SystemMaintenance::TimeNotifyUpcomingMaintenance',
    Value => 30,
);

@Tests = (
    {
        Name         => 'Test ' . $Index++ . ' -',
        StartDate    => '2014-01-10 12:00:00',
        StopDate     => '2014-01-10 14:59:59',
        FixedTimeSet => '2014-01-10 13:00:00',
        Comment      => 'Comment',
        IsActive     => 1,
        IsComming    => 0,
    },
    {
        Name         => 'Test ' . $Index++ . ' -',
        StartDate    => '2014-01-10 12:00:00',
        StopDate     => '2014-01-10 14:59:59',
        FixedTimeSet => '2014-01-10 11:59:59',
        Comment      => 'Comment',
        IsActive     => 0,
        IsComming    => 1,
    },
    {
        Name         => 'Test ' . $Index++ . ' -',
        StartDate    => '2014-01-10 12:00:00',
        StopDate     => '2014-01-10 14:59:59',
        FixedTimeSet => '2014-01-10 15:00:00',
        Comment      => 'Comment',
        IsActive     => 0,
        IsComming    => 0,
    },
);

for my $Test (@Tests) {

    for my $Date (qw(StartDate StopDate)) {
        my $ConvertionResult = $Kernel::OM->Create(
            'Kernel::System::DateTime',
            ObjectParams => {
                String => $Test->{$Date},
            }
        )->ToEpoch();
        $Test->{$Date} = $ConvertionResult || $Test->{$Date};
    }

    my $SystemMaintenanceID = $SystemMaintenanceObject->SystemMaintenanceAdd(
        StartDate => $Test->{StartDate},
        StopDate  => $Test->{StopDate},
        Comment   => 'Comment',
        ValidID   => 1,
        UserID    => $UserID,
    );

    $HelperObject->FixedTimeSet(
        $Kernel::OM->Create(
            'Kernel::System::DateTime',
            ObjectParams => {
                String => $Test->{FixedTimeSet}
            }
        )->ToEpoch(),
    );

    my %IsComming = $Kernel::OM->Get('Kernel::System::SystemMaintenance')->SystemMaintenanceIsComing();

    if ( $Test->{IsComming} ) {

        $Self->True(
            $IsComming{StartDate},
            "$Test->{Name} A system maintenance period is comming!",
        );
    }
    else {

        $Self->False(
            $IsComming{StartDate},
            "$Test->{Name} A system maintenance period is not comming!",
        );
    }

    my $IsActive = $Kernel::OM->Get('Kernel::System::SystemMaintenance')->SystemMaintenanceIsActive();

    if ( $Test->{IsActive} ) {

        $Self->True(
            $IsActive,
            "$Test->{Name} A system maintenance period is active!",
        );
    }
    else {

        $Self->False(
            $IsActive,
            "$Test->{Name} A system maintenance period is not active!",
        );
    }

    # delete test record
    my $Success = $SystemMaintenanceObject->SystemMaintenanceDelete(
        ID     => $SystemMaintenanceID,
        UserID => 1,
    );
    $Self->True(
        $Success,
        "SystemMaintenanceDelete() deleted SystemMaintenance $SystemMaintenanceID",
    );

}

# cleanup is done by RestoreDatabase

1;
