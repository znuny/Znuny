# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
package Kernel::Modules::AdminTranslation;

use strict;
use warnings;
use utf8;

use Kernel::Language qw(Translatable);
use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::Output::HTML::Layout',
    'Kernel::System::Cache',
    'Kernel::System::Group',
    'Kernel::System::Log',
    'Kernel::System::Time',
    'Kernel::System::Translation',
    'Kernel::System::User',
    'Kernel::System::Valid',
    'Kernel::System::Web::Request',
);

=head1 NAME

Kernel::Modules::AdminTranslation - Translation Admin Interface

=head1 SYNOPSIS

Create and maintain Translation Entries

=head1 PUBLIC INTERFACE

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {%Param};
    bless( $Self, $Type );

    $Self->{CacheType} = 'TranslationDeployment';
    $Self->{CacheTTL}  = 60 * 60 * 24 * 356;

    $Self->{MandatoryParams} = {
        ValidID     => 1,
        LanguageID  => 1,
        Source      => 1,
        Destination => 1,
    };

    return $Self;
}

=head2 Run()

Preform requests by Admin Users to create or update DatababaseBackend records

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');

    my %GetParams = $ParamObject->GetParams();

    # merge $Self into Param
    # to access $Self vars
    # in the templates
    %Param = (
        %Param,
        %GetParams,
    );

    my %NotifiyParam = (
        Priority => $Param{NotificationPriority} || 'Info',
        Info     => Translatable( $Param{Notification} ),
    );

    if ( !IsStringWithData( $Self->{Subaction} ) ) {
        return $Self->_Overview(
            OutputData   => \%Param,
            NotifiyParam => \%NotifiyParam
        );
    }

    my $ID = $ParamObject->GetParam( Param => 'ID' );

    if ( $Self->{Subaction} eq 'Deployment' ) {
        return $Self->_Deployment();
    }
    elsif ( $Self->{Subaction} =~ m{(Copy)}xms ) {
        return $Self->_Copy(
            Action => $1,
            ID     => $ID,
        );
    }
    elsif ( $Self->{Subaction} =~ m{Delete}xms ) {
        return $Self->_Delete(
            Action => $1,
            ID     => $ID,
        );
    }
    elsif ( $Self->{Subaction} =~ m{(Import)$} ) {
        return $Self->_Import(
            %Param,
            Action          => $1,
            DeploymentState => 0,
            ValidID         => 1,
        );
    }
    elsif ( $Self->{Subaction} =~ m{(Export)$} ) {
        return $Self->_Export(
            %Param,
            Action          => $1,
            DeploymentState => 0,
            ValidID         => 1,
        );
    }

    # AddAction / UpdateAction
    elsif ( $Self->{Subaction} =~ m{\A(\w+)Action\z} ) {
        return $Self->_GenericAction(
            Action     => $1,
            ID         => $ID,
            OutputData => \%Param,
        );
    }
    else {
        return $Self->_GenericForm(
            ID         => $ID,
            OutputData => \%Param,
        );
    }
}

=head2 _Overview()

Rendering the _OverviewActionList and _OverviewRender

    my $Success = $Self->_Overview();

=cut

sub _Overview {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    $Self->_OverviewActionList(%Param);
    $Self->_OverviewRender(%Param);

    my $Output = $LayoutObject->Header();
    $Output .= $LayoutObject->NavigationBar();

    if ( IsHashRefWithData( $Param{NotifiyParam} ) ) {
        $Output .= $LayoutObject->Notify(
            %{ $Param{NotifiyParam} },
        );
    }

    $Output .= $LayoutObject->Output(
        TemplateFile => 'AdminTranslation',
        Data         => $Param{OutputData},
    );
    $Output .= $LayoutObject->Footer();
    return $Output;
}

=head2 _OverviewActionList()

Displays the possible actions in the Overview view.

    my $Success = $Self->_OverviewActionList();

=cut

