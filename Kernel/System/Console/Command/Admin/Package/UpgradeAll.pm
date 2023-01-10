# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --
## nofilter(TidyAll::Plugin::Znuny::CodeStyle::STDERRCheck)

package Kernel::System::Console::Command::Admin::Package::UpgradeAll;

use strict;
use warnings;
use utf8;

use Kernel::System::VariableCheck qw(:all);

use parent qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::System::Cache',
    'Kernel::System::Package',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Upgrade all packages to the latest versions from the online repositories.');
    $Self->AddOption(
        Name        => 'force',
        Description => 'Force package upgrade/installation even if validation fails.',
        Required    => 0,
        HasValue    => 0,
    );

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');

    # Enable in-memory cache to improve SysConfig performance, which is normally disabled for commands.
    $CacheObject->Configure(
        CacheInMemory => 1,
    );

    my $PackageObject = $Kernel::OM->Get('Kernel::System::Package');

    my %IsRunningResult = $PackageObject->PackageUpgradeAllIsRunning();

    if ( $IsRunningResult{IsRunning} ) {
        $Self->Print("\nThere is another package upgrade process running\n");
        $Self->Print("\n<green>Done.</green>\n");
        return $Self->ExitCodeOk();
    }

    my @List = $PackageObject->RepositoryList(
        Result => 'short',
    );
    if ( !@List ) {
        $Self->Print("\nThere are no installed packages\n");
        $Self->Print("\n<green>Done.</green>\n");
        return $Self->ExitCodeOk();
    }

    my %RepositoryList = $PackageObject->ConfiguredRepositoryListGet();

    my @PackageOnlineList;
    my %PackageSoruceLookup;

    $Self->Print("<yellow>Fetching online repositories...</yellow>\n");

    for my $Source ( sort keys %RepositoryList ) {
        $Self->Print("  $Source... ");

        $PackageObject->RepositoryPackageListGet(
            Source => $Source,
            Lang   => 'en',
            Cache  => 1,
        );

        $Self->Print("<green>Done</green>\n");
    }

    # Check again after repository refresh
    %IsRunningResult = $PackageObject->PackageUpgradeAllIsRunning();

    if ( $IsRunningResult{IsRunning} ) {
        $Self->Print("\nThere is another package upgrade process running\n");
        $Self->Print("\n<green>Done.</green>\n");
        return $Self->ExitCodeOk();
    }

    $Self->Print("\n<yellow>Upgrading installed packages...</yellow>\n");

    my $ErrorMessage;
    my %Result;
    eval {

        # Localize the standard error, everything will be restored after the eval block.
        # Package installation or upgrades always produce messages in STDERR for files and directories.
        local *STDERR;

        # Redirect the standard error to a variable.
        open STDERR, ">>", \$ErrorMessage;
        %Result = $PackageObject->PackageUpgradeAll(
            Force => $Self->GetOption('force'),
        );
    };

    # Remove package upgrade data from the DB, so the GUI will not show the finished notification.
    $PackageObject->PackageUpgradeAllDataDelete();

    # Be sure to print any error messages in case of a failure.
    if ( IsHashRefWithData( $Result{Failed} ) ) {
        print STDERR $ErrorMessage if $ErrorMessage;
    }

    if (
        !IsHashRefWithData( $Result{Updated} )
        && !IsHashRefWithData( $Result{Installed} )
        && !IsHashRefWithData( $Result{Undeployed} )
        && !IsHashRefWithData( $Result{Failed} )
        )
    {
        $Self->Print("  All installed packages are already at their latest versions.\n");
        $Self->Print("\n<green>Done.</green>\n");
        return $Self->ExitCodeOk();
    }

    my %SuccessMessages = (
        Updated        => 'updated',
        Installed      => 'installed',
        AlreadyUpdated => 'already up-to-date',
        Undeployed     => 'already up-to-date but <red>not deployed correctly</red>',
    );

    for my $ResultPart (qw(AlreadyUpdated Undeployed Updated Installed)) {
        if ( IsHashRefWithData( $Result{$ResultPart} ) ) {
            $Self->Print( '  The following packages were ' . $SuccessMessages{$ResultPart} . "...\n" );
            my $Color = 'green';
            if ( $ResultPart eq 'Installed' || $ResultPart eq 'Undeployed' ) {
                $Color = 'yellow';
            }
            for my $PackageName ( sort keys %{ $Result{$ResultPart} } ) {
                $Self->Print("    <$Color>$PackageName</$Color>\n");
            }
        }
    }

    my %FailedMessages = (
        UpdateError    => 'could not be upgraded...',
        InstallError   => 'could not be installed...',
        Cyclic         => 'had cyclic dependencies...',
        NotFound       => 'could not be found in the online repositories...',
        WrongVersion   => 'require a version higher than the one found in the online repositories...',
        DependencyFail => 'fail to upgrade/install their package dependencies...'

    );

    if ( IsHashRefWithData( $Result{Failed} ) ) {
        for my $FailedPart (qw(UpdateError InstallError DependencyFail Cyclic NotFound WrongVersion)) {
            if ( IsHashRefWithData( $Result{Failed}->{$FailedPart} ) ) {
                $Self->Print("  The following packages $FailedMessages{$FailedPart}\n");
                for my $PackageName ( sort keys %{ $Result{Failed}->{$FailedPart} } ) {
                    $Self->Print("    <red>$PackageName</red>\n");
                }
            }
        }
    }

    if ( !$Result{Success} ) {
        $Self->Print("\n<red>Fail.</red>\n");
        return $Self->ExitCodeError();
    }

    if ( IsHashRefWithData( $Result{Undeployed} ) ) {
        my $Message = "\nPlease reinstall not correctly deployed packages using"
            . " <yellow>Admin::Package::Reinstall</yellow>"
            . " or <yellow>Admin::Package::ReinstallAll</yellow> console commands.\n";
        $Self->Print($Message);
    }

    # Disable in memory cache.
    $CacheObject->Configure(
        CacheInMemory => 0,
    );

    $Self->Print("\n<green>Done.</green>\n");
    return $Self->ExitCodeOk();
}

1;
