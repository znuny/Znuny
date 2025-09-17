# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::ProcessPreferences::Generic;

use strict;
use warnings;
use utf8;

use Kernel::Language qw(Translatable);
use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::System::ProcessManagement::Process',
    'Kernel::System::VirtualFS',
    'Kernel::System::Web::Request',
    'Kernel::System::Web::UploadCache',
);

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub Param {
    my ( $Self, %Param ) = @_;

    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');

    my $GetParam = $ParamObject->GetParam( Param => $Self->{ConfigItem}->{PrefKey} );

    if ( !defined($GetParam) ) {
        $GetParam = defined( $Param{ProcessData}->{ $Self->{ConfigItem}->{PrefKey} } )
            ? $Param{ProcessData}->{ $Self->{ConfigItem}->{PrefKey} }
            : $Self->{ConfigItem}->{DataSelected};
    }

    my @Params = (
        {
            %Param,
            %{ $Self->{ConfigItem} },
            Description => $Self->{ConfigItem}->{Desc} || $Self->{ConfigItem}->{Description},
            Name        => $Self->{ConfigItem}->{PrefKey},
            Block       => $Self->{ConfigItem}->{Block},
            Value       => $GetParam,
        },
    );

    return @Params;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $ProcessObject     = $Kernel::OM->Get('Kernel::System::ProcessManagement::Process');
    my $ParamObject       = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $UploadCacheObject = $Kernel::OM->Get('Kernel::System::Web::UploadCache');
    my $VirtualFSObject   = $Kernel::OM->Get('Kernel::System::VirtualFS');

    my %Params = $ParamObject->GetParams();

    KEY:
    for my $Key ( sort keys %{ $Param{GetParam} } ) {

        # delete preference
        $ProcessObject->ProcessPreferencesDelete(
            ProcessEntityID => $Param{ProcessData}->{EntityID},
            Key             => $Key,
        );

        # File upload
        if ( $Param{PreferenceConfig}->{Block} eq 'File' ) {

            # For file uploads, we always get an defined empty array ['']
            # because the data is retrieved via the UploadCacheObject and not directly via the form element.
            $Param{GetParam}->{$Key} = [];

            # To store the file in the VirtualFS, we need to create a unique filename
            # This is the prefix for the filename, to search and delete existing files
            my $PrefixFilename = 'VirtualFS::' . $Param{ProcessData}->{EntityID} . '::' . $Key . '::';

            my @ExistingFiles = $VirtualFSObject->Find(
                Filename => $PrefixFilename . '*',
            );

            # We need to delete the existing files, because the user can upload a new file
            # and we don't want to have old files in the VirtualFS.
            # It could be that a file with the same name has a completely different content.
            for my $File (@ExistingFiles) {
                $VirtualFSObject->Delete(
                    Filename => $File,
                );
            }

            # Get all files from the UploadCacheObject via the KEY::FormID
            my $FormID = $Params{ $Key . '::FormID' };
            next KEY if !$FormID;

            my @Files = $UploadCacheObject->FormIDGetAllFilesData(
                FormID => $FormID,
            );
            next KEY if !@Files;

            for my $File (@Files) {

                # To store the file in the VirtualFS, we need to create a unique filename
                # $Filename = StorageID::ProcessEntityID::PrefKey::Filename;
                my $Filename = $PrefixFilename . $File->{Filename};

                my $Success = $VirtualFSObject->Write(
                    Content     => \$File->{Content},
                    Filename    => $Filename,
                    Mode        => 'binary',
                    Preferences => {
                        ContentType => $File->{ContentType},
                        Filesize    => $File->{Filesize},
                        Filename    => $File->{Filename},
                    },
                );

                # Store new filename in GetParam to set the preference
                push @{ $Param{GetParam}->{$Key} }, $Filename;
            }
        }

        if ( IsArrayRefWithData( $Param{GetParam}->{$Key} ) ) {
            for my $Value ( @{ $Param{GetParam}->{$Key} } ) {

                # Set preference in the database
                $ProcessObject->ProcessPreferencesSet(
                    ProcessEntityID => $Param{ProcessData}->{EntityID},
                    Key             => $Key,
                    Value           => $Value,
                );
            }
        }

    }

    $Self->{Message} = Translatable('Preferences updated successfully!');

    return 1;
}

sub Error {
    my ( $Self, %Param ) = @_;

    return $Self->{Error} || '';
}

sub Message {
    my ( $Self, %Param ) = @_;

    return $Self->{Message} || '';
}

1;
