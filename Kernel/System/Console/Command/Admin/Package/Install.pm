# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::Console::Command::Admin::Package::Install;

use strict;
use warnings;

use parent qw(Kernel::System::Console::BaseCommand Kernel::System::Console::Command::Admin::Package::List);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Cache',
    'Kernel::System::Package',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Install a package.');
    $Self->AddOption(
        Name        => 'force',
        Description => 'Force package installation even if validation fails.',
        Required    => 0,
        HasValue    => 0,
    );
    $Self->AddArgument(
        Name => 'location',
        Description =>
            "Specify a file path, a remote repository (https://download.znuny.org/releases/packages/:Package-1.0.0.opm) or just any online repository by its configured name (e.g. 'MyRepository:Package').",
        Required   => 1,
        ValueRegex => qr/.*/smx,
    );

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    $Self->Print("<yellow>Installing package...</yellow>\n");

    my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');

    # Enable in-memory cache to improve SysConfig performance, which is normally disabled for commands.
    $CacheObject->Configure(
        CacheInMemory => 1,
    );

    my $FileString = $Self->_PackageContentGet( Location => $Self->GetArgument('location') );
    return $Self->ExitCodeError() if !$FileString;

    my $PackageObject = $Kernel::OM->Get('Kernel::System::Package');

    # Parse package.
    my %Structure = $PackageObject->PackageParse(
        String => $FileString,
    );

    # check if package is installed
    if ( $Kernel::OM->Get('Kernel::System::Package')->PackageIsInstalled( Name => $Structure{Name}->{Content} ) ) {
        $Self->PrintError("Package is already installed.");
        return $Self->ExitCodeError();
    }

    # intro screen
    if ( $Structure{IntroInstall} ) {
        my %Data = $Self->_PackageMetadataGet(
            Tag                  => $Structure{IntroInstall},
            AttributeFilterKey   => 'Type',
            AttributeFilterValue => 'pre',
        );
        if ( $Data{Description} ) {
            print "+----------------------------------------------------------------------------+\n";
            print "| $Structure{Name}->{Content}-$Structure{Version}->{Content}\n";
            print "$Data{Title}";
            print "$Data{Description}";
            print "+----------------------------------------------------------------------------+\n";
        }
    }

    # install
    my $Success = $PackageObject->PackageInstall(
        String => $FileString,
        Force  => $Self->GetOption('force'),
    );

    if ( !$Success ) {
        $Self->PrintError("Package installation failed.");
        return $Self->ExitCodeError();
    }

    # intro screen
    if ( $Structure{IntroInstall} ) {
        my %Data = $Self->_PackageMetadataGet(
            Tag                  => $Structure{IntroInstall},
            AttributeFilterKey   => 'Type',
            AttributeFilterValue => 'post',
        );
        if ( $Data{Description} ) {
            print "+----------------------------------------------------------------------------+\n";
            print "| $Structure{Name}->{Content}-$Structure{Version}->{Content}\n";
            print "$Data{Title}";
            print "$Data{Description}";
            print "+----------------------------------------------------------------------------+\n";
        }
    }

    # Disable in memory cache.
    $CacheObject->Configure(
        CacheInMemory => 0,
    );

    $Self->Print("<green>Done.</green>\n");
    return $Self->ExitCodeOk();
}

1;
