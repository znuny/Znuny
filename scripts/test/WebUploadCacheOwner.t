# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);

my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

my %Owners = (
    Agent => {
        UserID   => 1,
        UserType => 'User'
    },
    OtherAgent => {
        UserID   => 2,
        UserType => 'User'
    },
    CustomerUser => {
        UserID   => '1',
        UserType => 'CustomerUser'
    },
    NoOwner => {},
);

my %File = (
    Filename    => 'WebUploadCacheOwner.txt',
    Content     => 'Test',
    ContentType => 'text/plain',
    Disposition => 'attachment',
);

MODULE:
for my $Module (qw(DB FS)) {

    $ConfigObject->Set(
        Key   => 'WebUploadCacheModule',
        Value => "Kernel::System::Web::UploadCache::$Module",
    );
    $Kernel::OM->ObjectsDiscard( Objects => ["Kernel::System::Web::UploadCache::$Module"] );

    my %UploadCacheObjects;
    for my $Owner ( sort keys %Owners ) {
        $UploadCacheObjects{$Owner} = $Kernel::OM->Create(
            'Kernel::System::Web::UploadCache',
            ObjectParams => $Owners{$Owner},
        );
    }

    my $FormID = $UploadCacheObjects{Agent}->FormIDCreate();

    $Self->True(
        scalar $UploadCacheObjects{Agent}->FormIDAddFile(
            FormID => $FormID,
            %File,
        ),
        "#$Module - owner can add file",
    );

    my @Files = $UploadCacheObjects{Agent}->FormIDGetAllFilesMeta( FormID => $FormID );
    $Self->Is(
        scalar @Files,
        1,
        "#$Module - owner can read meta data",
    );

    @Files = $UploadCacheObjects{Agent}->FormIDGetAllFilesData( FormID => $FormID );
    $Self->Is(
        scalar @Files,
        1,
        "#$Module - owner can read files",
    );

    for my $Owner (qw(OtherAgent CustomerUser)) {
        my $UploadCacheObject = $UploadCacheObjects{$Owner};

        @Files = $UploadCacheObject->FormIDGetAllFilesMeta( FormID => $FormID );
        $Self->Is(
            scalar @Files,
            0,
            "#$Module - $Owner can't read meta data",
        );

        @Files = $UploadCacheObject->FormIDGetAllFilesData( FormID => $FormID );
        $Self->Is(
            scalar @Files,
            0,
            "#$Module - $Owner can't read files",
        );

        $Self->False(
            scalar $UploadCacheObject->FormIDAddFile(
                FormID => $FormID,
                %File,
                Filename => "$Owner.txt",
            ),
            "#$Module - $Owner can't add file",
        );

        $Self->False(
            scalar $UploadCacheObject->FormIDRemoveFile(
                FormID => $FormID,
                FileID => 1,
            ),
            "#$Module - $Owner can't remove file",
        );

        $Self->False(
            scalar $UploadCacheObject->FormIDRemove( FormID => $FormID ),
            "#$Module - $Owner can't remove Form ID",
        );
    }

    @Files = $UploadCacheObjects{Agent}->FormIDGetAllFilesMeta( FormID => $FormID );
    $Self->Is(
        scalar @Files,
        1,
        "#$Module - files of owner are unchanged",
    );

    @Files = $UploadCacheObjects{NoOwner}->FormIDGetAllFilesMeta( FormID => $FormID );
    $Self->Is(
        scalar @Files,
        1,
        "#$Module - access without owner (system) is allowed",
    );

    @Files = $UploadCacheObjects{Agent}->FormIDGetAllFilesMeta(
        FormID => $FormID,
        %{ $Owners{OtherAgent} },
    );
    $Self->Is(
        scalar @Files,
        0,
        "#$Module - explicitly given owner overrides the owner of the object",
    );

    $Self->False(
        scalar $UploadCacheObjects{Agent}->FormIDAddFile(
            FormID => $FormID,
            %File,
            UserType => 'Customer',
        ),
        "#$Module - invalid UserType is rejected",
    );

    if ( $Module eq 'FS' ) {
        $UploadCacheObjects{Agent}->FormIDAddFile(
            FormID => $FormID,
            %File,
            Filename => '.Owner',
        );

        @Files = $UploadCacheObjects{OtherAgent}->FormIDGetAllFilesMeta( FormID => $FormID );
        $Self->Is(
            scalar @Files,
            0,
            "#$Module - upload named .Owner doesn't overwrite the owner file",
        );

        $UploadCacheObjects{Agent}->FormIDRemoveFile(
            FormID => $FormID,
            FileID => 2,
        );
    }

    # Form ID without owner, e.g. created before owners were stored
    my $LegacyFormID = $UploadCacheObjects{NoOwner}->FormIDCreate();
    $UploadCacheObjects{NoOwner}->FormIDAddFile(
        FormID => $LegacyFormID,
        %File,
    );

    @Files = $UploadCacheObjects{OtherAgent}->FormIDGetAllFilesMeta( FormID => $LegacyFormID );
    $Self->Is(
        scalar @Files,
        1,
        "#$Module - Form ID without owner is accessible",
    );

    $Self->True(
        scalar $UploadCacheObjects{NoOwner}->FormIDRemove( FormID => $LegacyFormID ),
        "#$Module - Form ID without owner can be removed",
    );

    $Self->True(
        scalar $UploadCacheObjects{Agent}->FormIDRemoveFile(
            FormID => $FormID,
            FileID => 1,
        ),
        "#$Module - owner can remove file",
    );

    $Self->True(
        scalar $UploadCacheObjects{Agent}->FormIDRemove( FormID => $FormID ),
        "#$Module - owner can remove Form ID",
    );

    next MODULE if $Module ne 'FS';

    my $TempDir = $ConfigObject->Get('TempDir') . '/upload_cache';

    $Self->False(
        -d "$TempDir/$FormID" ? 1 : 0,
        "#$Module - FormIDRemove() removes directory including owner file",
    );

    # Form ID older than one day
    my $OldFormID = ( time() - 2 * 86400 ) . '.' . $HelperObject->GetRandomNumber() . '.1';
    $UploadCacheObjects{Agent}->FormIDAddFile(
        FormID => $OldFormID,
        %File,
    );

    $Self->True(
        -e "$TempDir/$OldFormID/.Owner" ? 1 : 0,
        "#$Module - owner file is written",
    );

    $UploadCacheObjects{Agent}->FormIDCleanUp();

    $Self->False(
        -d "$TempDir/$OldFormID" ? 1 : 0,
        "#$Module - FormIDCleanUp() removes directory including owner file",
    );
}

1;
