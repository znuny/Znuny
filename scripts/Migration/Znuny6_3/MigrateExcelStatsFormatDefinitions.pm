# --
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package scripts::Migration::Znuny6_3::MigrateExcelStatsFormatDefinitions;    ## no critic

use strict;
use warnings;
use File::Copy;

use parent qw(scripts::Migration::Base);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Log',
    'Kernel::System::Main',
);

=head1 SYNOPSIS

Migrate Excel Stats format definitions.

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    my $MainObject   = $Kernel::OM->Get('Kernel::System::Main');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');

    my $Home       = $ConfigObject->Get('Home') . '/';
    my $SourcePath = $Home . "var/statsformatdefinition/";
    my $DestPath   = $Home . "var/stats/formatdefinition/excel/";

    return 1 if !-d $SourcePath;

    my @Files = $MainObject->DirectoryRead(
        Directory => $SourcePath,
        Filter    => '*',
    );

    FILE:
    for my $File (@Files) {

        my $FullSourcePath = $SourcePath . $File;
        my $FullDestPath   = $DestPath . $File;

        my $FileMoved = move( $FullSourcePath, $FullDestPath );
        next FILE if $FileMoved;

        $LogObject->Log(
            Priority => 'error',
            Message  => "Error moving file from $FullSourcePath to $FullDestPath.",
        );
    }

    return 1;
}

1;
