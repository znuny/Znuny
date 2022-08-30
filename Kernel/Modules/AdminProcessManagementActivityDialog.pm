# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Modules::AdminProcessManagementActivityDialog;

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

    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');

    $Self->{Subaction} = $ParamObject->GetParam( Param => 'Subaction' ) || '';

    my $ActivityDialogID = $ParamObject->GetParam( Param => 'ID' )       || '';
    my $EntityID         = $ParamObject->GetParam( Param => 'EntityID' ) || '';

    my %SessionData = $Kernel::OM->Get('Kernel::System::AuthSession')->GetSessionIDData(
        SessionID => $Self->{SessionID},
    );

    # convert JSON string to array
    $Self->{ScreensPath} = $Kernel::OM->Get('Kernel::System::JSON')->Decode(
        Data => $SessionData{ProcessManagementScreensPath}
    );

    # get parameter from web browser
    my $GetParam = $Self->_GetParams();

    # get needed objects
    my $ConfigObject         = $Kernel::OM->Get('Kernel::Config');
    my $EntityObject         = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Entity');
    my $ActivityDialogObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::ActivityDialog');
    my $LayoutObject         = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # create available Fields list
    my $AvailableFieldsList = {
        Article     => 'Article',
        State       => 'StateID',
        Priority    => 'PriorityID',
        Lock        => 'LockID',
        Queue       => 'QueueID',
        CustomerID  => 'CustomerID',
        Owner       => 'OwnerID',
        PendingTime => 'PendingTime',
        Title       => 'Title',
        Attachments => 'Attachments',
    };

    # add service and SLA fields, if option is activated in sysconfig.
    if ( $ConfigObject->Get('Ticket::Service') ) {
        $AvailableFieldsList->{Service} = 'ServiceID';
        $AvailableFieldsList->{SLA}     = 'SLAID';
    }

    # add ticket type field, if option is activated in sysconfig.
    if ( $ConfigObject->Get('Ticket::Type') ) {
        $AvailableFieldsList->{Type} = 'TypeID';
    }

    # add responsible field, if option is activated in sysconfig.
    if ( $ConfigObject->Get('Ticket::Responsible') ) {
        $AvailableFieldsList->{Responsible} = 'ResponsibleID';
    }

    my $DynamicFieldList = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldList(
        ObjectType => ['Ticket'],
        ResultType => 'HASH',
    );

    DYNAMICFIELD:
    for my $DynamicFieldName ( values %{$DynamicFieldList} ) {

        next DYNAMICFIELD if !$DynamicFieldName;

        # do not show internal fields for process management
        next DYNAMICFIELD if $DynamicFieldName eq 'ProcessManagementProcessID';
        next DYNAMICFIELD if $DynamicFieldName eq 'ProcessManagementActivityID';
        next DYNAMICFIELD if $DynamicFieldName eq 'ProcessManagementAttachment';

        $AvailableFieldsList->{"DynamicField_$DynamicFieldName"} = $DynamicFieldName;
    }

    # ------------------------------------------------------------ #
    # ActivityDialogNew
    # ------------------------------------------------------------ #
    if ( $Self->{Subaction} eq 'ActivityDialogNew' ) {

        return $Self->_ShowEdit(
            %Param,
            Action => 'New',
        );
    }

    # ------------------------------------------------------------ #
    # ActivityDialogNewAction
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'ActivityDialogNewAction' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        # get Activity Dialog data
        my $ActivityDialogData;

        # set new configuration
        $ActivityDialogData->{Name}     = $GetParam->{Name};
        $ActivityDialogData->{EntityID} = $GetParam->{EntityID};
        $ActivityDialogData->{Config}   = $GetParam->{Config};
        my @GetParamFields = @{ $GetParam->{Config}->{Fields} };

        $ActivityDialogData->{Config}->{Fields}     = {};
        $ActivityDialogData->{Config}->{FieldOrder} = [];

        if (@GetParamFields) {

            FIELD:
            for my $FieldName (@GetParamFields) {

                next FIELD if !$FieldName;
                next FIELD if !$AvailableFieldsList->{$FieldName};

                # set fields hash
                $ActivityDialogData->{Config}->{Fields}->{$FieldName} = {};

                # set field order array
                push @{ $ActivityDialogData->{Config}->{FieldOrder} }, $FieldName;
            }
        }

        # add field detail config to fields
        if ( IsHashRefWithData( $GetParam->{Config}->{FieldDetails} ) ) {
            FIELDDETAIL:
            for my $FieldDetail ( sort keys %{ $GetParam->{Config}->{FieldDetails} } ) {
                next FIELDDETAIL if !$FieldDetail;
                next FIELDDETAIL if !$ActivityDialogData->{Config}->{Fields}->{$FieldDetail};

                $ActivityDialogData->{Config}->{Fields}->{$FieldDetail}
                    = $GetParam->{Config}->{FieldDetails}->{$FieldDetail};
            }
        }

        # set correct Interface value
        my %Interfaces = (
            AgentInterface    => ['AgentInterface'],
            CustomerInterface => ['CustomerInterface'],
            BothInterfaces    => [ 'AgentInterface', 'CustomerInterface' ],
        );
        $ActivityDialogData->{Config}->{Interface} = $Interfaces{ $ActivityDialogData->{Config}->{Interface} };

        if ( !$ActivityDialogData->{Config}->{Interface} ) {
            $ActivityDialogData->{Config}->{Interface} = $Interfaces{Agent};
        }

        # check required parameters
        my %Error;
        if ( !$GetParam->{Name} ) {

            # add server error error class
            $Error{NameServerError}        = 'ServerError';
            $Error{NameServerErrorMessage} = Translatable('This field is required');
        }

        if ( !$GetParam->{Config}->{DescriptionShort} ) {

            # add server error error class
            $Error{DescriptionShortServerError} = 'ServerError';
            $Error{DecriptionShortErrorMessage} = Translatable('This field is required');
        }

        # check if permission exists
        if ( defined $GetParam->{Config}->{Permission} && $GetParam->{Config}->{Permission} ne '' ) {
            my $PermissionList = $ConfigObject->Get('System::Permission');

            my %PermissionLookup = map { $_ => 1 } @{$PermissionList};

            if ( !$PermissionLookup{ $GetParam->{Config}->{Permission} } )
            {

                # add server error error class
                $Error{PermissionServerError} = 'ServerError';
            }
        }

        # check if required lock exists
        if ( $GetParam->{Config}->{RequiredLock} && $GetParam->{Config}->{RequiredLock} ne 1 ) {

            # add server error error class
            $Error{RequiredLockServerError} = 'ServerError';
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
                ActivityDialogData => $ActivityDialogData,
                Action             => 'New',
            );
        }

        # generate entity ID
        my $EntityID = $EntityObject->EntityIDGenerate(
            EntityType => 'ActivityDialog',
            UserID     => $Self->{UserID},
        );

        # show error if can't generate a new EntityID
        if ( !$EntityID ) {
            return $LayoutObject->ErrorScreen(
                Message => Translatable("There was an error generating a new EntityID for this ActivityDialog"),
            );
        }

        # otherwise save configuration and return process screen
        my $ActivityDialogID = $ActivityDialogObject->ActivityDialogAdd(
            Name     => $ActivityDialogData->{Name},
            EntityID => $EntityID,
            Config   => $ActivityDialogData->{Config},
            UserID   => $Self->{UserID},
        );

        # show error if can't create
        if ( !$ActivityDialogID ) {
            return $LayoutObject->ErrorScreen(
                Message => Translatable("There was an error creating the ActivityDialog"),
            );
        }

        # set entity sync state
        my $Success = $EntityObject->EntitySyncStateSet(
            EntityType => 'ActivityDialog',
            EntityID   => $EntityID,
            SyncState  => 'not_sync',
            UserID     => $Self->{UserID},
        );

        # show error if can't set
        if ( !$Success ) {
            return $LayoutObject->ErrorScreen(
                Message => $LayoutObject->{LanguageObject}->Translate(
                    'There was an error setting the entity sync status for ActivityDialog entity: %s',
                    $EntityID
                ),
            );
        }

        # remove this screen from session screen path
        $Self->_PopSessionScreen( OnlyCurrent => 1 );

        my $Redirect = $ParamObject->GetParam( Param => 'PopupRedirect' ) || '';

        # get latest config data to send it back to main window
        my $ActivityDialogConfig = $Self->_GetActivityDialogConfig(
            EntityID => $EntityID,
        );

        # check if needed to open another window or if popup should go back
        if ( $Redirect && $Redirect eq '1' ) {

            $Self->_PushSessionScreen(
                ID        => $ActivityDialogID,
                EntityID  => $ActivityDialogData->{EntityID},
                Subaction => 'ActivityDialogEdit'               # always use edit screen
            );

            my $RedirectField = $ParamObject->GetParam( Param => 'PopupRedirectID' ) || '';

            # redirect to another popup window
            return $Self->_PopupResponse(
                Redirect => 1,
                Screen   => {
                    Action    => 'AdminProcessManagementField',
                    Subaction => 'FieldEdit',
                    Field     => $RedirectField,
                },
                ConfigJSON => $ActivityDialogConfig,
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
                    ConfigJSON => $ActivityDialogConfig,
                );
            }
            else {

                # redirect to last screen
                return $Self->_PopupResponse(
                    Redirect   => 1,
                    Screen     => $LastScreen,
                    ConfigJSON => $ActivityDialogConfig,
                );
            }
        }
    }

    # ------------------------------------------------------------ #
    # ActivityDialogEdit
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'ActivityDialogEdit' ) {

        # check for ActivityDialogID
        if ( !$ActivityDialogID ) {
            return $LayoutObject->ErrorScreen(
                Message => Translatable("Need ActivityDialogID!"),
            );
        }

        # remove this screen from session screen path
        $Self->_PopSessionScreen( OnlyCurrent => 1 );

        # get Activity Dialog data
        my $ActivityDialogData = $ActivityDialogObject->ActivityDialogGet(
            ID     => $ActivityDialogID,
            UserID => $Self->{UserID},
        );

        # check for valid Activity Dialog data
        if ( !IsHashRefWithData($ActivityDialogData) ) {
            return $LayoutObject->ErrorScreen(
                Message => $LayoutObject->{LanguageObject}->Translate(
                    'Could not get data for ActivityDialogID %s',
                    $ActivityDialogID
                ),
            );
        }

        return $Self->_ShowEdit(
            %Param,
            ActivityDialogID   => $ActivityDialogID,
            ActivityDialogData => $ActivityDialogData,
            Action             => 'Edit',
        );
    }

    # ------------------------------------------------------------ #
    # ActvityDialogEditAction
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'ActivityDialogEditAction' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        # get Activity Dialog Data
        my $ActivityDialogData;

        # set new configuration
        $ActivityDialogData->{Name}     = $GetParam->{Name};
        $ActivityDialogData->{EntityID} = $GetParam->{EntityID};
        $ActivityDialogData->{Config}   = $GetParam->{Config};
        my @GetParamFields = @{ $GetParam->{Config}->{Fields} };

        $ActivityDialogData->{Config}->{Fields}     = {};
        $ActivityDialogData->{Config}->{FieldOrder} = [];

        if (@GetParamFields) {

            FIELD:
            for my $FieldName (@GetParamFields) {
                next FIELD if !$FieldName;
                next FIELD if !$AvailableFieldsList->{$FieldName};

                # set fields hash
                $ActivityDialogData->{Config}->{Fields}->{$FieldName} = {};

                # set field order array
                push @{ $ActivityDialogData->{Config}->{FieldOrder} }, $FieldName;
            }
        }

        # add field detail config to fields
        if ( IsHashRefWithData( $GetParam->{Config}->{FieldDetails} ) ) {
            FIELDDETAIL:
            for my $FieldDetail ( sort keys %{ $GetParam->{Config}->{FieldDetails} } ) {
                next FIELDDETAIL if !$FieldDetail;
                next FIELDDETAIL if !$ActivityDialogData->{Config}->{Fields}->{$FieldDetail};

                $ActivityDialogData->{Config}->{Fields}->{$FieldDetail}
                    = $GetParam->{Config}->{FieldDetails}->{$FieldDetail};
            }
        }

        # set default values for fields in case they don't have details
        for my $FieldName ( sort keys %{ $ActivityDialogData->{Config}->{Fields} } ) {
            if ( !IsHashRefWithData( $ActivityDialogData->{Config}->{Fields}->{$FieldName} ) ) {
                $ActivityDialogData->{Config}->{Fields}->{$FieldName}->{DescriptionShort} = $FieldName;
            }
        }

        # set correct Interface value
        my %Interfaces = (
            AgentInterface    => ['AgentInterface'],
            CustomerInterface => ['CustomerInterface'],
            BothInterfaces    => [ 'AgentInterface', 'CustomerInterface' ],
        );
        $ActivityDialogData->{Config}->{Interface} = $Interfaces{ $ActivityDialogData->{Config}->{Interface} };

        if ( !$ActivityDialogData->{Config}->{Interface} ) {
            $ActivityDialogData->{Config}->{Interface} = $Interfaces{Agent};
        }

        # check required parameters
        my %Error;

        if ( !$GetParam->{Name} ) {

            # add server error error class
            $Error{NameServerError}        = 'ServerError';
            $Error{NameServerErrorMessage} = Translatable('This field is required');
        }

        if ( !$GetParam->{Config}->{DescriptionShort} ) {

            # add server error error class
            $Error{DescriptionShortServerError} = 'ServerError';
            $Error{DecriptionShortErrorMessage} = Translatable('This field is required');
        }

        # check if permission exists
        if ( defined $GetParam->{Config}->{Permission} && $GetParam->{Config}->{Permission} ne '' ) {

            my $PermissionList = $ConfigObject->Get('System::Permission');

            my %PermissionLookup = map { $_ => 1 } @{$PermissionList};

            if ( !$PermissionLookup{ $GetParam->{Config}->{Permission} } )
            {

                # add server error error class
                $Error{PermissionServerError} = 'ServerError';
            }
        }

        # check if required lock exists
        if ( $GetParam->{Config}->{RequiredLock} && $GetParam->{Config}->{RequiredLock} ne 1 ) {

            # add server error error class
            $Error{RequiredLockServerError} = 'ServerError';
        }

        # if there is an error return to edit screen
        if ( IsHashRefWithData( \%Error ) ) {
            return $Self->_ShowEdit(
                %Error,
                %Param,
                ActivityDialogData => $ActivityDialogData,
                Action             => 'Edit',
            );
        }

        # otherwise save configuration and return to overview screen
        my $Success = $ActivityDialogObject->ActivityDialogUpdate(
            ID       => $ActivityDialogID,
            Name     => $ActivityDialogData->{Name},
            EntityID => $ActivityDialogData->{EntityID},
            Config   => $ActivityDialogData->{Config},
            UserID   => $Self->{UserID},
        );

        # show error if can't update
        if ( !$Success ) {
            return $LayoutObject->ErrorScreen(
                Message => Translatable("There was an error updating the ActivityDialog"),
            );
        }

        # set entity sync state
        $Success = $EntityObject->EntitySyncStateSet(
            EntityType => 'ActivityDialog',
            EntityID   => $ActivityDialogData->{EntityID},
            SyncState  => 'not_sync',
            UserID     => $Self->{UserID},
        );

        # show error if can't set
        if ( !$Success ) {
            return $LayoutObject->ErrorScreen(
                Message => $LayoutObject->{LanguageObject}->Translate(
                    'There was an error setting the entity sync status for ActivityDialog entity: %s',
                    $ActivityDialogData->{EntityID}
                ),
            );
        }

        # remove this screen from session screen path
        $Self->_PopSessionScreen( OnlyCurrent => 1 );

        my $Redirect = $ParamObject->GetParam( Param => 'PopupRedirect' ) || '';

        # get latest config data to send it back to main window
        my $ActivityDialogConfig = $Self->_GetActivityDialogConfig(
            EntityID => $ActivityDialogData->{EntityID},
        );

        # check if needed to open another window or if popup should go back
        if ( $Redirect && $Redirect eq '1' ) {

            $Self->_PushSessionScreen(
                ID        => $ActivityDialogID,
                EntityID  => $ActivityDialogData->{EntityID},
                Subaction => 'ActivityDialogEdit'               # always use edit screen
            );

            my $RedirectField = $ParamObject->GetParam( Param => 'PopupRedirectID' ) || '';

            # redirect to another popup window
            return $Self->_PopupResponse(
                Redirect => 1,
                Screen   => {
                    Action    => 'AdminProcessManagementField',
                    Subaction => 'FieldEdit',
                    Field     => $RedirectField,
                },
                ConfigJSON => $ActivityDialogConfig,
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
                    ConfigJSON => $ActivityDialogConfig,
                );
            }
            else {

                # redirect to last screen
                return $Self->_PopupResponse(
                    Redirect   => 1,
                    Screen     => $LastScreen,
                    ConfigJSON => $ActivityDialogConfig,
                );
            }
        }
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
            Message => Translatable("This subaction is not valid"),
        );
    }
}

