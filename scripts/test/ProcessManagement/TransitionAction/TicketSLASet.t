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
my $ServiceObject          = $Kernel::OM->Get('Kernel::System::Service');
my $SLAObject              = $Kernel::OM->Get('Kernel::System::SLA');
my $TicketObject           = $Kernel::OM->Get('Kernel::System::Ticket');
my $TransitionActionObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::TransitionAction::TicketSLASet');

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
my $ModuleName = 'TicketSLASet';
my $RandomID   = $HelperObject->GetRandomID();

# add a customer user
my $TestCustomerUserLogin = $HelperObject->TestCustomerUserCreate();

# set user details
my ( $TestUserLogin, $TestUserID ) = $HelperObject->TestUserCreate();

#
# Create new services
#
my @Services = (
    {
        Name    => 'Service0' . $RandomID,
        ValidID => 1,
        UserID  => 1,
    },
);

for my $ServiceData (@Services) {
    my $ServiceID = $ServiceObject->ServiceAdd( %{$ServiceData} );

    # sanity test
    $Self->IsNot(
        $ServiceID,
        undef,
        "ServiceAdd() for $ServiceData->{Name}, ServiceID should not be undef",
    );

    $ServiceObject->CustomerUserServiceMemberAdd(
        CustomerUserLogin => 'customer@example.com',
        ServiceID         => $ServiceID,
        Active            => 1,
        UserID            => 1,
    );

    # store the ServiceID
    $ServiceData->{ServiceID} = $ServiceID;
}

#
# Create new SLAs
#
my @SLAs = (
    {
        Name       => 'SLA0' . $RandomID,
        ServiceIDs => [ $Services[0]->{ServiceID} ],
        ValidID    => 1,
        UserID     => 1,
    },
    {
        Name       => 'SLA1' . $RandomID,
        ServiceIDs => [ $Services[0]->{ServiceID} ],
        ValidID    => 1,
        UserID     => 1,
    },
    {
        Name       => 'SLA2' . $RandomID,
        ServiceIDs => [],
        ValidID    => 1,
        UserID     => 1,
    },
);

for my $SLAData (@SLAs) {
    my $SLAID = $SLAObject->SLAAdd( %{$SLAData} );

    # sanity test
    $Self->IsNot(
        $SLAID,
        undef,
        "SLAAdd() for $SLAData->{Name}, SLAID should not be undef",
    );

    # store the SLAID
    $SLAData->{SLAID} = $SLAID;
}

#
# Assign services to customer (0 and 1)
#
my $Success = $ServiceObject->CustomerUserServiceMemberAdd(
    CustomerUserLogin => $TestCustomerUserLogin,
    ServiceID         => $Services[0]->{ServiceID},
    Active            => 1,
    UserID            => 1,
);

# sanity test
$Self->True(
    $Success,
    "CustomerUserServiceMemberAdd() for user $TestCustomerUserLogin, and Service $Services[0]->{Name}"
        . " with true",
);