sub _OverviewActionList {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    $Self->_ActionListRender(
        ActionItems => [
            {
                LinkHref  => $LayoutObject->{Baselink} . 'Action=' . $LayoutObject->{Action} . ';Subaction=Add',
                LinkClass => 'CallForAction Fullsize Center',
                LinkText  => "Add Translation",
                IconClass => 'fa fa-plus-square',
            },
            {
                LinkHref => $LayoutObject->{Baselink}
                    . 'Action='
                    . $LayoutObject->{Action}
                    . ';Subaction=Deployment;ID=1',
                LinkClass => 'CallForAction Fullsize Center',
                LinkText  => "Deployment",
                IconClass => 'fa fa-rocket',
            }
        ],
    );

    $LayoutObject->Block(
        Name => 'Filter',
        Data => {
            %Param,
            Label => 'Filter',
        },
    );

    my @Inputs = (
        {
            FilterInput   => 'Language',
            FilterElement => 'Translations',
            Label         => 'Language',
            ColumnNumber  => 0,
        },
        {
            FilterInput   => 'Source',
            FilterElement => 'Translations',
            Label         => 'Source',
            ColumnNumber  => 1,
        },
    );

    for my $Input (@Inputs) {

        $LayoutObject->Block(
            Name => 'FilterInput',
            Data => \%{$Input},
        );

        my $JSBlock = 'Core.UI.Table.InitTableFilter($(\'#'
            . $Input->{FilterInput}
            . '\'), $(\'#'
            . $Input->{FilterElement} . '\'),'
            . $Input->{ColumnNumber} . ');';

        my $Key = 'AdminTranslation'
            . $Input->{FilterInput}
            . $Input->{FilterElement}
            . $Input->{ColumnNumber};

        $LayoutObject->AddJSOnDocumentCompleteIfNotExists(
            Key  => $Key,
            Code => $JSBlock,
        );
    }

    $LayoutObject->Block(
        Name => 'ImportExport',
        Data => {
            %Param,
            Label => 'Import / Export',
            Explanation =>
                'Here you can upload a configuration file to import %s to your system. The file needs to be in .yml | .csv | .xlsx format.',
            Action => $Param{Action} || $LayoutObject->{Action},
        }
    );

    return 1;
}

=head2 _OverviewRender()

Renders the blocks for existing Database records in the Overview list view

    my $Success = $Self->_OverviewRender();

=cut

sub _OverviewRender {
    my ( $Self, %Param ) = @_;

    my $LayoutObject      = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $TranslationObject = $Kernel::OM->Get('Kernel::System::Translation');
    my $ValidObject       = $Kernel::OM->Get('Kernel::System::Valid');
    my $ConfigObject      = $Kernel::OM->Get('Kernel::Config');
    my $UserObject        = $Kernel::OM->Get('Kernel::System::User');

    my $YesNoOptions       = $ConfigObject->Get('YesNoOptions');
    my %DeploymentStateCSS = (
        0 => 'Error',
        1 => 'Success',
    );

    $LayoutObject->Block(
        Name => 'Overview',
        Data => \%Param,
    );

    $LayoutObject->Block(
        Name => 'DeleteHeader',
    );

    my @List = $TranslationObject->DataListGet(
        Valid  => 0,
        UserID => $Self->{UserID},
    );

    my %UserList = $UserObject->UserList(
        Type  => 'Long',
        Valid => 0,
    );

    # show message if no elements are present
    # and exit early
    if ( !@List ) {
        $LayoutObject->Block(
            Name => 'NoDataFoundMsg',
            Data => {},
        );

        return 1;
    }

    # get valid list
    my %ValidList = $ValidObject->ValidList();

    ITEM:
    for my $Record (@List) {

        my %Data = (
            Valid => $ValidList{ $Record->{ValidID} },
            %{$Record},
            ChangeBy           => $UserList{ $Record->{ChangeBy} },
            DeploymentState    => $YesNoOptions->{ $Record->{DeploymentState} },
            DeploymentStateCSS => $DeploymentStateCSS{ $Record->{DeploymentState} },
        );

        $LayoutObject->Block(
            Name => 'OverviewRow',
            Data => \%Data,
        );

        if ( $Record->{ValidID} ne 1 ) {
            $LayoutObject->Block(
                Name => 'DeleteRow',
                Data => \%Data,
            );
        }
    }

    $Param{BackendData}->{DeploymentState} = $YesNoOptions->{
        $Param{BackendData}->{DeploymentState} // 0
    };

    return 1;
}

