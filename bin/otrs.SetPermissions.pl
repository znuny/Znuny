#!/usr/bin/env perl
# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

use strict;
use warnings;

use File::Basename;
use FindBin qw($RealBin);
use lib dirname($RealBin);
use lib dirname($RealBin) . '/Kernel/cpan-lib';
use lib dirname($RealBin) . '/Custom';

use File::Find();
use File::stat();
use Getopt::Long();

my $OTRSDirectory       = dirname($RealBin);
my $OTRSDirectoryLength = length($OTRSDirectory);

my $OtrsUser = 'otrs';    # default: otrs
my $WebGroup = '';        # Try to find a default from predefined group list, take the first match.

WEBGROUP:
for my $GroupCheck (qw(wwwrun apache www-data www _www)) {
    my ($GroupName) = getgrnam $GroupCheck;
    if ($GroupName) {
        $WebGroup = $GroupName;
        last WEBGROUP;
    }
}

my $AdminGroup = 'root';    # default: root
my ( $Help, $DryRun, $SkipArticleDir, @SkipRegex, $OtrsUserID, $WebGroupID, $AdminGroupID );

sub PrintUsage {
    print <<EOF;

Set OTRS file permissions.

Usage:
 otrs.SetPermissions.pl [--otrs-user=<OTRS_USER>] [--web-group=<WEB_GROUP>] [--admin-group=<ADMIN_GROUP>] [--skip-article-dir] [--skip-regex="REGEX"] [--dry-run]

Options:
 [--otrs-user=<OTRS_USER>]     - OTRS user, defaults to 'otrs'.
 [--web-group=<WEB_GROUP>]     - Web server group ('_www', 'www-data' or similar), try to find a default.
 [--admin-group=<ADMIN_GROUP>] - Admin group, defaults to 'root'.
 [--skip-article-dir]          - Skip var/article as it might take too long on some systems.
 [--skip-regex="REGEX"]        - Add another skip regex like "^/var/my/directory". Paths start with / but are relative to the OTRS directory. --skip-regex can be specified multiple times.
 [--dry-run]                   - Only report, don't change.
 [--help]                      - Display help for this command.

Help:
Using this script without any options it will try to detect the correct user and group settings needed for your setup.

 otrs.SetPermissions.pl

EOF
    return;
}

# Files/directories that should be ignored and not recursed into.
my @IgnoreFiles = (
    qr{^/\.git}smx,
    qr{^/\.tidyall}smx,
    qr{^/\.tx}smx,
    qr{^/\.settings}smx,
    qr{^/\.ssh}smx,
    qr{^/\.gpg}smx,
    qr{^/\.gnupg}smx,
);

# Files to be marked as executable.
my @ExecutableFiles = (
    qr{\.(?:pl|psgi|sh)$}smx,
    qr{^/var/git/hooks/(?:pre|post)-receive$}smx,
);

# Special files that must not be written by web server user.
my @ProtectedFiles = (
    qr{^/\.fetchmailrc$}smx,
    qr{^/\.procmailrc$}smx,
);

my $ExitStatus = 0;

sub Run {
    Getopt::Long::GetOptions(
        'help'             => \$Help,
        'otrs-user=s'      => \$OtrsUser,
        'web-group=s'      => \$WebGroup,
        'admin-group=s'    => \$AdminGroup,
        'dry-run'          => \$DryRun,
        'skip-article-dir' => \$SkipArticleDir,
        'skip-regex=s'     => \@SkipRegex,
    );

    if ( defined $Help ) {
        PrintUsage();
        exit 0;
    }

    if ( $> != 0 ) {    # $EFFECTIVE_USER_ID
        print STDERR "ERROR: Please run this script as superuser (root).\n";
        exit 1;
    }

    # check params
    $OtrsUserID = getpwnam $OtrsUser;
    if ( !$OtrsUser || !defined $OtrsUserID ) {
        print STDERR "ERROR: --otrs-user is missing or invalid.\n";
        exit 1;
    }
    $WebGroupID = getgrnam $WebGroup;
    if ( !$WebGroup || !defined $WebGroupID ) {
        print STDERR "ERROR: --web-group is missing or invalid.\n";
        exit 1;
    }
    $AdminGroupID = getgrnam $AdminGroup;
    if ( !$AdminGroup || !defined $AdminGroupID ) {
        print STDERR "ERROR: --admin-group is invalid.\n";
        exit 1;
    }
    if ( defined $SkipArticleDir ) {
        push @IgnoreFiles, qr{^/var/article}smx;
    }
    for my $Regex (@SkipRegex) {
        push @IgnoreFiles, qr{$Regex}smx;
    }

    print "Setting permissions on $OTRSDirectory\n";
    File::Find::find(
        {
            wanted   => \&SetPermissions,
            no_chdir => 1,
            follow   => 1,
        },
        $OTRSDirectory,
    );
    exit $ExitStatus;
}

