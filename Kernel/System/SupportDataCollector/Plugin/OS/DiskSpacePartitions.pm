# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::SupportDataCollector::Plugin::OS::DiskSpacePartitions;

use strict;
use warnings;

use parent qw(Kernel::System::SupportDataCollector::PluginBase);

use Kernel::Language qw(Translatable);

our @ObjectDependencies = ();

sub GetDisplayPath {
    return Translatable('Operating System') . '/' . Translatable('Disk Partitions Usage');
}

sub Run {
    my $Self = shift;

    # Check if used OS is a Linux system
    if ( $^O !~ /(linux|unix|netbsd|freebsd|darwin)/i ) {
        return $Self->GetResults();
    }

    my $Commandline = "df -lHx tmpfs -x iso9660 -x udf -x squashfs";

    # current MacOS and FreeBSD does not support the -x flag for df
    if ( $^O =~ /(darwin|freebsd)/i ) {
        $Commandline = "df -lH";
    }

    # run the command an store the result on an array
    my @Lines;
    if ( open( my $In, "-|", "$Commandline" ) ) {
        @Lines = <$In>;
        close($In);
    }

    # clean results, in some systems when partition is too long it splits the line in two, it is
    #   needed to have all partition information in just one line for example
    #   From:
    #   /dev/mapper/system-tmp
    #                   2064208    85644   1873708   5% /tmp
    #   To:
    #   /dev/mapper/system-tmp                   2064208    85644   1873708   5% /tmp
    my @CleanLines;
    my $PreviousLine;

    LINE:
    for my $Line (@Lines) {

        chomp $Line;

        # if line does not have percent number (then it should only contain the partition)
        if ( $Line !~ m{\d+%} ) {

            # remember the line
            $PreviousLine = $Line;
            next LINE;
        }

        # if line starts with just spaces and have a percent number
        elsif ( $Line =~ m{\A \s+ (?: \d+ | \s+)+ \d+ % .+? \z}msx ) {

            # concatenate previous line and store it
            push @CleanLines, $PreviousLine . $Line;
            $PreviousLine = '';
            next LINE;
        }

        # otherwise store the line as it is
        push @CleanLines, $Line;
        $PreviousLine = '';
    }

    my %SeenPartitions;
    LINE:
    for my $Line (@CleanLines) {

        # remove leading white spaces in line
        $Line =~ s{\A\s+}{};

        if ( $Line =~ m{\A .+? \s .* \s \d+ % .+? \z}msx ) {
            my ( $Partition, $Size, $UsedPercent, $MountPoint )
                = $Line =~ m{\A (.+?) \s+ ([\d\.KGMT]*) \s+ .*? \s+ (\d+)%.+? (\/.*) \z}msx;

            $MountPoint //= '';

            $Partition = "$MountPoint ($Partition)";

            next LINE if $SeenPartitions{$Partition}++;

            $Self->AddResultInformation(
                Identifier => $Partition,
                Label      => $Partition,
                Value      => $Size . ' (Used: ' . $UsedPercent . '%)',
            );
        }
    }

    return $Self->GetResults();
}

1;