=head2 _Form()

Fetches data of the currently requested record if Parameter ID is given,
else displays the Add page.

Calls _FormActionList and _FormRender for record rendering or displaying the Add form.

    my $Success = $Self->_Form(
        ID => 1234,                 # optional, ID of the currently edited record, empty on Add
    );

=cut

sub _Form {
    my ( $Self, %Param ) = @_;

    my $LayoutObject      = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $TranslationObject = $Kernel::OM->Get('Kernel::System::Translation');
    my $ConfigObject      = $Kernel::OM->Get('Kernel::Config');
    my $UserObject        = $Kernel::OM->Get('Kernel::System::User');

    $Param{BackendData} ||= {};

    if ( $Param{ID} ) {
        my %BackendData = $TranslationObject->DataGet(
            ID     => $Param{ID},
            UserID => $Self->{UserID},
        );
        if ( !%BackendData ) {
            return $LayoutObject->ErrorScreen(
                Message => "Could not find Translation for ID '$Param{ID}'!",
            );
        }

        $Param{BackendData} = \%BackendData;
    }

    $Self->_FormActionList(%Param);
    $Self->_FormRender(%Param);

    my $UserID = $LayoutObject->{UserID};

    my %Preferences = $UserObject->GetPreferences(
        UserID => $UserID,
    );

    # get names of languages in english
    my %DefaultUsedLanguages = %{ $ConfigObject->Get('DefaultUsedLanguages') || {} };
    my $DefaultLanguage      = $ConfigObject->Get('DefaultLanguage');

    $Param{LanguageOption} = $LayoutObject->BuildSelection(
        Data       => \%DefaultUsedLanguages,
        Name       => 'LanguageID',
        SelectedID => $Param{BackendData}->{LanguageID} || $Preferences{UserLanguage} || $DefaultLanguage || 'en',
        Class      => 'Validate_Required Modernize ' . ( $Param{Errors}->{LanguageIDInvalid} || '' ),
    );

    my $YesNoOptionsYesNoOptions = $ConfigObject->Get('YesNoOptionsYesNoOptions');

    $Param{BackendData}->{DeploymentState} = $YesNoOptionsYesNoOptions->{
        $Param{BackendData}->{DeploymentState} // 0
    };

    $LayoutObject->Block(
        Name => 'Language',
        Data => {
            %Param,
            %{ $Param{Errors} },
        },
    );

    return %Param;
}

=head2 _FormActionList()

Displays the possible actions on the left side of Record adding/Record updating form.

    my $Success = $Self->_FormActionList();

=cut

sub _FormActionList {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    $Self->_ActionListRender(
        ActionItems => [
            {
                LinkHref  => $LayoutObject->{Baselink} . 'Action=' . $LayoutObject->{Action},
                LinkClass => 'CallForAction Fullsize Center',
                LinkText  => 'Go to overview',
                IconClass => 'fa fa-caret-left',
            }
        ],
    );

    return 1;
}

=head2 _FormRender()

Renders the Add or Update form for the record.

The following fields are always displayed:
    Name (has to be unique)
    Valid

    my $Success = $Self->_FormRender(
        BackendData => {} # required, containing the record on Update, empty hashref on Add.
    );

=cut

sub _FormRender {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ValidObject  = $Kernel::OM->Get('Kernel::System::Valid');
    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');

    NEEDED:
    for my $Needed (qw(BackendData)) {

        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }
    my %BackendData = %{ $Param{BackendData} };

    # get valid list
    my %ValidList        = $ValidObject->ValidList();
    my %ValidListReverse = reverse %ValidList;

    $Param{ValidOption} = $LayoutObject->BuildSelection(
        Data       => \%ValidList,
        Name       => 'ValidID',
        SelectedID => $BackendData{ValidID} || $ValidListReverse{valid},
        Class      => 'Validate_Required Modernize ' . ( $Param{Errors}->{ValidIDInvalid} || '' ),
    );

    $LayoutObject->Block(
        Name => 'Form',
        Data => {
            %Param,
            %BackendData,
            %{ $Param{Errors} },
        },
    );

    $LayoutObject->Block(
        Name => 'Header' . $Param{Action},
        Data => $Param{OutputData},
    );

    # show appropriate messages for ServerError
    if ( $Param{Errors}->{NameExists} ) {
        $LayoutObject->Block(
            Name => 'ExistNameServerError',
        );
    }
    else {
        $LayoutObject->Block(
            Name => 'NameServerError',
        );
    }

    for my $Error ( sort keys %{ $Param{Errors} } ) {
        $LayoutObject->Block(
            Name => $Param{Errors}->{$Error},
        );
    }

    return 1;
}

