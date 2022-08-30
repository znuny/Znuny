# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Modules::AdminProcessManagementTransitionAction;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);
use Kernel::Language qw(Translatable);

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $ParamObject            = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject           = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $EntityObject           = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Entity');
    my $TransitionActionObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::TransitionAction');

    $Self->{Subaction} = $ParamObject->GetParam( Param => 'Subaction' ) || '';

    my $TransitionActionID = $ParamObject->GetParam( Param => 'ID' )       || '';
    my $EntityID           = $ParamObject->GetParam( Param => 'EntityID' ) || '';

    my %SessionData = $Kernel::OM->Get('Kernel::System::AuthSession')->GetSessionIDData(
        SessionID => $Self->{SessionID},
    );

    # convert JSON string to array
    $Self->{ScreensPath} = $Kernel::OM->Get('Kernel::System::JSON')->Decode(
        Data => $SessionData{ProcessManagementScreensPath}
    );

    # ------------------------------------------------------------ #
    # TransitionActionNew
    # ------------------------------------------------------------ #
    if ( $Self->{Subaction} eq 'TransitionActionNew' ) {

        return $Self->_ShowEdit(
            %Param,
            Action => 'New',
        );
    }

    # ------------------------------------------------------------ #
    # TransitionActionNewAction
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'TransitionActionNewAction' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        # get transition action data
        my $TransitionActionData;

        # get parameter from web browser
        my $GetParam = $Self->_GetParams();

        # set new configuration
        $TransitionActionData->{Name}   = $GetParam->{Name};
        $TransitionActionData->{Config} = $GetParam->{Config};

        # check required parameters
        my %Error;
        if ( !$GetParam->{Name} ) {

            # add server error error class
            $Error{NameServerError}        = 'ServerError';
            $Error{NameServerErrorMessage} = Translatable('This field is required');
        }

        if ( !$GetParam->{Config}->{Module} ) {

            # add server error error class
            $Error{ModuleServerError}        = 'ServerError';
            $Error{ModuleServerErrorMessage} = Translatable('This field is required');
        }

        if ( !IsHashRefWithData( $GetParam->{Config}->{Config} ) ) {
            return $LayoutObject->ErrorScreen(
                Message => Translatable('At least one valid config parameter is required.'),
            );
        }

        if ( !$GetParam->{Config}->{Scope} ) {

            # add server error error class
            $Error{NameServerError}        = 'ServerError';
            $Error{NameServerErrorMessage} = Translatable('This field is required');
        }

        if ( $GetParam->{Config}->{Scope} eq 'Process' && !$GetParam->{Config}->{ScopeEntityID} ) {

            # add server error error class
            $Error{NameServerError}        = 'ServerError';
            $Error{NameServerErrorMessage} = Translatable('This field is required');
        }

        # if there is an error return to edit screen
        if ( IsHashRefWithData( \%Error ) ) {
            return $Self->_ShowEdit(
                %Error,
                %Param,
                TransitionActionData => $TransitionActionData,
                Action               => 'New',
            );
        }

        # generate entity ID
        my $EntityID = $EntityObject->EntityIDGenerate(
            EntityType => 'TransitionAction',
            UserID     => $Self->{UserID},
        );

        # show error if can't generate a new EntityID
        if ( !$EntityID ) {
            return $LayoutObject->ErrorScreen(
                Message => Translatable('There was an error generating a new EntityID for this TransitionAction'),
            );
        }

        # otherwise save configuration and return process screen
        my $TransitionActionID = $TransitionActionObject->TransitionActionAdd(
            Name     => $TransitionActionData->{Name},
            EntityID => $EntityID,
            Config   => $TransitionActionData->{Config},
            UserID   => $Self->{UserID},
        );

        # show error if can't create
        if ( !$TransitionActionID ) {
            return $LayoutObject->ErrorScreen(
                Message => Translatable('There was an error creating the TransitionAction'),
            );
        }

        # set entity sync state
        my $Success = $EntityObject->EntitySyncStateSet(
            EntityType => 'TransitionAction',
            EntityID   => $EntityID,
            SyncState  => 'not_sync',
            UserID     => $Self->{UserID},
        );

        # show error if can't set
        if ( !$Success ) {
            return $LayoutObject->ErrorScreen(
                Message => $LayoutObject->{LanguageObject}->Translate(
                    'There was an error setting the entity sync status for TransitionAction entity: %s',
                    $EntityID
                ),
            );
        }

        # remove this screen from session screen path
        $Self->_PopSessionScreen( OnlyCurrent => 1 );

        my $Redirect = $ParamObject->GetParam( Param => 'PopupRedirect' ) || '';

        # get latest config data to send it back to main window
        my $TransitionActionConfig = $Self->_GetTransitionActionConfig(
            EntityID => $EntityID,
        );

        # check if needed to open another window or if popup should go back
        if ( $Redirect && $Redirect eq '1' ) {

            $Self->_PushSessionScreen(
                ID        => $TransitionActionID,
                EntityID  => $EntityID,
                Subaction => 'TransitionActionEdit'    # always use edit screen
            );

            my $RedirectAction    = $ParamObject->GetParam( Param => 'PopupRedirectAction' )    || '';
            my $RedirectSubaction = $ParamObject->GetParam( Param => 'PopupRedirectSubaction' ) || '';
            my $RedirectID        = $ParamObject->GetParam( Param => 'PopupRedirectID' )        || '';
            my $RedirectEntityID  = $ParamObject->GetParam( Param => 'PopupRedirectEntityID' )  || '';

            # redirect to another popup window
            return $Self->_PopupResponse(
                Redirect => 1,
                Screen   => {
                    Action    => $RedirectAction,
                    Subaction => $RedirectSubaction,
                    ID        => $RedirectID,
                    EntityID  => $RedirectID,
                },
                ConfigJSON => $TransitionActionConfig,
            );
        }
        else {

            # remove last screen
            my $LastScreen = $Self->_PopSessionScreen();

            # check if needed to return to main screen or to be redirected to last screen
            if ( $LastScreen->{Action} eq 'AdminProcessManagement' ) {

                # close the popup
                return $Self->_PopupResponse(
                    ClosePopup => 1,
                    ConfigJSON => $TransitionActionConfig,
                );
            }
            else {

                # redirect to last screen
                return $Self->_PopupResponse(
                    Redirect   => 1,
                    Screen     => $LastScreen,
                    ConfigJSON => $TransitionActionConfig,
                );
            }
        }
    }

    # ------------------------------------------------------------ #
    # TransitionActionEdit
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'TransitionActionEdit' ) {

        # check for TransitionActionID
        if ( !$TransitionActionID ) {
            return $LayoutObject->ErrorScreen(
                Message => Translatable('Need TransitionActionID!'),
            );
        }

        # remove this screen from session screen path
        $Self->_PopSessionScreen( OnlyCurrent => 1 );

        # get TransitionAction data
        my $TransitionActionData = $TransitionActionObject->TransitionActionGet(
            ID     => $TransitionActionID,
            UserID => $Self->{UserID},
        );

        # check for valid TransitionAction data
        if ( !IsHashRefWithData($TransitionActionData) ) {
            return $LayoutObject->ErrorScreen(
                Message => $LayoutObject->{LanguageObject}->Translate(
                    'Could not get data for TransitionActionID %s',
                    $TransitionActionID
                ),
            );
        }

        return $Self->_ShowEdit(
            %Param,
            TransitionActionID   => $TransitionActionID,
            TransitionActionData => $TransitionActionData,
            Action               => 'Edit',
        );
    }

    # ------------------------------------------------------------ #
    # TransitionActionEditAction
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'TransitionActionEditAction' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        # get transition action data
        my $TransitionActionData;

        # get parameter from web browser
        my $GetParam = $Self->_GetParams();

        # set new configuration
        $TransitionActionData->{Name}     = $GetParam->{Name};
        $TransitionActionData->{EntityID} = $GetParam->{EntityID};
        $TransitionActionData->{Config}   = $GetParam->{Config};

        # check required parameters
        my %Error;
        if ( !$GetParam->{Name} ) {

            # add server error error class
            $Error{NameServerError}        = 'ServerError';
            $Error{NameServerErrorMessage} = Translatable('This field is required');
        }

        if ( !$GetParam->{Config}->{Module} ) {

            # add server error error class
            $Error{ModuleServerError}        = 'ServerError';
            $Error{ModuleServerErrorMessage} = Translatable('This field is required');
        }

        if ( !$GetParam->{Config}->{Config} ) {
            return $LayoutObject->ErrorScreen(
                Message => Translatable('At least one valid config parameter is required.'),
            );
        }

        if ( !$GetParam->{Config}->{Scope} ) {

            # add server error error class
            $Error{NameServerError}        = 'ServerError';
            $Error{NameServerErrorMessage} = Translatable('This field is required');
        }

        if ( $GetParam->{Config}->{Scope} eq 'Process' && !$GetParam->{Config}->{ScopeEntityID} ) {

            # add server error error class
            $Error{NameServerError}        = 'ServerError';
            $Error{NameServerErrorMessage} = Translatable('This field is required');
        }

        # if there is an error return to edit screen
        if ( IsHashRefWithData( \%Error ) ) {
            return $Self->_ShowEdit(
                %Error,
                %Param,
                TransitionActionData => $TransitionActionData,
                Action               => 'Edit',
            );
        }

        # otherwise save configuration and return to overview screen
        my $Success = $TransitionActionObject->TransitionActionUpdate(
            ID       => $TransitionActionID,
            EntityID => $TransitionActionData->{EntityID},
            Name     => $TransitionActionData->{Name},
            Config   => $TransitionActionData->{Config},
            UserID   => $Self->{UserID},
        );

        # show error if can't update
        if ( !$Success ) {
            return $LayoutObject->ErrorScreen(
                Message => Translatable('There was an error updating the TransitionAction'),
            );
        }

        # set entity sync state
        $Success = $EntityObject->EntitySyncStateSet(
            EntityType => 'TransitionAction',
            EntityID   => $TransitionActionData->{EntityID},
            SyncState  => 'not_sync',
            UserID     => $Self->{UserID},
        );

        # show error if can't set
        if ( !$Success ) {
            return $LayoutObject->ErrorScreen(
                Message => $LayoutObject->{LanguageObject}->Translate(
                    'There was an error setting the entity sync status for TransitionAction entity: %s',
                    $TransitionActionData->{EntityID}
                ),
            );
        }

        # remove this screen from session screen path
        $Self->_PopSessionScreen( OnlyCurrent => 1 );

        my $Redirect = $ParamObject->GetParam( Param => 'PopupRedirect' ) || '';

        # get latest config data to send it back to main window
        my $TransitionActionConfig = $Self->_GetTransitionActionConfig(
            EntityID => $TransitionActionData->{EntityID},
        );

        # check if needed to open another window or if popup should go back
        if ( $Redirect && $Redirect eq '1' ) {

            $Self->_PushSessionScreen(
                ID        => $TransitionActionID,
                EntityID  => $TransitionActionData->{EntityID},
                Subaction => 'TransitionActionEdit'               # always use edit screen
            );

            my $RedirectAction    = $ParamObject->GetParam( Param => 'PopupRedirectAction' )    || '';
            my $RedirectSubaction = $ParamObject->GetParam( Param => 'PopupRedirectSubaction' ) || '';
            my $RedirectID        = $ParamObject->GetParam( Param => 'PopupRedirectID' )        || '';
            my $RedirectEntityID  = $ParamObject->GetParam( Param => 'PopupRedirectEntityID' )  || '';

            # redirect to another popup window
            return $Self->_PopupResponse(
                Redirect => 1,
                Screen   => {
                    Action    => $RedirectAction,
                    Subaction => $RedirectSubaction,
                    ID        => $RedirectID,
                    EntityID  => $RedirectID,
                },
                ConfigJSON => $TransitionActionConfig,
            );
        }
        else {

            # remove last screen
            my $LastScreen = $Self->_PopSessionScreen();

            # check if needed to return to main screen or to be redirected to last screen
            if ( $LastScreen->{Action} eq 'AdminProcessManagement' ) {

                # close the popup
                return $Self->_PopupResponse(
                    ClosePopup => 1,
                    ConfigJSON => $TransitionActionConfig,
                );
            }
            else {

                # redirect to last screen
                return $Self->_PopupResponse(
                    Redirect   => 1,
                    Screen     => $LastScreen,
                    ConfigJSON => $TransitionActionConfig,
                );
            }
        }
    }

    # ------------------------------------------------------------ #
    # Add default parameter
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'GetDefaultConfigParameters' ) {
        my $Module          = $ParamObject->GetParam( Param => 'Module' );
        my %ConfigParameter = $Self->_GetDefaultConfigParameters(
            Module => $Module,
        );

        my $JSON = $LayoutObject->JSONEncode(
            Data => {
                %ConfigParameter
            }
        );
        return $LayoutObject->Attachment(
            ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
            Content     => $JSON || '',
            Type        => 'inline',
            NoCache     => 1,
        );
    }

    # ------------------------------------------------------------ #
    # Close popup
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'ClosePopup' ) {

        # close the popup
        return $Self->_PopupResponse(
            ClosePopup => 1,
            ConfigJSON => '',
        );
    }

    # ------------------------------------------------------------ #
    # Error
    # ------------------------------------------------------------ #
    else {
        return $LayoutObject->ErrorScreen(
            Message => Translatable('This subaction is not valid'),
        );
    }
}

