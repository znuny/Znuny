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

my $TransitionValidationObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::TransitionValidation::Contains');
my $ZnunyHelperObject          = $Kernel::OM->Get('Kernel::System::ZnunyHelper');
my $HelperObject               = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $TicketObject               = $Kernel::OM->Get('Kernel::System::Ticket');

my @DynamicFields = (
    {
        Name       => 'Text',
        Label      => "Text",
        ObjectType => 'Ticket',
        FieldType  => 'Text',
        Config     => {
            DefaultValue => "",
        },
    },
    {
        Name       => 'TextArea',
        Label      => "TextArea",
        ObjectType => 'Ticket',
        FieldType  => 'TextArea',
        Config     => {
            DefaultValue => "",
        },
    },
    {
        Name       => 'Dropdown',
        Label      => "Dropdown",
        ObjectType => 'Ticket',
        FieldType  => 'Dropdown',
        Config     => {
            DefaultValue   => "",
            PossibleValues => {
                1 => 1,
                2 => 2,
                3 => 3,
            }
        },
    },
    {
        Name       => 'Date',
        Label      => "Date",
        ObjectType => 'Ticket',
        FieldType  => 'Date',
        Config     => {
            DefaultValue => "",
        },
    },
    {
        Name       => 'DateTime',
        Label      => "DateTime",
        ObjectType => 'Ticket',
        FieldType  => 'DateTime',
        Config     => {
            DefaultValue => "",
        },
    },
    {
        Name       => 'Multiselect',
        Label      => "Multiselect",
        ObjectType => 'Ticket',
        FieldType  => 'Multiselect',
        Config     => {
            DefaultValue   => "",
            PossibleValues => {
                1 => 1,
                2 => 2,
                3 => 3,
            }
        },
    },
    {
        Name       => 'Multiselect2',
        Label      => "Multiselect2",
        ObjectType => 'Ticket',
        FieldType  => 'Multiselect',
        Config     => {
            DefaultValue   => "",
            PossibleValues => {
                1 => 1,
                2 => 2,
                3 => 3,
            }
        },
    },
);

my $Result = $ZnunyHelperObject->_DynamicFieldsCreate(@DynamicFields);

my @Tests = (

    {
        Name => "No Data - undef",
        Data => {
            Data => {
            },
            FieldName => 'Queue',
            Condition => {},
        },
        ExpectedResult => undef,
    },

    # String
    {
        Name => "Queue: Postmaster =~ Raw",
        Data => {
            Data => {
                Queue => 'Postmaster'
            },
            FieldName => 'Queue',
            Condition => {
                Type  => 'Contains',
                Match => 'Raw',
            },
        },
        ExpectedResult => 0,
    },
    {
        Name => "Queue: Postmaster =~ master",
        Data => {
            Data => {
                Queue => 'Postmaster'
            },
            FieldName => 'Queue',
            Condition => {
                Type  => 'Contains',
                Match => 'master',
            },
        },
        ExpectedResult => 1,
    },

    # Integer
    {
        Name => "DynamicField_Text 0 =~ 0",
        Data => {
            Data => {
                DynamicField_Text => 0
            },
            FieldName => 'DynamicField_Text',
            Condition => {
                Type  => 'Contains',
                Match => 0,
            },
        },
        ExpectedResult => 1,
    },
    {
        Name => "DynamicField_Text 1 =~ 0",
        Data => {
            Data => {
                DynamicField_Text => 1
            },
            FieldName => 'DynamicField_Text',
            Condition => {
                Type  => 'Contains',
                Match => 0,
            },
        },
        ExpectedResult => 0,
    },

    # Text
    {
        Name => "DynamicField_Text Junk = Junk",
        Data => {
            Data => {
                DynamicField_Text  => 'Queue',
                DynamicField_Queue => 'Junk',
                Queue              => 'Junk',
            },
            FieldName => '<OTRS_TICKET_DynamicField_Text>',
            Condition => {
                Type  => 'Contains',
                Match => '<OTRS_TICKET_DynamicField_Queue>',
            },
        },
        ExpectedResult => 1,
    },

);

for my $Test (@Tests) {
    my $TicketID = $HelperObject->TicketCreate(
        %{ $Test->{Data}->{Data} },
    );

    ATTRIBUTE:
    for my $Attribute ( sort keys %{ $Test->{Data}->{Data} } ) {
        next ATTRIBUTE if !( $Attribute =~ m{DynamicField_(.*)} );

        my $DynamicField = $1;
        my $Value        = $Test->{Data}->{Data}->{$Attribute};

        my $Success = $HelperObject->DynamicFieldSet(
            Field    => $DynamicField,
            ObjectID => $TicketID,
            Value    => $Value,
        );
    }

    my %Ticket = $TicketObject->TicketGet(
        TicketID      => $TicketID,
        DynamicFields => 1,
        UserID        => 1,
    );

    my $ValidateResult = $TransitionValidationObject->Validate(
        Data => \%Ticket,
        %{ $Test->{Data} },
    );

    $Self->Is(
        $ValidateResult,
        $Test->{ExpectedResult},
        "Expected ExpectedResult ($Test->{Name})",
    );
}

1;
