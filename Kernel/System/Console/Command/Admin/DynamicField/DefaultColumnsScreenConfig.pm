# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
package Kernel::System::Console::Command::Admin::DynamicField::DefaultColumnsScreenConfig;

use strict;
use warnings;

use parent qw(Kernel::System::Console::BaseCommand);
use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::DynamicField',
    'Kernel::System::ZnunyHelper',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description("Adds and removes dynamic fields to/from default column screen configurations.");

    $Self->AddOption(
        Name        => 'list-available',
        Description => 'Shows all available dynamic fields and screens with configurable default columns.',
        Required    => 0,
        HasValue    => 0,
    );

    $Self->AddOption(
        Name        => 'list-configs',
        Description => 'Shows current configurations of dynamic fields and screens with default columns.',
        Required    => 0,
        HasValue    => 0,
    );

    $Self->AddOption(
        Name        => 'dynamic-field',
        Description => 'Name(s) of dynamic field(s) for which to set default columns screen configuration(s).',
        Required    => 0,
        HasValue    => 1,
        Multiple    => 1,
        ValueRegex  => qr/.+/,
    );

    $Self->AddOption(
        Name        => 'screen',
        Description => 'Name(s) of screens for which to set dynamic fields as default columns.',
        Required    => 0,
        HasValue    => 1,
        Multiple    => 1,
        ValueRegex  => qr/.+/,
    );

    $Self->AddOption(
        Name => 'set-default-column-mode',
        Description =>
            'Sets the default columns configuration mode for the given dynamic field(s) and screen(s). Valid modes are: 0 (disabled), 1 (available) and 2 (enabled by default).',
        Required   => 0,
        HasValue   => 1,
        ValueRegex => qr/\A[0-2]\z/,
    );

    $Self->AddOption(
        Name => 'remove-from-default-columns-screens',
        Description =>
            'Removes the given dynamic field(s) from the default columns configuration of the given screen(s).',
        Required => 0,
        HasValue => 0,
    );

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $ZnunyHelperObject  = $Kernel::OM->Get('Kernel::System::ZnunyHelper');
    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');

    my $AvailableDynamicFieldNamesByID = $DynamicFieldObject->DynamicFieldList(
        Valid      => 0,
        ResultType => 'HASH',
    );

    if ( !IsHashRefWithData($AvailableDynamicFieldNamesByID) ) {
        $Self->PrintError('No dynamic fields found.');
        return $Self->ExitCodeError();
    }

    my @AvailableDynamicFieldNames = sort values %{$AvailableDynamicFieldNamesByID};
    my %AvailableDynamicFieldNames = map { $_ => 1 } @AvailableDynamicFieldNames;

    my $AvailableDynamicFieldScreens = $ZnunyHelperObject->_ValidDynamicFieldScreenListGet();
    if ( !IsHashRefWithData($AvailableDynamicFieldScreens) ) {
        $Self->PrintError('No dynamic field screen configurations found.');
        return $Self->ExitCodeError();
    }

    my $AvailableDefaultColumnScreens = $AvailableDynamicFieldScreens->{DefaultColumnsScreens};
    if ( !IsArrayRefWithData($AvailableDefaultColumnScreens) ) {
        $Self->PrintError('No default column screen configurations found.');
        return $Self->ExitCodeError();
    }

    my @AvailableDefaultColumnScreens = sort @{$AvailableDefaultColumnScreens};
    my %AvailableDefaultColumnScreens = map { $_ => 1 } @AvailableDefaultColumnScreens;

    if ( $Self->GetOption('list-available') ) {
        $Self->_ListAvailable(
            AvailableDynamicFieldNames    => \@AvailableDynamicFieldNames,
            AvailableDefaultColumnScreens => \@AvailableDefaultColumnScreens,
        );
        return $Self->ExitCodeOk();
    }

    if ( $Self->GetOption('list-configs') ) {
        $Self->_ListConfigurations(
            AvailableDynamicFieldNames    => \@AvailableDynamicFieldNames,
            AvailableDefaultColumnScreens => \@AvailableDefaultColumnScreens,
        );
        return $Self->ExitCodeOk();
    }

    return $Self->_UpdateScreenConfigurations(
        AvailableDynamicFieldNames    => \%AvailableDynamicFieldNames,
        AvailableDefaultColumnScreens => \%AvailableDefaultColumnScreens,
    );
}

sub _ListAvailable {
    my ( $Self, %Param ) = @_;

    $Self->Print("<green>Available dynamic fields:</green>\n");
    $Self->Print( ( join "\n", @{ $Param{AvailableDynamicFieldNames} } ) . "\n\n" );

    $Self->Print("<green>Available screens with default column configuration:</green>\n");
    $Self->Print( ( join "\n", @{ $Param{AvailableDefaultColumnScreens} } ) . "\n" );

    return;
}

