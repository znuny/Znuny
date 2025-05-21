# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
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

my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
my $MainObject   = $Kernel::OM->Get('Kernel::System::Main');
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $StatsObject  = $Kernel::OM->Get('Kernel::System::Stats');

my $Home            = $ConfigObject->Get('Home');
my $TargetDirectory = $Home . '/var/tmp/StatsGenerate';

my $StatsRef = $StatsObject->StatsListGet(
    AccessRw => 1,
    UserID   => 1,
);

my $StatNumber = '10001';

if ( IsHashRefWithData($StatsRef) ) {
    $Self->Is(
        $StatsRef->{1}->{StatNumber},
        $StatNumber,
        "StatNumber exists: $StatNumber.",
    );
}

my @Tests = (
    {
        Name          => "No options (should fail)",
        CommandModule => 'Kernel::System::Console::Command::Maint::Stats::Generate',
        Parameter     => [],
        ExitCode      => 1,
        STDOUT        => undef,
        STDERR        => 'Error: please provide option \'--number\'.',
    },
    {
        Name          => "Invalid stats number format",
        CommandModule => 'Kernel::System::Console::Command::Maint::Stats::Generate',
        Parameter     => [ '--number', 'XX' ],
        ExitCode      => 1,
        STDOUT        => undef,
        STDERR        => 'Error: please provide a valid value for option \'--number\'.',
    },
    {
        Name          => "Format CSV",
        CommandModule => 'Kernel::System::Console::Command::Maint::Stats::Generate',
        Parameter     => [
            '--number', '10001', '--language', 'en',
            '--target-directory', $TargetDirectory, '--target-filename', 'FormatCSV',
            '--format', 'CSV'
        ],
        TargetDirectory => $TargetDirectory,
        TargetFilename  => 'FormatCSV',
        Format          => 'csv',
        FileCount       => 1,
        ExitCode        => 0,
        STDOUT          => undef,
        STDERR          => undef,
    },
    {
        Name          => "Format Excel",
        CommandModule => 'Kernel::System::Console::Command::Maint::Stats::Generate',
        Parameter     => [
            '--number', '10001', '--language', 'en',
            '--target-directory', $TargetDirectory, '--target-filename', 'FormatExcel',
            '--format', 'Excel'
        ],
        TargetDirectory => $TargetDirectory,
        TargetFilename  => 'FormatExcel',
        Format          => 'xlsx',
        FileCount       => 1,
        ExitCode        => 0,
        STDOUT          => undef,
        STDERR          => undef,
    },
    {
        Name          => "Format Print|PDF",
        CommandModule => 'Kernel::System::Console::Command::Maint::Stats::Generate',
        Parameter     => [
            '--number', '10001', '--language', 'en',
            '--target-directory', $TargetDirectory, '--target-filename', 'FormatPDF',
            '--format', 'PDF'
        ],
        TargetDirectory => $TargetDirectory,
        TargetFilename  => 'FormatPDF',
        Format          => 'pdf',
        FileCount       => 1,
        ExitCode        => 0,
        STDOUT          => undef,
        STDERR          => undef,
    },
);

for my $Test (@Tests) {

    if ( $Test->{TargetDirectory} ) {

        # Remove the target directory if it exists and create a new one.
        File::Path::remove_tree( $Test->{TargetDirectory} );
        mkdir $Test->{TargetDirectory};
    }

    my $Result = $HelperObject->ConsoleCommand(
        CommandModule => $Test->{CommandModule},
        Parameter     => $Test->{Parameter},
    );

    $Self->True(
        scalar IsHashRefWithData($Result),
        "ConsoleCommand returns a HashRef with data ($Test->{Name})",
    ) || return 1;

    $Self->Is(
        $Result->{ExitCode},
        $Test->{ExitCode},
        "Expected ExitCode ($Test->{Name})",
    );

    STREAM:
    for my $Stream (qw(STDOUT STDERR)) {
        next STREAM if !defined $Test->{$Stream};

        $Self->True(
            scalar( $Result->{$Stream} =~ m{$Test->{$Stream}}sm ),
            "$Stream contains '$Test->{ $Stream }' ($Test->{Name})",
        );
    }

    if ( $Test->{TargetDirectory} ) {
        $Self->True(
            -e $Test->{TargetDirectory},
            "TargetDirectory exists.",
        );

        my @FilesInDirectory = $MainObject->DirectoryRead(
            Directory => $Test->{TargetDirectory},
            Filter    => "*.$Test->{Format}",
        );

        if ( $Test->{FileCount} ) {
            $Self->Is(
                scalar @FilesInDirectory,
                $Test->{FileCount},
                "Expected FileCount ($Test->{FileCount})",
            );
        }
        if ( $Test->{TargetFilename} ) {

            # remove all but the last part of the filename
            my $Filename = $FilesInDirectory[0];
            $Filename =~ s{.*/}{}xms;

            $Self->Is(
                $Filename,
                $Test->{TargetFilename} . "." . $Test->{Format},
                "Expected TargetFilename ($Test->{TargetFilename})",
            );
        }

        $Self->True(
            $FilesInDirectory[0],
            "File exists: $FilesInDirectory[0].",
        );
    }
}

1;
