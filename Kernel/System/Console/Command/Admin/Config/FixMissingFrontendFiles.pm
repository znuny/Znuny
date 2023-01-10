# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
## nofilter(TidyAll::Plugin::Znuny::Perl::Dumper)

package Kernel::System::Console::Command::Admin::Config::FixMissingFrontendFiles;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);
use Data::Dumper;

use parent qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Main',
    'Kernel::System::Storable',
    'Kernel::System::SysConfig',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Fixes missing JavaScript and CSS configurations between Znuny upgrades.');
    $Self->AddOption(
        Name        => 'dryrun',
        Description => 'Only show the fixes that would be made. No changes will be applied to the configuration.',
        Required    => 0,
        HasValue    => 0,
    );

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $ConfigObject    = $Kernel::OM->Get('Kernel::Config');
    my $MainObject      = $Kernel::OM->Get('Kernel::System::Main');
    my $StorableObject  = $Kernel::OM->Get('Kernel::System::Storable');
    my $SysConfigObject = $Kernel::OM->Get('Kernel::System::SysConfig');

    my $Home = $ConfigObject->Get('Home');

    $Self->Print("<yellow>Fixing missing JavaScript and CSS configurations...</yellow>\n\n");

    my %SettingNew;
    my %SettingMissing;

    my @CommonConfigs = qw(
        Loader::Agent::CommonJS
        Loader::Agent::CommonCSS
        Loader::Customer::CommonJS
        Loader::Customer::CommonCSS
    );

    for my $CommonKey (@CommonConfigs) {

        CONFIGKEY:
        for my $ConfigKey ( sort keys %{ $ConfigObject->{$CommonKey} || {} } ) {
            my $SettingName = $CommonKey . '###' . $ConfigKey;

            # Get default setting
            my %Setting = $SysConfigObject->SettingGet(
                Name  => $SettingName,
                NoLog => 1,
            );

            if (
                $Setting{UserModificationActive}
                || $Setting{ExclusiveLockUserID}
                )
            {
                $Self->PrintError("Setting '$SettingName' ignored because it is locked!");
                next CONFIGKEY;
            }

            my $DefaultValue = $Setting{DefaultValue};
            next CONFIGKEY if ref $DefaultValue ne 'ARRAY';

            my $CurrentValue = $Setting{EffectiveValue};
            next CONFIGKEY if ref $CurrentValue ne 'ARRAY';

            my $NewValue = $StorableObject->Clone(
                Data => $CurrentValue,
            );

            my $MissingValue = [];

            VALUE:
            for my $Value ( @{$DefaultValue} ) {
                my $ValueFound = grep { $_ eq $Value } @{$CurrentValue};
                next VALUE if $ValueFound;

                push @{$NewValue},     $Value;
                push @{$MissingValue}, $Value;
            }

            next CONFIGKEY if !IsArrayRefWithData($MissingValue);

            $SettingNew{$SettingName}     = $NewValue;
            $SettingMissing{$SettingName} = $MissingValue;
        }
    }

    my @FrontendFiles = $MainObject->DirectoryRead(
        Directory => $Home . '/Kernel/Modules',
        Filter    => '*.pm',
    );

    my @Frontends = qw(
        Frontend::Module
        CustomerFrontend::Module
    );

    for my $Frontend (@Frontends) {
        for my $Action ( sort keys %{ $ConfigObject->{$Frontend} || {} } ) {
            my $CommonKey = 'Loader::Module::' . $Action;

            for my $ConfigKey ( sort keys %{ $ConfigObject->{$CommonKey} || {} } ) {
                my $SettingName = $CommonKey . '###' . $ConfigKey;

                # Get default setting
                my %Setting = $SysConfigObject->SettingGet(
                    Name  => $SettingName,
                    NoLog => 1,
                );

                TYPE:
                for my $Type (qw(CSS JavaScript)) {
                    my $DefaultValue = $Setting{DefaultValue}->{$Type};
                    next TYPE if ref $DefaultValue ne 'ARRAY';

                    my $CurrentValue = $Setting{EffectiveValue}->{$Type};
                    next TYPE if ref $CurrentValue ne 'ARRAY';

                    my $NewValue = $SettingNew{$SettingName} // $StorableObject->Clone(
                        Data => $CurrentValue,
                    );
                    my $MissingValue = [];

                    CHECKVALUE:
                    for my $Value ( @{$DefaultValue} ) {
                        my $ValueFound = grep { $_ eq $Value } @{$CurrentValue};

                        next CHECKVALUE if $ValueFound;

                        push @{$NewValue},     $Value;
                        push @{$MissingValue}, $Value;
                    }

                    next TYPE if !IsArrayRefWithData($MissingValue);

                    $SettingNew{$SettingName} //= {};

                    $SettingNew{$SettingName}->{$Type} = $NewValue;
                    $SettingMissing{$SettingName} = $MissingValue;
                }
            }
        }
    }

    my $DryRun = $Self->GetOption('dryrun');
    if ($DryRun) {
        my $Result = Dumper( \%SettingMissing );

        $Self->Print("The following CSS/JavaScript files are missing:\n");
        $Self->Print($Result);
        $Self->Print(
            "\nPlease verify the results with a developer before you fix the configuration. A reason could be e.g. a custom development package.\n"
        );
        $Self->Print("<green>Done.</green>\n");
        return $Self->ExitCodeOk();
    }

    for my $SettingName ( sort keys %SettingNew ) {

        # Get default setting
        my %Setting = $SysConfigObject->SettingGet(
            Name    => $SettingName,
            Default => 1,
        );

        if ( !%Setting ) {
            $Self->PrintError("Setting '$SettingName' doesn't exist!");
            return $Self->ExitCodeError();
        }

        my $ExclusiveLockGUID = $SysConfigObject->SettingLock(
            UserID    => 1,
            Force     => 1,
            DefaultID => $Setting{DefaultID},
        );

        my $Success = $SysConfigObject->SettingUpdate(
            Name              => $SettingName,
            EffectiveValue    => $SettingNew{$SettingName},
            ExclusiveLockGUID => $ExclusiveLockGUID,
            UserID            => 1,
        );

        if ( !$Success ) {
            $Self->PrintError("Setting '$SettingName' could not be updated!");
            return $Self->ExitCodeError();
        }

        $Success = $SysConfigObject->SettingUnlock(
            UserID    => 1,
            DefaultID => $Setting{DefaultID},
        );

        if ( !$Success ) {
            $Self->PrintError("Setting '$SettingName' could not be unlocked!");
            return $Self->ExitCodeError();
        }
    }

    my $Result = Dumper( \%SettingNew );

    $Self->Print("The following settings have been fixed:\n");
    $Self->Print( $Result . "\n" );

    if (%SettingNew) {
        my %DeploymentResult = $SysConfigObject->ConfigurationDeploy(
            Comments      => "Admin::Config::FixMissingFrontendFiles console command execution",
            UserID        => 1,
            Force         => 1,
            DirtySettings => [ sort keys %SettingNew ],
        );

        if ( !$DeploymentResult{Success} ) {
            $Self->PrintError("Deployment failed!\n");
            return $Self->ExitCodeError();
        }
    }

    $Self->Print("<green>Done.</green>\n");
    return $Self->ExitCodeOk();
}

1;
