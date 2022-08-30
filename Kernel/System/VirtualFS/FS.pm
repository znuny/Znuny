# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::VirtualFS::FS;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Log',
    'Kernel::System::Main',
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # get data dir
    $Self->{DataDir}    = $Kernel::OM->Get('Kernel::Config')->Get('Home') . '/var/virtualfs';
    $Self->{Permission} = '660';

    # create data dir
    if ( !-d $Self->{DataDir} ) {
        mkdir $Self->{DataDir} || die $!;
    }

    # check write permissions
    if ( !-w $Self->{DataDir} ) {

        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'notice',
            Message  => "Can't write $Self->{DataDir}! try: \$OTRS_HOME/bin/otrs.SetPermissions.pl!",
        );
        die "Can't write $Self->{DataDir}! try: \$OTRS_HOME/bin/otrs.SetPermissions.pl!";
    }

    # config (not used right now)
    $Self->{Compress} = 0;
    $Self->{Crypt}    = 0;

    return $Self;
}

sub Read {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(BackendKey Mode)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    my $Attributes = $Self->_BackendKeyParse(%Param);

    my $Content = $Kernel::OM->Get('Kernel::System::Main')->FileRead(
        Directory => $Self->{DataDir} . $Attributes->{DataDir},
        Filename  => $Attributes->{Filename},
        Mode      => $Param{Mode},
    );

    # uncompress (in case)
    if ( $Attributes->{Compress} ) {

        # $Content = ...
    }

    # decrypt (in case)
    if ( $Attributes->{Crypt} ) {

        # $Content = ...
    }

    return if !$Content;
    return $Content;
}

sub Write {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Content Filename Mode)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    # compress (in case)
    if ( $Self->{Compress} ) {

        # $Param{Content} = ...
    }

    # crypt (in case)
    if ( $Self->{Crypt} ) {

        # $Param{Content} = ...
    }

    # get main object
    my $MainObject = $Kernel::OM->Get('Kernel::System::Main');

    my $MD5 = $MainObject->FilenameCleanUp(
        Filename => $Param{Filename},
        Type     => 'MD5',
    );

    my $DataDir = '';
    my @Dirs    = $Self->_SplitDir( Filename => $MD5 );

    DIRECTORY:
    for my $Dir (@Dirs) {

        $DataDir .= '/' . $Dir;

        next DIRECTORY if -e $Self->{DataDir} . $DataDir;
        next DIRECTORY if mkdir $Self->{DataDir} . $DataDir;

        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Can't create $Self->{DataDir}$DataDir: $!",
        );

        return;
    }

    # write article to fs
    my $Filename = $MainObject->FileWrite(
        Directory  => $Self->{DataDir} . $DataDir,
        Filename   => $MD5,
        Mode       => $Param{Mode},
        Content    => $Param{Content},
        Permission => $Self->{Permission},
    );

    return if !$Filename;

    my $BackendKey = $Self->_BackendKeyGenerate(
        Filename => $Filename,
        DataDir  => $DataDir,
        Compress => $Self->{Compress},
        Crypt    => $Self->{Crypt},
        Mode     => $Param{Mode},
    );

    return $BackendKey;
}

sub Delete {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{BackendKey} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Need BackendKey!",
        );
        return;
    }

    my $Attributes = $Self->_BackendKeyParse(%Param);

    return $Kernel::OM->Get('Kernel::System::Main')->FileDelete(
        Directory => $Self->{DataDir} . $Attributes->{DataDir},
        Filename  => $Attributes->{Filename},
    );
}

sub _BackendKeyGenerate {
    my ( $Self, %Param ) = @_;

    my $BackendKey = '';
    for my $Key ( sort keys %Param ) {
        $BackendKey .= "$Key=$Param{$Key};";
    }

    return $BackendKey;
}

sub _BackendKeyParse {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{BackendKey} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Need BackendKey!",
        );
        return;
    }

    my @Pairs = split /;/, $Param{BackendKey};

    my %Attributes;
    for my $Pair (@Pairs) {
        my ( $Key, $Value ) = split /=/, $Pair;
        $Attributes{$Key} = $Value;
    }

    return \%Attributes;
}

sub _SplitDir {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{Filename} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Need Filename!",
        );
        return;
    }

    my @Dir;
    $Dir[0] = substr $Param{Filename}, 0, 2;
    $Dir[1] = substr $Param{Filename}, 2, 2;

    return ( $Dir[0], $Dir[1] );
}

1;
