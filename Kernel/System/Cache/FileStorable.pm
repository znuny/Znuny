# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::Cache::FileStorable;

use strict;
use warnings;

use POSIX;
use Digest::MD5 qw();
use File::Path qw();
use File::Find qw();

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Encode',
    'Kernel::System::Log',
    'Kernel::System::Main',
    'Kernel::System::Storable',
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # get config object
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    my $TempDir = $ConfigObject->Get('TempDir');
    $Self->{CacheDirectory} = $TempDir . '/CacheFileStorable';

    # check if cache directory exists and in case create one
    for my $Directory ( $TempDir, $Self->{CacheDirectory} ) {
        if ( !-e $Directory ) {
            ## no critic
            if ( !mkdir( $Directory, 0770 ) ) {
                ## use critic
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'error',
                    Message  => "Can't create directory '$Directory': $!",
                );
            }
        }
    }

    # Specify how many levels of subdirectories to use, can be 0, 1 or more.
    $Self->{'Cache::SubdirLevels'} = $ConfigObject->Get('Cache::SubdirLevels');
    $Self->{'Cache::SubdirLevels'} //= 2;

    return $Self;
}

sub Set {
    my ( $Self, %Param ) = @_;

    for my $Needed (qw(Type Key Value TTL)) {
        if ( !defined $Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    my $Dump = $Kernel::OM->Get('Kernel::System::Storable')->Serialize(
        Data => {
            TTL   => time() + $Param{TTL},
            Value => $Param{Value},
        },
    );

    my ( $Filename, $CacheDirectory ) = $Self->_GetFilenameAndCacheDirectory(%Param);

    if ( !-e $CacheDirectory ) {

        # Create directory. This could fail if another process creates the
        #   same directory, so don't use the return value.
        File::Path::mkpath( $CacheDirectory, 0, 0770 );    ## no critic

        if ( !-e $CacheDirectory ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Can't create directory '$CacheDirectory': $!",
            );
            return;
        }
    }
    my $FileLocation = $Kernel::OM->Get('Kernel::System::Main')->FileWrite(

      # Use Location rather than Filename and Directory to skip the (unneeded) filename clean-up for better performance.
        Location   => $CacheDirectory . '/' . $Filename,
        Content    => \$Dump,
        Type       => 'Local',
        Mode       => 'binmode',
        Permission => '660',
    );

    return if !$FileLocation;
    return 1;
}

sub Get {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Type Key)) {
        if ( !defined $Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    my ( $Filename, $CacheDirectory ) = $Self->_GetFilenameAndCacheDirectory(%Param);

    my $Content = $Kernel::OM->Get('Kernel::System::Main')->FileRead(

      # Use Location rather than Filename and Directory to skip the (unneeded) filename clean-up for better performance.
        Location        => $CacheDirectory . '/' . $Filename,
        Type            => 'Local',
        Mode            => 'binmode',
        DisableWarnings => 1,
    );

    # check if cache exists
    return if !$Content;

    # Check if file has contents, due to a race condition the file could be empty, see bug#12881.
    return if !${$Content};

    # read data structure back from file dump, use block eval for safety reasons
    my $Storage = eval {
        $Kernel::OM->Get('Kernel::System::Storable')->Deserialize(
            Data => ${$Content}
        );
    };
    if ( ref $Storage ne 'HASH' || $Storage->{TTL} < time() ) {
        $Self->Delete(%Param);
        return;
    }

    return $Storage->{Value};
}

sub Delete {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Type Key)) {
        if ( !defined $Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    my ( $Filename, $CacheDirectory ) = $Self->_GetFilenameAndCacheDirectory(%Param);

    return $Kernel::OM->Get('Kernel::System::Main')->FileDelete(

      # Use Location rather than Filename and Directory to skip the (unneeded) filename clean-up for better performance.
        Location        => $CacheDirectory . '/' . $Filename,
        Type            => 'Local',
        DisableWarnings => 1,
    );
}

sub CleanUp {
    my ( $Self, %Param ) = @_;

    # get main object
    my $MainObject = $Kernel::OM->Get('Kernel::System::Main');

    my @TypeList = $MainObject->DirectoryRead(
        Directory => $Self->{CacheDirectory},
        Filter    => $Param{Type} || '*',
    );

    if ( $Param{KeepTypes} ) {
        my $KeepTypesRegex = join( '|', map {"\Q$_\E"} @{ $Param{KeepTypes} } );
        @TypeList = grep { $_ !~ m{/$KeepTypesRegex/?$}smx } @TypeList;
    }

    return 1 if !@TypeList;

    my $FileCallback = sub {

        my $CacheFile = $File::Find::name;

        # Remove directory if it is empty
        if ( -d $CacheFile ) {
            rmdir $CacheFile;
            return;
        }

        # For expired filed, check the content and TTL
        if ( $Param{Expired} ) {
            my $Content = $MainObject->FileRead(

      # Use Location rather than Filename and Directory to skip the (unneeded) filename clean-up for better performance.
                Location        => $CacheFile,
                Mode            => 'binmode',
                DisableWarnings => 1,
            );

            if ( ref $Content eq 'SCALAR' ) {
                my $Storage = eval {
                    $Kernel::OM->Get('Kernel::System::Storable')->Deserialize( Data => ${$Content} );
                };
                return if ( ref $Storage eq 'HASH' && $Storage->{TTL} > time() );
            }
        }

        # Delete all cache files; don't error out when the file doesn't
        # exist anymore, it was probably just another process deleting it.
        my $Success = unlink $CacheFile;
        if ( !$Success && $! != POSIX::ENOENT ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Can't remove file $CacheFile: $!",
            );
        }
    };

    # We use finddepth so that the most deeply nested files will be deleted first,
    #   and then the directories above are already empty and can just be removed.
    File::Find::finddepth(
        {
            wanted   => $FileCallback,
            no_chdir => 1,
        },
        @TypeList
    );

    return 1;
}

sub _GetFilenameAndCacheDirectory {
    my ( $Self, %Param ) = @_;

    for my $Needed (qw(Type Key)) {
        if ( !defined $Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    my $Filename = $Param{Key};
    $Kernel::OM->Get('Kernel::System::Encode')->EncodeOutput( \$Filename );
    $Filename = Digest::MD5::md5_hex($Filename);

    my $CacheDirectory = $Self->{CacheDirectory} . '/' . $Param{Type};

    for my $Level ( 1 .. $Self->{'Cache::SubdirLevels'} ) {
        $CacheDirectory .= '/' . substr( $Filename, $Level - 1, 1 );
    }

    return $Filename, $CacheDirectory;
}

1;