sub SetPermissions {

    # First get a canonical full filename
    my $File = $File::Find::fullname;

    # If the link is a dangling symbolic link, then fullname will be set to undef.
    return if !defined $File;

    # Make sure it is inside the OTRS directory to avoid following symlinks outside
    if ( substr( $File, 0, $OTRSDirectoryLength ) ne $OTRSDirectory ) {
        $File::Find::prune = 1;    # don't descend into subdirectories
        return;
    }

    # Now get a canonical relative filename under the OTRS directory
    my $RelativeFile = substr( $File, $OTRSDirectoryLength ) || '/';

    for my $IgnoreRegex (@IgnoreFiles) {
        if ( $RelativeFile =~ $IgnoreRegex ) {
            $File::Find::prune = 1;    # don't descend into subdirectories
            print "Skipping $RelativeFile\n";
            return;
        }
    }

    # Ok, get target permissions for file
    SetFilePermissions( $File, $RelativeFile );

    return;
}

sub SetFilePermissions {
    my ( $File, $RelativeFile ) = @_;

    ## no critic (ProhibitLeadingZeros)
    # Writable by default, owner OTRS and group webserver.
    my ( $TargetPermission, $TargetUserID, $TargetGroupID ) = ( 0660, $OtrsUserID, $WebGroupID );
    if ( -d $File ) {

        # SETGID for all directories so that both OTRS and the web server can write to the files.
        # Other users should be able to read and cd to the directories.
        $TargetPermission = 02775;
    }
    else {
        # Executable bit for script files.
        EXEXUTABLE_REGEX:
        for my $ExecutableRegex (@ExecutableFiles) {
            if ( $RelativeFile =~ $ExecutableRegex ) {
                $TargetPermission = 0770;
                last EXEXUTABLE_REGEX;
            }
        }

        # Some files are protected and must not be written by webserver. Set admin group.
        PROTECTED_REGEX:
        for my $ProtectedRegex (@ProtectedFiles) {
            if ( $RelativeFile =~ $ProtectedRegex ) {
                $TargetPermission = -d $File ? 0750 : 0640;
                $TargetGroupID    = $AdminGroupID;
                last PROTECTED_REGEX;
            }
        }
    }

    # Special treatment for toplevel folder: this must be readonly,
    #   otherwise procmail will refuse to read .procmailrc (see bug#9391).
    if ( $RelativeFile eq '/' ) {
        $TargetPermission = 0755;
    }

    # There seem to be cases when stat does not work on a dangling link, skip in this case.
    my $Stat = File::stat::stat($File) || return;
    if ( ( $Stat->mode() & 07777 ) != $TargetPermission ) {
        if ( defined $DryRun ) {
            print sprintf(
                "$RelativeFile permissions %o -> %o\n",
                $Stat->mode() & 07777,
                $TargetPermission
            );
        }
        elsif ( !chmod( $TargetPermission, $File ) ) {
            print STDERR sprintf(
                "ERROR: could not change $RelativeFile permissions %o -> %o: $!\n",
                $Stat->mode() & 07777,
                $TargetPermission
            );
            $ExitStatus = 1;
        }
    }
    if ( ( $Stat->uid() != $TargetUserID ) || ( $Stat->gid() != $TargetGroupID ) ) {
        if ( defined $DryRun ) {
            print sprintf(
                "$RelativeFile ownership %s:%s -> %s:%s\n",
                $Stat->uid(),
                $Stat->gid(),
                $TargetUserID,
                $TargetGroupID
            );
        }
        elsif ( !chown( $TargetUserID, $TargetGroupID, $File ) ) {
            print STDERR sprintf(
                "ERROR: could not change $RelativeFile ownership %s:%s -> %s:%s: $!\n",
                $Stat->uid(),
                $Stat->gid(),
                $TargetUserID,
                $TargetGroupID
            );
            $ExitStatus = 1;
        }
    }

    return;
    ## use critic
}

Run();