#
# Create a test tickets
#
my @TicketData;
for my $Item ( 0 .. 1 ) {
    my $TicketID = $TicketObject->TicketCreate(
        Title         => ( $Item == 0 ) ? $SLAs[0]->{SLAID} : 'test',
        QueueID       => 1,
        Lock          => 'unlock',
        Priority      => '3 normal',
        StateID       => 1,
        TypeID        => 1,
        Service       => ( $Item == 0 ) ? $Services[0]->{Name} : undef,
        CustomerUser  => ( $Item == 0 ) ? $TestCustomerUserLogin : undef,
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

    push @TicketData, \%Ticket;
}

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
            Ticket => $TicketData[0],
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
            Ticket => $TicketData[0],
            Config => {},
        },
        Success => 0,
    },
    {
        Name   => 'Wrong Config',
        Config => {
            UserID => $UserID,
            Ticket => $TicketData[0],
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
                SLA => 'open',
            },
        },
        Success => 0,
    },
    {
        Name   => 'Wrong Config Format',
        Config => {
            UserID => $UserID,
            Ticket => $TicketData[0],
            Config => 1,
        },
        Success => 0,
    },
    {
        Name   => 'Wrong SLA',
        Config => {
            UserID => $UserID,
            Ticket => $TicketData[0],
            Config => {
                SLA => 'NotExisting' . $RandomID,
            },
        },
        Success => 0,
    },
    {
        Name   => 'Wrong SLAID',
        Config => {
            UserID => $UserID,
            Ticket => $TicketData[0],
            Config => {
                SLAID => 'NotExisting' . $RandomID,
            },
        },
        Success => 0,
    },
    {
        Name   => 'Not assigned SLA',
        Config => {
            UserID => $UserID,
            Ticket => $TicketData[0],
            Config => {
                SLA => $SLAs[2]->{Name},
            },
        },
        Success => 0,
    },
    {
        Name   => 'Not Assigned SLAID',
        Config => {
            UserID => $UserID,
            Ticket => $TicketData[0],
            Config => {
                SLAID => $SLAs[2]->{SLAID},
            },
        },
        Success => 0,
    },
    {
        Name   => "Ticket without service with SLA $SLAs[0]->{Name}",
        Config => {
            UserID => $UserID,
            Ticket => $TicketData[1],
            Config => {
                SLAID => $SLAs[0]->{Name},
            },
        },
        Success => 0,
    },
    {
        Name   => "Ticket without service with SLAID $SLAs[1]->{Name}",
        Config => {
            UserID => $UserID,
            Ticket => $TicketData[1],
            Config => {
                SLAID => $SLAs[0]->{SLAID},
            },
        },
        Success => 0,
    },
    {
        Name   => "Correct SLA $SLAs[0]->{Name}",
        Config => {
            UserID => $UserID,
            Ticket => $TicketData[0],
            Config => {
                SLA => $SLAs[0]->{Name},
            },
        },
        Success => 1,
    },
    {
        Name   => "Correct SLA $SLAs[1]->{Name}",
        Config => {
            UserID => $UserID,
            Ticket => $TicketData[0],
            Config => {
                SLA => $SLAs[1]->{Name},
            },
        },
        Success => 1,
    },
    {
        Name   => "Correct SLAID $SLAs[0]->{Name}",
        Config => {
            UserID => $UserID,
            Ticket => $TicketData[0],
            Config => {
                SLAID => $SLAs[0]->{SLAID},
            },
        },
        Success => 1,
    },
    {
        Name   => "Correct SLAID $SLAs[1]->{Name}",
        Config => {
            UserID => $UserID,
            Ticket => $TicketData[0],
            Config => {
                SLAID => $SLAs[0]->{SLAID},
            },
        },
        Success => 1,
    },
    {
        Name   => "Correct Ticket->Title",
        Config => {
            UserID => $UserID,
            Ticket => $TicketData[0],
            Config => {
                SLAID => '<OTRS_TICKET_Title>',
            },
        },
        Success => 1,
    },
    {
        Name   => "Correct Ticket->NotExisting",
        Config => {
            UserID => $UserID,
            Ticket => $TicketData[0],
            Config => {
                SLAID => '<OTRS_TICKET_NotExisting>',
            },
        },
        Success => 0,
    },
    {
        Name   => "Correct Using Different UserID",
        Config => {
            UserID => $UserID,
            Ticket => $TicketData[0],
            Config => {
                SLA    => $SLAs[0]->{Name},
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
        my $TicketID = $TicketData[0]->{TicketID};
        if ( $Test->{Config}->{Ticket}->{TicketID} eq $TicketData[1]->{TicketID} ) {
            $TicketID = $TicketData[1]->{TicketID};
        }
        my %Ticket = $TicketObject->TicketGet(
            TicketID => $TicketID,
            UserID   => 1,
        );

        ATTRIBUTE:
        for my $Attribute ( sort keys %{ $Test->{Config}->{Config} } ) {

            $Self->True(
                defined $Ticket{$Attribute},
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

my $TicketID        = $HelperObject->TicketCreate();
my $ForeignTicketID = $HelperObject->TicketCreate();

$TicketObject->TicketServiceSet(
    Service  => 'Service0' . $RandomID,
    TicketID => $ForeignTicketID,
    UserID   => 1,
);

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

my %Ticket = $TicketObject->TicketGet(
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
        SLA             => 'SLA0' . $RandomID,
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
    $ForeignTicket{SLA},
    'SLA0' . $RandomID,
    'value in foreign ticket got set',
);

# cleanup is done by RestoreDatabase.

1;
