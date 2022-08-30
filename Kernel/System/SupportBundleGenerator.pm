# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::SupportBundleGenerator;

use strict;
use warnings;

use Archive::Tar;
use Cwd qw(abs_path);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::CSV',
    'Kernel::System::JSON',
    'Kernel::System::Log',
    'Kernel::System::Main',
    'Kernel::System::Package',
    'Kernel::System::Registration',
    'Kernel::System::SupportDataCollector',
    'Kernel::System::SysConfig',
    'Kernel::System::DateTime',
);

=head1 NAME

Kernel::System::SupportBundleGenerator - support bundle generator

=head1 DESCRIPTION

All support bundle generator functions.

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $SupportBundleGeneratorObject = $Kernel::OM->Get('Kernel::System::SupportBundleGenerator');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash ref to object
    my $Self = {};
    bless( $Self, $Type );

    # cleanup the Home variable (remove tailing "/")
    $Self->{Home} = $Kernel::OM->Get('Kernel::Config')->Get('Home');
    $Self->{Home} =~ s{\/\z}{};

    $Self->{RandomID} = $Kernel::OM->Get('Kernel::System::Main')->GenerateRandomString(
        Length     => 8,
        Dictionary => [ 0 .. 9, 'a' .. 'f' ],
    );

    return $Self;
}

=head2 Generate()

Generates a support bundle C<.tar> or C<.tar.gz> with the following contents: Registration Information,
Support Data, Installed Packages, and another C<.tar> or C<.tar.gz> with all changed or new files in the
OTRS installation directory.

    my $Result = $SupportBundleGeneratorObject->Generate();

