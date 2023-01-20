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

my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

my $Home = $ConfigObject->Get('Home');
$Home =~ s{\/\z}{};

# create an ARCHIVE file on developer systems to continue working
my $ArchiveGeneratorTool = $Home . '/bin/otrs.CheckSum.pl';

# if tool is not present we can't continue
if ( !-e $ArchiveGeneratorTool ) {
    $Self->True(
        0,
        "$ArchiveGeneratorTool does not exist, we can't continue",
    );
    return;
}

# execute ARCHIVE generator tool
my $Result = `$ArchiveGeneratorTool -a create 2>&1`;

if ( !-e $Home . '/ARCHIVE' || -z $Home . '/ARCHIVE' ) {

    # if ARCHIVE file is not present we can't continue
    $Self->True(
        0,
        "ARCHIVE file is not generated, we can't continue. Script output was: $Result",
    );
    return;
}
else {
    $Self->True(
        1,
        "ARCHIVE file is generated for UnitTest purpose. Script output was: $Result",
    );
}

my $ChecksumFileNotPresent = sub {
    $Self->False(
        1,
        'Archive unit test requires the checksum file (ARCHIVE) to be present and valid. Please first call the following command to create it: bin/otrs.CheckSum.pl -a create'
    );
    return 1;
};

my $MainObject = $Kernel::OM->Get('Kernel::System::Main');

my $ChecksumFile = "$Home/ARCHIVE";

# Checksum file content as an array ref.
my $ChecksumFileArrayRef = $MainObject->FileRead(
    Location        => $ChecksumFile,
    Mode            => 'utf8',
    Type            => 'Local',
    Result          => 'ARRAY',
    DisableWarnings => 1,
);
return $ChecksumFileNotPresent->() if !$ChecksumFileArrayRef || !@{$ChecksumFileArrayRef};

my $ChecksumFileSize = -s $ChecksumFile;
$Self->True(
    $ChecksumFileSize && $ChecksumFileSize > 2**10 && $ChecksumFileSize < 2**20,
    'Checksum file size in expected range (> 1KB && < 1MB)'
);

my $ErrorsFound;

# Verify MD5 digests in the checksum file.
LINE:
while ( my $Line = shift @{$ChecksumFileArrayRef} ) {
    my @Entry = split '::', $Line;
    next LINE if @Entry < 2;

    chomp $Entry[1];
    my $Filename = "$Home/$Entry[1]";

    if ( !-f $Filename ) {
        $Self->False(
            1,
            "$Filename not found"
        );
        next LINE;
    }

    if ( $Filename =~ /Cron|CHANGES|apache2-perl-startup/ ) {

        # Skip files with expected changes.
        next LINE;
    }

    if ( -e "$Filename.save" ) {

        # Ignore files overwritten by packages.
        next LINE;
    }

    my $Digest = $MainObject->MD5sum(
        Filename => $Filename,
    );

    # To save data, we only record errors of files, no positive results.
    if ( $Digest ne $Entry[0] ) {
        $Self->Is(
            $Digest,
            $Entry[0],
            "$Filename digest"
        );
        $ErrorsFound++;
    }
}

$Self->False(
    $ErrorsFound,
    "Mismatches in file list",
);

1;
