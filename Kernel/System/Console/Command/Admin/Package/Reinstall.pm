# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::Console::Command::Admin::Package::Reinstall;

use strict;
use warnings;

use parent qw(Kernel::System::Console::BaseCommand Kernel::System::Console::Command::Admin::Package::List);

our @ObjectDependencies = (
    'Kernel::System::Cache',
    'Kernel::System::Package',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Reinstall a package.');
    $Self->AddOption(
        Name        => 'force',
        Description => 'Force package reinstallation even if validation fails.',
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

    $Self->Print("<yellow>Reinstalling package...</yellow>\n");

    my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');

    # Enable in-memory cache to improve SysConfig performance, which is normally disabled for commands.
    $CacheObject->Configure(
        CacheInMemory => 1,
    );

    my $FileString = $Self->_PackageContentGet( Location => $Self->GetArgument('location') );
    return $Self->ExitCodeError() if !$FileString;

    # parse package
    my %Structure = $Kernel::OM->Get('Kernel::System::Package')->PackageParse(
        String => $FileString,
    );

    # check if package is installed
    if ( !$Kernel::OM->Get('Kernel::System::Package')->PackageIsInstalled( Name => $Structure{Name}->{Content} ) ) {
        $Self->PrintError("Package is not installed.");
        return $Self->ExitCodeError();
    }

    # intro screen
    if ( $Structure{IntroReinstall} ) {
        my %Data = $Self->_PackageMetadataGet(
            Tag                  => $Structure{IntroReinstall},
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
    my $Success = $Kernel::OM->Get('Kernel::System::Package')->PackageReinstall(
        String => $FileString,
        Force  => $Self->GetOption('force'),
    );

    if ( !$Success ) {
        $Self->PrintError("Package reinstallation failed.");
        return $Self->ExitCodeError();
    }

    # intro screen
    if ( $Structure{IntroReinstall} ) {
        my %Data = $Self->_PackageMetadataGet(
            Tag                  => $Structure{IntroReinstall},
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
