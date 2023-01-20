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

my $TransitionValidationBaseObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::TransitionValidation::Base');

my @Tests = (
    {
        Name => "Basic: CheckValue Postmaster - MatchValue open",
        Data => {
            Data => {
                State => 'open',
                Queue => 'Postmaster',
            },
            FieldName => 'Queue',
            Condition => {
                Value => 'open',
            },
        },
        Expected => {
            CheckValue => 'Postmaster',
            MatchValue => 'open',
        }
    },
    {
        Name => "Smart Tags simple: CheckValue Raw - MatchValue Raw",
        Data => {
            Data => {
                DynamicField_Text => 'Queue',
                Queue             => 'Raw',
            },
            FieldName => 'Queue',
            Condition => {
                Value => '<OTRS_TICKET_Queue>',
            },
        },
        Expected => {
            CheckValue => 'Raw',
            MatchValue => 'Raw',
        }
    },
    {
        Name => "Smart Tags simple: CheckValue Postmaster - MatchValue open",
        Data => {
            Data => {
                State => 'open',
                Queue => 'Postmaster',
            },
            FieldName => 'Queue',
            Condition => {
                Value => '<OTRS_TICKET_State>',
            },
        },
        Expected => {
            CheckValue => 'Postmaster',
            MatchValue => 'open',
        }
    },
    {
        Name => "Smart Tags complex: CheckValue Junk - MatchValue Junk",
        Data => {
            Data => {
                DynamicField_Text  => 'Queue',
                DynamicField_Queue => 'Junk',
                Queue              => 'Junk',
            },
            FieldName => '<OTRS_TICKET_DynamicField_Text>',
            Condition => {
                Value => '<OTRS_TICKET_DynamicField_Queue>',
            },
        },
        Expected => {
            CheckValue => 'Junk',
            MatchValue => 'Junk',
        }
    },
);

for my $Test (@Tests) {
    my $CheckValue = $TransitionValidationBaseObject->CheckValueGet(
        %{ $Test->{Data} },
    );

    $Self->Is(
        $CheckValue,
        $Test->{Expected}->{CheckValue},
        "$Test->{Name} - CheckValueGet - Expected ExpectedResult",
    );

    my $MatchValue = $TransitionValidationBaseObject->MatchValueGet(
        %{ $Test->{Data} },
        MatchValue => $Test->{Data}->{Condition}->{Value},
    );

    $Self->Is(
        $MatchValue,
        $Test->{Expected}->{MatchValue},
        "$Test->{Name} - MatchValueGet - Expected MatchValue",
    );
}

1;