=head2 _GenericForm()

Renders the html page and form for add or update views

    my $Output = $Self->_GenericForm();

=cut

sub _GenericForm {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    my $Output = $LayoutObject->Header();
    $Output .= $LayoutObject->NavigationBar();
    my %Data = $Self->_Form(
        Action     => $Self->{Subaction},
        ID         => $Param{ID},
        OutputData => $Param{OutputData},
    );

    $Output .= $LayoutObject->Output(
        TemplateFile => 'AdminTranslation',
        Data         => {
            %Data,
            %{ $Param{OutputData} },
        },
    );

    $Output .= $LayoutObject->Footer();
    return $Output;
}

=head2 _GenericAction()

Handles the add or update request to store or change records

Returns the output of _Overview in case of success.

Displays the add or update form in case of error.

    my $Output = $Self->_GenericAction();

=cut

sub _GenericAction {
    my ( $Self, %Param ) = @_;

    my $LayoutObject      = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $TranslationObject = $Kernel::OM->Get('Kernel::System::Translation');

    # challenge token check for write action
    $LayoutObject->ChallengeTokenCheck();

    my %ValidationResult;
    my %Errors;
    my %GetParam;

    if ( $Param{ID} ) {
        $GetParam{ID} = $Param{ID};
    }
    if ( IsHashRefWithData( $Param{GetParam} ) ) {
        %GetParam = (
            %GetParam,
            %{ $Param{GetParam} },
        );
    }

    $Self->_Validate(
        ValidationResult => \%ValidationResult,
        Errors           => \%Errors,
        GetParam         => \%GetParam,
    );

    # if no errors occurred store the values
    if ( !%Errors ) {

        my $FunctionName      = 'Data' . $Param{Action};
        my $CreateChangeByKey = 'ChangeBy';

        if ( $Param{Action} eq 'Add' ) {
            $CreateChangeByKey = 'CreateBy';
        }

        if ( !$GetParam{ID} ) {
            delete $GetParam{ID};
        }

        # update type
        my $Stored = $TranslationObject->$FunctionName(
            %GetParam,
            $CreateChangeByKey => $Self->{UserID},
            ChangeBy           => $Self->{UserID},
            UserID             => $Self->{UserID},
        );

        my %NotifiyParam;
        if ($Stored) {
            $NotifiyParam{Info} = "Translation stored!";
            $Param{ID}          = $GetParam{ID} || $Stored;
        }
        else {
            $NotifiyParam{Error} = 'Storing Translation failed!';
        }

        if ( defined $GetParam{'ContinueAfterSave'} && $GetParam{'ContinueAfterSave'} eq '1' ) {
            return $LayoutObject->Redirect(
                OP => "Action=$GetParam{Action};Subaction=Update;ID=$Param{ID}"
            );
        }

        return $Self->_Overview(
            OutputData   => $Param{OutputData},
            NotifiyParam => \%NotifiyParam
        );
    }

    # something has gone wrong
    my $Output = $LayoutObject->Header();
    $Output .= $LayoutObject->NavigationBar();
    $Output .= $LayoutObject->Notify( Priority => 'Error' );

    $Self->_Form(
        Action           => $Param{Action},
        Errors           => \%Errors,
        BackendData      => \%GetParam,
        ValidationResult => \%ValidationResult,
        OutputData       => $Param{OutputData},
    );

    $Output .= $LayoutObject->Output(
        TemplateFile => 'AdminTranslation',
        Data         => $Param{OutputData},
    );
    $Output .= $LayoutObject->Footer();
    return $Output;
}

