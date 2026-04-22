# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::Console::Command::Admin::Package::Export;

use strict;
use warnings;

use parent qw(Kernel::System::Console::BaseCommand);

use Kernel::System::VariableCheck qw(:all);

use File::Basename;
use File::Path qw(make_path);

our @ObjectDependencies = (
    'Kernel::System::Main',
    'Kernel::System::Package',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Export the content of a package to a directory.');
    $Self->AddOption(
        Name        => 'target-directory',
        Description =>
            "Export content of the package to the specified directory. If omitted, will use file name of given source path without its extension as target directory.",
        Required   => 0,
        HasValue   => 1,
        ValueRegex => qr/.*/smx,
    );
    $Self->AddOption(
        Name        => 'create-missing-target-directory',
        Description => "Create the target directory if it does not exist.",
        Required    => 0,
        HasValue    => 0,
    );
    $Self->AddArgument(
        Name        => 'source-path',
        Description => "Specify the path to a package (opm) file that will be exported.",
        Required    => 1,
        ValueRegex  => qr/.*/smx,
    );

    return;
}

sub PreRun {
    my ( $Self, %Param ) = @_;

    my $SourcePath = $Self->GetArgument('source-path');
    if ( $SourcePath && !-r $SourcePath ) {
        die "File $SourcePath does not exist / can not be read.\n";
    }

    my $TargetDirectory = $Self->GetOption('target-directory');
    if ( !IsStringWithData($TargetDirectory) ) {
        $TargetDirectory = basename($SourcePath);
        $TargetDirectory =~ s{(\A.*)\..*\z}{$1};
    }

    my $CreateMissingTargetDirectory = $Self->GetOption('create-missing-target-directory');
    if (
        !$CreateMissingTargetDirectory
        && $TargetDirectory
        && !-d $TargetDirectory
        )
    {
        die "Directory $TargetDirectory does not exist.\n";
    }

    $Self->{TargetDirectory} = $TargetDirectory;

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    $Self->Print("<yellow>Exporting package contents...</yellow>\n");

    my $SourcePath = $Self->GetArgument('source-path');

    my $FileString;
    my $ContentRef = $Kernel::OM->Get('Kernel::System::Main')->FileRead(
        Location => $SourcePath,
        Mode     => 'utf8',        # optional - binmode|utf8
        Result   => 'SCALAR',      # optional - SCALAR|ARRAY
    );
    if ( !$ContentRef || ref $ContentRef ne 'SCALAR' ) {
        $Self->PrintError("File $SourcePath is empty / could not be read.");
        return $Self->ExitCodeError();
    }
    $FileString = ${$ContentRef};

    my %Structure = $Kernel::OM->Get('Kernel::System::Package')->PackageParse(
        String => $FileString,
    );

    # just export files if PackageIsDownloadable flag is enable
    if (
        defined $Structure{PackageIsDownloadable}
        && !$Structure{PackageIsDownloadable}->{Content}
        )
    {
        $Self->PrintError("Files cannot be exported.\n");
        return $Self->ExitCodeError();
    }

    my $TargetDirectory              = $Self->{TargetDirectory};
    my $CreateMissingTargetDirectory = $Self->GetOption('create-missing-target-directory');
    if (
        $CreateMissingTargetDirectory
        && !-d $TargetDirectory
        )
    {
        make_path($TargetDirectory);
        if ( !-d $TargetDirectory ) {
            $Self->PrintError("Error creating target directory $TargetDirectory.");
            return $Self->ExitCodeError();
        }
    }
    my $Success = $Kernel::OM->Get('Kernel::System::Package')->PackageExport(
        String => $FileString,
        Home   => $TargetDirectory,
    );

    if ($Success) {
        $Self->Print("<green>Exported files of package $SourcePath to $TargetDirectory.</green>\n");
        return $Self->ExitCodeOk();
    }
}

1;
