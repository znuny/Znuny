# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::Console::Command::Dev::Code::CPANUpdate;

use strict;
use warnings;

use File::Path();

use parent qw(Kernel::System::Console::BaseCommand);

use Kernel::System::Environment;
use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Main',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Update dependencies in Kernel/cpan-lib.');

    $Self->AddOption(
        Name => 'mode',
        Description =>
            "Update all dependencies (development), one dependency (single), only critical ones (stable), or just check for outdated modules (check).",
        Required   => 1,
        HasValue   => 1,
        Multiple   => 0,
        ValueRegex => qr{\Astable|single|check\z},
    );

    $Self->AddOption(
        Name        => 'module',
        Description => "Module name that should be upgraded (only used for mode 'single')",
        Required    => 0,
        HasValue    => 1,
        Multiple    => 1,
        ValueRegex  => qr/.+/,
    );

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $MainObject   = $Kernel::OM->Get('Kernel::System::Main');

    my $Home    = $ConfigObject->Get('Home');
    my $Mode    = $Self->GetOption('mode') || '';
    my $CPANDir = "$Home/Kernel/cpan-lib";

    my %PerlInfo = Kernel::System::Environment->PerlInfoGet(
        BundledModules => 1,
    );

    if ( $Mode eq 'stable' ) {
        MODULE_CONFIG:
        for my $ModuleConfig ( $Self->LoadModuleConfig() ) {
            next MODULE_CONFIG if !$ModuleConfig->{UpdateInStableMode};

            $Self->InstallModule(
                ModuleConfig => $ModuleConfig,
                TargetPath   => $CPANDir,
            );
        }
    }
    elsif ( $Mode eq 'check' ) {
        $Self->Print( sprintf "Module%sInstalled%sAvailable\n", ' ' x 30, ' ' x 5 );

        for my $Module ( sort keys %{ $PerlInfo{Modules} || {} } ) {
            my $Space          = ' ' x ( 36 - length $Module );
            my $Installed      = $PerlInfo{Modules}->{$Module};
            my $SpaceInstalled = ' ' x ( 14 - length $Installed );

            $Self->Print( $Module . $Space . $Installed . $SpaceInstalled );

            my $ProxySetting                  = $Self->_GetProxySetting();
            my $NoProxySetting                = $Self->_GetNoProxySetting();
            my $DisableSSLVerificationSetting = $Self->_GetDisableSSLVerificationSetting();

            my $URL = sprintf "https://fastapi.metacpan.org/v1/download_url/%s", $Module;
            my $Command
                = "wget $ProxySetting $NoProxySetting $DisableSSLVerificationSetting -q -O - $URL | grep version | cut -d '\"' -f4";
            my $Available = `$Command`;
            chomp $Available;

            $Available ||= '0';
            my $Color = $Available > $Installed ? 'yellow' : 'green';

            $Self->Print("<$Color>$Available</$Color>\n");
        }
    }
    elsif ( $Mode eq 'single' ) {
        my $ModulesToUpdate = $Self->GetOption('module');

        if ( !$ModulesToUpdate ) {
            $Self->PrintError("Need module!");
            return $Self->ExitCodeError();
        }

        for my $Module ( @{ $ModulesToUpdate || [] } ) {
            $Self->InstallModule(
                ModuleConfig => { Module => $Module },
                TargetPath   => $CPANDir,
            );
        }
    }
    elsif ( $Mode eq 'development' ) {
        my $CPAN2Dir = "$Home/Kernel/cpan-lib2";

        # Delete Kernel/cpan-lib.
        if ( -d $CPAN2Dir ) {
            File::Path::remove_tree($CPAN2Dir) || die "Could not clean-up $CPAN2Dir: $!.";
        }
        File::Path::make_path($CPAN2Dir) || die "Could not create $CPAN2Dir: $!.";

        # Install modules.
        for my $ModuleConfig ( $Self->LoadModuleConfig() ) {
            $Self->InstallModule(
                ModuleConfig => $ModuleConfig,
                TargetPath   => $CPAN2Dir,
            );
        }

        # Copy our own extension for Devel::REPL from previous cpan-lib folder.
        File::Path::make_path("$CPAN2Dir/Devel/REPL/Plugin");
        system("cp -r $CPANDir/Devel/REPL/Plugin/OTRS.pm $CPAN2Dir/Devel/REPL/Plugin/OTRS.pm");

        # Replace cpan-lib folder.
        File::Path::remove_tree($CPANDir) || die "Could not remove $CPANDir: $!.";
        rename $CPAN2Dir, $CPANDir || die "Could not replace $CPANDir: $!.";
    }

    # Clean-up unwanted files.
    File::Path::remove_tree("$CPANDir/Test/Selenium");
    system("find $CPANDir -name *.pod -exec rm -f {} +");
    system("find $CPANDir -name *.pl -exec rm -f {} +");
    system("find $CPANDir -name *.so -exec rm -f {} +");
    system("find $CPANDir -name *.exists -exec rm -f {} +");

    # Fix unwanted 755 permissions.
    system("find $CPANDir -type f -exec chmod 640 {} +");

    my $ReadmeContent = <<'EOF';