sub _GetTransitionActionConfig {
    my ( $Self, %Param ) = @_;

    # Get new Transition Config as JSON
    my $ProcessDump = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Process')->ProcessDump(
        ResultType => 'HASH',
        UserID     => $Self->{UserID},
    );

    my %TransitionActionConfig;
    $TransitionActionConfig{TransitionAction} = ();
    $TransitionActionConfig{TransitionAction}->{ $Param{EntityID} }
        = $ProcessDump->{TransitionAction}->{ $Param{EntityID} };

    return \%TransitionActionConfig;
}

sub _ShowEdit {
    my ( $Self, %Param ) = @_;

    # get TransitionAction information
    my $TransitionActionData = $Param{TransitionActionData} || {};

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # check if last screen action is main screen
    if ( $Self->{ScreensPath}->[-1]->{Action} eq 'AdminProcessManagement' ) {

        # show close popup link
        $LayoutObject->Block(
            Name => 'ClosePopup',
            Data => {},
        );
    }
    else {

        # show go back link
        $LayoutObject->Block(
            Name => 'GoBack',
            Data => {
                Action          => $Self->{ScreensPath}->[-1]->{Action}          || '',
                Subaction       => $Self->{ScreensPath}->[-1]->{Subaction}       || '',
                ID              => $Self->{ScreensPath}->[-1]->{ID}              || '',
                EntityID        => $Self->{ScreensPath}->[-1]->{EntityID}        || '',
                StartActivityID => $Self->{ScreensPath}->[-1]->{StartActivityID} || '',
            },
        );
    }

    if ( defined $Param{Action} && $Param{Action} eq 'Edit' ) {
        $Param{Title} = $LayoutObject->{LanguageObject}->Translate(
            'Edit Transition Action "%s"',
            $TransitionActionData->{Name}
        );
    }
    else {
        $Param{Title} = Translatable('Create New Transition Action');
    }

    my $Output = $LayoutObject->Header(
        Value => $Param{Title},
        Type  => 'Small',
    );

    if ( defined $Param{Action} && $Param{Action} eq 'Edit' ) {

        my $Index       = 1;
        my @ConfigItems = sort keys %{ $TransitionActionData->{Config}->{Config} };
        for my $Key (@ConfigItems) {

            $LayoutObject->Block(
                Name => 'ConfigItemEditRow',
                Data => {
                    Key   => $Key,
                    Value => $TransitionActionData->{Config}->{Config}->{$Key},
                    Index => $Index,
                },
            );
            $Index++;
        }

        # display other affected transitions by editing this activity (if applicable)
        my $AffectedProcesses = $Self->_CheckTransitionActionUsage(
            EntityID => $TransitionActionData->{EntityID},
        );

        if ( @{$AffectedProcesses} ) {

            $LayoutObject->Block(
                Name => 'EditWarning',
                Data => {
                    ProcessList => join( ', ', @{$AffectedProcesses} ),
                }
            );
        }

    }
    else {
        $LayoutObject->Block(
            Name => 'ConfigItemInitRow',
        );
    }

    # lookup existing Transition Actions on disk
    my $Directory
        = $Kernel::OM->Get('Kernel::Config')->Get('Home') . '/Kernel/System/ProcessManagement/TransitionAction';
    my @List = $Kernel::OM->Get('Kernel::System::Main')->DirectoryRead(
        Directory => $Directory,
        Filter    => '*.pm',
    );
    my %TransitionAction;
    ITEM:
    for my $Item (@List) {

        # remove .pm
        $Item =~ s/^.*\/(.+?)\.pm$/$1/;
        next ITEM if $Item eq 'Base';
        $TransitionAction{ 'Kernel::System::ProcessManagement::TransitionAction::' . $Item } = $Item;
    }

    # build TransitionAction string
    $Param{ModuleStrg} = $LayoutObject->BuildSelection(
        Data         => \%TransitionAction,
        Name         => 'Module',
        PossibleNone => 1,
        Translation  => 0,
        SelectedID   => $TransitionActionData->{Config}->{Module},
        Class        => 'Modernize Validate_Required ' . ( $Param{Errors}->{'ModuleInvalid'} || '' ),
    );

    $Param{ScopeSelection} = $LayoutObject->BuildSelection(
        Data => {
            Global  => 'Global',
            Process => 'Process',
        },
        Name           => 'Scope',
        ID             => 'Scope',
        SelectedID     => $TransitionActionData->{Config}->{Scope} || 'Global',
        Sort           => 'IndividualKey',
        SortIndividual => [ 'Global', 'Process' ],
        Translation    => 1,
        Class          => 'Modernize W50pc ',
    );

    my $ProcessList = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Process')->ProcessList(
        UserID      => 1,
        UseEntities => 1,
    );

    my $GetParam = $Self->_GetParams();

    $Param{ScopeEntityIDSelection} = $LayoutObject->BuildSelection(
        Data        => $ProcessList,
        Name        => 'ScopeEntityID',
        ID          => 'ScopeEntityID',
        SelectedID  => $TransitionActionData->{Config}->{ScopeEntityID} // $GetParam->{ProcessEntityID},
        Sort        => 'AlphanumericValue',
        Translation => 1,
        Class       => 'Modernize W50pc ',
    );

    $Output .= $LayoutObject->Output(
        TemplateFile => "AdminProcessManagementTransitionAction",
        Data         => {
            %Param,
            %{$TransitionActionData},
            Name => $TransitionActionData->{Name},
        },
    );

    $Output .= $LayoutObject->Footer();

    return $Output;
}