Returns:

    $Result = {
        Success => 1,                                # Or false, in case of an error
        Data    => {
            Filecontent => \$Tar,                    # Outer tar content reference
            Filename    => 'SupportBundle.tar',      # The outer tar filename
            Filesize    =>  123                      # The size of the file in mega bytes
        },

=cut

sub Generate {
    my ( $Self, %Param ) = @_;

    if ( !-e $Self->{Home} . '/ARCHIVE' ) {
        my $Message = $Self->{Home} . '/ARCHIVE: Is missing, can not continue!';
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => $Message,
        );
        return {
            Success => 0,
            Message => $Message,
        };
    }

    my %SupportFiles;

    # get the list of installed packages
    ( $SupportFiles{PackageListContent}, $SupportFiles{PackageListFilename} ) = $Self->GeneratePackageList();
    if ( !$SupportFiles{PackageListFilename} ) {
        my $Message = 'Can not generate the list of installed packages!';
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => $Message,
        );
        return {
            Success => 0,
            Message => $Message,
        };
    }

    # get the registration information
    ( $SupportFiles{RegistrationInfoContent}, $SupportFiles{RegistrationInfoFilename} )
        = $Self->GenerateRegistrationInfo();
    if ( !$SupportFiles{RegistrationInfoFilename} ) {
        my $Message = 'Can not get the registration information!';
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => $Message,
        );
        return {
            Success => 0,
            Message => $Message,
        };
    }

    # get the support data
    ( $SupportFiles{SupportDataContent}, $SupportFiles{SupportDataFilename} ) = $Self->GenerateSupportData();
    if ( !$SupportFiles{SupportDataFilename} ) {
        my $Message = 'Can not collect the support data!';
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => $Message,
        );
        return {
            Success => 0,
            Message => $Message,
        };
    }

    # get the archive of custom files
    ( $SupportFiles{CustomFilesArchiveContent}, $SupportFiles{CustomFilesArchiveFilename} )
        = $Self->GenerateCustomFilesArchive();
    if ( !$SupportFiles{CustomFilesArchiveFilename} ) {
        my $Message = 'Can not generate the custom files archive!';
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => $Message,
        );
        return {
            Success => 0,
            Message => $Message,
        };
    }

    # get the configuration dump
    ( $SupportFiles{ConfigurationDumpContent}, $SupportFiles{ConfigurationDumpFilename} )
        = $Self->GenerateConfigurationDump();
    if ( !$SupportFiles{ConfigurationDumpFilename} ) {
        my $Message = 'Can not get the configuration dump!';
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => $Message,
        );
        return {
            Success => 0,
            Message => $Message,
        };
    }

    # get config object
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # save and create archive
    my $TempDir = $ConfigObject->Get('TempDir') . '/SupportBundle';

    if ( !-d $TempDir ) {
        mkdir $TempDir;
    }

    $TempDir = $ConfigObject->Get('TempDir') . '/SupportBundle/' . $Self->{RandomID};

    if ( !-d $TempDir ) {
        mkdir $TempDir;
    }

    # remove all files
    my @ListOld = glob( $TempDir . '/*' );
    for my $File (@ListOld) {
        unlink $File;
    }

    # get main object
    my $MainObject = $Kernel::OM->Get('Kernel::System::Main');

    my @List;
    for my $Key (qw(PackageList RegistrationInfo SupportData CustomFilesArchive ConfigurationDump)) {

        if ( $SupportFiles{ $Key . 'Filename' } && $SupportFiles{ $Key . 'Content' } ) {

            my $Location = $TempDir . '/' . $SupportFiles{ $Key . 'Filename' };
            my $Content  = $SupportFiles{ $Key . 'Content' };

            my $FileLocation = $MainObject->FileWrite(
                Location   => $Location,
                Content    => $Content,
                Mode       => 'binmode',
                Type       => 'Local',
                Permission => '644',
            );

            push @List, $Location;
        }
    }

    my $DateTimeObject = $Kernel::OM->Create('Kernel::System::DateTime');
    my $Filename       = "SupportBundle_" . $DateTimeObject->Format( Format => "%Y-%m-%d_%H-%M" );

    # add files to the tar archive
    my $Archive   = $TempDir . '/' . $Filename;
    my $TarObject = Archive::Tar->new();
    $TarObject->add_files(@List);
    $TarObject->write( $Archive, 0 ) || die "Could not write: $_!";

    # add files to the tar archive
    open( my $Tar, '<', $Archive );    ## no critic
    binmode $Tar;
    my $TmpTar = do { local $/; <$Tar> };
    close $Tar;

    # remove all files
    @ListOld = glob( $TempDir . '/*' );
    for my $File (@ListOld) {
        unlink $File;
    }

    # remove temporary directory
    rmdir $TempDir;

    if ( $Kernel::OM->Get('Kernel::System::Main')->Require('Compress::Zlib') ) {
        my $GzTar = Compress::Zlib::memGzip($TmpTar);

        # log info
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'notice',
            Message  => 'Download Compress::Zlib end',
        );

        return {
            Success => 1,
            Data    => {
                Filecontent => \$GzTar,
                Filename    => $Filename . '.tar.gz',
                Filesize    => bytes::length($GzTar) / ( 1024 * 1024 ),
            },
        };
    }

    # log info
    $Kernel::OM->Get('Kernel::System::Log')->Log(
        Priority => 'notice',
        Message  => 'Download no Compress::Zlib end',
    );

    return {
        Success => 1,
        Data    => {
            Filecontent => \$TmpTar,
            Filename    => $Filename . '.tar',
            Filesize    => bytes::length($TmpTar) / ( 1024 * 1024 ),
        },
    };
}

=head2 GenerateCustomFilesArchive()

Generates a C<.tar> or C<.tar.gz> file with all eligible changed or added files taking the ARCHIVE file as a reference

    my ( $Content, $Filename ) = $SupportBundleGeneratorObject->GenerateCustomFilesArchive();

Returns:

    $Content  = $FileContentsRef;
    $Filename = 'application.tar';      # or 'application.tar.gz'

=cut