This directory contains bundled pure-perl CPAN modules that are used by the OTRS source code.

Please note that this directory is auto-generated by the command `Dev::Code::CPANUpdate`.

License information of the bundled modules can be found in file
[COPYING-Third-Party](../../COPYING-Third-Party).
EOF

    $MainObject->FileWrite(
        Location => "$CPANDir/README.md",
        Content  => \$ReadmeContent,
    );

    return $Self->ExitCodeOk();
}

sub InstallModule {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    my $Home         = $ConfigObject->Get('Home');
    my $ModuleConfig = $Param{ModuleConfig};
    my $TargetPath   = $Param{TargetPath};

    $Self->Print("Updating <yellow>$ModuleConfig->{Module}</yellow>...\n");

    my $TmpDir = "$Home/var/tmp/CPANUpdate";

    if ( -d $TmpDir ) {
        File::Path::remove_tree($TmpDir) || die "Could not clean-up $TmpDir: $!.";
    }
    File::Path::make_path($TmpDir) || die "Could not create $TmpDir: $!.";

    my $ProxySetting                  = $Self->_GetProxySetting();
    my $NoProxySetting                = $Self->_GetNoProxySetting();
    my $DisableSSLVerificationSetting = $Self->_GetDisableSSLVerificationSetting();

    my $Command
        = "wget $ProxySetting $NoProxySetting $DisableSSLVerificationSetting -q -O - https://fastapi.metacpan.org/v1/download_url/$ModuleConfig->{Module} | grep download_url | cut -d '\"' -f4";

    my $DownloadURL = `$Command`;
    die "Error: Could not get DownloadURL." if !$DownloadURL;
    chomp $DownloadURL;

    system(
        "cd $TmpDir; wget $ProxySetting $NoProxySetting $DisableSSLVerificationSetting -q -O - $DownloadURL | tar -xzf - --strip 1"
    );

    if ( $ModuleConfig->{BuildBLib} ) {
        system("cd $TmpDir; perl Makefile.PL; make; cp -r $TmpDir/blib/lib/* $TargetPath");
        return 1;
    }

    if ( -d "$TmpDir/lib" ) {
        system("cp -r $TmpDir/lib/* $TargetPath");
        return 1;
    }

    my @ModuleParts     = split '::', $ModuleConfig->{Module};
    my $LastModuleLevel = pop @ModuleParts;
    my $ModulePath      = join '/', @ModuleParts;
    if ( -f "$TmpDir/$LastModuleLevel.pm" ) {
        if ( !-d "$TargetPath/$ModulePath" ) {
            File::Path::make_path("$TargetPath/$ModulePath") || die "Could not create $TargetPath/$ModulePath: $!.";
        }
        system("cp -r $TmpDir/$LastModuleLevel.pm $TargetPath/$ModulePath");
        return 1;
    }

    die "Download and/or file extraction of $DownloadURL failed.";
}

sub LoadModuleConfig {
    return (
        {
            Module             => 'Mozilla::CA',
            UpdateInStableMode => 1,
        },
    );
}

sub _GetProxySetting {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    my $Proxy = $ConfigObject->Get('WebUserAgent::Proxy');
    return '' if !IsStringWithData($Proxy);

    ( my $EscapedProxy = $Proxy ) =~ s{([\$"])}{\\$1}g;

    my $ProxySetting = '-e use_proxy=yes -e http_proxy="' . $EscapedProxy . '" -e https_proxy="' . $EscapedProxy . '"';

    return $ProxySetting;
}

sub _GetNoProxySetting {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    my $NoProxies = $ConfigObject->Get('WebUserAgent::NoProxy');
    return '' if !IsStringWithData($NoProxies);

    my @NoProxies = split /\s*;\s*/, $NoProxies;
    return '' if !@NoProxies;

    my $NoProxySetting = '';

    NOPROXY:
    for my $NoProxy (@NoProxies) {
        next NOPROXY if !IsStringWithData($NoProxy);

        ( my $EscapedNoProxy = $NoProxy ) =~ s{([\$"])}{\\$1}g;

        $NoProxySetting .= '-e no_proxy="' . $EscapedNoProxy . '" ';
    }

    return $NoProxySetting;
}

sub _GetDisableSSLVerificationSetting {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    my $DisableSSLVerification = $ConfigObject->Get('WebUserAgent::DisableSSLVerification');
    return '' if !$DisableSSLVerification;

    my $DisableSSLVerificationSetting = '--no-check-certificate';

    return $DisableSSLVerificationSetting;
}

1;