sub _GetParams {
    my ( $Self, %Param ) = @_;

    my $GetParam;
    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');

    # get parameters from web browser
    for my $ParamName (qw(Name EntityID ProcessEntityID)) {
        $GetParam->{$ParamName} = $ParamObject->GetParam( Param => $ParamName ) || '';
    }

    for my $ParamName (qw(Module Scope ScopeEntityID)) {
        $GetParam->{Config}->{$ParamName} = $ParamObject->GetParam( Param => $ParamName ) || '';
    }
    $GetParam->{Config}->{Scope} //= 'Global';
    if ( $GetParam->{Config}->{Scope} eq 'Global' ) {
        delete $GetParam->{Config}->{ScopeEntityID};
    }

    # get config params
    my @ParamNames = $ParamObject->GetParamNames();
    my ( @ConfigParamKeys, @ConfigParamValues );

    for my $ParamName (@ParamNames) {

        # get keys
        if ( $ParamName =~ m{ConfigKey\[(\d+)\]}xms ) {
            push @ConfigParamKeys, $1;
        }

        # get values
        if ( $ParamName =~ m{ConfigValue\[(\d+)\]}xms ) {
            push @ConfigParamValues, $1;
        }
    }

    if ( @ConfigParamKeys != @ConfigParamValues ) {
        return $Kernel::OM->Get('Kernel::Output::HTML::Layout')->ErrorScreen(
            Message => Translatable('Error: Not all keys seem to have values or vice versa.'),
        );
    }

    my ( $KeyValue, $ValueValue );
    PARAM:
    for my $Key (@ConfigParamKeys) {
        $KeyValue   = $ParamObject->GetParam( Param => "ConfigKey[$Key]" );
        $ValueValue = $ParamObject->GetParam( Param => "ConfigValue[$Key]" );

        next PARAM if !$KeyValue || $KeyValue eq '';
        $GetParam->{Config}->{Config}->{$KeyValue} = $ValueValue;
    }

    return $GetParam;
}