sub GenerateCustomFilesArchive {
    my ( $Self, %Param ) = @_;

    # get config object
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    my $TempDir = $ConfigObject->Get('TempDir') . '/SupportBundle';

    if ( !-d $TempDir ) {
        mkdir $TempDir;
    }

    $TempDir = $ConfigObject->Get('TempDir') . '/SupportBundle/' . $Self->{RandomID};

    if ( !-d $TempDir ) {
        mkdir $TempDir;
    }

    # remove all files
    my @ListOld = glob( $TempDir . '/*' );
    for my $File (@ListOld) {
        unlink $File;
    }

    my $CustomFilesArchive = $TempDir . '/application.tar';
    if ( -f $CustomFilesArchive ) {
        unlink $CustomFilesArchive || die "Can't unlink $CustomFilesArchive: $!";
    }

    # get a MD5Sum lookup table from all known files (from framework and packages)
    $Self->{MD5SumLookup} = $Self->_GetMD5SumLookup();

    # get the list of file to add to the Dump
    my @List = $Self->_GetCustomFileList( Directory => $Self->{Home} );

    # add files to the Dump
    my $TarObject = Archive::Tar->new();

    $TarObject->add_files(@List);

    # within the tar file the paths are not absolute, so leading "/" must be removed
    my $HomeWithoutSlash = $Self->{Home};
    $HomeWithoutSlash =~ s{\A\/}{};

    # Mask passwords in Config files.
    CONFIGFILE:
    for my $ConfigFile ( $TarObject->list_files() ) {

        next CONFIGFILE if ( $ConfigFile !~ 'Kernel/Config.pm' && $ConfigFile !~ 'Kernel/Config/Files' );

        my $Content = $TarObject->get_content($ConfigFile);

        if ( !$Content ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "$ConfigFile was not found in the modified files!",
            );
            next CONFIGFILE;
        }

        $Content = $Self->_MaskPasswords(
            StringToMask => $Content,
        );

        $TarObject->replace_content( $ConfigFile, $Content );
    }

    my $Write = $TarObject->write( $CustomFilesArchive, 0 );
    if ( !$Write ) {

        # log info
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Can't write $CustomFilesArchive: $!",
        );
        return;
    }

    # add files to the tar archive
    my $TARFH;
    if ( !open( $TARFH, '<', $CustomFilesArchive ) ) {    ## no critic

        # log info
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Can't read $CustomFilesArchive: $!",
        );
        return;
    }

    binmode $TARFH;
    my $TmpTar = do { local $/; <$TARFH> };
    close $TARFH;

    if ( $Kernel::OM->Get('Kernel::System::Main')->Require('Compress::Zlib') ) {
        my $GzTar = Compress::Zlib::memGzip($TmpTar);

        # log info
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'notice',
            Message  => "Compression of $CustomFilesArchive end",
        );

        return ( \$GzTar, 'application.tar.gz' );
    }

    # log info
    $Kernel::OM->Get('Kernel::System::Log')->Log(
        Priority => 'notice',
        Message  => "$CustomFilesArchive was not compressed",
    );

    return ( \$TmpTar, 'application.tar' );
}

=head2 GeneratePackageList()

Generates a .csv file with all installed packages

    my ( $Content, $Filename ) = $SupportBundleGeneratorObject->GeneratePackageList();

Returns:
    $Content  = $FileContentsRef;
    $Filename = 'InstalledPackages.csv';

=cut

sub GeneratePackageList {
    my ( $Self, %Param ) = @_;

    my @PackageList = $Kernel::OM->Get('Kernel::System::Package')->RepositoryList( Result => 'Short' );

    # get csv object
    my $CSVObject = $Kernel::OM->Get('Kernel::System::CSV');

    my $CSVContent = '';
    for my $Package (@PackageList) {

        my @PackageData = (
            [
                $Package->{Name},
                $Package->{Version},
                $Package->{MD5sum},
                $Package->{Vendor},
            ],
        );

        # convert data into CSV string
        $CSVContent .= $CSVObject->Array2CSV(
            Data => \@PackageData,
        );
    }

    return ( \$CSVContent, 'InstalledPackages.csv' );
}

=head2 GenerateRegistrationInfo()

Generates a C<.json> file with the otrs system registration information

    my ( $Content, $Filename ) = $SupportBundleGeneratorObject->GenerateRegistrationInfo();

Returns:

    $Content  = $FileContentsRef;
    $Filename = 'RegistrationInfo.json';

