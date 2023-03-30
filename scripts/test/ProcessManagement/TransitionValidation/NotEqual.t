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

my $TransitionValidationObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::TransitionValidation::NotEqual');
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
        Name => "Queue: Postmaster != Raw",
        Data => {
            Data => {
                Queue => 'Postmaster'
            },
            FieldName => 'Queue',
            Condition => {
                Type  => 'NotEqual',
                Match => 'Raw',
            },
        },
        ExpectedResult => 1,
    },

    # Integer
    {
        Name => "DynamicField_Text 1 != 0",
        Data => {
            Data => {
                DynamicField_Text => 1
            },
            FieldName => 'DynamicField_Text',
            Condition => {
                Type  => 'NotEqual',
                Match => 0,
            },
        },
        ExpectedResult => 1,
    },

    # Text
    {
        Name => "DynamicField_Text '1' != '0'",
        Data => {
            Data => {
                DynamicField_Text => '1'
            },
            FieldName => 'DynamicField_Text',
            Condition => {
                Type  => 'NotEqual',
                Match => '0',
            },
        },
        ExpectedResult => 1,
    },
    {
        Name => "DynamicField_Text 2 != 1",
        Data => {
            Data => {
                DynamicField_Text => 2
            },
            FieldName => 'DynamicField_Text',
            Condition => {
                Type  => 'NotEqual',
                Match => 1,
            },
        },
        ExpectedResult => 1,
    },

    # TextArea
    {
        Name => "DynamicField_TextArea 1234567890ß´+#äüpöl != 1234567890ß´+#äüpöl",
        Data => {
            Data => {
                DynamicField_TextArea => '1234567890ß´+#äüpöl',
            },
            FieldName => 'DynamicField_TextArea',
            Condition => {
                Type  => 'NotEqual',
                Match => '1234567890ß´+#äüpöl',
            },
        },
        ExpectedResult => 0,
    },

    # Date
    {
        Name => "DynamicField_Date 2020-10-01 != 2020-10-01 00:00:00",
        Data => {
            Data => {
                DynamicField_Date => '2020-10-01',
            },
            FieldName => 'DynamicField_Date',
            Condition => {
                Type  => 'NotEqual',
                Match => '2020-10-01 00:00:00',
            },
        },
        ExpectedResult => 0,
    },

    # DateTime
    {
        Name => "DynamicField_DateTime 2020-09-01 10:09:00 != 2020-09-01 10:00:00",
        Data => {
            Data => {
                DynamicField_DateTime => '2020-09-01 10:09:00',
            },
            FieldName => 'DynamicField_DateTime',
            Condition => {
                Type  => 'NotEqual',
                Match => '2020-09-01 10:00:00',
            },
        },
        ExpectedResult => 1,
    },

    # Dropdown
    {
        Name => "DynamicField_Dropdown 1 != 2",
        Data => {
            Data => {
                DynamicField_Dropdown => '1',
            },
            FieldName => 'DynamicField_Dropdown',
            Condition => {
                Type  => 'NotEqual',
                Match => '2',
            },
        },
        ExpectedResult => 1,
    },

    # Multiselect
    {
        Name => "DynamicField_Multiselect [ 1, 2, 3 ] != 1",
        Data => {
            Data => {
                DynamicField_Multiselect => [ 1, 2, 3 ],
            },
            FieldName => 'DynamicField_Multiselect',
            Condition => {
                Type  => 'NotEqual',
                Match => '1',
            },
        },
        ExpectedResult => 0,
    },
    {
        Name => "DynamicField_Multiselect [ 1, 2, 3 ] != [ 1, 2, 3 ]",
        Data => {
            Data => {
                DynamicField_Multiselect => [ 1, 2, 3 ],
            },
            FieldName => 'DynamicField_Multiselect',
            Condition => {
                Type  => 'NotEqual',
                Match => [ 1, 2, 3 ],
            },
        },
        ExpectedResult => 0,
    },
    {
        Name => "DynamicField_Multiselect [ 1 ] != [ 1 ]",
        Data => {
            Data => {
                DynamicField_Multiselect => [1],
            },
            FieldName => 'DynamicField_Multiselect',
            Condition => {
                Type  => 'NotEqual',
                Match => [1],
            },
        },
        ExpectedResult => 0,
    },
    {
        Name => "DynamicField_Multiselect [ 1, 2, 3 ] != [ 1, 2 ]",
        Data => {
            Data => {
                DynamicField_Multiselect => [ 1, 2, 3 ],
            },
            FieldName => 'DynamicField_Multiselect',
            Condition => {
                Type  => 'NotEqual',
                Match => [ 1, 2 ],
            },
        },
        ExpectedResult => 1,
    },
    {
        Name => "DynamicField_Multiselect [ 1 ] != [ 1, 2, 3 ]",
        Data => {
            Data => {
                DynamicField_Multiselect => [1],
            },
            FieldName => 'DynamicField_Multiselect',
            Condition => {
                Type  => 'NotEqual',
                Match => [ 1, 2, 3 ],
            },
        },
        ExpectedResult => 1,
    },
    {
        Name => "DynamicField_Multiselect [ 1, 2, 3 ] != 1, 2, 3 DynamicField_Multiselect2",
        Data => {
            Data => {
                DynamicField_Multiselect => [ 1, 2, 3 ],
            },
            FieldName => 'DynamicField_Multiselect',
            Condition => {
                Type  => 'NotEqual',
                Match => "1, 2, 3",
            },
        },
        ExpectedResult => 1,
    },
    {
        Name => "DynamicField_Multiselect [ 1, 2, 3 ] != [ 1, 2, 3 ] DynamicField_Multiselect2",
        Data => {
            Data => {
                DynamicField_Multiselect  => [ 1, 2, 3 ],
                DynamicField_Multiselect2 => [ 1, 2, 3 ],
            },
            FieldName => 'DynamicField_Multiselect',
            Condition => {
                Type  => 'NotEqual',
                Match => "<OTRS_TICKET_DynamicField_Multiselect2>",
            },
        },
        ExpectedResult => 1,
    },
    {
        Name => "DynamicField_Multiselect 1 != 4",
        Data => {
            Data => {
                DynamicField_Multiselect => [ 1, 2, 3 ],
            },
            FieldName => 'DynamicField_Multiselect',
            Condition => {
                Type  => 'NotEqual',
                Match => '4',
            },
        },
        ExpectedResult => 1,
    },

    # Lowercase
    {
        Name => "DynamicField_Text: raw != RAW",
        Data => {
            Data => {
                DynamicField_Text => 'raw'
            },
            FieldName => 'DynamicField_Text',
            Condition => {
                Type  => 'NotEqual',
                Match => 'RAW',
            },
        },
        ExpectedResult => 0,
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
