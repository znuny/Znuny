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

use Kernel::System::VariableCheck qw(:all);

# get needed objects
my $TicketObject              = $Kernel::OM->Get('Kernel::System::Ticket');
my $TransitionActionObject    = $Kernel::OM->Get('Kernel::System::ProcessManagement::TransitionAction::TicketLockSet');
my $DynamicFieldObject        = $Kernel::OM->Get('Kernel::System::DynamicField');
my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

# get helper object
$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase  => 1,
        UseTmpArticleDir => 1,
    },
);
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

# define variables
my $UserID     = 1;
my $ModuleName = 'TicketLockSet';
my $RandomID   = $HelperObject->GetRandomID();

# set user details
my ( $TestUserLogin, $TestUserID ) = $HelperObject->TestUserCreate();

#
# Create a test ticket
#
my $TicketID = $TicketObject->TicketCreate(
    Title         => 'test',
    QueueID       => 1,
    Lock          => 'lock',       # This value is specially important for this test
    Priority      => '3 normal',
    StateID       => 1,
    TypeID        => 1,
    OwnerID       => 1,
    ResponsibleID => 1,
    UserID        => $UserID,
);

# sanity checks
$Self->True(
    $TicketID,
    "TicketCreate() - $TicketID",
);

my %Ticket = $TicketObject->TicketGet(
    TicketID => $TicketID,
    UserID   => $UserID,
);
$Self->True(
    IsHashRefWithData( \%Ticket ),
    "TicketGet() - Get Ticket with ID $TicketID.",
);

# Run() tests
my @Tests = (
    {
        Name    => 'No Params',
        Config  => undef,
        Success => 0,
    },
    {
        Name   => 'No UserID',
        Config => {
            UserID => undef,
            Ticket => \%Ticket,
            Config => {
                CustomerID => 'test',
            },
        },
        Success => 0,
    },
    {
        Name   => 'No Ticket',
        Config => {
            UserID => $UserID,
            Ticket => undef,
            Config => {
                CustomerID => 'test',
            },
        },
        Success => 0,
    },
    {
        Name   => 'No Config',
        Config => {
            UserID => $UserID,
            Ticket => \%Ticket,
            Config => {},
        },
        Success => 0,
    },
    {
        Name   => 'Wrong Config',
        Config => {
            UserID => $UserID,
            Ticket => \%Ticket,
            Config => {
                NoAgentNotify => 0,
            },
        },
        Success => 0,
    },
    {
        Name   => 'Wrong Ticket Format',
        Config => {
            UserID => $UserID,
            Ticket => 1,
            Config => {
                Lock => 'lock',
            },
        },
        Success => 0,
    },
    {
        Name   => 'Wrong Config Format',
        Config => {
            UserID => $UserID,
            Ticket => \%Ticket,
            Config => 1,
        },
        Success => 0,
    },
    {
        Name   => 'Wrong Lock',
        Config => {
            UserID => $UserID,
            Ticket => \%Ticket,
            Config => {
                Lock => 'NotExisting' . $RandomID,
            },
        },
        Success => 0,
    },
    {
        Name   => 'Wrong LockID',
        Config => {
            UserID => $UserID,
            Ticket => \%Ticket,
            Config => {
                LockID => 'NotExisting' . $RandomID,
            },
        },
        Success => 0,
    },
    {
        Name   => 'Correct Lock unlock',
        Config => {
            UserID => $UserID,
            Ticket => \%Ticket,
            Config => {
                Lock => 'unlock',
            },
        },
        Success => 1,
    },
    {
        Name   => 'Correct Lock lock',
        Config => {
            UserID => $UserID,
            Ticket => \%Ticket,
            Config => {
                Lock => 'lock',
            },
        },
        Success => 1,
    },
    {
        Name   => 'Correct LockID unlock',
        Config => {
            UserID => $UserID,
            Ticket => \%Ticket,
            Config => {
                LockID => 1,
            },
        },
        Success => 1,
    },
    {
        Name   => 'Correct LockID lock',
        Config => {
            UserID => $UserID,
            Ticket => \%Ticket,
            Config => {
                LockID => 2,
            },
        },
        Success => 1,
    },
    {
        Name   => 'Correct Ticket->QueueID',
        Config => {
            UserID => $UserID,
            Ticket => \%Ticket,
            Config => {
                LockID => '<OTRS_TICKET_QueueID>',
            },
        },
        Success => 1,
    },
    {
        Name   => 'Wrong Ticket->NotExisiting',
        Config => {
            UserID => $UserID,
            Ticket => \%Ticket,
            Config => {
                Lock => '<OTRS_TICKET_BotExisting>',
            },
        },
        Success => 0,
    },
    {
        Name   => 'Correct Using Different UserID',
        Config => {
            UserID => $UserID,
            Ticket => \%Ticket,
            Config => {
                Lock   => 'unlock',
                UserID => $TestUserID,
            },
        },
        Success => 1,
    },
);