=cut

sub GenerateRegistrationInfo {
    my ( $Self, %Param ) = @_;

    my %RegistrationInfo = $Kernel::OM->Get('Kernel::System::Registration')->RegistrationDataGet(
        Extended => 1,
    );

    my %Data;
    if (%RegistrationInfo) {
        my $State = $RegistrationInfo{State} || '';
        if ( $State && lc $State eq 'registered' ) {
            $State = 'active';
        }

        %Data = (
            %{ $RegistrationInfo{System} },
            State              => $State,
            APIVersion         => $RegistrationInfo{APIVersion},
            APIKey             => $RegistrationInfo{APIKey},
            LastUpdateID       => $RegistrationInfo{LastUpdateID},
            RegistrationKey    => $RegistrationInfo{UniqueID},
            SupportDataSending => $RegistrationInfo{SupportDataSending},
            Type               => $RegistrationInfo{Type},
            Description        => $RegistrationInfo{Description},
        );
    }
    else {
        %Data = %RegistrationInfo;
    }

    my $JSONContent = $Kernel::OM->Get('Kernel::System::JSON')->Encode(
        Data => \%Data,
    );

    return ( \$JSONContent, 'RegistrationInfo.json' );
}

=head2 GenerateConfigurationDump()

Generates a <.yml> file with the otrs system registration information

    my ( $Content, $Filename ) = $SupportBundleGeneratorObject->GenerateConfigurationDump();

Returns:
    $Content  = $FileContentsRef;
    $Filename = <'ModifiedSettings.yml'>;

=cut

sub GenerateConfigurationDump {
    my ( $Self, %Param ) = @_;

    my $Export = $Kernel::OM->Get('Kernel::System::SysConfig')->ConfigurationDump(
        SkipDefaultSettings => 1,
    );

    $Export = $Self->_MaskPasswords(
        StringToMask => $Export,
        YAML         => 1
    );

    return ( \$Export, 'ModifiedSettings.yml' );
}

=head2 GenerateSupportData()

Generates a C<.json> file with the support data

    my ( $Content, $Filename ) = $SupportBundleGeneratorObject->GenerateSupportData();

Returns:

    $Content  = $FileContentsRef;
    $Filename = 'GenerateSupportData.json';

=cut

sub GenerateSupportData {
    my ( $Self, %Param ) = @_;

    my $SupportDataCollectorWebTimeout
        = $Kernel::OM->Get('Kernel::Config')->Get('SupportDataCollector::WebUserAgent::Timeout');

    my %SupportData = $Kernel::OM->Get('Kernel::System::SupportDataCollector')->Collect(
        WebTimeout => $SupportDataCollectorWebTimeout,
    );

    my $JSONContent = $Kernel::OM->Get('Kernel::System::JSON')->Encode(
        Data => \%SupportData,
    );

    return ( \$JSONContent, 'SupportData.json' );
}

sub _GetMD5SumLookup {
    my ( $Self, %Param ) = @_;

    # generate a MD5 Sum lookup table from framework ARCHIVE
    my $FileList = $Kernel::OM->Get('Kernel::System::Main')->FileRead(
        Location        => $Self->{Home} . '/ARCHIVE',
        Mode            => 'utf8',
        Type            => 'Local',
        Result          => 'ARRAY',
        DisableWarnings => 1,
    );
    my %MD5SumLookup;
    for my $Line ( @{$FileList} ) {
        my ( $MD5Sum, $File ) = split /::/, $Line;
        chomp $File;
        $MD5SumLookup{ $Self->{Home} . '/' . $File } = $MD5Sum;
    }

    # get package object
    my $PackageObject = $Kernel::OM->Get('Kernel::System::Package');

    # get a list of packages installed
    my @PackagesList = $PackageObject->RepositoryList(
        Result => 'short',
    );

    # get from each installed package  a MD5 Sum Lookup table and store it on a global Lookup table
    my %PackageMD5SumLookup;
    for my $Package (@PackagesList) {
        my $PartialMD5Sum = $PackageObject->PackageFileGetMD5Sum( %{$Package} );
        %PackageMD5SumLookup = ( %PackageMD5SumLookup, %{$PartialMD5Sum} );
    }

    # add MD5Sums from all packages to the list from framework ARCHIVE
    # overwritten files by packages will also overwrite the MD5 Sum
    %MD5SumLookup = ( %MD5SumLookup, %PackageMD5SumLookup );

    return \%MD5SumLookup;
}