=head2 _Copy()

copy object

    my $Output = $Self->_Copy();

=cut

sub _Copy {
    my ( $Self, %Param ) = @_;

    my $LayoutObject      = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $TranslationObject = $Kernel::OM->Get('Kernel::System::Translation');

    my $ObjectID = $TranslationObject->DataCopy(
        ID     => $Param{ID},
        UserID => $Self->{UserID},
    );

    my $JSON = $LayoutObject->JSONEncode(
        Data => {
            Action    => 'AdminTranslation',
            Subaction => 'Update',
            ID        => $ObjectID,
        },
    );

    return $LayoutObject->Attachment(
        ContentType => 'text/html',
        Content     => $JSON,
        Type        => 'inline',
        NoCache     => 1,
    );
}

=head2 _Delete()

delete object

    my $Output = $Self->_Delete();

=cut

sub _Delete {
    my ( $Self, %Param ) = @_;

    my $LayoutObject      = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $CacheObject       = $Kernel::OM->Get('Kernel::System::Cache');
    my $TranslationObject = $Kernel::OM->Get('Kernel::System::Translation');

    my $Success = $TranslationObject->DataDelete(
        ID     => $Param{ID},
        UserID => $Self->{UserID},
    );

    $CacheObject->Set(
        Type  => $Self->{CacheType},
        Key   => 'Deleted',
        Value => 1,
        TTL   => $Self->{CacheTTL},
    );

    return $LayoutObject->Attachment(
        ContentType => 'text/html',
        Content     => $Success,
        Type        => 'inline',
        NoCache     => 1,
    );
}

=head2 _Import()

handled import

    my $Attachment = $Self->_Import();

=cut

sub _Import {
    my ( $Self, %Param ) = @_;

    my $LayoutObject      = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $TranslationObject = $Kernel::OM->Get('Kernel::System::Translation');
    my $ParamObject       = $Kernel::OM->Get('Kernel::System::Web::Request');

    my %UploadFile = $ParamObject->GetUploadAll(
        Param => 'FileUpload',
    );

    if ( !$Param{Format} ) {
        $Param{Format} = $Self->_GetFileFormat(%UploadFile) || '';
    }

    my $OverwriteExistingEntities = $ParamObject->GetParam( Param => 'OverwriteExistingEntities' );
    my $Success                   = $TranslationObject->DataImport(
        Content   => $UploadFile{Content},
        Format    => $Param{Format},
        Overwrite => $OverwriteExistingEntities,
        Data      => \%Param,
    );

    my $Error = '';
    if ( !$Success ) {
        $Error = ";NotificationPriority=Error;Notification=Data could not be imported.";
    }

    return $LayoutObject->Redirect(
        OP => "Action=$Self->{Action}$Error"
    );
}

=head2 _Export()

handled export

    my $Attachment = $Self->_Export();

=cut

sub _Export {
    my ( $Self, %Param ) = @_;

    my $LayoutObject      = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $TranslationObject = $Kernel::OM->Get('Kernel::System::Translation');
    my $TimeObject        = $Kernel::OM->Get('Kernel::System::Time');
    my $ParamObject       = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $ConfigObject      = $Kernel::OM->Get('Kernel::Config');

    my $ExportConfig = $ConfigObject->Get("DBCRUD")->{Export} || {};
    my $CustomConfig;

    if (
        $TranslationObject->{Name}
        && $ConfigObject->Get( $TranslationObject->{Name} )
        && $ConfigObject->Get( $TranslationObject->{Name} )->{Export}
        )
    {
        $CustomConfig = $ConfigObject->Get( $TranslationObject->{Name} )->{Export} || {};
    }

    $Param{Format} //= $CustomConfig->{DefaultFormat} || $ExportConfig->{DefaultFormat};

    my $Export = $TranslationObject->DataExport(
        Format => $Param{Format},
        Cache  => 0,
    );

    my $TimeStamp = $TimeObject->CurrentTimestamp();

    return $LayoutObject->Attachment(
        ContentType => 'text/html; charset=' . $LayoutObject->{Charset} || 'utf-8',
        Content     => $Export,
        Type        => 'attachment',
        Filename    => "Export_Translation_$TimeStamp.$Param{Format}",
        NoCache     => 1,
    );
}

