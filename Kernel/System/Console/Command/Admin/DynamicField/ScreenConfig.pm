# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
package Kernel::System::Console::Command::Admin::DynamicField::ScreenConfig;

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

    $Self->Description("Adds and removes dynamic fields to/from screen configurations.");

    $Self->AddOption(
        Name        => 'list-available',
        Description => 'Shows all available dynamic fields and screens.',
        Required    => 0,
        HasValue    => 0,
    );

    $Self->AddOption(
        Name        => 'list-configs',
        Description => 'Shows current configurations of dynamic fields and screens.',
        Required    => 0,
        HasValue    => 0,
    );

    $Self->AddOption(
        Name        => 'dynamic-field',
        Description => 'Name(s) of dynamic field(s) for which to set screen configuration(s).',
        Required    => 0,
        HasValue    => 1,
        Multiple    => 1,
        ValueRegex  => qr/.+/,
    );

    $Self->AddOption(
        Name        => 'screen',
        Description => 'Name(s) of screens for which to set dynamic fields.',
        Required    => 0,
        HasValue    => 1,
        Multiple    => 1,
        ValueRegex  => qr/.+/,
    );

    $Self->AddOption(
        Name => 'set-mode',
        Description =>
            'Sets the mode for the given dynamic field(s) and screen(s). Valid modes are: 0 (disabled), 1 (enabled) and 2 (enabled and required).',
        Required   => 0,
        HasValue   => 1,
        ValueRegex => qr/\A[0-2]\z/,
    );

    $Self->AddOption(
        Name => 'remove-from-screens',
        Description =>
            'Removes the given dynamic field(s) from the given screen(s).',
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
    if (
        !IsHashRefWithData($AvailableDynamicFieldScreens)
        || !IsArrayRefWithData( $AvailableDynamicFieldScreens->{DynamicFieldScreens} )
        )
    {
        $Self->PrintError('No dynamic field screen configurations found.');
        return $Self->ExitCodeError();
    }
    $AvailableDynamicFieldScreens = $AvailableDynamicFieldScreens->{DynamicFieldScreens};

    my @AvailableDynamicFieldScreens = sort @{$AvailableDynamicFieldScreens};
    my %AvailableDynamicFieldScreens = map { $_ => 1 } @AvailableDynamicFieldScreens;

    if ( $Self->GetOption('list-available') ) {
        $Self->_ListAvailable(
            AvailableDynamicFieldNames   => \@AvailableDynamicFieldNames,
            AvailableDynamicFieldScreens => \@AvailableDynamicFieldScreens,
        );
        return $Self->ExitCodeOk();
    }

    if ( $Self->GetOption('list-configs') ) {
        $Self->_ListConfigurations(
            AvailableDynamicFieldNames   => \@AvailableDynamicFieldNames,
            AvailableDynamicFieldScreens => \@AvailableDynamicFieldScreens,
        );
        return $Self->ExitCodeOk();
    }

    return $Self->_UpdateScreenConfigurations(
        AvailableDynamicFieldNames   => \%AvailableDynamicFieldNames,
        AvailableDynamicFieldScreens => \%AvailableDynamicFieldScreens,
    );
}

sub _ListAvailable {
    my ( $Self, %Param ) = @_;

    $Self->Print("<green>Available dynamic fields:</green>\n");
    $Self->Print( ( join "\n", @{ $Param{AvailableDynamicFieldNames} } ) . "\n\n" );

    $Self->Print("<green>Available screens:</green>\n");
    $Self->Print( ( join "\n", @{ $Param{AvailableDynamicFieldScreens} } ) . "\n" );

    return;
}

sub _ListConfigurations {
    my ( $Self, %Param ) = @_;

    my $ConfigObject      = $Kernel::OM->Get('Kernel::Config');
    my $ZnunyHelperObject = $Kernel::OM->Get('Kernel::System::ZnunyHelper');

    $Self->Print("<green>Current configurations of dynamic fields and screens:</green>\n");

    my %CurrentDynamicFieldScreenConfigurations = $ZnunyHelperObject->_DefaultColumnsGet(
        @{ $Param{AvailableDynamicFieldScreens} }
    );

    my %ModeDescriptions = (
        0 => '0 (disabled)',
        1 => '1 (enabled)',
        2 => '2 (enabled and required)',
    );

    SCREEN:
    for my $Screen ( sort keys %CurrentDynamicFieldScreenConfigurations ) {
        $Self->Print("\tScreen '$Screen'\n");

        for my $DynamicFieldName ( @{ $Param{AvailableDynamicFieldNames} } ) {
            my $DynamicFieldMode = $CurrentDynamicFieldScreenConfigurations{$Screen}->{$DynamicFieldName};
            if (
                defined $DynamicFieldMode
                && exists $ModeDescriptions{$DynamicFieldMode}
                )
            {
                $Self->Print(
                    "\t\tDynamic field '$DynamicFieldName': $ModeDescriptions{$DynamicFieldMode}\n"
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

        $Self->Print( "\n" . $Self->GetUsageHelp() );
        return $Self->ExitCodeError();
    }

    my %SelectedDynamicFieldNames = map { $_ => 1 } @{$SelectedDynamicFieldNames};
    my %SelectedScreens           = map { $_ => 1 } @{$SelectedScreens};

    my $SetMode           = $Self->GetOption('set-mode');
    my $RemoveFromScreens = $Self->GetOption('remove-from-screens');

    if (
        (
            (
                !defined $SetMode
                || !length $SetMode
            )
            && !$RemoveFromScreens
        )
        || (
            defined $SetMode
            && length $SetMode
            && $RemoveFromScreens
        )
        )
    {
        $Self->PrintError('Either give option set-mode or remove-from-screens.');

        $Self->Print( "\n" . $Self->GetUsageHelp() );

        return $Self->ExitCodeError();
    }

    if ($RemoveFromScreens) {
        $Self->Print("<green>Removing dynamic fieldes from screen configurations...</green>\n");
    }
    else {
        $Self->Print("<green>Updating screen configurations...</green>\n");
    }

    my %ScreenConfigurations;
    SCREEN:
    for my $Screen ( sort keys %SelectedScreens ) {
        $Self->Print("\tScreen '$Screen'\n");

        if ( !$Param{AvailableDynamicFieldScreens}->{$Screen} ) {
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

            $ScreenConfigurations{$Screen}->{$DynamicFieldName} = $RemoveFromScreens ? 1 : $SetMode;

            $Self->Print("\t\t\tOK\n");
        }
    }

    if ($RemoveFromScreens) {
        $ZnunyHelperObject->_DynamicFieldsScreenDisable(%ScreenConfigurations);
    }
    else {
        $ZnunyHelperObject->_DynamicFieldsScreenEnable(%ScreenConfigurations);
    }

    $Self->Print("<green>Done.</green>\n");

    return $Self->ExitCodeOk();
}

1;