sub _GetCustomFileList {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Directory)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    # get config object
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # article directory
    my $ArticleDir = $ConfigObject->Get('Ticket::Article::Backend::MIMEBase::ArticleDataDir');

    # cleanup file name
    $ArticleDir =~ s/\/\//\//g;

    # temp directory
    my $TempDir = $ConfigObject->Get('TempDir');

    # cleanup file name
    $TempDir =~ s/\/\//\//g;

    # assemble additional paths to be ignored
    my %AdditionalIgnoredAbsPaths = map { $Self->_GetAbsPath($_) => 1 } (
        $ConfigObject->Get('SMIME::PrivatePath'),
        $ConfigObject->Get('SMIME::CertPath'),
    );

    # check all $Param{Directory}/* in home directory
    my @Files;
    my @List = glob("$Param{Directory}/*");
    FILE:
    for my $File (@List) {
        my $AbsFilePath = $Self->_GetAbsPath($File);
        next FILE if $AdditionalIgnoredAbsPaths{$AbsFilePath};

        # cleanup file name
        $File =~ s/\/\//\//g;

        # check if directory
        if ( -d $File ) {

            # do not include article in file system
            next FILE if $File =~ /\Q$ArticleDir\E/i;

            # do not include tmp in file system
            next FILE if $File =~ /\Q$TempDir\E/i;

            # do not include js-cache
            next FILE if $File =~ /js-cache/;

            # do not include css-cache
            next FILE if $File =~ /css-cache/;

            # do not include documentation
            next FILE if $File =~ /doc/;

            # add directory to list
            push @Files, $Self->_GetCustomFileList( Directory => $File );
        }
        else {

            # do not include hidden files
            next FILE if $File =~ /^\./;

            # do not include files with # in file name
            next FILE if $File =~ /#/;

            # do not include previous system dumps
            next FILE if $File =~ /.tar/;

            # do not include ARCHIVE
            next FILE if $File =~ /ARCHIVE/;

            # do not include if file is not readable
            next FILE if !-r $File;

            my $MD5Sum = $Kernel::OM->Get('Kernel::System::Main')->MD5sum(
                Filename => $File,
            );

            # check if is a known file, in such case, check if MD5 is the same as the expected
            #   skip file if MD5 matches
            if ( $Self->{MD5SumLookup}->{$File} && $Self->{MD5SumLookup}->{$File} eq $MD5Sum ) {
                next FILE;
            }

            # add file to list
            push @Files, $File;
        }
    }

    return @Files;
}

sub _MaskPasswords {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(StringToMask)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    my $StringToMask = $Param{StringToMask};

    # Trim any passswords.
    # Simple settings like $Self->{'DatabasePw'} or $Self->{'AuthModule::LDAP::SearchUserPw1'}.
    $StringToMask =~ s/(\$Self->\{'*[^']+(?:Password|Pw)\d*'*\}\s*=\s*)\'.*?\'/$1\'xxx\'/mg;

    # Complex settings like:
    #     $Self->{CustomerUser1} = {
    #         Params => {
    #             UserPw => 'xxx',
    $StringToMask =~ s/((?:Password|Pw)\d*\s*=>\s*)\'.*?\'/$1\'xxx\'/mg;

    # Obfuscate user login data to avoid showing it.
    $StringToMask =~ s{://\w+:\w+@}{://[user]:[password]@}smxg;

    return $StringToMask;
}

sub _GetAbsPath {
    my ( $Self, $Path ) = @_;

    return if !defined $Path;
    return if !length $Path;

    my $AbsPath = abs_path($Path);

    return $AbsPath;
}

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut

1;