=head2 _Deployment()

handled deployment

    my $Success = $Self->_Deployment();

=cut

sub _Deployment {
    my ( $Self, %Param ) = @_;

    my $CacheObject       = $Kernel::OM->Get('Kernel::System::Cache');
    my $TranslationObject = $Kernel::OM->Get('Kernel::System::Translation');
    my $LayoutObject      = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    $TranslationObject->DataDeployment(
        UserID => $Self->{UserID},
    );

    $CacheObject->Delete(
        Type => $Self->{CacheType},
        Key  => 'Deleted',
    );

    my $Notification = 'Translations synchronized!';
    return $LayoutObject->Redirect(
        OP => "Action=AdminTranslation;Notification=" . $Notification,
    );
}

=head2 _Validate()

Validates the submit of an Add or Update request

Calls _ValidateMandatory and _ValidateName

    my $Success = $Self->_Validate(
        ValidationResult => {}, # Hashref that gets filled with the " ServerError" CSS class
                                # that is used to mark erroneous values in the template toolkit file
        Errors           => {}, # Hashref that gets filled with error messages if _Validate fails on some entries
        GetParam         => {   # Hashref holding the submitted values
            Name => ...,
            ...
        },
    );

=cut

sub _Validate {
    my ( $Self, %Param ) = @_;

    my $LogObject         = $Kernel::OM->Get('Kernel::System::Log');
    my $TranslationObject = $Kernel::OM->Get('Kernel::System::Translation');
    my $ParamObject       = $Kernel::OM->Get('Kernel::System::Web::Request');

    NEEDED:
    for my $Needed (qw(ValidationResult Errors GetParam)) {

        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    $Self->_ValidateMandatory(%Param);
    $Self->_ValidateName(%Param);

    my $Errors   = $Param{Errors};
    my $GetParam = $Param{GetParam};

    $GetParam->{ChangeBy}        = $Self->{UserID};
    $GetParam->{DeploymentState} = 0;

    # validate if translation still exists
    my @Data = $TranslationObject->DataListGet(
        LanguageID => $GetParam->{LanguageID},
        Source     => $GetParam->{Source},
        UserID     => $Self->{UserID},
    );

    # Restrict to those translations that exactly match (case sensitive).
    # This ensures that entries with the same text but with different case can be used.
    @Data = grep { $_->{Source} eq $GetParam->{Source} } @Data;

    TRANSLATION:
    for my $Translation (@Data) {
        next TRANSLATION if $Translation->{ID} eq $GetParam->{ID};
        $Errors->{SourceExists} = 1;
        return 1;
    }

    PARAM:
    for my $Param ( sort keys %{ $Self->{MandatoryParams} } ) {

        $GetParam->{$Param} = $ParamObject->GetParam( Param => $Param ) || '';

        next PARAM if length $GetParam->{$Param};

        $Errors->{ $Param . 'Invalid' }     = 'ServerError';
        $Errors->{ $Param . 'ServerError' } = $Param . 'ServerError';
    }

    return 1;
}

=head2 _ValidateName()

Checks if the given Name is available, fills the Errors Hashref if it is n't available any more.

    my $Success = $Self->_ValidateName(
        Errors           => {}, # Hashref that gets filled with error messages if _Validate fails on some entries
        GetParam         => {   # Hashref holding the submitted values
            Name => ...,
            ...
        },
    );

=cut

sub _ValidateName {
    my ( $Self, %Param ) = @_;

    my $TranslationObject = $Kernel::OM->Get('Kernel::System::Translation');

    my $Errors   = $Param{Errors};
    my $GetParam = $Param{GetParam};

    return 1 if !$TranslationObject->{FunctionDataNameExists};
    return 1 if !$TranslationObject->DataNameExists(
        Name   => $GetParam->{Name},
        ID     => $GetParam->{ID},
        UserID => $Self->{UserID},
    );

    $Errors->{NameExists}  = 1;
    $Errors->{NameInvalid} = 'ServerError';

    return 1;
}

=head2 _ValidateMandatory()

Checks if mandatory parameters (defined in ``$Self->{MandatoryParams}->{Fieldname}`` ) are present and have at least length.

    my $Success = $Self->_ValidateMandatory(
        Errors           => {}, # Hashref that gets filled with error messages if _Validate fails on some entries
        GetParam         => {   # Hashref holding the submitted values
            Name => ...,
            ...
        },
    );

=cut

sub _ValidateMandatory {
    my ( $Self, %Param ) = @_;

    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');

    my $Errors   = $Param{Errors};
    my $GetParam = $Param{GetParam};

    # additional GetParams for legacy packages
    my %GetParams = $ParamObject->GetParams();

    PARAM:
    for my $Param ( sort keys %{ $Self->{MandatoryParams} } ) {

        # DynamicFields have to get validated via
        # EditFieldValueValidate function
        next PARAM if $Param =~ m{\ADynamicField_}xms;

        if ( !defined $GetParam->{$Param} ) {
            $GetParam->{$Param} = $GetParams{$Param} || '';
        }

        # Value "0" is a valid entry
        next PARAM if defined $GetParam->{$Param};
        next PARAM if length $GetParam->{$Param};

        # name and valid id are mandatory
        $Errors->{ $Param . 'Invalid' }     = 'ServerError';
        $Errors->{ $Param . 'ServerError' } = $Param . 'ServerError';
    }

    return 1;
}

=head2 _ActionListRender()

generates action list.

    my $Success = $Self->_ActionListRender(
        ActionItems => [
            {
                LinkHref  => $LayoutObject->{Baselink} . 'Action=' . $LayoutObject->{Action} . ';Subaction=Add',
                LinkClass => 'CallForAction Fullsize Center',
                LinkText  => "Add Translation",
                IconClass => 'fa fa-plus-square',
            },
            {
                LinkHref => $LayoutObject->{Baselink}
                    . 'Action='
                    . $LayoutObject->{Action}
                    . ';Subaction=Deployment;ID=1',
                LinkClass => 'CallForAction Fullsize Center',
                LinkText  => "Deployment",
                IconClass => 'fa fa-rocket',
            }
        ],
    );

Returns:

    my $Success = 1;

=cut

sub _ActionListRender {
    my ( $Self, %Param ) = @_;

    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    NEEDED:
    for my $Needed (qw(ActionItems)) {

        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    $LayoutObject->Block(
        Name => 'ActionList',
        Data => {
            ActionItems => $Param{ActionItems},
        },
    );

    return 1;
}

=head2 _GetAttributes()

Get all common attributes.

    my $Success = $Self->_GetAttributes();

Returns:

    my $Success = 1;

=cut

sub _GetAttributes {
    my ( $Self, %Param ) = @_;

    my $ValidObject = $Kernel::OM->Get('Kernel::System::Valid');
    my $UserObject  = $Kernel::OM->Get('Kernel::System::User');
    my $GroupObject = $Kernel::OM->Get('Kernel::System::Group');

    %{ $Self->{Attributes}->{Group} } = $GroupObject->GroupList(
        Valid => 1,
    );
    %{ $Self->{Attributes}->{Valid} } = $ValidObject->ValidList();
    %{ $Self->{Attributes}->{User} }  = $UserObject->UserList(
        Type          => 'Long',
        Valid         => 1,
        NoOutOfOffice => 1,
    );

    my %Attributes = %{ $Self->{Attributes} };

    return %Attributes;
}

=head2 _GetFileFormat()

returns the file format

    my $Format = $Self->_GetFileFormat(%UploadFile);

=cut

sub _GetFileFormat {
    my ( $Self, %Param ) = @_;

    my $Format;
    if ( $Param{Filename} =~ m{\.csv\z}xmsi ) {
        $Format = 'csv';
    }
    elsif ( $Param{Filename} =~ m{\.xlsx\z}xmsi ) {
        $Format = 'excel';
    }
    elsif ( $Param{Filename} =~ m{\.yml\z}xmsi ) {
        $Format = 'yml';
    }
    else {
        $Param{Filename} =~ m{\.(.+)\z}xmsi;
        $Format = $1;
    }

    return $Format;
}

1;
