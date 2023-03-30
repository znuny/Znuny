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

my $ZnunyHelperObject    = $Kernel::OM->Get('Kernel::System::ZnunyHelper');
my $UnitTestHelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $GenericAgentObject   = $Kernel::OM->Get('Kernel::System::GenericAgent');

# Test export
my @Tests = (
    {
        Name     => '_GenericAgentCreate - create new GA',
        Function => '_GenericAgentCreate',
        Data     => [
            {
                Name => 'UnitTestJob',
                Data => {
                    Valid => '1',

                    # Event based execution (single ticket)
                    EventValues => [
                        'TicketCreate'
                    ],

                    # Select Tickets
                    LockIDs => [
                        '1'
                    ],

                    # Update/Add Ticket Attributes
                    NewLockID => '2',
                },
                UserID => 1,
            },
        ],
        ExpectedResult => {
            Name => 'UnitTestJob',
            Data => {
                Valid => '1',

                # Event based execution (single ticket)
                EventValues => [
                    'TicketCreate'
                ],

                # Select Tickets
                LockIDs => [
                    '1'
                ],

                # Update/Add Ticket Attributes
                NewLockID => '2',
            },
            UserID => 1,
        },
    },
    {
        Name     => '_GenericAgentCreate - update GA',
        Function => '_GenericAgentCreate',
        Data     => [
            {
                Name => 'UnitTestJob',
                Data => {
                    Valid => '3',

                    # Event based execution (single ticket)
                    EventValues => [
                        'TicketCreate'
                    ],

                    # Select Tickets
                    LockIDs => [
                        '1'
                    ],

                    # Update/Add Ticket Attributes
                    NewLockID => '2',
                },
                UserID => 1,
            },
        ],
        ExpectedResult => {
            Name => 'UnitTestJob',
            Data => {
                Valid => '3',

                # Event based execution (single ticket)
                EventValues => [
                    'TicketCreate'
                ],

                # Select Tickets
                LockIDs => [
                    '1'
                ],

                # Update/Add Ticket Attributes
                NewLockID => '2',
            },
            UserID => 1,
        },
    },
    {
        Name     => '_GenericAgentCreateIfNotExists - create a new GA',
        Function => '_GenericAgentCreateIfNotExists',
        Data     => [
            {
                Name => 'UnitTestJobIfNotExists',
                Data => {
                    Valid => '3',

                    # Event based execution (single ticket)
                    EventValues => [
                        'TicketCreate'
                    ],

                    # Select Tickets
                    LockIDs => [
                        '1'
                    ],

                    # Update/Add Ticket Attributes
                    NewLockID => '2',
                },
                UserID => 1,
            },
        ],
        ExpectedResult => {
            Name => 'UnitTestJobIfNotExists',
            Data => {
                Valid => '3',

                # Event based execution (single ticket)
                EventValues => [
                    'TicketCreate'
                ],

                # Select Tickets
                LockIDs => [
                    '1'
                ],

                # Update/Add Ticket Attributes
                NewLockID => '2',
            },
            UserID => 1,
        },
    },

    {
        Name     => '_GenericAgentCreateIfNotExists - no changes',
        Function => '_GenericAgentCreateIfNotExists',
        Data     => [
            {
                Name => 'UnitTestJobIfNotExists',
                Data => {
                    Valid => '1',

                    # Event based execution (single ticket)
                    EventValues => [
                        'TicketCreate'
                    ],

                    # Select Tickets
                    LockIDs => [
                        '2'
                    ],

                    # Update/Add Ticket Attributes
                    NewLockID => '2',
                },
                UserID => 1,
            },
        ],
        ExpectedResult => {
            Name => 'UnitTestJobIfNotExists',
            Data => {
                Valid => '3',

                # Event based execution (single ticket)
                EventValues => [
                    'TicketCreate'
                ],

                # Select Tickets
                LockIDs => [
                    '1'
                ],

                # Update/Add Ticket Attributes
                NewLockID => '2',
            },
            UserID => 1,
        },
    },
);

TEST:
for my $Test (@Tests) {

    my $Function = $Test->{Function};

    my $Success = $ZnunyHelperObject->$Function( @{ $Test->{Data} } );

    $Self->True(
        $Success,
        "$Function was successful.",
    );

    for my $Job ( @{ $Test->{Data} } ) {

        my %CreatedJob = $GenericAgentObject->JobGet( Name => $Job->{Name} );

        # prepare jobs to diff correctly
        my %ExpectedJob = %{ $Test->{ExpectedResult} };

        delete $ExpectedJob{UserID};
        delete $ExpectedJob{Name};

        my %CreatedJobDiff = (
            Data => {
                %CreatedJob,
            },
        );
        delete $CreatedJobDiff{Data}->{Name};

        my $IsDeeplyResult = $Self->IsDeeply(
            \%ExpectedJob,
            \%CreatedJobDiff,
            "Created data via $Function are correct.",
        );

    }

}

1;