sub _ListConfigurations {
    my ( $Self, %Param ) = @_;

    my $ConfigObject      = $Kernel::OM->Get('Kernel::Config');
    my $ZnunyHelperObject = $Kernel::OM->Get('Kernel::System::ZnunyHelper');

    $Self->Print("<green>Current configurations of dynamic fields and screens with default columns:</green>\n");

    my %CurrentDefaultColumnConfigurations = $ZnunyHelperObject->_DefaultColumnsGet(
        @{ $Param{AvailableDefaultColumnScreens} }
    );

    my %ModeDescriptions = (
        0 => '0 (disabled)',
        1 => '1 (available)',
        2 => '2 (enabled by default)',
    );

    SCREEN:
    for my $Screen ( sort keys %CurrentDefaultColumnConfigurations ) {
        $Self->Print("\tScreen '$Screen'\n");

        for my $DynamicFieldName ( @{ $Param{AvailableDynamicFieldNames} } ) {
            my $DynamicFieldDefaultColumnMode
                = $CurrentDefaultColumnConfigurations{$Screen}->{"DynamicField_$DynamicFieldName"};
            if (
                defined $DynamicFieldDefaultColumnMode
                && exists $ModeDescriptions{$DynamicFieldDefaultColumnMode}
                )
            {
                $Self->Print(
                    "\t\tDynamic field '$DynamicFieldName': $ModeDescriptions{$DynamicFieldDefaultColumnMode}\n"
                );
            }
        }
    }

    return;
}

sub _UpdateScreenConfigurations {
    my ( $Self, %Param ) = @_;

    my $ZnunyHelperObject = $Kernel::OM->Get('Kernel::System::ZnunyHelper');

    my $SelectedDynamicFieldNames = $Self->GetOption('dynamic-field') // [];
    my $SelectedScreens           = $Self->GetOption('screen')        // [];
    if (
        !IsArrayRefWithData($SelectedDynamicFieldNames)
        || !IsArrayRefWithData($SelectedScreens)
        )
    {
        $Self->PrintError(
            'Both options dynamic-field and screen must be given at least once. Use option list-available to list available dynamic fields and screens.'
        );
        return $Self->ExitCodeError();
    }

    my %SelectedDynamicFieldNames = map { $_ => 1 } @{$SelectedDynamicFieldNames};
    my %SelectedScreens           = map { $_ => 1 } @{$SelectedScreens};

    my $SetDefaultColumnMode            = $Self->GetOption('set-default-column-mode');
    my $RemoveFromDefaultColumnsScreens = $Self->GetOption('remove-from-default-columns-screens');

    if (
        (
            (
                !defined $SetDefaultColumnMode
                || !length $SetDefaultColumnMode
            )
            && !$RemoveFromDefaultColumnsScreens
        )
        || (
            defined $SetDefaultColumnMode
            && length $SetDefaultColumnMode
            && $RemoveFromDefaultColumnsScreens
        )
        )
    {
        $Self->PrintError('Either give option set-default-column-mode or remove-from-default-columns-screens.');
        return $Self->ExitCodeError();
    }

    if ($RemoveFromDefaultColumnsScreens) {
        $Self->Print("<green>Removing dynamic fieldes from default columns screen configurations...</green>\n");
    }
    else {
        $Self->Print("<green>Updating default columns screen configurations...</green>\n");
    }

    my %ScreenConfigurations;
    SCREEN:
    for my $Screen ( sort keys %SelectedScreens ) {
        $Self->Print("\tScreen '$Screen'\n");

        if ( !$Param{AvailableDefaultColumnScreens}->{$Screen} ) {
            $Self->Print("\t\tScreen configuration not found.\n");
            next SCREEN;
        }

        DYNAMICFIELDNAME:
        for my $DynamicFieldName ( sort keys %SelectedDynamicFieldNames ) {
            $Self->Print("\t\tDynamic field '$DynamicFieldName'\n");
            if ( !$Param{AvailableDynamicFieldNames}->{$DynamicFieldName} ) {
                $Self->Print("\t\t\tDynamic field not found.\n");
                next DYNAMICFIELDNAME;
            }

            $ScreenConfigurations{$Screen}->{"DynamicField_$DynamicFieldName"}
                = $RemoveFromDefaultColumnsScreens ? 1 : $SetDefaultColumnMode;

            $Self->Print("\t\t\tOK\n");
        }
    }

    if ($RemoveFromDefaultColumnsScreens) {
        $ZnunyHelperObject->_DefaultColumnsDisable(%ScreenConfigurations);
    }
    else {
        $ZnunyHelperObject->_DefaultColumnsEnable(%ScreenConfigurations);
    }

    $Self->Print("<green>Done.</green>\n");

    return $Self->ExitCodeOk();
}

1;
