# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::Web::UploadCache;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::Config',
);

=head1 NAME

Kernel::System::Web::UploadCache - an upload file system cache

=head1 DESCRIPTION

All upload cache functions.

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $WebUploadCacheObject = $Kernel::OM->Get('Kernel::System::Web::UploadCache');

The agent and customer interfaces set the owner of the current request via ObjectParamAdd(),
so that all upload cache entries are bound to and checked against the logged in user:

    $Kernel::OM->ObjectParamAdd(
        'Kernel::System::Web::UploadCache' => {
            UserID   => 123,                 # agent UserID or customer UserLogin
            UserType => 'User',              # 'User' or 'CustomerUser'
        },
    );

Without an owner (e.g. console commands, daemon) no ownership check is done.

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    $Self->{UserID}   = $Param{UserID};
    $Self->{UserType} = $Param{UserType};

    my $GenericModule = $Kernel::OM->Get('Kernel::Config')->Get('WebUploadCacheModule')
        || 'Kernel::System::Web::UploadCache::DB';

    # load generator auth module
    $Self->{Backend} = $Kernel::OM->Get($GenericModule);

    return $Self if $Self->{Backend};
    return;
}

=head2 FormIDCreate()

create a new Form ID

    my $FormID = $UploadCacheObject->FormIDCreate();

=cut

sub FormIDCreate {
    my ( $Self, %Param ) = @_;

    $Self->{LastFormID} = $Self->{Backend}->FormIDCreate(%Param);
    return $Self->{LastFormID};
}

=head2 FormIDRemove()

remove all data for a provided Form ID

    $UploadCacheObject->FormIDRemove( FormID => 123456 );

All methods working on a Form ID accept the optional parameters UserID and UserType.
They default to the owner given via ObjectParamAdd() (see new()).
Access is denied if the Form ID belongs to another owner.

    $UploadCacheObject->FormIDRemove(
        FormID   => 123456,
        UserID   => 123,             # optional
        UserType => 'User',          # optional, 'User' or 'CustomerUser'
    );

=cut

sub FormIDRemove {
    my ( $Self, %Param ) = @_;

    return $Self->{Backend}->FormIDRemove(
        $Self->_OwnerParamsGet(),
        %Param,
    );
}

=head2 FormIDAddFile()

add a file to a Form ID

    $UploadCacheObject->FormIDAddFile(
        FormID      => 12345,
        Filename    => 'somefile.html',
        Content     => $FileInString,
        ContentType => 'text/html',
        Disposition => 'inline', # optional
    );

ContentID is optional (automatically generated if not given on disposition = inline)

    $UploadCacheObject->FormIDAddFile(
        FormID      => 12345,
        Filename    => 'somefile.html',
        Content     => $FileInString,
        ContentID   => 'some_id@example.com',
        ContentType => 'text/html',
        Disposition => 'inline', # optional
    );

=cut

sub FormIDAddFile {
    my ( $Self, %Param ) = @_;

    return $Self->{Backend}->FormIDAddFile(
        $Self->_OwnerParamsGet(),
        %Param,
    );
}

=head2 FormIDRemoveFile()

removes a file from a form id

    $UploadCacheObject->FormIDRemoveFile(
        FormID => 12345,
        FileID => 1,
    );

=cut

sub FormIDRemoveFile {
    my ( $Self, %Param ) = @_;

    return $Self->{Backend}->FormIDRemoveFile(
        $Self->_OwnerParamsGet(),
        %Param,
    );
}

=head2 FormIDGetAllFilesData()

returns an array with a hash ref of all files for a Form ID

    my @Data = $UploadCacheObject->FormIDGetAllFilesData(
        FormID => 12345,
    );

    Return data of on hash is Content, ContentType, ContentID, Filename, Filesize, FileID;

=cut

sub FormIDGetAllFilesData {
    my ( $Self, %Param ) = @_;

    return @{
        $Self->{Backend}->FormIDGetAllFilesData(
            $Self->_OwnerParamsGet(),
            %Param,
        ) // []
    };
}

=head2 FormIDGetAllFilesMeta()

returns an array with a hash ref of all files for a Form ID

Note: returns no content, only meta data.

    my @Data = $UploadCacheObject->FormIDGetAllFilesMeta(
        FormID => 12345,
    );

    Return data of hash is ContentType, ContentID, Filename, Filesize, FileID;

=cut

sub FormIDGetAllFilesMeta {
    my ( $Self, %Param ) = @_;

    return @{
        $Self->{Backend}->FormIDGetAllFilesMeta(
            $Self->_OwnerParamsGet(),
            %Param,
        ) // []
    };
}

=head2 FormIDCleanUp()

Removed no longer needed temporary files.

Each file older than 1 day will be removed.

    $UploadCacheObject->FormIDCleanUp();

=cut

sub FormIDCleanUp {
    my ( $Self, %Param ) = @_;

    return $Self->{Backend}->FormIDCleanUp(%Param);
}

sub _OwnerParamsGet {
    my ( $Self, %Param ) = @_;

    return if !$Self->{UserID} || !$Self->{UserType};

    return (
        UserID   => $Self->{UserID},
        UserType => $Self->{UserType},
    );
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