sub _GetActivityDialogConfig {
    my ( $Self, %Param ) = @_;

    # Get new ActivityDialog Config as JSON
    my $ProcessDump = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Process')->ProcessDump(
        ResultType => 'HASH',
        UserID     => $Self->{UserID},
    );

    my %ActivityDialogConfig;
    $ActivityDialogConfig{ActivityDialog} = ();
    $ActivityDialogConfig{ActivityDialog}->{ $Param{EntityID} } = $ProcessDump->{ActivityDialog}->{ $Param{EntityID} };

    return \%ActivityDialogConfig;
}

sub _ShowEdit {
    my ( $Self, %Param ) = @_;

    # get Activity Dialog information
    my $ActivityDialogData = $Param{ActivityDialogData} || {};

    my $LayoutObject           = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $StandardTemplateObject = $Kernel::OM->Get('Kernel::System::StandardTemplate');

    # get parameter from web browser
    my $GetParam = $Self->_GetParams();
    $GetParam->{ProcessEntityID} ||= $Self->{ScreensPath}->[-1]->{ProcessEntityID};

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
                ProcessEntityID => $Self->{ScreensPath}->[-1]->{ProcessEntityID} || '',
            },
        );
    }

    # create available Fields list
    my $AvailableFieldsList = {
        Article     => 'Article',
        State       => 'StateID',
        Priority    => 'PriorityID',
        Lock        => 'LockID',
        Queue       => 'QueueID',
        CustomerID  => 'CustomerID',
        Owner       => 'OwnerID',
        PendingTime => 'PendingTime',
        Title       => 'Title',
        Attachments => 'Attachments',
    };

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # add service and SLA fields, if option is activated in SysConfig.
    if ( $ConfigObject->Get('Ticket::Service') ) {
        $AvailableFieldsList->{Service} = 'ServiceID';
        $AvailableFieldsList->{SLA}     = 'SLAID';
    }

    # add ticket type field, if option is activated in SysConfig.
    if ( $ConfigObject->Get('Ticket::Type') ) {
        $AvailableFieldsList->{Type} = 'TypeID';
    }

    # add responsible field, if option is activated in SysConfig.
    if ( $ConfigObject->Get('Ticket::Responsible') ) {
        $AvailableFieldsList->{Responsible} = 'ResponsibleID';
    }

    my $DynamicFieldList = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldList(
        ObjectType => ['Ticket'],
        ResultType => 'HASH',
    );

    DYNAMICFIELD:
    for my $DynamicFieldName ( values %{$DynamicFieldList} ) {

        next DYNAMICFIELD if !$DynamicFieldName;

        # do not show internal fields for process management
        next DYNAMICFIELD if $DynamicFieldName eq 'ProcessManagementProcessID';
        next DYNAMICFIELD if $DynamicFieldName eq 'ProcessManagementActivityID';
        next DYNAMICFIELD if $DynamicFieldName eq 'ProcessManagementAttachment';

        $AvailableFieldsList->{"DynamicField_$DynamicFieldName"} = $DynamicFieldName;
    }

    # localize available fields
    my %AvailableFields = %{$AvailableFieldsList};

    if ( defined $Param{Action} && $Param{Action} eq 'Edit' ) {

        # get used fields by the activity dialog
        my %AssignedFields;

        if ( IsHashRefWithData( $ActivityDialogData->{Config}->{Fields} ) ) {
            FIELD:
            for my $Field ( sort keys %{ $ActivityDialogData->{Config}->{Fields} } ) {
                next FIELD if !$Field;
                next FIELD if !$ActivityDialogData->{Config}->{Fields}->{$Field};

                $AssignedFields{$Field} = 1;
            }
        }

        # remove used fields from available list
        for my $Field ( sort keys %AssignedFields ) {
            delete $AvailableFields{$Field};
        }

        # sort by translated field names
        my %AvailableFieldsTranslated;
        for my $Field ( sort keys %AvailableFields ) {
            my $Translation = $LayoutObject->{LanguageObject}->Translate($Field);
            $AvailableFieldsTranslated{$Field} = $Translation;
        }

        # display available fields
        for my $Field (
            sort { $AvailableFieldsTranslated{$a} cmp $AvailableFieldsTranslated{$b} }
            keys %AvailableFieldsTranslated
            )
        {
            $LayoutObject->Block(
                Name => 'AvailableFieldRow',
                Data => {
                    Field               => $Field,
                    FieldnameTranslated => $AvailableFieldsTranslated{$Field},
                },
            );
        }

        # display used fields
        ASSIGNEDFIELD:
        for my $Field ( @{ $ActivityDialogData->{Config}->{FieldOrder} } ) {
            next ASSIGNEDFIELD if !$AssignedFields{$Field};

            my $FieldConfig = $ActivityDialogData->{Config}->{Fields}->{$Field};

            my $FieldConfigJSON = $Kernel::OM->Get('Kernel::System::JSON')->Encode(
                Data => $FieldConfig,
            );

            $LayoutObject->Block(
                Name => 'AssignedFieldRow',
                Data => {
                    Field       => $Field,
                    FieldConfig => $FieldConfigJSON,
                },
            );
        }

        # display other affected processes by editing this activity (if applicable)
        my $AffectedActivities = $Self->_CheckActivityDialogUsage(
            EntityID => $ActivityDialogData->{EntityID},
        );

        if ( @{$AffectedActivities} ) {

            $LayoutObject->Block(
                Name => 'EditWarning',
                Data => {
                    ActivityList => join( ', ', @{$AffectedActivities} ),
                }
            );
        }

        $Param{Title} = $LayoutObject->{LanguageObject}->Translate(
            'Edit Activity Dialog "%s"',
            $ActivityDialogData->{Name}
        );
    }
    else {

        # sort by translated field names
        my %AvailableFieldsTranslated;
        for my $Field ( sort keys %AvailableFields ) {
            my $Translation = $LayoutObject->{LanguageObject}->Translate($Field);
            $AvailableFieldsTranslated{$Field} = $Translation;
        }

        # display available fields
        for my $Field (
            sort { $AvailableFieldsTranslated{$a} cmp $AvailableFieldsTranslated{$b} }
            keys %AvailableFieldsTranslated
            )
        {
            $LayoutObject->Block(
                Name => 'AvailableFieldRow',
                Data => {
                    Field               => $Field,
                    FieldnameTranslated => $AvailableFieldsTranslated{$Field},
                },
            );
        }

        $Param{Title} = Translatable('Create New Activity Dialog');
    }

    # get interface infos
    if ( defined $ActivityDialogData->{Config}->{Interface} ) {
        my $InterfaceLength = scalar @{ $ActivityDialogData->{Config}->{Interface} };
        if ( $InterfaceLength == 2 ) {
            $ActivityDialogData->{Config}->{Interface} = 'BothInterfaces';
        }
        elsif ( $InterfaceLength == 1 ) {
            $ActivityDialogData->{Config}->{Interface} = $ActivityDialogData->{Config}->{Interface}->[0];
        }
        else {
            $ActivityDialogData->{Config}->{Interface} = 'AgentInterface';
        }
    }
    else {
        $ActivityDialogData->{Config}->{Interface} = 'AgentInterface';
    }

    # create interface selection
    $Param{InterfaceSelection} = $LayoutObject->BuildSelection(
        Data => {
            AgentInterface    => Translatable('Agent Interface'),
            CustomerInterface => Translatable('Customer Interface'),
            BothInterfaces    => Translatable('Agent and Customer Interface'),
        },
        Name         => 'Interface',
        ID           => 'Interface',
        SelectedID   => $ActivityDialogData->{Config}->{Interface} || '',
        Sort         => 'AlphanumericKey',
        Translation  => 1,
        PossibleNone => 0,
        Class        => 'Modernize',
    );

    # create permission selection
    $Param{PermissionSelection} = $LayoutObject->BuildSelection(
        Data         => $Kernel::OM->Get('Kernel::Config')->Get('System::Permission') || ['rw'],
        Name         => 'Permission',
        ID           => 'Permission',
        SelectedID   => $ActivityDialogData->{Config}->{Permission} || '',
        Sort         => 'AlphanumericKey',
        Translation  => 1,
        PossibleNone => 1,
        Class        => 'Modernize' . ( $Param{PermissionServerError} || '' ),
    );

    # create "required lock" selection
    $Param{RequiredLockSelection} = $LayoutObject->BuildSelection(
        Data => {
            0 => Translatable('No'),
            1 => Translatable('Yes'),
        },
        Name        => 'RequiredLock',
        ID          => 'RequiredLock',
        SelectedID  => $ActivityDialogData->{Config}->{RequiredLock} || 0,
        Sort        => 'AlphanumericKey',
        Translation => 1,
        Class       => 'Modernize ' . ( $Param{RequiredLockServerError} || '' ),
    );

    # create Display selection
    $Param{DisplaySelection} = $LayoutObject->BuildSelection(
        Data => {
            0 => Translatable('Do not show Field'),
            1 => Translatable('Show Field'),
            2 => Translatable('Show Field As Mandatory'),
        },
        Name        => 'Display',
        ID          => 'Display',
        Sort        => 'AlphanumericKey',
        Translation => 1,
        Class       => 'Modernize',
    );

    my @ChannelList = $Kernel::OM->Get('Kernel::System::CommunicationChannel')->ChannelList();

    # Allow only Internal and Phone communication channels, this has to be hard coded at the moment.
    my %Channels = map { $_->{ChannelName} => $_->{DisplayName} }
        grep { $_->{ChannelName} eq 'Internal' || $_->{ChannelName} eq 'Phone' }
        @ChannelList;

    # create Communication Channel selection ()
    $Param{CommunicationChannelSelection} = $LayoutObject->BuildSelection(
        Data          => \%Channels,
        SelectedValue => 'Internal',
        Name          => 'CommunicationChannel',
        ID            => 'CommunicationChannel',
        Sort          => 'Alphanumeric',
        Translation   => 1,
        Class         => 'Modernize',
    );

    my %TimeUnitsSelectionList = (
        0 => Translatable('Do not show Field'),
        2 => Translatable('Show Field As Mandatory'),
    );

    if ( !$ConfigObject->Get('Ticket::Frontend::NeedAccountedTime') ) {
        $TimeUnitsSelectionList{1} = 'Show Field';
    }

    # create TimeUnits selection
    my %StandardTemplates = $StandardTemplateObject->StandardTemplateList(
        Valid => 1,
        Type  => 'ProcessManagement',
    );

    if (%StandardTemplates) {
        $Param{StandardTemplateSelection} = $LayoutObject->BuildSelection(
            Data         => \%StandardTemplates,
            ID           => 'StandardTemplateID',
            Name         => 'StandardTemplateID',
            SelectedID   => $Param{StandardTemplateID} || '',
            Class        => 'Modernize',
            PossibleNone => 1,
            Sort         => 'AlphanumericValue',
            Translation  => 1,
            Multiple     => 1,
            Max          => 200,
        );

        $LayoutObject->Block(
            Name => 'StandardTemplateContainer',
            Data => \%Param,
        );
    }

    # create TimeUnits selection
    if ( $ConfigObject->Get('Ticket::Frontend::AccountTime') ) {

        $Param{TimeUnitsSelection} = $LayoutObject->BuildSelection(
            Data          => \%TimeUnitsSelectionList,
            SelectedValue => 0,
            Name          => 'TimeUnits',
            ID            => 'TimeUnits',
            Translation   => 1,
            Class         => 'Modernize',
        );

        $LayoutObject->Block(
            Name => 'TimeUnitsContainer',
            Data => \%Param,
        );
    }

    # extract parameters from config
    $Param{DescriptionShort} = $Param{ActivityDialogData}->{Config}->{DescriptionShort};
    $Param{DescriptionLong}  = $Param{ActivityDialogData}->{Config}->{DescriptionLong};
    $Param{SubmitAdviceText} = $Param{ActivityDialogData}->{Config}->{SubmitAdviceText};
    $Param{SubmitButtonText} = $Param{ActivityDialogData}->{Config}->{SubmitButtonText};

    $Param{ScopeSelection} = $LayoutObject->BuildSelection(
        Data => {
            Global  => 'Global',
            Process => 'Process',
        },
        Name           => 'Scope',
        ID             => 'Scope',
        SelectedID     => $Param{ActivityDialogData}->{Config}->{Scope} || 'Global',
        Sort           => 'IndividualKey',
        SortIndividual => [ 'Global', 'Process' ],
        Translation    => 1,
        Class          => 'Modernize W50pc ',
    );

    my $ProcessList = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Process')->ProcessList(
        UserID      => 1,
        UseEntities => 1,
    );

    $Param{ScopeEntityIDSelection} = $LayoutObject->BuildSelection(
        Data        => $ProcessList,
        Name        => 'ScopeEntityID',
        ID          => 'ScopeEntityID',
        SelectedID  => $Param{ActivityDialogData}->{Config}->{ScopeEntityID} // $GetParam->{ProcessEntityID},
        Sort        => 'AlphanumericValue',
        Translation => 1,
        Class       => 'Modernize W50pc ',
    );

    my $Output = $LayoutObject->Header(
        Value => $Param{Title},
        Type  => 'Small',
    );
    $Output .= $LayoutObject->Output(
        TemplateFile => "AdminProcessManagementActivityDialog",
        Data         => {
            %Param,
            %{$ActivityDialogData},
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
    for my $ParamName (qw( Name EntityID)) {
        $GetParam->{$ParamName} = $ParamObject->GetParam( Param => $ParamName ) || '';
    }

    for my $ParamName (
        qw( Interface DescriptionShort DescriptionLong Permission RequiredLock Scope ScopeEntityID SubmitAdviceText
        SubmitButtonText ProcessEntityID)
        )
    {
        $GetParam->{Config}->{$ParamName} = $ParamObject->GetParam( Param => $ParamName ) || '';
    }
    $GetParam->{Config}->{Scope} //= 'Global';
    if ( $GetParam->{Config}->{Scope} eq 'Global' ) {
        delete $GetParam->{Config}->{ScopeEntityID};
    }

    my $Fields     = $ParamObject->GetParam( Param => 'Fields' ) || '';
    my $JSONObject = $Kernel::OM->Get('Kernel::System::JSON');

    if ($Fields) {
        $GetParam->{Config}->{Fields} = $JSONObject->Decode(
            Data => $Fields,
        );
    }
    else {
        $GetParam->{Config}->{Fields} = '';
    }

    my $FieldDetails = $ParamObject->GetParam( Param => 'FieldDetails' ) || '';

    if ($FieldDetails) {
        $GetParam->{Config}->{FieldDetails} = $JSONObject->Decode(
            Data => $FieldDetails,
        );
    }
    else {
        $GetParam->{Config}->{FieldDetails} = '';
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
    my $JSONScreensPath = my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout')->JSONEncode(
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
        Action          => $Self->{Action} || '',
        Subaction       => $Param{Subaction},
        ID              => $Param{ID},
        EntityID        => $Param{EntityID},
        ProcessEntityID => $Param{ProcessEntityID},
    };

    # convert screens path to string (JSON)
    my $JSONScreensPath = my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout')->JSONEncode(
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

sub _CheckActivityDialogUsage {
    my ( $Self, %Param ) = @_;

    # get a list of parents with all the details
    my $List = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Activity')->ActivityListGet(
        UserID => 1,
    );

    my @Usage;

    # search entity id in all parents
    PARENT:
    for my $ParentData ( @{$List} ) {
        next PARENT if !$ParentData;
        next PARENT if !$ParentData->{ActivityDialogs};
        ENTITY:
        for my $EntityID ( @{ $ParentData->{ActivityDialogs} } ) {
            if ( $EntityID eq $Param{EntityID} ) {
                push @Usage, $ParentData->{Name};
                last ENTITY;
            }
        }
    }

    return \@Usage;
}

1;