sub _PopSessionScreen {
    my ( $Self, %Param ) = @_;

    my $LastScreen;

    if ( defined $Param{OnlyCurrent} && $Param{OnlyCurrent} == 1 ) {

        # check if last screen action is current screen action
        if ( $Self->{ScreensPath}->[-1]->{Action} eq $Self->{Action} ) {

            # remove last screen
            $LastScreen = pop @{ $Self->{ScreensPath} };
        }
    }
    else {

        # remove last screen
        $LastScreen = pop @{ $Self->{ScreensPath} };
    }

    # convert screens path to string (JSON)
    my $JSONScreensPath = $Kernel::OM->Get('Kernel::Output::HTML::Layout')->JSONEncode(
        Data => $Self->{ScreensPath},
    );

    # update session
    $Kernel::OM->Get('Kernel::System::AuthSession')->UpdateSessionID(
        SessionID => $Self->{SessionID},
        Key       => 'ProcessManagementScreensPath',
        Value     => $JSONScreensPath,
    );

    return $LastScreen;
}

sub _PushSessionScreen {
    my ( $Self, %Param ) = @_;

    # add screen to the screen path
    push @{ $Self->{ScreensPath} }, {
        Action    => $Self->{Action} || '',
        Subaction => $Param{Subaction},
        ID        => $Param{ID},
        EntityID  => $Param{EntityID},
    };

    # convert screens path to string (JSON)
    my $JSONScreensPath = $Kernel::OM->Get('Kernel::Output::HTML::Layout')->JSONEncode(
        Data => $Self->{ScreensPath},
    );

    # update session
    $Kernel::OM->Get('Kernel::System::AuthSession')->UpdateSessionID(
        SessionID => $Self->{SessionID},
        Key       => 'ProcessManagementScreensPath',
        Value     => $JSONScreensPath,
    );

    return 1;
}

