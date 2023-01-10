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

my $ZnunyHelperObject = $Kernel::OM->Get('Kernel::System::ZnunyHelper');
my $CommandObject
    = $Kernel::OM->Get('Kernel::System::Console::Command::Admin::DynamicField::DefaultColumnsScreenConfig');

my @DynamicFields;

for my $Count ( 1 .. 3 ) {
    push @DynamicFields, "Test$Count";

    $ZnunyHelperObject->_DynamicFieldsCreateIfNotExists(
        {
            Name       => 'Test' . $Count,
            Label      => 'Label' . $Count,
            FieldType  => 'Text',
            ObjectType => 'Ticket',
            Config     => {
                DefaultValue => '',
            },
        },
    );
}

my @Tests = (
    {
        Name      => 'Showing all available dynamic fields and screens with configurable default columns.',
        Arguments => {
            '--list-available' => undef,
        },
        ExpectedExitCode => 0,
    },
    {
        Name      => 'Showing current configurations of dynamic fields and screens with default columns.',
        Arguments => {
            '--list-configs' => undef,
        },
        ExpectedExitCode => 0,
    },
    {
        Name =>
            'Setting dynamic field Test1 as default column for screen DashboardBackend###0120-TicketNew with mode 1.',
        Arguments => {
            '--dynamic-field' => [
                'Test1'
            ],
            '--screen' => [
                'DashboardBackend###0120-TicketNew',
            ],
            '--set-default-column-mode' => 1,
        },
        ExpectedExitCode => 0,
    },
    {
        Name =>
            'Setting dynamic fields Test1 .. Test3 as default column for screens AgentCustomerInformationCenter::Backend###0130-CIC-TicketOpen and Ticket::Frontend::AgentTicketQueue###DefaultColumns with mode 2',
        Arguments => {
            '--dynamic-field' => \@DynamicFields,
            '--screen'        => [
                'AgentCustomerInformationCenter::Backend###0130-CIC-TicketOpen',
                'Ticket::Frontend::AgentTicketQueue###DefaultColumns',
            ],
            '--set-default-column-mode' => 2,
        },
        ExpectedExitCode => 0
    },
    {
        Name      => 'Removing dynamic field Test1 as default column from screen DashboardBackend###0120-TicketNew.',
        Arguments => {
            '--dynamic-field' => [
                'Test1'
            ],
            '--screen' => [
                'DashboardBackend###0120-TicketNew'
            ],
            '--remove-from-default-columns-screens' => undef,
        },
        ExpectedExitCode => 0,
    },
    {
        Name =>
            'Removing dynamic fields Test1 .. Test3 as default columns from screens AgentCustomerInformationCenter::Backend###0130-CIC-TicketOpen and Ticket::Frontend::AgentTicketQueue###DefaultColumns.',
        Arguments => {
            '--dynamic-field' => \@DynamicFields,
            '--screen'        => [
                'AgentCustomerInformationCenter::Backend###0130-CIC-TicketOpen',
                'Ticket::Frontend::AgentTicketQueue###DefaultColumns'
            ],
            '--remove-from-default-columns-screens' => undef,
        },
        ExpectedExitCode => 0
    },
);

TEST:
for my $Test (@Tests) {
    my @Arguments;
    ARGUMENT:
    for my $Argument ( sort keys %{ $Test->{Arguments} // {} } ) {
        my $ArgumentValues = $Test->{Arguments}->{$Argument};
        if ( ref $ArgumentValues ne 'ARRAY' ) {
            $ArgumentValues = [$ArgumentValues];
        }

        ARGUMENTVALUE:
        for my $ArgumentValue ( @{$ArgumentValues} ) {
            push @Arguments, $Argument;
            next ARGUMENTVALUE if !defined $ArgumentValue;

            push @Arguments, $ArgumentValue;
        }
    }

    my $ExitCode = $CommandObject->Execute(@Arguments);

    $Self->Is(
        $ExitCode,
        $Test->{ExpectedExitCode},
        $Test->{Name} . ' - Exit code must match expected one.',
    );

    next TEST if $ExitCode;
    next TEST if $ExitCode != $Test->{ExpectedExitCode};

    next TEST if !$Test->{Arguments}->{'--dynamic-field'};
    next TEST if !$Test->{Arguments}->{'--screen'};

    $ZnunyHelperObject->_RebuildConfig();

    for my $Screen ( @{ $Test->{Arguments}->{'--screen'} } ) {
        my %DefaultColumnsScreenConfig = $ZnunyHelperObject->_DefaultColumnsGet($Screen);

        DYNAMICFIELDNAME:
        for my $DynamicFieldName ( @{ $Test->{Arguments}->{'--dynamic-field'} } ) {
            if ( $Test->{Arguments}->{'--set-default-column-mode'} ) {
                $Self->Is(
                    $DefaultColumnsScreenConfig{$Screen}->{"DynamicField_$DynamicFieldName"},
                    $Test->{Arguments}->{'--set-default-column-mode'},
                    $Test->{Name} . ' - SysConfig must be set to expected default column mode.',
                );
                next DYNAMICFIELDNAME;
            }

            $Self->False(
                scalar $DefaultColumnsScreenConfig{$Screen}->{"DynamicField_$DynamicFieldName"},
                $Test->{Name} . ' - SysConfig must not contain default column mode for dynamic field.',
            );
        }
    }
}

1;
