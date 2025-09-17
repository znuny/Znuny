# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
## nofilter(TidyAll::Plugin::Znuny::Common::CustomizationMarkers)
## nofilter(TidyAll::Plugin::Znuny::Perl::LayoutObject)

package Kernel::System::Translation;

use strict;
use warnings;
use utf8;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::Output::HTML::Layout',
    'Kernel::System::Log',
    'Kernel::System::Main',
);

use parent qw(Kernel::System::DBCRUD);

=head1 NAME

Kernel::System::Translation - Translation lib

=head1 SYNOPSIS

All Translation functions

=head1 PUBLIC INTERFACE

=head2 new()

create an object

    my $TranslationObject = $Kernel::OM->Get('Kernel::System::Translation');

=cut

=head2 DataDeployment()

Deploys all translations.

    my $Success = $TranslationObject->DataDeployment(
        UserID => 1,
    );

Returns:

    my $Success = 1;

=cut

sub DataDeployment {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $MainObject   = $Kernel::OM->Get('Kernel::System::Main');
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');

    NEEDED:
    for my $Needed (qw(UserID)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my $Home = $ConfigObject->Get('Home');

    # delete all translation files
    $Self->TranslationFilesDelete();

    my %Data;
    my @Data = $Self->DataListGet(
        UserID  => 1,
        ValidID => 1,
    );

    my @Translations;

    for my $Translation (@Data) {
        my $LanguageID  = $Translation->{LanguageID};
        my $Source      = $Translation->{Source};
        my $Destination = $Translation->{Destination};

        $Data{$LanguageID}->{$Source} = $Destination;

        # update this translationids later
        push @Translations, {
            ID         => $Translation->{ID},
            ChangeTime => $Translation->{ChangeTime},
        };
    }

    return 1 if !%Data;

    # Keep comment lines like Copyright in files also in the generated output.
    local $ENV{TEMPLATE_KEEP_COMMENTS} = 1;

    for my $LanguageID ( sort keys %Data ) {

        my $Translations;
        my $TranslationFileName = $LanguageID . "_zzzTranslationAuto";
        my $FileName            = $Home . "/Kernel/Language/$TranslationFileName.pm";

        for my $Source ( sort keys %{ $Data{$LanguageID} } ) {

            my $Destination = $Data{$LanguageID}->{$Source};

            $LayoutObject->Block(
                Name => 'TranslationRow',
                Data => {
                    Source      => $Source,
                    Destination => $Destination,
                },
            );
        }

        my $Content = $LayoutObject->Output(
            TemplateFile => 'Translation/File',
            Data         => {
                LanguageID => $LanguageID,
            },
        );

        $MainObject->FileWrite(
            Location => $FileName,
            Mode     => 'utf8',
            Content  => \$Content,
        ) || die "Could not write $FileName";
    }

    # Update DeploymentState
    for my $Translation (@Translations) {
        $Self->DataUpdate(
            ID              => $Translation->{ID},
            UserID          => $Param{UserID},
            DeploymentState => '1',
            ChangeTime      => $Translation->{ChangeTime},
        );
    }

    local $ENV{TEMPLATE_KEEP_COMMENTS} = 0;

    return 1;
}

=head2 TranslationFilesDelete()

Deletes all translation files

    my $Success = $TranslationObject->TranslationFilesDelete();

Returns:

    my $Success = 1;

=cut

sub TranslationFilesDelete {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $MainObject   = $Kernel::OM->Get('Kernel::System::Main');

    my $Home = $ConfigObject->Get('Home');

    my @TranslationFilesInDirectory = $MainObject->DirectoryRead(
        Directory => $Home . '/Kernel/Language/',
        Filter    => '*TranslationAuto.pm',
    );

    for my $TranslationFile (@TranslationFilesInDirectory) {
        my $Success = $MainObject->FileDelete(
            Location => $TranslationFile
        );
    }

    return 1;
}

=head2 DataExport()

exports data.

    my $Export = $TranslationObject->DataExport(
        Format => 'yml',
        Cache  => 0,
    );

Returns:

    my $Export = 'STRING';

=cut

=head2 DataImport()

imports data.

    my $Success = $TranslationObject->DataImport(
        Content => $ContentString,
        Format => 'yml',             # optional - default
    );

Returns:

    my $Success = 1;

=cut

=head2 DataAdd()

creates data attributes

    my $CreatedID = $TranslationObject->DataAdd(
        ID              => '...',
        LanguageID      => '...',
        Source          => '...',
        Destination     => '...',
        ValidID         => '...',
        CreateTime      => '...',
        CreateBy        => '...',
        ChangeTime      => '...',
        ChangeBy        => '...',
        DeploymentState => '...',
        UserID          => 1,
    );

Returns:

    my $CreatedID = 1;

=cut

=head2 DataGet()

get data attributes

    my %Data = $TranslationObject->DataGet(
        ID              => '...', # optional
        LanguageID      => '...', # optional
        Source          => '...', # optional
        Destination     => '...', # optional
        ValidID         => '...', # optional
        CreateTime      => '...', # optional
        CreateBy        => '...', # optional
        ChangeTime      => '...', # optional
        ChangeBy        => '...', # optional
        DeploymentState => '...', # optional
        UserID          => 1,
    );

Returns:

    my %Data = (
        ID              => '...',
        LanguageID      => '...',
        Source          => '...',
        Destination     => '...',
        ValidID         => '...',
        CreateTime      => '...',
        CreateBy        => '...',
        ChangeTime      => '...',
        ChangeBy        => '...',
        DeploymentState => '...',
    );

=cut

=head2 DataListGet()

get list data with attributes

    my @Data = $TranslationObject->DataListGet(
        ID              => '...', # optional
        LanguageID      => '...', # optional
        Source          => '...', # optional
        Destination     => '...', # optional
        ValidID         => '...', # optional
        CreateTime      => '...', # optional
        CreateBy        => '...', # optional
        ChangeTime      => '...', # optional
        ChangeBy        => '...', # optional
        DeploymentState => '...', # optional
        UserID          => 1,
    );

Returns:

    my @Data = (
        {
            ID              => '...',
            LanguageID      => '...',
            Source          => '...',
            Destination     => '...',
            ValidID         => '...',
            CreateTime      => '...',
            CreateBy        => '...',
            ChangeTime      => '...',
            ChangeBy        => '...',
            DeploymentState => '...',
        },
        ...
    );

=cut

=head2 DataUpdate()

update data attributes

    my $Success = $TranslationObject->DataUpdate(
        ID     => 1234,
        UserID => 1,
        # all other attributes are optional
    );

Returns:

    my $Success = 1; # 1|0

=cut

=head2 DataNameExists()

checks if a entry with the given name exists

    my $NameExists = $TranslationObject->DataNameExists(
        ID     => 1234,
        Name   => '...',
        UserID => 1,
    );

Returns:

    my $NameExists = 1; # 1|0

=cut

=head2 DataDelete()

deletes data attributes - at least one is required.

    my $Success = $TranslationObject->DataDelete(
        ID              => '...', # optional
        LanguageID      => '...', # optional
        Source          => '...', # optional
        Destination     => '...', # optional
        ValidID         => '...', # optional
        CreateTime      => '...', # optional
        CreateBy        => '...', # optional
        ChangeTime      => '...', # optional
        ChangeBy        => '...', # optional
        DeploymentState => '...', # optional
        UserID          => 1,
    );

Returns:

    my $Success = 1; # 1|0

=cut

=head2 DataSearch()

search for value in defined attributes

    my %Data = $TranslationObject->DataSearch(
        Search          => 'test*test',
        ID              => '...', # optional
        LanguageID      => '...', # optional
        Source          => '...', # optional
        Destination     => '...', # optional
        ValidID         => '...', # optional
        CreateTime      => '...', # optional
        CreateBy        => '...', # optional
        ChangeTime      => '...', # optional
        ChangeBy        => '...', # optional
        DeploymentState => '...', # optional
        UserID          => 1,
    );

Returns:

    my %Data = (
        '1' => {
            'ID'              => '...',
            'LanguageID'      => '...',
            'Source'          => '...',
            'Destination'     => '...',
            'ValidID'         => '...',
            'CreateTime'      => '...',
            'CreateBy'        => '...',
            'ChangeTime'      => '...',
            'ChangeBy'        => '...',
            'DeploymentState' => '...',
        },
        ...
    );

=cut

=head2 InitConfig()

init config for object

    my $Success = $TranslationObject->InitConfig();

Returns:

    my $Success = 1;

=cut

sub InitConfig {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    $Self->{AutoCreateMissingUUIDDatabaseTableColumns} = 1;

    $Self->{Columns} = {
        ID => {
            Column       => 'id',
            SearchTarget => 0,
        },
        LanguageID => {
            Column       => 'language_id',
            SearchTarget => 1,
            Export       => 1,
            ImportID     => 1,
        },
        Source => {
            Column       => 'source_string',
            SearchTarget => 1,
            Export       => 1,
            ImportID     => 1,
        },
        Destination => {
            Column       => 'destination_string',
            SearchTarget => 0,
            Export       => 1,
        },
        ValidID => {
            Column       => 'valid_id',
            SearchTarget => 0,
            Export       => 1,
        },
        CreateTime => {
            Column       => 'create_time',
            SearchTarget => 0,
            TimeStampAdd => 1,
        },
        CreateBy => {
            Column       => 'create_by',
            SearchTarget => 0,
        },
        ChangeTime => {
            Column          => 'change_time',
            SearchTarget    => 0,
            TimeStampAdd    => 1,
            TimeStampUpdate => 1,
        },
        ChangeBy => {
            Column       => 'change_by',
            SearchTarget => 0,
        },
        DeploymentState => {
            Column       => 'deployment_state',
            SearchTarget => 0,
        },
    };

    # base table configuration
    $Self->{Name}           = 'Translation';
    $Self->{Identifier}     = 'ID';
    $Self->{DatabaseTable}  = 'translation';
    $Self->{UserIDCheck}    = 1;
    $Self->{DefaultSortBy}  = 'ID';
    $Self->{DefaultOrderBy} = 'ASC';
    $Self->{CacheType}      = 'Translation';
    $Self->{CacheTTL}       = $ConfigObject->Get( 'DBCRUD::' . $Self->{Name} . '::CacheTTL' ) || 60 * 60 * 8;

    # base function activation
    $Self->{FunctionDataAdd}        = 1;
    $Self->{FunctionDataUpdate}     = 1;
    $Self->{FunctionDataGet}        = 1;
    $Self->{FunctionDataListGet}    = 1;
    $Self->{FunctionDataSearch}     = 1;
    $Self->{FunctionDataNameExists} = 0;
    $Self->{FunctionDataDelete}     = 1;
    $Self->{FunctionDataExport}     = 1;
    $Self->{FunctionDataImport}     = 1;

    return 1;
}

1;
