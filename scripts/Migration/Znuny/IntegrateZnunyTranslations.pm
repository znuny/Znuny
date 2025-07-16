# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
## nofilter(TidyAll::Plugin::Znuny::Perl::Pod::NamePod)

package scripts::Migration::Znuny::IntegrateZnunyTranslations;    ## no critic

use strict;
use warnings;
use utf8;

use IO::Interactive qw(is_interactive);

use parent qw(scripts::Migration::Base);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Translation',
);

=head1 SYNOPSIS

Integrate Znuny translations.

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    $Self->_AddExistingCustomTranslationsToDB(%Param);
    $Self->_CleanUpExistingTranslationFiles(%Param);
    $Self->_Deployment(%Param);

    return 1;
}

sub _AddExistingCustomTranslationsToDB {
    my ( $Self, %Param ) = @_;

    my $ConfigObject      = $Kernel::OM->Get('Kernel::Config');
    my $TranslationObject = $Kernel::OM->Get('Kernel::System::Translation');
    my $MainObject        = $Kernel::OM->Get('Kernel::System::Main');
    my $LogObject         = $Kernel::OM->Get('Kernel::System::Log');

    my $Home = $ConfigObject->Get('Home');

    my @FilesInDirectory = $MainObject->DirectoryRead(
        Directory => $Home . "/Kernel/Language",
        Filter    => '*_Custom.pm',
    );

    FILE:
    for my $File (@FilesInDirectory) {

        # Skip the file if it ends with 'xx_Custom.pm'.
        next FILE if $File =~ m{xx_Custom.pm}xmsi;

        # Get the module name from the file path.
        my $Module = $File =~ s/^$Home\/(.*)\.pm$/$1/rg;
        $Module =~ s/\/\//\//g;
        $Module =~ s/\//::/g;

        # Get the language ID from the module name.
        my $LanguageID = $Module;
        $LanguageID =~ s/Kernel::Language::(.+)_Custom/$1/g;

        # load translation module
        if ( !$MainObject->Require($Module) ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Sorry, can't load $Module! Check the $File (perl -cw)!",
            );
            next FILE;
        }

        my $ModuleDataMethod = $Module->can('Data');
        if ( !$ModuleDataMethod ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Sorry, can't load $Module! Check if it provides Data method.",
            );
            next FILE;
        }

        # Run Method and get Translations via Data function
        $ModuleDataMethod->($Self);
        my $Translations = $Self->{Translation};
        delete $Self->{Translation};

        my @Data = $TranslationObject->DataListGet(
            LanguageID => $LanguageID,
            UserID     => 1,
        );

        TRANSLATION:
        for my $Source ( sort keys %{$Translations} ) {

            my $Destination = $Translations->{$Source};
            next TRANSLATION if $Destination eq '';

            my $Exists = grep { $_->{Source} eq $Source } @Data;
            next TRANSLATION if $Exists;

            my $CreatedID = $TranslationObject->DataAdd(
                LanguageID      => $LanguageID,
                Source          => $Source,
                Destination     => $Destination,
                ValidID         => 1,
                DeploymentState => 0,
                CreateBy        => 1,
                ChangeBy        => 1,
                UserID          => 1,
            );
        }

        # Rename the file to avoid re-importing
        my $NewFile = $File . '.bak';

        # Rename the file
        if ( rename( $File, $NewFile ) ) {
            print "File renamed successfully from $File to $NewFile\n";
        }
        else {
            warn "Could not rename file: $!";
        }

    }

    return 1;
}

sub _CleanUpExistingTranslationFiles {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    my $Home  = $ConfigObject->Get('Home');
    my @Files = glob("$Home/Kernel/Language/*_zzzZnunyTranslationsAuto.pm");

    for my $File (@Files) {
        if ( -e $File ) {
            unlink $File;
            print "        Deleted: $File\n";
        }
    }

    return 1;
}

sub _Deployment {
    my ( $Self, %Param ) = @_;

    my $TranslationObject = $Kernel::OM->Get('Kernel::System::Translation');

    my $Success = $TranslationObject->DataDeployment(
        UserID => 1,
    );

    if ( !$Success ) {
        print "        Failed to deploy translations.\n";
        return;
    }

    print "        Successfully deployed translations.\n";
    return 1;
}

1;