sub _PopupResponse {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    if ( $Param{Redirect} && $Param{Redirect} eq 1 ) {

        # send data to JS
        $LayoutObject->AddJSData(
            Key   => 'Redirect',
            Value => {
                ConfigJSON => $Param{ConfigJSON},
                %{ $Param{Screen} },
            }
        );
    }
    elsif ( $Param{ClosePopup} && $Param{ClosePopup} eq 1 ) {

        # send data to JS
        $LayoutObject->AddJSData(
            Key   => 'ClosePopup',
            Value => {
                ConfigJSON => $Param{ConfigJSON},
            }
        );
    }

    my $Output = $LayoutObject->Header( Type => 'Small' );
    $Output .= $LayoutObject->Output(
        TemplateFile => "AdminProcessManagementPopupResponse",
        Data         => {},
    );
    $Output .= $LayoutObject->Footer( Type => 'Small' );

    return $Output;
}

sub _CheckTransitionActionUsage {
    my ( $Self, %Param ) = @_;

    # get a list of parents with all the details
    my $List = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Process')->ProcessListGet(
        UserID => 1,
    );

    my @Usage;

    # search entity id in all parents
    PARENT:
    for my $ParentData ( @{$List} ) {
        next PARENT if !$ParentData;
        next PARENT if !$ParentData->{TransitionActions};
        ENTITY:
        for my $EntityID ( @{ $ParentData->{TransitionActions} } ) {
            if ( $EntityID eq $Param{EntityID} ) {
                push @Usage, $ParentData->{Name};
                last ENTITY;
            }
        }
    }

    return \@Usage;
}

sub _GetDefaultConfigParameters {
    my ( $Self, %Param ) = @_;

    NEEDED:
    for my $Needed (qw(Module)) {
        next NEEDED if defined $Param{$Needed};
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need ' . $Needed . '!'
        );
        return;
    }

# get TransitionAction name of full namespace e.g. 'Kernel::System::ProcessManagement::TransitionAction::TicketCreate' to 'TicketCreate'
    if ( $Param{Module} =~ m/TransitionAction::(.+)$/ ) {
        my $TransitionAction = $1;
        my $Config = $Kernel::OM->Get('Kernel::Config')->Get('ProcessManagement::TransitionAction::DefaultParameters');
        my %Settings;
        for my $Key ( sort keys %{$Config} ) {
            if ( IsHashRefWithData( $Config->{$Key} ) ) {
                %Settings = ( %Settings, %{ $Config->{$Key} } );
            }
        }
        return %{ $Settings{$TransitionAction} || {} };
    }
    return;
}

1;