for my $Test (@Tests) {

    # make a deep copy to avoid changing the definition
    my $OrigTest = Storable::dclone($Test);

    my $Success = $TransitionActionObject->Run(
        %{ $Test->{Config} },
        ProcessEntityID          => 'P1',
        ActivityEntityID         => 'A1',
        TransitionEntityID       => 'T1',
        TransitionActionEntityID => 'TA1',
    );

    if ( $Test->{Success} ) {

        $Self->True(
            $Success,
            "$ModuleName Run() - Test:'$Test->{Name}' | executed with True"
        );

        # get ticket
        %Ticket = $TicketObject->TicketGet(
            TicketID => $TicketID,
            UserID   => 1,
        );

        ATTRIBUTE:
        for my $Attribute ( sort keys %{ $Test->{Config}->{Config} } ) {

            $Self->True(
                $Ticket{$Attribute},
                "$ModuleName - Test:'$Test->{Name}' | Attribute: $Attribute for TicketID:"
                    . " $TicketID exists with True",
            );

            my $ExpectedValue = $Test->{Config}->{Config}->{$Attribute};
            if (
                $OrigTest->{Config}->{Config}->{$Attribute}
                =~ m{\A<OTRS_TICKET_([A-Za-z0-9_]+)>\z}msx
                )
            {
                $ExpectedValue = $Ticket{$1} // '';
                $Self->IsNot(
                    $Test->{Config}->{Config}->{$Attribute},
                    $OrigTest->{Config}->{Config}->{$Attribute},
                    "$ModuleName - Test:'$Test->{Name}' | Attribute: $Attribute value: $OrigTest->{Config}->{Config}->{$Attribute} should been replaced",
                );
            }

            $Self->Is(
                $Ticket{$Attribute},
                $ExpectedValue,
                "$ModuleName - Test:'$Test->{Name}' | Attribute: $Attribute for TicketID:"
                    . " $TicketID match expected value",
            );
        }

        if ( $OrigTest->{Config}->{Config}->{UserID} ) {
            $Self->Is(
                $Test->{Config}->{Config}->{UserID},
                undef,
                "$ModuleName - Test:'$Test->{Name}' | Attribute: UserID for TicketID:"
                    . " $TicketID should be removed (as it was used)",
            );
        }
    }
    else {
        $Self->False(
            $Success,
            "$ModuleName Run() - Test:'$Test->{Name}' | executed with False"
        );
    }
}

# Run TransitionAction with ForeignTicketID
# create a dynamic field
my $DFForeignTicketID = 'UnitTestForeignTicketID' . $RandomID;
my $DFForeignID       = $DynamicFieldObject->DynamicFieldAdd(
    FieldOrder => 9991,
    Name       => $DFForeignTicketID,
    Label      => $DFForeignTicketID,
    ObjectType => 'Ticket',
    FieldType  => 'Text',
    Config     => {
        DefaultValue => '',
    },
    ValidID => 1,
    UserID  => 1,
);

my $ForeignTicketID = $HelperObject->TicketCreate();

my $DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
    Name => $DFForeignTicketID,
);

my $ValueSet = $DynamicFieldBackendObject->ValueSet(
    DynamicFieldConfig => $DynamicFieldConfig,
    ObjectID           => $TicketID,
    Value              => $ForeignTicketID,
    UserID             => 1,
);

$Self->True(
    $ValueSet,
    "ValueSet()",
);

%Ticket = $TicketObject->TicketGet(
    TicketID      => $TicketID,
    DynamicFields => 1,
    UserID        => 1,
);

my $DynamicFieldSetResult = $TransitionActionObject->Run(
    UserID                   => 1,
    Ticket                   => \%Ticket,
    ProcessEntityID          => 'P123',
    ActivityEntityID         => 'A123',
    TransitionEntityID       => 'T123',
    TransitionActionEntityID => 'TA123',
    Config                   => {
        ForeignTicketID => '<OTRS_Ticket_DynamicField_' . $DFForeignTicketID . '>',
        Lock            => 'lock',
        UserID          => 1,
    },
);

$Self->True(
    $DynamicFieldSetResult,
    "TransitionActionObject->Run()",
);

my %ForeignTicket = $TicketObject->TicketGet(
    TicketID      => $ForeignTicketID,
    DynamicFields => 1,
    UserID        => 1,
);

$Self->Is(
    $ForeignTicket{Lock},
    'lock',
    'value in foreign ticket got set',
);

# cleanup is done by RestoreDatabase.

1;
