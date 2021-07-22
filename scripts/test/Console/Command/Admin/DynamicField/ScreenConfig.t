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
my $CommandObject     = $Kernel::OM->Get('Kernel::System::Console::Command::Admin::DynamicField::ScreenConfig');

my @DynamicFields;
for my $Count ( 1 .. 3 ) {
    push @DynamicFields, "Test$Count";

    $ZnunyHelperObject->_DynamicFieldsCreateIfNotExists(
        {
            Name       => 'Test' . $Count,
            Label      => 'Test' . $Count,
            FieldType  => 'Text',
            ObjectType => 'Ticket',
            Config     => {
                DefaultValue => '',
            },
        },
    );
}

my $GetDynamicFieldScreenConfig = sub {
    my %Param = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');

    NEEDED:
    for my $Needed (qw(ConfigKey)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my @Keys   = split '###', $Param{ConfigKey};
    my $Config = $ConfigObject->Get( $Keys[0] );

    INDEX:
    for my $Index ( 1 ... $#Keys ) {
        last INDEX if !IsHashRefWithData($Config);

        $Config = $Config->{ $Keys[$Index] };
    }

    return if ref $Config ne 'HASH';

    return $Config;
};

my @Tests = (
    {
        Name      => 'Showing all available dynamic fields and screens.',
        Arguments => {
            '--list-available' => undef,
        },
        ExpectedExitCode => 0,
    },
    {
        Name      => 'Showing current configurations of dynamic fields and screens.',
        Arguments => {
            '--list-configs' => undef,
        },
        ExpectedExitCode => 0,
    },
    {
        Name =>
            'Setting dynamic field Test1 for screen AgentTicketZoom with mode 1.',
        Arguments => {
            '--dynamic-field' => [
                'Test1'
            ],
            '--screen' => [
                'Ticket::Frontend::AgentTicketZoom###DynamicField',
            ],
            '--set-mode' => 1,
        },
        ExpectedExitCode => 0,
    },
    {
        Name =>
            'Setting dynamic fields Test1 .. Test3 for screens AgentTicketClose and AgentTicketNote with mode 2',
        Arguments => {
            '--dynamic-field' => \@DynamicFields,
            '--screen'        => [
                'Ticket::Frontend::AgentTicketClose###DynamicField',
                'Ticket::Frontend::AgentTicketNote###DynamicField',
            ],
            '--set-mode' => 2,
        },
        ExpectedExitCode => 0
    },
    {
        Name      => 'Removing dynamic field Test1 from screen AgentTicketZoom.',
        Arguments => {
            '--dynamic-field' => [
                'Test1'
            ],
            '--screen' => [
                'Ticket::Frontend::AgentTicketZoom###DynamicField'
            ],
            '--remove-from-screens' => undef,
        },
        ExpectedExitCode => 0,
    },
    {
        Name =>
            'Removing dynamic fields Test1 .. Test3 from screens AgentTicketClose and AgentTicketNote.',
        Arguments => {
            '--dynamic-field' => \@DynamicFields,
            '--screen'        => [
                'Ticket::Frontend::AgentTicketClose###DynamicField',
                'Ticket::Frontend::AgentTicketNote###DynamicField',
            ],
            '--remove-from-screens' => undef,
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
        my $ScreenConfig = $GetDynamicFieldScreenConfig->(
            ConfigKey => $Screen,
        );

        $Self->True(
            ref $ScreenConfig eq 'HASH',
            $Test->{Name} . ' - Screen config must be found.',
        );

        DYNAMICFIELDNAME:
        for my $DynamicFieldName ( @{ $Test->{Arguments}->{'--dynamic-field'} } ) {
            if ( $Test->{Arguments}->{'--set-mode'} ) {

                $Self->Is(
                    $ScreenConfig->{$DynamicFieldName},
                    $Test->{Arguments}->{'--set-mode'},
                    $Test->{Name} . ' - SysConfig must be set to expected mode.',
                );
                next DYNAMICFIELDNAME;
            }

            $Self->False(
                scalar $ScreenConfig->{$DynamicFieldName},
                $Test->{Name} . ' - SysConfig must not contain mode for dynamic field.',
            );
        }
    }
}

1;
