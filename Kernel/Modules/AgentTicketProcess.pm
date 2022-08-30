# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Modules::AgentTicketProcess;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);
use Kernel::Language qw(Translatable);

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless $Self, $Type;

    # global config hash for id dissolution
    $Self->{NameToID} = {
        Title              => 'Title',
        State              => 'StateID',
        StateID            => 'StateID',
        Priority           => 'PriorityID',
        PriorityID         => 'PriorityID',
        Lock               => 'LockID',
        LockID             => 'LockID',
        Queue              => 'QueueID',
        QueueID            => 'QueueID',
        Customer           => 'CustomerID',
        CustomerID         => 'CustomerID',
        CustomerNo         => 'CustomerID',
        CustomerUserID     => 'CustomerUserID',
        Owner              => 'OwnerID',
        OwnerID            => 'OwnerID',
        Type               => 'TypeID',
        TypeID             => 'TypeID',
        SLA                => 'SLAID',
        SLAID              => 'SLAID',
        Service            => 'ServiceID',
        ServiceID          => 'ServiceID',
        StandardTemplateID => 'StandardTemplateID',
        Responsible        => 'ResponsibleID',
        ResponsibleID      => 'ResponsibleID',
        PendingTime        => 'PendingTime',
        Article            => 'Article',
        Attachments        => 'Attachments',
    };

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # get param object
    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');

    my $TicketID               = $ParamObject->GetParam( Param => 'TicketID' );
    my $ActivityDialogEntityID = $ParamObject->GetParam( Param => 'ActivityDialogEntityID' );
    my $ActivityDialogHashRef;

    # get needed objects
    my $ActivityDialogObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::ActivityDialog');
    my $LayoutObject         = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $TicketObject         = $Kernel::OM->Get('Kernel::System::Ticket');

    $Self->{FirstActivityDialog} = $ParamObject->GetParam( Param => 'FirstActivityDialog' );
    $Self->{LinkTicketID}        = $ParamObject->GetParam( Param => 'LinkTicketID' ) || '';
    $Self->{ArticleID}           = $ParamObject->GetParam( Param => 'ArticleID' ) || '';

    # get the ticket information on link actions
    if ( $Self->{LinkTicketID} ) {
        my %TicketData = $TicketObject->TicketGet(
            TicketID => $Self->{LinkTicketID},
            UserID   => $Self->{UserID},
            Extended => 1,
        );
        $Self->{LinkTicketData} = \%TicketData;

        # set LinkTicketID param for showing on main form
        $Param{LinkTicketID} = $Self->{LinkTicketID};
    }

    # get the article information on link actions
    if ( $Self->{ArticleID} ) {
        my $ArticleBackendObject = $Kernel::OM->Get('Kernel::System::Ticket::Article')->BackendForArticle(
            TicketID  => $Self->{LinkTicketID},
            ArticleID => $Self->{ArticleID},
        );

        my %Article = $ArticleBackendObject->ArticleGet(
            TicketID  => $Self->{LinkTicketID},
            ArticleID => $Self->{ArticleID},
        );

        $Self->{LinkArticleData} = \%Article;

        # set ArticleID param for showing on main form
        $Param{ArticleID} = $Self->{ArticleID};
    }

    if ($TicketID) {

        # check if there is a configured required permission
        # for the ActivityDialog (if there is one)
        my $ActivityDialogPermission = 'rw';
        if ($ActivityDialogEntityID) {
            $ActivityDialogHashRef = $ActivityDialogObject->ActivityDialogGet(
                ActivityDialogEntityID => $ActivityDialogEntityID,
                Interface              => 'AgentInterface',
            );

            if ( !IsHashRefWithData($ActivityDialogHashRef) ) {
                return $LayoutObject->ErrorScreen(
                    Message => $LayoutObject->{LanguageObject}->Translate(
                        'Couldn\'t get ActivityDialogEntityID "%s"!',
                        $ActivityDialogEntityID,
                    ),
                    Comment => Translatable('Please contact the administrator.'),
                );
            }

            if ( $ActivityDialogHashRef->{Permission} ) {
                $ActivityDialogPermission = $ActivityDialogHashRef->{Permission};
            }
        }

        # check permissions
        my $Access = $TicketObject->TicketPermission(
            Type     => $ActivityDialogPermission,
            TicketID => $Self->{TicketID},
            UserID   => $Self->{UserID}
        );

        # error screen, don't show ticket
        if ( !$Access ) {
            return $LayoutObject->NoPermission(
                Message =>
                    $LayoutObject->{LanguageObject}->Translate( 'You need %s permissions!', $ActivityDialogPermission ),
                WithHeader => 'yes',
            );
        }

        # get ACL restrictions
        my %PossibleActions = ( 1 => $Self->{Action} );

        my $ACL = $TicketObject->TicketAcl(
            Data          => \%PossibleActions,
            Action        => $Self->{Action},
            TicketID      => $Self->{TicketID},
            ReturnType    => 'Action',
            ReturnSubType => '-',
            UserID        => $Self->{UserID},
        );
        my %AclAction = $TicketObject->TicketAclActionData();

        # check if ACL restrictions exist
        if ( $ACL || IsHashRefWithData( \%AclAction ) ) {

            my %AclActionLookup = reverse %AclAction;

            # show error screen if ACL prohibits this action
            if ( !$AclActionLookup{ $Self->{Action} } ) {
                return $LayoutObject->NoPermission( WithHeader => 'yes' );
            }
        }

        if ( IsHashRefWithData($ActivityDialogHashRef) ) {

            # check if it's already locked by somebody else
            if ( $ActivityDialogHashRef->{RequiredLock} ) {

                if ( $TicketObject->TicketLockGet( TicketID => $TicketID ) ) {
                    my $AccessOk = $TicketObject->OwnerCheck(
                        TicketID => $TicketID,
                        OwnerID  => $Self->{UserID},
                    );
                    if ( !$AccessOk ) {
                        my $Output = $LayoutObject->Header(
                            Type => 'Small',
                        );
                        $Output .= $LayoutObject->Warning(
                            Message => Translatable('Sorry, you need to be the ticket owner to perform this action.'),
                            Comment => Translatable('Please change the owner first.'),
                        );
                        $Output .= $LayoutObject->Footer(
                            Type => 'Small',
                        );
                        return $Output;
                    }
                }
                else {

                    my %Ticket = $TicketObject->TicketGet(
                        TicketID => $TicketID,
                    );

                    my $Lock = $TicketObject->TicketLockSet(
                        TicketID => $TicketID,
                        Lock     => 'lock',
                        UserID   => $Self->{UserID}
                    );

                    # Set new owner if ticket owner is different then logged user.
                    if ( $Lock && ( $Ticket{OwnerID} != $Self->{UserID} ) ) {

                        # Remember previous owner, which will be used to restore ticket owner on undo action.
                        $Param{PreviousOwner} = $Ticket{OwnerID};

                        my $Success = $TicketObject->TicketOwnerSet(
                            TicketID  => $TicketID,
                            UserID    => $Self->{UserID},
                            NewUserID => $Self->{UserID},
                        );

                        # Reload the parent window to show the updated lock state.
                        $Param{ParentReload} = 1;

                        # Show lock state link.
                        $Param{RenderLocked} = 1;
                    }

                    my $TicketNumber = $TicketObject->TicketNumberLookup(
                        TicketID => $TicketID,
                        UserID   => $Self->{UserID},
                    );

                    # notify the agent that the ticket was locked
                    push @{ $Param{Notify} }, {
                        Priority => 'Notice',
                        Data     => "$TicketNumber: " . $LayoutObject->{LanguageObject}->Translate("Ticket locked."),
                    };
                }
            }

            my $PossibleActivityDialogs = { 1 => $ActivityDialogEntityID };

            # get ACL restrictions
            my $ACL = $TicketObject->TicketAcl(
                Data                   => $PossibleActivityDialogs,
                ActivityDialogEntityID => $ActivityDialogEntityID,
                TicketID               => $TicketID,
                ReturnType             => 'ActivityDialog',
                ReturnSubType          => '-',
                Action                 => $Self->{Action},
                UserID                 => $Self->{UserID},
            );

            if ($ACL) {
                %{$PossibleActivityDialogs} = $TicketObject->TicketAclData();
            }

            # check if ACL restrictions exist
            if ( !IsHashRefWithData($PossibleActivityDialogs) )
            {
                return $LayoutObject->NoPermission( WithHeader => 'yes' );
            }
        }
    }

    # list only Active processes by default
    my @ProcessStates = ('Active');

    # set IsMainWindow, IsAjaxRequest, IsProcessEnroll for proper error responses, screen display
    # and process list
    $Self->{IsMainWindow}    = $ParamObject->GetParam( Param => 'IsMainWindow' )    || '';
    $Self->{IsAjaxRequest}   = $ParamObject->GetParam( Param => 'IsAjaxRequest' )   || '';
    $Self->{IsProcessEnroll} = $ParamObject->GetParam( Param => 'IsProcessEnroll' ) || '';

    # fetch also FadeAway processes to continue working with existing tickets, but not to start new
    #    ones
    if ( !$Self->{IsMainWindow} && $Self->{Subaction} ) {
        push @ProcessStates, 'FadeAway';
    }

    # create process object
    $Kernel::OM->ObjectParamAdd(
        'Kernel::System::ProcessManagement::Process' => {
            ActivityObject         => $Kernel::OM->Get('Kernel::System::ProcessManagement::Activity'),
            ActivityDialogObject   => $ActivityDialogObject,
            TransitionObject       => $Kernel::OM->Get('Kernel::System::ProcessManagement::Transition'),
            TransitionActionObject => $Kernel::OM->Get('Kernel::System::ProcessManagement::TransitionAction'),
        }
    );
    my $ProcessObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::Process');

    # get processes
    my $ProcessList = $ProcessObject->ProcessList(
        ProcessState => \@ProcessStates,
        Interface    => ['AgentInterface'],
    );

    # also get the list of processes initiated by customers, as an activity dialog might be
    # configured for the agent interface
    my $FollowupProcessList = $ProcessObject->ProcessList(
        ProcessState => \@ProcessStates,
        Interface    => [ 'AgentInterface', 'CustomerInterface' ],
    );

    my $ProcessEntityID = $ParamObject->GetParam( Param => 'ProcessEntityID' );

    if ( !IsHashRefWithData($ProcessList) && !IsHashRefWithData($FollowupProcessList) ) {
        return $LayoutObject->ErrorScreen(
            Message => Translatable('No Process configured!'),
            Comment => Translatable('Please contact the administrator.'),
        );
    }

    # prepare process list for ACLs, use only entities instead of names, convert from
    #   P1 => Name to P1 => P1. As ACLs should work only against entities
    my %ProcessListACL = map { $_ => $_ } sort keys %{$ProcessList};

    # validate the ProcessList with stored ACLs
    my $ACL = $TicketObject->TicketAcl(
        ReturnType    => 'Process',
        ReturnSubType => '-',
        Data          => \%ProcessListACL,
        Action        => $Self->{Action},
        UserID        => $Self->{UserID},
        TicketID      => $TicketID,
    );

    if ( IsHashRefWithData($ProcessList) && $ACL ) {

        # get ACL results
        my %ACLData = $TicketObject->TicketAclData();

        # recover process names
        my %ReducedProcessList = map { $_ => $ProcessList->{$_} } sort keys %ACLData;

        # replace original process list with the reduced one
        $ProcessList = \%ReducedProcessList;
    }

    # get form id
    $Self->{FormID} = $ParamObject->GetParam( Param => 'FormID' );

    # create form id
    if ( !$Self->{FormID} ) {
        $Self->{FormID} = $Kernel::OM->Get('Kernel::System::Web::UploadCache')->FormIDCreate();
    }

    # if we have no subaction display the process list to start a new one
    if ( !$Self->{Subaction} ) {

        # to display the process list is mandatory to have processes that agent can start
        if ( !IsHashRefWithData($ProcessList) ) {
            return $LayoutObject->ErrorScreen(
                Message => Translatable('No Process configured!'),
                Comment => Translatable('Please contact the administrator.'),
            );
        }

        # get process id (if any, a process should be pre-selected)
        $Param{ProcessID} = $ParamObject->GetParam( Param => 'ID' );
        if ( $Param{ProcessID} ) {
            $Param{PreSelectProcess} = 1;
        }

        return $Self->_DisplayProcessList(
            %Param,
            ProcessList     => $ProcessList,
            ProcessEntityID => $ProcessEntityID || $Param{ProcessID},
            TicketID        => $TicketID,
        );
    }

    # check if the selected process from the list is valid, prevent tamper with process selection
    #    list (not existing, invalid an fade away processes must not be able to start a new process
    #    ticket)
    elsif (
        $Self->{Subaction} eq 'DisplayActivityDialogAJAX'
        && !$ProcessList->{$ProcessEntityID}
        && $Self->{IsMainWindow}
        )
    {

        # translate the error message (as it will be injected in the HTML)
        my $ErrorMessage = $LayoutObject->{LanguageObject}->Translate("The selected process is invalid!");

        # return a predefined HTML structure as the AJAX call is expecting and HTML response
        return $LayoutObject->Attachment(
            ContentType => 'text/html; charset=' . $LayoutObject->{Charset},
            Content     => '<div class="ServerError" data-message="' . $ErrorMessage . '"></div>',
            Type        => 'inline',
            NoCache     => 1,
        );
    }

    # if invalid process is detected on an ActivityDialog pop-up screen show an error message
    elsif (
        $Self->{Subaction} eq 'DisplayActivityDialog'
        && !$FollowupProcessList->{$ProcessEntityID}
        && !$Self->{IsMainWindow}
        )
    {
        $LayoutObject->FatalError(
            Message => $LayoutObject->{LanguageObject}->Translate( 'Process %s is invalid!', $ProcessEntityID ),
            Comment => Translatable('Please contact the administrator.'),
        );
    }

    # Get the necessary parameters
    # collects a mixture of present values bottom to top:
    # SysConfig DefaultValues, ActivityDialog DefaultValues, TicketValues, SubmittedValues
    # including ActivityDialogEntityID and ProcessEntityID
    # is used for:
    # - Parameter checking before storing
    # - will be used for ACL checking later on
    my $GetParam = $Self->_GetParam(
        ProcessEntityID => $ProcessEntityID,
    );

    if ( $Self->{Subaction} eq 'StoreActivityDialog' && $ProcessEntityID ) {
        $LayoutObject->ChallengeTokenCheck();

        return $Self->_StoreActivityDialog(
            %Param,
            ProcessName     => $ProcessList->{$ProcessEntityID},
            ProcessEntityID => $ProcessEntityID,
            GetParam        => $GetParam,
        );
    }
    if ( $Self->{Subaction} eq 'DisplayActivityDialog' && $ProcessEntityID ) {

        return $Self->_OutputActivityDialog(
            %Param,
            ProcessEntityID => $ProcessEntityID,
            GetParam        => $GetParam,
        );
    }
    if ( $Self->{Subaction} eq 'DisplayActivityDialogAJAX' && $ProcessEntityID ) {

        my $ActivityDialogHTML = $Self->_OutputActivityDialog(
            %Param,
            ProcessEntityID => $ProcessEntityID,
            GetParam        => $GetParam,
        );
        return $LayoutObject->Attachment(
            ContentType => 'text/html; charset=' . $LayoutObject->{Charset},
            Content     => $ActivityDialogHTML,
            Type        => 'inline',
            NoCache     => 1,
        );

    }
    elsif ( $Self->{Subaction} eq 'AJAXUpdate' ) {

        return $Self->_RenderAjax(
            %Param,
            ProcessEntityID => $ProcessEntityID,
            GetParam        => $GetParam,
        );
    }
    return $LayoutObject->ErrorScreen(
        Message => Translatable('Subaction is invalid!'),
        Comment => Translatable('Please contact the administrator.'),
    );
}

sub _RenderAjax {
    my ( $Self, %Param ) = @_;

    # get layout object
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # FatalError is safe because a JSON structure is expecting, then it will result into a
    # communications error

    for my $Needed (qw(ProcessEntityID)) {
        if ( !$Param{$Needed} ) {
            $LayoutObject->FatalError(
                Message => $LayoutObject->{LanguageObject}
                    ->Translate( 'Parameter %s is missing in %s.', $Needed, '_RenderAjax' ),
            );
        }
    }
    my $ActivityDialogEntityID = $Param{GetParam}{ActivityDialogEntityID};
    if ( !$ActivityDialogEntityID ) {
        $LayoutObject->FatalError(
            Message => $LayoutObject->{LanguageObject}
                ->Translate( 'Parameter %s is missing in %s.', 'ActivityDialogEntityID', '_RenderAjax' ),
        );
    }
    my $ActivityDialog = $Kernel::OM->Get('Kernel::System::ProcessManagement::ActivityDialog')->ActivityDialogGet(
        ActivityDialogEntityID => $ActivityDialogEntityID,
        Interface              => 'AgentInterface',
    );

    if ( !IsHashRefWithData($ActivityDialog) ) {
        $LayoutObject->FatalError(
            Message => $LayoutObject->{LanguageObject}->Translate(
                'No ActivityDialog configured for %s in _RenderAjax!',
                $ActivityDialogEntityID,
            ),
        );
    }

    # get list type
    my $TreeView = 0;
    if ( $Kernel::OM->Get('Kernel::Config')->Get('Ticket::Frontend::ListType') eq 'tree' ) {
        $TreeView = 1;
    }

    my %FieldsProcessed;
    my @JSONCollector;

    my $Services;

    # All submitted DynamicFields
    # get dynamic field values form http request
    my %DynamicFieldValues;

    my $DynamicField = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldListGet(
        Valid      => 1,
        ObjectType => 'Ticket',
    );

    # get needed object
    my $ParamObject               = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    # cycle trough the activated Dynamic Fields for this screen
    DYNAMICFIELD:
    for my $DynamicFieldConfig ( @{$DynamicField} ) {
        next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

        # extract the dynamic field value from the web request
        $DynamicFieldValues{ $DynamicFieldConfig->{Name} } = $DynamicFieldBackendObject->EditFieldValueGet(
            DynamicFieldConfig => $DynamicFieldConfig,
            ParamObject        => $ParamObject,
            LayoutObject       => $LayoutObject,
        );
    }

    # convert dynamic field values into a structure for ACLs
    my %DynamicFieldCheckParam;
    DYNAMICFIELD:
    for my $DynamicFieldItem ( sort keys %DynamicFieldValues ) {
        next DYNAMICFIELD if !$DynamicFieldItem;
        next DYNAMICFIELD if !defined $DynamicFieldValues{$DynamicFieldItem};
        next DYNAMICFIELD if !length $DynamicFieldValues{$DynamicFieldItem};

        $DynamicFieldCheckParam{ 'DynamicField_' . $DynamicFieldItem } = $DynamicFieldValues{$DynamicFieldItem};
    }
    $Param{GetParam}->{DynamicField} = \%DynamicFieldCheckParam;

    # Get the activity dialog's Submit Param's or Config Params
    DIALOGFIELD:
    for my $CurrentField ( @{ $ActivityDialog->{FieldOrder} } ) {

        # Skip if we're working on a field that was already done with or without ID
        if (
            $Self->{NameToID}{$CurrentField}
            && $FieldsProcessed{ $Self->{NameToID}{$CurrentField} }
            )
        {
            next DIALOGFIELD;
        }

        if ( $CurrentField =~ m{^DynamicField_(.*)}xms ) {
            my $DynamicFieldName = $1;

            my $DynamicFieldConfig = ( grep { $_->{Name} eq $DynamicFieldName } @{$DynamicField} )[0];

            next DIALOGFIELD if !IsHashRefWithData($DynamicFieldConfig);

            my $IsACLReducible = $DynamicFieldBackendObject->HasBehavior(
                DynamicFieldConfig => $DynamicFieldConfig,
                Behavior           => 'IsACLReducible',
            );
            next DIALOGFIELD if !$IsACLReducible;

            my $PossibleValues = $DynamicFieldBackendObject->PossibleValuesGet(
                DynamicFieldConfig => $DynamicFieldConfig,
            );

            # convert possible values key => value to key => key for ACLs using a Hash slice
            my %AclData = %{$PossibleValues};
            @AclData{ keys %AclData } = keys %AclData;

            # get ticket object
            my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

            # set possible values filter from ACLs
            my $ACL = $TicketObject->TicketAcl(
                %{ $Param{GetParam} },
                ReturnType    => 'Ticket',
                ReturnSubType => 'DynamicField_' . $DynamicFieldConfig->{Name},
                Data          => \%AclData,
                Action        => $Self->{Action},
                UserID        => $Self->{UserID},
            );

            if ($ACL) {
                my %Filter = $TicketObject->TicketAclData();

                # convert Filer key => key back to key => value using map
                %{$PossibleValues} = map { $_ => $PossibleValues->{$_} } keys %Filter;
            }

            my $DataValues = $DynamicFieldBackendObject->BuildSelectionDataGet(
                DynamicFieldConfig => $DynamicFieldConfig,
                PossibleValues     => $PossibleValues,
                Value              => $DynamicFieldValues{ $DynamicFieldConfig->{Name} },
            ) || $PossibleValues;

            # add dynamic field to the JSONCollector
            push(
                @JSONCollector,
                {
                    Name        => 'DynamicField_' . $DynamicFieldConfig->{Name},
                    Data        => $DataValues,
                    SelectedID  => $DynamicFieldValues{ $DynamicFieldConfig->{Name} },
                    Translation => $DynamicFieldConfig->{Config}->{TranslatableValues} || 0,
                    Max         => 100,
                }
            );
        }
        elsif ( $Self->{NameToID}{$CurrentField} eq 'OwnerID' ) {
            next DIALOGFIELD if $FieldsProcessed{ $Self->{NameToID}{$CurrentField} };

            my $Data = $Self->_GetOwners(
                %{ $Param{GetParam} },
            );

            # add Owner to the JSONCollector
            push(
                @JSONCollector,
                {
                    Name         => $Self->{NameToID}{$CurrentField},
                    Data         => $Data,
                    SelectedID   => $Param{GetParam}{ $Self->{NameToID}{$CurrentField} },
                    PossibleNone => 1,
                    Translation  => 0,
                    Max          => 100,
                },
            );
            $FieldsProcessed{ $Self->{NameToID}{$CurrentField} } = 1;
        }
        elsif ( $Self->{NameToID}{$CurrentField} eq 'ResponsibleID' ) {
            next DIALOGFIELD if $FieldsProcessed{ $Self->{NameToID}{$CurrentField} };

            my $Data = $Self->_GetResponsibles(
                %{ $Param{GetParam} },
            );

            # add Responsible to the JSONCollector
            push(
                @JSONCollector,
                {
                    Name         => $Self->{NameToID}{$CurrentField},
                    Data         => $Data,
                    SelectedID   => $Param{GetParam}{ $Self->{NameToID}{$CurrentField} },
                    PossibleNone => 1,
                    Translation  => 0,
                    Max          => 100,
                },
            );
            $FieldsProcessed{ $Self->{NameToID}{$CurrentField} } = 1;
        }
        elsif ( $Self->{NameToID}{$CurrentField} eq 'QueueID' ) {
            next DIALOGFIELD if $FieldsProcessed{ $Self->{NameToID}{$CurrentField} };

            my $Data = $Self->_GetQueues(
                %{ $Param{GetParam} },
            );

            # add Queue to the JSONCollector
            push(
                @JSONCollector,
                {
                    Name         => $Self->{NameToID}{$CurrentField},
                    Data         => $Data,
                    SelectedID   => $Param{GetParam}{ $Self->{NameToID}{$CurrentField} },
                    PossibleNone => 1,
                    Translation  => 0,
                    TreeView     => $TreeView,
                    Max          => 100,
                },
            );
            $FieldsProcessed{ $Self->{NameToID}{$CurrentField} } = 1;
        }

        elsif ( $Self->{NameToID}{$CurrentField} eq 'StateID' ) {
            next DIALOGFIELD if $FieldsProcessed{ $Self->{NameToID}{$CurrentField} };

            my $Data = $Self->_GetStates(
                %{ $Param{GetParam} },
            );

            # add State to the JSONCollector
            push(
                @JSONCollector,
                {
                    Name        => 'StateID',
                    Data        => $Data,
                    SelectedID  => $Param{GetParam}{ $Self->{NameToID}{$CurrentField} },
                    Translation => 1,
                    Max         => 100,
                },
            );
            $FieldsProcessed{ $Self->{NameToID}{$CurrentField} } = 1;
        }
        elsif ( $Self->{NameToID}{$CurrentField} eq 'PriorityID' ) {
            next DIALOGFIELD if $FieldsProcessed{ $Self->{NameToID}{$CurrentField} };

            my $Data = $Self->_GetPriorities(
                %{ $Param{GetParam} },
            );

            # add Priority to the JSONCollector
            push(
                @JSONCollector,
                {
                    Name        => $Self->{NameToID}{$CurrentField},
                    Data        => $Data,
                    SelectedID  => $Param{GetParam}{ $Self->{NameToID}{$CurrentField} },
                    Translation => 1,
                    Max         => 100,
                },
            );
            $FieldsProcessed{ $Self->{NameToID}{$CurrentField} } = 1;
        }
        elsif ( $Self->{NameToID}{$CurrentField} eq 'ServiceID' ) {
            next DIALOGFIELD if $FieldsProcessed{ $Self->{NameToID}{$CurrentField} };

            my $Data = $Self->_GetServices(
                %{ $Param{GetParam} },
            );
            $Services = $Data;

            # add Service to the JSONCollector (Use ServiceID from web request)
            push(
                @JSONCollector,
                {
                    Name         => $Self->{NameToID}{$CurrentField},
                    Data         => $Data,
                    SelectedID   => $ParamObject->GetParam( Param => 'ServiceID' ) || '',
                    PossibleNone => 1,
                    Translation  => 0,
                    TreeView     => $TreeView,
                    Max          => 100,
                },
            );
            $FieldsProcessed{ $Self->{NameToID}{$CurrentField} } = 1;
        }
        elsif ( $Self->{NameToID}{$CurrentField} eq 'SLAID' ) {
            next DIALOGFIELD if $FieldsProcessed{ $Self->{NameToID}{$CurrentField} };

            # if SLA is render before service (by it order in the fields) it needs to create
            # the service list
            if ( !IsHashRefWithData($Services) ) {
                $Services = $Self->_GetServices(
                    %{ $Param{GetParam} },
                );
            }

            my $Data = $Self->_GetSLAs(
                %{ $Param{GetParam} },
                Services  => $Services,
                ServiceID => $ParamObject->GetParam( Param => 'ServiceID' ) || '',
            );

            # add SLA to the JSONCollector (Use SelectedID from web request)
            push(
                @JSONCollector,
                {
                    Name         => $Self->{NameToID}{$CurrentField},
                    Data         => $Data,
                    SelectedID   => $ParamObject->GetParam( Param => 'SLAID' ) || '',
                    PossibleNone => 1,
                    Translation  => 0,
                    Max          => 100,
                },
            );
            $FieldsProcessed{ $Self->{NameToID}{$CurrentField} } = 1;
        }
        elsif ( $Self->{NameToID}{$CurrentField} eq 'TypeID' ) {
            next DIALOGFIELD if $FieldsProcessed{ $Self->{NameToID}{$CurrentField} };

            my $Data = $Self->_GetTypes(
                %{ $Param{GetParam} },
            );

            # Add Type to the JSONCollector (Use SelectedID from web request).
            push(
                @JSONCollector,
                {
                    Name         => $Self->{NameToID}{$CurrentField},
                    Data         => $Data,
                    SelectedID   => $ParamObject->GetParam( Param => 'TypeID' ) || '',
                    PossibleNone => 1,
                    Translation  => 0,
                    Max          => 100,
                },
            );
            $FieldsProcessed{ $Self->{NameToID}{$CurrentField} } = 1;
        }
        elsif ( $Self->{NameToID}{$CurrentField} eq 'Article' ) {
            next DIALOGFIELD if $FieldsProcessed{ $Self->{NameToID}{$CurrentField} };

            my $TemplateGeneratorObject = $Kernel::OM->Get('Kernel::System::TemplateGenerator');
            my $StandardTemplateObject  = $Kernel::OM->Get('Kernel::System::StandardTemplate');
            my $StdAttachmentObject     = $Kernel::OM->Get('Kernel::System::StdAttachment');
            my $UploadCacheObject       = $Kernel::OM->Get('Kernel::System::Web::UploadCache');

            my %StandardTemplate = $StandardTemplateObject->StandardTemplateGet(
                ID => $Param{GetParam}->{StandardTemplateID},
            );

            # remove pre-submitted attachments
            $UploadCacheObject->FormIDRemove( FormID => $Self->{FormID} );

            my $StandardTemplateText = $TemplateGeneratorObject->_Replace(
                RichText => $LayoutObject->{BrowserRichText},
                Text     => $StandardTemplate{Template},
                Data     => {
                    %{ $Param{GetParam} },
                },
                TicketData => {
                    %{ $Param{GetParam} },
                },
                UserID => $Self->{UserID},
            );

            # add standard attachments to ticket
            my @TicketAttachments;
            my %AllStdAttachments = $StdAttachmentObject->StdAttachmentStandardTemplateMemberList(
                StandardTemplateID => $Param{GetParam}->{StandardTemplateID},
            );
            for my $ID ( sort keys %AllStdAttachments ) {
                my %AttachmentsData = $StdAttachmentObject->StdAttachmentGet( ID => $ID );
                $UploadCacheObject->FormIDAddFile(
                    FormID      => $Self->{FormID},
                    Disposition => 'attachment',
                    %AttachmentsData,
                );
            }

            @TicketAttachments = $UploadCacheObject->FormIDGetAllFilesMeta(
                FormID => $Self->{FormID},
            );

            for my $Attachment (@TicketAttachments) {
                $Attachment->{Filesize} = $LayoutObject->HumanReadableDataSize(
                    Size => $Attachment->{Filesize},
                );
            }

            push(
                @JSONCollector,
                {
                    Name => 'RichText',
                    Data => $StandardTemplateText // '',
                },
                {
                    Name     => 'TicketAttachments',
                    Data     => \@TicketAttachments,
                    KeepData => 1,
                },
            );

            $FieldsProcessed{ $Self->{NameToID}{$CurrentField} } = 1;
        }
    }

    my $JSON = $LayoutObject->BuildSelectionJSON( [@JSONCollector] );

    return $LayoutObject->Attachment(
        ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
        Content     => $JSON,
        Type        => 'inline',
        NoCache     => 1,
    );
}

# =cut
#
# _GetParam()
#
# returns the current data state of the submitted information
#
# This contains the following data for the different callers:
#
#     Initial call with selected Process:
#         ProcessEntityID
#         ActivityDialogEntityID
#         DefaultValues for the configured Fields in that ActivityDialog
#         DefaultValues for the 4 required Fields Queue State Lock Priority
#
#     First Store call submitting an Activity Dialog:
#         ProcessEntityID
#         ActivityDialogEntityID
#         SubmittedValues for the current ActivityDialog
#         ActivityDialog DefaultValues for invisible fields of that ActivityDialog
#         DefaultValues for the 4 required Fields Queue State Lock Priority
#             if not configured in the ActivityDialog
#
#     ActivityDialog fillout request on existing Ticket:
#         ProcessEntityID
#         ActivityDialogEntityID
#         TicketValues
#
#     ActivityDialog store request or AjaxUpdate request on existing Tickets:
#         ProcessEntityID
#         ActivityDialogEntityID
#         TicketValues for all not-Submitted Values
#         Submitted Values
#
#     my $GetParam = _GetParam(
#         ProcessEntityID => $ProcessEntityID,
#     );
#
# =cut

sub _GetParam {
    my ( $Self, %Param ) = @_;

    #my $IsAJAXUpdate = $Param{AJAX} || '';

    # get layout object
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    for my $Needed (qw(ProcessEntityID)) {
        if ( !$Param{$Needed} ) {
            $LayoutObject->FatalError(
                Message => $LayoutObject->{LanguageObject}
                    ->Translate( 'Parameter %s is missing in %s.', $Needed, '_GetParam' ),
            );
        }
    }

    # get param object
    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');

    my %GetParam;
    my %Ticket;
    my $ProcessEntityID        = $Param{ProcessEntityID};
    my $TicketID               = $ParamObject->GetParam( Param => 'TicketID' );
    my $ActivityDialogEntityID = $ParamObject->GetParam(
        Param => 'ActivityDialogEntityID',
    );
    my $ActivityEntityID;
    my %ValuesGotten;
    my $Value;

    # get activity dialog object
    my $ActivityDialogObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::ActivityDialog');

    # create process object
    $Kernel::OM->ObjectParamAdd(
        'Kernel::System::ProcessManagement::Process' => {
            ActivityObject         => $Kernel::OM->Get('Kernel::System::ProcessManagement::Activity'),
            ActivityDialogObject   => $ActivityDialogObject,
            TransitionObject       => $Kernel::OM->Get('Kernel::System::ProcessManagement::Transition'),
            TransitionActionObject => $Kernel::OM->Get('Kernel::System::ProcessManagement::TransitionAction'),
        }
    );
    my $ProcessObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::Process');

    # If we got no ActivityDialogEntityID and no TicketID
    # we have to get the Processes' Startpoint
    if ( !$ActivityDialogEntityID && ( !$TicketID || $Self->{IsProcessEnroll} ) ) {
        my $ActivityActivityDialog = $ProcessObject->ProcessStartpointGet(
            ProcessEntityID => $ProcessEntityID,
        );
        if (
            !$ActivityActivityDialog->{ActivityDialog}
            || !$ActivityActivityDialog->{Activity}
            )
        {
            my $Message = $LayoutObject->{LanguageObject}->Translate(
                'Got no Start ActivityEntityID or Start ActivityDialogEntityID for Process: %s in _GetParam!',
                $ProcessEntityID,
            );

            # does not show header and footer again
            if ( $Self->{IsMainWindow} ) {
                return $LayoutObject->Error(
                    Message => $Message,
                );
            }

            $LayoutObject->FatalError(
                Message => $Message,
            );
        }
        $ActivityDialogEntityID = $ActivityActivityDialog->{ActivityDialog};
        $ActivityEntityID       = $ActivityActivityDialog->{Activity};
    }

    my $ActivityDialog = $ActivityDialogObject->ActivityDialogGet(
        ActivityDialogEntityID => $ActivityDialogEntityID,
        Interface              => 'AgentInterface',
    );

    if ( !IsHashRefWithData($ActivityDialog) ) {
        return $LayoutObject->ErrorScreen(
            Message => $LayoutObject->{LanguageObject}->Translate(
                'Couldn\'t get ActivityDialogEntityID "%s"!',
                $ActivityDialogEntityID,
            ),
            Comment => Translatable('Please contact the administrator.'),
        );
    }

    # get config object
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # if there is a ticket then is not an AJAX request
    if ($TicketID) {
        %Ticket = $Kernel::OM->Get('Kernel::System::Ticket')->TicketGet(
            TicketID      => $TicketID,
            UserID        => $Self->{UserID},
            DynamicFields => 1,
        );

        %GetParam = %Ticket;
        if ( !IsHashRefWithData( \%GetParam ) ) {
            $LayoutObject->FatalError(
                Message => $LayoutObject->{LanguageObject}->Translate(
                    'Couldn\'t get Ticket for TicketID: %s in _GetParam!',
                    $TicketID,
                ),
            );
        }

        if ( !$Self->{IsProcessEnroll} ) {
            $ActivityEntityID = $Ticket{
                'DynamicField_'
                    . $ConfigObject->Get("Process::DynamicFieldProcessManagementActivityID")
            };
            if ( !$ActivityEntityID ) {
                $LayoutObject->FatalError(
                    Message => Translatable(
                        'Couldn\'t determine ActivityEntityID. DynamicField or Config isn\'t set properly!'
                    ),
                );
            }
        }

    }
    $GetParam{ActivityDialogEntityID} = $ActivityDialogEntityID;
    $GetParam{ActivityEntityID}       = $ActivityEntityID;
    $GetParam{ProcessEntityID}        = $ProcessEntityID;

    # Get the activitydialogs's Submit Param's or Config Params
    DIALOGFIELD:
    for my $CurrentField ( @{ $ActivityDialog->{FieldOrder} } ) {

        # Skip if we're working on a field that was already done with or without ID
        if ( $Self->{NameToID}{$CurrentField} && $ValuesGotten{ $Self->{NameToID}{$CurrentField} } )
        {
            next DIALOGFIELD;
        }

        if ( $CurrentField =~ m{^DynamicField_(.*)}xms ) {
            my $DynamicFieldName = $1;

            my $DynamicField = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldListGet(
                Valid      => 1,
                ObjectType => 'Ticket',
            );

            # Get the Config of the current DynamicField (the first element of the grep result array)
            my $DynamicFieldConfig = ( grep { $_->{Name} eq $DynamicFieldName } @{$DynamicField} )[0];

            if ( !IsHashRefWithData($DynamicFieldConfig) ) {
                my $Message =
                    "DynamicFieldConfig missing for field: $DynamicFieldName, or is not a Ticket Dynamic Field!";

                # log error but does not stop the execution as it could be an old Article
                # DynamicField, see bug#11666
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'error',
                    Message  => $Message,
                );

                next DIALOGFIELD;
            }

            # Get DynamicField Values
            $Value = $Kernel::OM->Get('Kernel::System::DynamicField::Backend')->EditFieldValueGet(
                DynamicFieldConfig => $DynamicFieldConfig,
                ParamObject        => $ParamObject,
                LayoutObject       => $LayoutObject,
            );

            # If we got a submitted param, take it and next out
            if (
                defined $Value
                && (
                    $Value eq ''
                    || IsStringWithData($Value)
                    || IsArrayRefWithData($Value)
                    || IsHashRefWithData($Value)
                )
                )
            {
                $GetParam{$CurrentField} = $Value;
                next DIALOGFIELD;
            }

            # If we didn't have a Param Value try the ticket Value
            # next out if it was successful
            if (
                defined $Ticket{$CurrentField}
                && (
                    $Ticket{$CurrentField} eq ''
                    || IsStringWithData( $Ticket{$CurrentField} )
                    || IsArrayRefWithData( $Ticket{$CurrentField} )
                    || IsHashRefWithData( $Ticket{$CurrentField} )
                )
                )
            {
                $GetParam{$CurrentField} = $Ticket{$CurrentField};
                next DIALOGFIELD;
            }

            # If we had neither submitted nor ticket param get the ActivityDialog's default Value
            # next out if it was successful
            $Value = $ActivityDialog->{Fields}{$CurrentField}{DefaultValue};
            if ( defined $Value && length $Value ) {
                $GetParam{$CurrentField} = $Value;
                next DIALOGFIELD;
            }

            # If we had no submitted, ticket or ActivityDialog default value
            # use the DynamicField's default value and next out
            $Value = $DynamicFieldConfig->{Config}{DefaultValue};
            if ( defined $Value && length $Value ) {
                $GetParam{$CurrentField} = $Value;
                next DIALOGFIELD;
            }

            # if all that failed then the field should not have a defined value otherwise
            # if a value (even empty) is sent, fields like Date or DateTime will mark the field as
            # used with the field display value, this could lead to unwanted field sets,
            # see bug#9159
            next DIALOGFIELD;
        }

        # get attachment fields
        if ( $CurrentField eq 'Attachments' ) {
            @{ $GetParam{Attachments} } = $ParamObject->GetArray(
                Param => 'Attachments',
            );
            next DIALOGFIELD;
        }

        # get article fields
        if ( $CurrentField eq 'Article' ) {

            $GetParam{Subject} = $ParamObject->GetParam( Param => 'Subject' );
            $GetParam{Body}    = $ParamObject->GetParam( Param => 'Body' );
            @{ $GetParam{InformUserID} } = $ParamObject->GetArray(
                Param => 'InformUserID',
            );

            $ValuesGotten{Article} = 1 if ( $GetParam{Subject} && $GetParam{Body} );

            $GetParam{TimeUnits}          = $ParamObject->GetParam( Param => 'TimeUnits' );
            $GetParam{StandardTemplateID} = $ParamObject->GetParam( Param => 'StandardTemplateID' );
        }

        if ( $CurrentField eq 'CustomerID' ) {
            $GetParam{Customer} = $ParamObject->GetParam(
                Param => 'SelectedCustomerUser',
            ) || '';
            $GetParam{CustomerUserID} = $ParamObject->GetParam(
                Param => 'SelectedCustomerUser',
            ) || '';
        }

        if ( $CurrentField eq 'PendingTime' ) {
            my $Prefix = 'PendingTime';

            # Ok, we need to try to find the target state now
            my %StateData;

            # get state object
            my $StateObject = $Kernel::OM->Get('Kernel::System::State');

            # Was something submitted from the GUI?
            my $TargetStateID = $ParamObject->GetParam( Param => 'StateID' );
            if ($TargetStateID) {
                %StateData = $StateObject->StateGet(
                    ID => $TargetStateID,
                );
            }

            # Fallback 1: default value of dialog field State
            if ( !%StateData && $ActivityDialog->{Fields}{State}{DefaultValue} ) {
                %StateData = $StateObject->StateGet(
                    Name => $ActivityDialog->{Fields}{State}{DefaultValue},
                );
            }

            # Fallback 2: default value of dialog field StateID
            if ( !%StateData && $ActivityDialog->{Fields}{StateID}{DefaultValue} ) {
                %StateData = $StateObject->StateGet(
                    ID => $ActivityDialog->{Fields}{StateID}{DefaultValue},
                );
            }

            # Fallback 3: existing ticket state
            if ( !%StateData && %Ticket ) {
                %StateData = $StateObject->StateGet(
                    ID => $Ticket{StateID},
                );
            }

            # get pending time values
            # depends on StateType containing '^pending'
            if (
                IsHashRefWithData( \%StateData )
                && $StateData{TypeName}
                && $StateData{TypeName} =~ /^pending/i
                )
            {

                # map the GetParam's Date Values to our DateParamHash
                my %DateParam = (
                    Prefix => $Prefix,
                    map {
                        ( $Prefix . $_ )
                            => $ParamObject->GetParam( Param => ( $Prefix . $_ ) )
                        }
                        qw(Year Month Day Hour Minute)
                );

                # if all values are present
                if (
                    defined $DateParam{ $Prefix . 'Year' }
                    && defined $DateParam{ $Prefix . 'Month' }
                    && defined $DateParam{ $Prefix . 'Day' }
                    && defined $DateParam{ $Prefix . 'Hour' }
                    && defined $DateParam{ $Prefix . 'Minute' }
                    )
                {

                    # recalculate time according to the user's timezone
                    %DateParam = $LayoutObject->TransformDateSelection(
                        %DateParam,
                    );

                    # reformat for storing (e.g. take out Prefix)
                    %{ $GetParam{$CurrentField} }
                        = map { $_ => $DateParam{ $Prefix . $_ } } qw(Year Month Day Hour Minute);
                    $ValuesGotten{PendingTime} = 1;
                }
            }
        }

        # Non DynamicFields
        # 1. try to get the required param
        my $Value = $ParamObject->GetParam( Param => $Self->{NameToID}{$CurrentField} );

        if ($Value) {

            # if we have an ID field make sure the value without ID won't be in the
            # %GetParam Hash any more
            if ( $Self->{NameToID}{$CurrentField} =~ m{(.*)ID$}xms ) {
                $GetParam{$1} = undef;
            }
            $GetParam{ $Self->{NameToID}{$CurrentField} }     = $Value;
            $ValuesGotten{ $Self->{NameToID}{$CurrentField} } = 1;
            next DIALOGFIELD;
        }

        # If we got ticket params, the GetParam Hash was already filled before the loop
        # and we can next out
        if ( $GetParam{ $Self->{NameToID}{$CurrentField} } ) {
            $ValuesGotten{ $Self->{NameToID}{$CurrentField} } = 1;
            next DIALOGFIELD;
        }

        if ( $CurrentField eq 'Queue' && !$GetParam{ $Self->{NameToID}{$CurrentField} } ) {
            my $UserDefaultQueue = $ConfigObject->Get('Ticket::Frontend::UserDefaultQueue') || '';
            if ($UserDefaultQueue) {
                my $QueueID = $Kernel::OM->Get('Kernel::System::Queue')->QueueLookup( Queue => $UserDefaultQueue );
                if ($QueueID) {
                    $GetParam{$CurrentField}                          = $UserDefaultQueue;
                    $GetParam{ $Self->{NameToID}{$CurrentField} }     = $QueueID;
                    $ValuesGotten{ $Self->{NameToID}{$CurrentField} } = 1;
                    next DIALOGFIELD;
                }
            }
        }

        # if no Submitted nore Ticket Param get ActivityDialog Config's Param
        if ( $CurrentField ne 'CustomerID' ) {
            $Value = $ActivityDialog->{Fields}{$CurrentField}{DefaultValue};
        }
        if ($Value) {
            $ValuesGotten{ $Self->{NameToID}{$CurrentField} } = 1;
            $GetParam{$CurrentField} = $Value;
            next DIALOGFIELD;
        }
    }

    for my $CurrentField (qw(Queue State Lock Priority)) {
        $Value = undef;
        if ( !$ValuesGotten{ $Self->{NameToID}{$CurrentField} } ) {
            $Value = $ConfigObject->Get("Process::Default$CurrentField");
            if ( !$Value ) {

                my $Message = $LayoutObject->{LanguageObject}->Translate(
                    'Process::Default%s Config Value missing!',
                    $CurrentField,
                );

                # does not show header and footer again
                if ( $Self->{IsMainWindow} ) {
                    return $LayoutObject->Error(
                        Message => $Message,
                    );
                }

                $LayoutObject->FatalError(
                    Message => $Message,
                );
            }
            $GetParam{$CurrentField} = $Value;
            $ValuesGotten{ $Self->{NameToID}{$CurrentField} } = 1;
        }
    }

    my $Dest = $ParamObject->GetParam( Param => 'Dest' ) || '';
    if ($Dest) {

        my @QueueParts = split( /\|\|/, $Dest );

        $GetParam{QueueID} = $QueueParts[0];
        $GetParam{Queue}   = $QueueParts[1];

        $ValuesGotten{QueueID} = 1;
    }

    # get also the IDs for the Required files (if they are not present)
    if ( $GetParam{Queue} && !$GetParam{QueueID} ) {
        $GetParam{QueueID} = $Kernel::OM->Get('Kernel::System::Queue')->QueueLookup( Queue => $GetParam{Queue} );
    }
    if ( $GetParam{State} && !$GetParam{StateID} ) {
        $GetParam{StateID} = $Kernel::OM->Get('Kernel::System::State')->StateLookup( State => $GetParam{State} );
    }
    if ( $GetParam{Lock} && !$GetParam{LockID} ) {
        $GetParam{LockID} = $Kernel::OM->Get('Kernel::System::Lock')->LockLookup( Lock => $GetParam{Lock} );
    }
    if ( $GetParam{Priority} && !$GetParam{PriorityID} ) {
        $GetParam{PriorityID} = $Kernel::OM->Get('Kernel::System::Priority')->PriorityLookup(
            Priority => $GetParam{Priority},
        );
    }

    # and finally we'll have the special parameters:
    $GetParam{ResponsibleAll} = $ParamObject->GetParam( Param => 'ResponsibleAll' );
    $GetParam{OwnerAll}       = $ParamObject->GetParam( Param => 'OwnerAll' );
    $GetParam{ElementChanged} = $ParamObject->GetParam( Param => 'ElementChanged' );

    return \%GetParam;
}

sub _OutputActivityDialog {
    my ( $Self, %Param ) = @_;
    my $TicketID               = $Param{GetParam}{TicketID};
    my $ActivityDialogEntityID = $Param{GetParam}{ActivityDialogEntityID};

    # get layout object
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # Check needed parameters:
    # ProcessEntityID only
    # TicketID ActivityDialogEntityID
    if ( !$Param{ProcessEntityID} || ( !$TicketID && !$ActivityDialogEntityID ) ) {
        my $Message = Translatable('Got no ProcessEntityID or TicketID and ActivityDialogEntityID!');

        # does not show header and footer again
        if ( $Self->{IsMainWindow} ) {
            return $LayoutObject->Error(
                Message => $Message,
            );
        }

        $LayoutObject->FatalError(
            Message => $Message,
        );
    }

    my $ActivityActivityDialog;
    my %Ticket;
    my %Error         = ();
    my %ErrorMessages = ();

    # If we had Errors, we got an Errorhash
    %Error         = %{ $Param{Error} }         if ( IsHashRefWithData( $Param{Error} ) );
    %ErrorMessages = %{ $Param{ErrorMessages} } if ( IsHashRefWithData( $Param{ErrorMessages} ) );

    # get needed objects
    my $ActivityObject       = $Kernel::OM->Get('Kernel::System::ProcessManagement::Activity');
    my $ActivityDialogObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::ActivityDialog');

    # create process object
    $Kernel::OM->ObjectParamAdd(
        'Kernel::System::ProcessManagement::Process' => {
            ActivityObject         => $ActivityObject,
            ActivityDialogObject   => $ActivityDialogObject,
            TransitionObject       => $Kernel::OM->Get('Kernel::System::ProcessManagement::Transition'),
            TransitionActionObject => $Kernel::OM->Get('Kernel::System::ProcessManagement::TransitionAction'),
        }
    );
    my $ProcessObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::Process');

    # get needed object
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    if ( !$TicketID || $Self->{IsProcessEnroll} ) {
        $ActivityActivityDialog = $ProcessObject->ProcessStartpointGet(
            ProcessEntityID => $Param{ProcessEntityID},
        );

        if ( !IsHashRefWithData($ActivityActivityDialog) ) {
            my $Message = $LayoutObject->{LanguageObject}->Translate(
                'Can\'t get StartActivityDialog and StartActivityDialog for the ProcessEntityID "%s"!',
                $Param{ProcessEntityID},
            );

            # does not show header and footer again
            if ( $Self->{IsMainWindow} ) {
                return $LayoutObject->Error(
                    Message => $Message,
                );
            }

            $LayoutObject->FatalError(
                Message => $Message,
            );
        }
    }
    else {

        # no AJAX update in this part
        %Ticket = $TicketObject->TicketGet(
            TicketID      => $TicketID,
            UserID        => $Self->{UserID},
            DynamicFields => 1,
        );

        if ( !IsHashRefWithData( \%Ticket ) ) {
            $LayoutObject->FatalError(
                Message => $LayoutObject->{LanguageObject}->Translate( 'Can\'t get Ticket "%s"!', $Param{TicketID} ),
            );
        }

        my $DynamicFieldProcessID = 'DynamicField_'
            . $ConfigObject->Get('Process::DynamicFieldProcessManagementProcessID');
        my $DynamicFieldActivityID = 'DynamicField_'
            . $ConfigObject->Get('Process::DynamicFieldProcessManagementActivityID');

        if ( !$Ticket{$DynamicFieldProcessID} || !$Ticket{$DynamicFieldActivityID} ) {
            $LayoutObject->FatalError(
                Message => $LayoutObject->{LanguageObject}->Translate(
                    'Can\'t get ProcessEntityID or ActivityEntityID for Ticket "%s"!',
                    $Param{TicketID},
                ),
            );
        }

        $ActivityActivityDialog = {
            Activity       => $Ticket{$DynamicFieldActivityID},
            ActivityDialog => $ActivityDialogEntityID,
        };
    }

    if ( !%Ticket && $Self->{IsProcessEnroll} ) {
        %Ticket = $TicketObject->TicketGet(
            TicketID      => $TicketID,
            UserID        => $Self->{UserID},
            DynamicFields => 1,
        );
    }

    my $Activity = $ActivityObject->ActivityGet(
        Interface        => 'AgentInterface',
        ActivityEntityID => $ActivityActivityDialog->{Activity}
    );
    if ( !$Activity ) {
        my $Message = $LayoutObject->{LanguageObject}->Translate(
            'Can\'t get Activity configuration for ActivityEntityID "%s"!',
            $ActivityActivityDialog->{Activity},
        );

        # does not show header and footer again
        if ( $Self->{IsMainWindow} ) {
            return $LayoutObject->Error(
                Message => $Message,
            );
        }

        $LayoutObject->FatalError(
            Message => $Message,
        );
    }

    my $ActivityDialog = $ActivityDialogObject->ActivityDialogGet(
        ActivityDialogEntityID => $ActivityActivityDialog->{ActivityDialog},
        Interface              => 'AgentInterface',
    );
    if ( !IsHashRefWithData($ActivityDialog) ) {
        my $Message = $LayoutObject->{LanguageObject}->Translate(
            'Can\'t get ActivityDialog configuration for ActivityDialogEntityID "%s"!',
            $ActivityActivityDialog->{ActivityDialog},
        );

        # does not show header and footer again
        if ( $Self->{IsMainWindow} ) {
            return $LayoutObject->Error(
                Message => $Message,
            );
        }

        $LayoutObject->FatalError(
            Message => $Message,
        );
    }

    # grep out Overwrites if defined on the Activity
    my @OverwriteActivityDialogNumber = grep {
        ref $Activity->{ActivityDialog}{$_} eq 'HASH'
            && $Activity->{ActivityDialog}{$_}{ActivityDialogEntityID}
            && $Activity->{ActivityDialog}{$_}{ActivityDialogEntityID} eq
            $ActivityActivityDialog->{ActivityDialog}
            && IsHashRefWithData( $Activity->{ActivityDialog}{$_}{Overwrite} )
    } keys %{ $Activity->{ActivityDialog} };

    # let the Overwrites Overwrite the ActivityDialog's Hash values
    if ( $OverwriteActivityDialogNumber[0] ) {
        %{$ActivityDialog} = (
            %{$ActivityDialog},
            %{ $Activity->{ActivityDialog}{ $OverwriteActivityDialogNumber[0] }{Overwrite} }
        );
    }

    # Add PageHeader, Navbar, Formheader (Process/ActivityDialogHeader)
    my $Output;
    my $MainBoxClass;

    if ( !$Self->{IsMainWindow} && !$Self->{IsProcessEnroll} ) {
        $Output = $LayoutObject->Header(
            Type  => 'Small',
            Value => $Ticket{Number},
        );

        # display given notify messages if this is not an AJAX request
        if ( IsArrayRefWithData( $Param{Notify} ) ) {

            for my $NotifyData ( @{ $Param{Notify} } ) {
                $Output .= $LayoutObject->Notify( %{$NotifyData} );
            }
        }

        $LayoutObject->Block(
            Name => 'Header',
            Data => {
                Name =>
                    $LayoutObject->{LanguageObject}->Translate( $ActivityDialog->{Name} )
                    || '',
            }
        );
    }
    elsif (
        ( $Self->{IsMainWindow} || $Self->{IsProcessEnroll} )
        && IsHashRefWithData( \%Error )
        )
    {

        # add rich text editor
        if ( $LayoutObject->{BrowserRichText} ) {

            # use height/width defined for this screen
            $Param{RichTextHeight} = $Self->{Config}->{RichTextHeight} || 0;
            $Param{RichTextWidth}  = $Self->{Config}->{RichTextWidth}  || 0;

            # set up rich text editor
            $LayoutObject->SetRichTextParameters(
                Data => \%Param,
            );
        }

        # display complete header and navigation bar in AJAX dialogs when there is a server error
        #    unless we are in a process enrollment (only when IsMainWindow is active)
        my $Type = $Self->{IsMainWindow} ? '' : 'Small';
        $Output = $LayoutObject->Header(
            Type => $Type,
        );
        if ( $Self->{IsMainWindow} ) {
            $Output .= $LayoutObject->NavigationBar();
        }

        # display original header texts (the process list maybe is not necessary)
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AgentTicketProcess' . $Type,
            Data         => {
                %Param,
                FormID          => $Self->{FormID},
                IsProcessEnroll => $Self->{IsProcessEnroll},
            },
        );

        # set the MainBox class to add correct borders to the screen
        $MainBoxClass = 'MainBox';
    }

    # display process information
    if ( $Self->{IsMainWindow} ) {

        # get process data
        my $Process = $ProcessObject->ProcessGet(
            ProcessEntityID => $Param{ProcessEntityID},
        );

        # output main process information
        $LayoutObject->Block(
            Name => 'ProcessInfoSidebar',
            Data => {
                Process        => $Process->{Name}        || '',
                Activity       => $Activity->{Name}       || '',
                ActivityDialog => $ActivityDialog->{Name} || '',
            },
        );

        # output activity dialog short description (if any)
        if (
            defined $ActivityDialog->{DescriptionShort}
            && $ActivityDialog->{DescriptionShort} ne ''
            )
        {
            $LayoutObject->Block(
                Name => 'ProcessInfoSidebarActivityDialogDesc',
                Data => {
                    ActivityDialogDescription => $ActivityDialog->{DescriptionShort} || '',
                },
            );
        }

        # output long description information if exists
        if (
            defined $ActivityDialog->{DescriptionLong}
            && length $ActivityDialog->{DescriptionLong}
            )
        {
            $LayoutObject->Block(
                Name => 'LongDescriptionSidebar',
                Data => {
                    Description => $ActivityDialog->{DescriptionLong},
                },
            );
        }
    }

    # show descriptions
    if ( $ActivityDialog->{DescriptionShort} ) {
        $LayoutObject->Block(
            Name => 'DescriptionShort',
            Data => {
                DescriptionShort
                    => $LayoutObject->{LanguageObject}->Translate(
                    $ActivityDialog->{DescriptionShort},
                    ),
            },
        );
    }
    if ( $ActivityDialog->{DescriptionLong} ) {
        $LayoutObject->Block(
            Name => 'DescriptionLong',
            Data => {
                DescriptionLong
                    => $LayoutObject->{LanguageObject}->Translate(
                    $ActivityDialog->{DescriptionLong},
                    ),
            },
        );
    }

    # show close & cancel link if necessary
    if ( !$Self->{IsMainWindow} && !$Self->{IsProcessEnroll} ) {
        if ( $Param{RenderLocked} ) {
            $LayoutObject->Block(
                Name => 'PropertiesLock',
                Data => {
                    %Param,
                    TicketID => $TicketID,
                },
            );
        }
        else {
            $LayoutObject->Block(
                Name => 'CancelLink',
            );
        }

    }

    $Output .= $LayoutObject->Output(
        TemplateFile => 'ProcessManagement/ActivityDialogHeader',
        Data         => {
            FormName               => 'ActivityDialogDialog' . $ActivityActivityDialog->{ActivityDialog},
            FormID                 => $Self->{FormID},
            Subaction              => 'StoreActivityDialog',
            TicketID               => $Ticket{TicketID} || '',
            LinkTicketID           => $Self->{LinkTicketID},
            ActivityDialogEntityID => $ActivityActivityDialog->{ActivityDialog},
            ProcessEntityID        => $Param{ProcessEntityID}
                || $Ticket{
                'DynamicField_'
                    . $ConfigObject->Get(
                    'Process::DynamicFieldProcessManagementProcessID'
                    )
                },
            IsMainWindow    => $Self->{IsMainWindow},
            IsProcessEnroll => $Self->{IsProcessEnroll},
            MainBoxClass    => $MainBoxClass || '',
        },
    );

    my %RenderedFields = ();

    # get the list of fields where the AJAX loader icon should appear on AJAX updates triggered
    # by ActivityDialog fields
    my $AJAXUpdatableFields = $Self->_GetAJAXUpdatableFields(
        ActivityDialogFields => $ActivityDialog->{Fields},
    );

    # Loop through ActivityDialogFields and render their output
    DIALOGFIELD:
    for my $CurrentField ( @{ $ActivityDialog->{FieldOrder} } ) {
        if ( !IsHashRefWithData( $ActivityDialog->{Fields}{$CurrentField} ) ) {
            my $Message = $LayoutObject->{LanguageObject}->Translate(
                'Can\'t get data for Field "%s" of ActivityDialog "%s"!',
                $CurrentField,
                $ActivityActivityDialog->{ActivityDialog},
            );

            # does not show header and footer again
            if ( $Self->{IsMainWindow} ) {
                return $LayoutObject->Error(
                    Message => $Message,
                );
            }

            $LayoutObject->FatalError(
                Message => $Message,
            );
        }

        my %FieldData = %{ $ActivityDialog->{Fields}{$CurrentField} };

        # We render just visible ActivityDialogFields
        next DIALOGFIELD if !$FieldData{Display};

        # render DynamicFields
        if ( $CurrentField =~ m{^DynamicField_(.*)}xms ) {
            my $DynamicFieldName = $1;
            my $Response         = $Self->_RenderDynamicField(
                ActivityDialogField => $ActivityDialog->{Fields}{$CurrentField},
                FieldName           => $DynamicFieldName,
                DescriptionShort    => $ActivityDialog->{Fields}{$CurrentField}{DescriptionShort},
                DescriptionLong     => $ActivityDialog->{Fields}{$CurrentField}{DescriptionLong},
                Ticket              => \%Ticket,
                Error               => \%Error,
                ErrorMessages       => \%ErrorMessages || {},
                FormID              => $Self->{FormID},
                GetParam            => $Param{GetParam},
                AJAXUpdatableFields => $AJAXUpdatableFields,
            );

            if ( !$Response->{Success} ) {

                # does not show header and footer again
                if ( $Self->{IsMainWindow} ) {
                    return $LayoutObject->Error(
                        Message => $Response->{Message},
                    );
                }

                $LayoutObject->FatalError(
                    Message => $Response->{Message},
                );
            }

            $Output .= $Response->{HTML};

            $RenderedFields{$CurrentField} = 1;

        }

        # render Attachments
        elsif ( $CurrentField eq 'Attachments' && $TicketID ) {
            next DIALOGFIELD if $RenderedFields{$CurrentField};

            my $Response = $Self->_RenderAttachment(
                ActivityDialogField => $ActivityDialog->{Fields}->{$CurrentField},
                FieldName           => $CurrentField,
                DescriptionShort    => $ActivityDialog->{Fields}->{$CurrentField}->{DescriptionShort},
                DescriptionLong     => $ActivityDialog->{Fields}->{$CurrentField}->{DescriptionLong},
                Ticket              => \%Ticket,
                Error               => \%Error,
                FormID              => $Self->{FormID},
                GetParam            => $Param{GetParam},
                AJAXUpdatableFields => $AJAXUpdatableFields,
            );

            if ( !$Response->{Success} ) {

                # does not show header and footer again
                if ( $Self->{IsMainWindow} ) {
                    return $LayoutObject->Error(
                        Message => $Response->{Message},
                    );
                }

                $LayoutObject->FatalError(
                    Message => $Response->{Message},
                );
            }

            $Output .= $Response->{HTML};
            $RenderedFields{$CurrentField} = 1;
        }

        # render State
        elsif ( $Self->{NameToID}->{$CurrentField} eq 'StateID' )
        {

            # We don't render Fields twice,
            # if there was already a Config without ID, skip this field
            next DIALOGFIELD if $RenderedFields{ $Self->{NameToID}->{$CurrentField} };

            my $Response = $Self->_RenderState(
                ActivityDialogField => $ActivityDialog->{Fields}{$CurrentField},
                FieldName           => $CurrentField,
                DescriptionShort    => $ActivityDialog->{Fields}{$CurrentField}{DescriptionShort},
                DescriptionLong     => $ActivityDialog->{Fields}{$CurrentField}{DescriptionLong},
                Ticket              => \%Ticket,
                Error               => \%Error,
                FormID              => $Self->{FormID},
                GetParam            => $Param{GetParam},
                AJAXUpdatableFields => $AJAXUpdatableFields,
            );

            if ( !$Response->{Success} ) {

                # does not show header and footer again
                if ( $Self->{IsMainWindow} ) {
                    return $LayoutObject->Error(
                        Message => $Response->{Message},
                    );
                }

                $LayoutObject->FatalError(
                    Message => $Response->{Message},
                );
            }

            $Output .= $Response->{HTML};

            $RenderedFields{ $Self->{NameToID}->{$CurrentField} } = 1;
        }

        # render Queue
        elsif ( $Self->{NameToID}->{$CurrentField} eq 'QueueID' )
        {
            next DIALOGFIELD if $RenderedFields{ $Self->{NameToID}->{$CurrentField} };

            my $Response = $Self->_RenderQueue(
                ActivityDialogField => $ActivityDialog->{Fields}{$CurrentField},
                FieldName           => $CurrentField,
                DescriptionShort    => $ActivityDialog->{Fields}{$CurrentField}{DescriptionShort},
                DescriptionLong     => $ActivityDialog->{Fields}{$CurrentField}{DescriptionLong},
                Ticket              => \%Ticket,
                Error               => \%Error,
                FormID              => $Self->{FormID},
                GetParam            => $Param{GetParam},
                AJAXUpdatableFields => $AJAXUpdatableFields,
            );

            if ( !$Response->{Success} ) {

                # does not show header and footer again
                if ( $Self->{IsMainWindow} ) {
                    return $LayoutObject->Error(
                        Message => $Response->{Message},
                    );
                }

                $LayoutObject->FatalError(
                    Message => $Response->{Message},
                );
            }

            $Output .= $Response->{HTML};

            $RenderedFields{ $Self->{NameToID}->{$CurrentField} } = 1;
        }

        # render Priority
        elsif ( $Self->{NameToID}->{$CurrentField} eq 'PriorityID' )
        {
            next DIALOGFIELD if $RenderedFields{ $Self->{NameToID}->{$CurrentField} };

            my $Response = $Self->_RenderPriority(
                ActivityDialogField => $ActivityDialog->{Fields}{$CurrentField},
                FieldName           => $CurrentField,
                DescriptionShort    => $ActivityDialog->{Fields}{$CurrentField}{DescriptionShort},
                DescriptionLong     => $ActivityDialog->{Fields}{$CurrentField}{DescriptionLong},
                Ticket              => \%Ticket,
                Error               => \%Error,
                FormID              => $Self->{FormID},
                GetParam            => $Param{GetParam},
                AJAXUpdatableFields => $AJAXUpdatableFields,
            );

            if ( !$Response->{Success} ) {

                # does not show header and footer again
                if ( $Self->{IsMainWindow} ) {
                    return $LayoutObject->Error(
                        Message => $Response->{Message},
                    );
                }

                $LayoutObject->FatalError(
                    Message => $Response->{Message},
                );
            }

            $Output .= $Response->{HTML};

            $RenderedFields{ $Self->{NameToID}->{$CurrentField} } = 1;
        }

        # render Lock
        elsif ( $Self->{NameToID}->{$CurrentField} eq 'LockID' ) {
            next DIALOGFIELD if $RenderedFields{ $Self->{NameToID}->{$CurrentField} };

            my $Response = $Self->_RenderLock(
                ActivityDialogField => $ActivityDialog->{Fields}{$CurrentField},
                FieldName           => $CurrentField,
                DescriptionShort    => $ActivityDialog->{Fields}{$CurrentField}{DescriptionShort},
                DescriptionLong     => $ActivityDialog->{Fields}{$CurrentField}{DescriptionLong},
                Ticket              => \%Ticket,
                Error               => \%Error,
                FormID              => $Self->{FormID},
                GetParam            => $Param{GetParam},
                AJAXUpdatableFields => $AJAXUpdatableFields,
            );

            if ( !$Response->{Success} ) {

                # does not show header and footer again
                if ( $Self->{IsMainWindow} ) {
                    return $LayoutObject->Error(
                        Message => $Response->{Message},
                    );
                }

                $LayoutObject->FatalError(
                    Message => $Response->{Message},
                );
            }

            $Output .= $Response->{HTML};

            $RenderedFields{ $Self->{NameToID}->{$CurrentField} } = 1;
        }

        # render Service
        elsif ( $Self->{NameToID}->{$CurrentField} eq 'ServiceID' ) {
            next DIALOGFIELD if $RenderedFields{ $Self->{NameToID}->{$CurrentField} };

            my $Response = $Self->_RenderService(
                ActivityDialogField => $ActivityDialog->{Fields}{$CurrentField},
                FieldName           => $CurrentField,
                DescriptionShort    => $ActivityDialog->{Fields}{$CurrentField}{DescriptionShort},
                DescriptionLong     => $ActivityDialog->{Fields}{$CurrentField}{DescriptionLong},
                Ticket              => \%Ticket,
                Error               => \%Error,
                FormID              => $Self->{FormID},
                GetParam            => $Param{GetParam},
                AJAXUpdatableFields => $AJAXUpdatableFields,
            );

            if ( !$Response->{Success} ) {

                # does not show header and footer again
                if ( $Self->{IsMainWindow} ) {
                    return $LayoutObject->Error(
                        Message => $Response->{Message},
                    );
                }

                $LayoutObject->FatalError(
                    Message => $Response->{Message},
                );
            }

            $Output .= $Response->{HTML};

            $RenderedFields{$CurrentField} = 1;
        }

        # render SLA
        elsif ( $Self->{NameToID}->{$CurrentField} eq 'SLAID' ) {
            next DIALOGFIELD if $RenderedFields{ $Self->{NameToID}->{$CurrentField} };

            my $Response = $Self->_RenderSLA(
                ActivityDialogField => $ActivityDialog->{Fields}{$CurrentField},
                FieldName           => $CurrentField,
                DescriptionShort    => $ActivityDialog->{Fields}{$CurrentField}{DescriptionShort},
                DescriptionLong     => $ActivityDialog->{Fields}{$CurrentField}{DescriptionLong},
                Ticket              => \%Ticket,
                Error               => \%Error,
                FormID              => $Self->{FormID},
                GetParam            => $Param{GetParam},
                AJAXUpdatableFields => $AJAXUpdatableFields,
            );

            if ( !$Response->{Success} ) {

                # does not show header and footer again
                if ( $Self->{IsMainWindow} ) {
                    return $LayoutObject->Error(
                        Message => $Response->{Message},
                    );
                }

                $LayoutObject->FatalError(
                    Message => $Response->{Message},
                );
            }

            $Output .= $Response->{HTML};

            $RenderedFields{ $Self->{NameToID}->{$CurrentField} } = 1;
        }

        # render Owner
        elsif ( $Self->{NameToID}->{$CurrentField} eq 'OwnerID' ) {
            next DIALOGFIELD if $RenderedFields{ $Self->{NameToID}->{$CurrentField} };

            my $Response = $Self->_RenderOwner(
                ActivityDialogField => $ActivityDialog->{Fields}{$CurrentField},
                FieldName           => $CurrentField,
                DescriptionShort    => $ActivityDialog->{Fields}{$CurrentField}{DescriptionShort},
                DescriptionLong     => $ActivityDialog->{Fields}{$CurrentField}{DescriptionLong},
                Ticket              => \%Ticket,
                Error               => \%Error,
                FormID              => $Self->{FormID},
                GetParam            => $Param{GetParam},
                AJAXUpdatableFields => $AJAXUpdatableFields,
            );

            if ( !$Response->{Success} ) {

                # does not show header and footer again
                if ( $Self->{IsMainWindow} ) {
                    return $LayoutObject->Error(
                        Message => $Response->{Message},
                    );
                }

                $LayoutObject->FatalError(
                    Message => $Response->{Message},
                );
            }

            $Output .= $Response->{HTML};

            $RenderedFields{ $Self->{NameToID}->{$CurrentField} } = 1;
        }

        # render responsible
        elsif ( $Self->{NameToID}->{$CurrentField} eq 'ResponsibleID' ) {
            next DIALOGFIELD if $RenderedFields{ $Self->{NameToID}->{$CurrentField} };

            my $Response = $Self->_RenderResponsible(
                ActivityDialogField => $ActivityDialog->{Fields}{$CurrentField},
                FieldName           => $CurrentField,
                DescriptionShort    => $ActivityDialog->{Fields}{$CurrentField}{DescriptionShort},
                DescriptionLong     => $ActivityDialog->{Fields}{$CurrentField}{DescriptionLong},
                Ticket              => \%Ticket,
                Error               => \%Error,
                FormID              => $Self->{FormID},
                GetParam            => $Param{GetParam},
                AJAXUpdatableFields => $AJAXUpdatableFields,
            );

            if ( !$Response->{Success} ) {

                # does not show header and footer again
                if ( $Self->{IsMainWindow} ) {
                    return $LayoutObject->Error(
                        Message => $Response->{Message},
                    );
                }

                $LayoutObject->FatalError(
                    Message => $Response->{Message},
                );
            }

            $Output .= $Response->{HTML};

            $RenderedFields{ $Self->{NameToID}->{$CurrentField} } = 1;
        }

        # render CustomerID
        elsif ( $Self->{NameToID}->{$CurrentField} eq 'CustomerID' ) {
            next DIALOGFIELD if $RenderedFields{ $Self->{NameToID}->{$CurrentField} };

            my $Response = $Self->_RenderCustomer(
                ActivityDialogField => $ActivityDialog->{Fields}{$CurrentField},
                FieldName           => $CurrentField,
                DescriptionShort    => $ActivityDialog->{Fields}{$CurrentField}{DescriptionShort},
                DescriptionLong     => $ActivityDialog->{Fields}{$CurrentField}{DescriptionLong},
                Ticket              => \%Ticket,
                Error               => \%Error,
                FormID              => $Self->{FormID},
                GetParam            => $Param{GetParam},
                AJAXUpdatableFields => $AJAXUpdatableFields,
            );

            if ( !$Response->{Success} ) {

                # does not show header and footer again
                if ( $Self->{IsMainWindow} ) {
                    return $LayoutObject->Error(
                        Message => $Response->{Message},
                    );
                }

                $LayoutObject->FatalError(
                    Message => $Response->{Message},
                );
            }

            $Output .= $Response->{HTML};

            $RenderedFields{ $Self->{NameToID}->{$CurrentField} } = 1;
        }

        elsif ( $CurrentField eq 'PendingTime' ) {

            # PendingTime is just useful if we have State or StateID
            if ( !grep {m{^(StateID|State)$}xms} @{ $ActivityDialog->{FieldOrder} } ) {
                my $Message = $LayoutObject->{LanguageObject}->Translate(
                    'PendingTime can just be used if State or StateID is configured for the same ActivityDialog. ActivityDialog: %s!',
                    $ActivityActivityDialog->{ActivityDialog},
                );

                # does not show header and footer again
                if ( $Self->{IsMainWindow} ) {
                    return $LayoutObject->Error(
                        Message => $Message,
                    );
                }

                $LayoutObject->FatalError(
                    Message => $Message,
                );
            }

            next DIALOGFIELD if $RenderedFields{ $Self->{NameToID}->{$CurrentField} };

            my $Response = $Self->_RenderPendingTime(
                ActivityDialogField => $ActivityDialog->{Fields}{$CurrentField},
                FieldName           => $CurrentField,
                DescriptionShort    => $ActivityDialog->{Fields}{$CurrentField}{DescriptionShort},
                DescriptionLong     => $ActivityDialog->{Fields}{$CurrentField}{DescriptionLong},
                Ticket              => \%Ticket,
                Error               => \%Error,
                FormID              => $Self->{FormID},
                GetParam            => $Param{GetParam},
            );

            if ( !$Response->{Success} ) {

                # does not show header and footer again
                if ( $Self->{IsMainWindow} ) {
                    return $LayoutObject->Error(
                        Message => $Response->{Message},
                    );
                }

                $LayoutObject->FatalError(
                    Message => $Response->{Message},
                );
            }

            $Output .= $Response->{HTML};

            $RenderedFields{ $Self->{NameToID}->{$CurrentField} } = 1;
        }

        # render Title
        elsif ( $Self->{NameToID}->{$CurrentField} eq 'Title' ) {
            next DIALOGFIELD if $RenderedFields{ $Self->{NameToID}->{$CurrentField} };

            my $Response = $Self->_RenderTitle(
                ActivityDialogField => $ActivityDialog->{Fields}{$CurrentField},
                FieldName           => $CurrentField,
                DescriptionShort    => $ActivityDialog->{Fields}{$CurrentField}{DescriptionShort},
                DescriptionLong     => $ActivityDialog->{Fields}{$CurrentField}{DescriptionLong},
                Ticket              => \%Ticket,
                Error               => \%Error,
                FormID              => $Self->{FormID},
                GetParam            => $Param{GetParam},
            );

            if ( !$Response->{Success} ) {

                # does not show header and footer again
                if ( $Self->{IsMainWindow} ) {
                    return $LayoutObject->Error(
                        Message => $Response->{Message},
                    );
                }

                $LayoutObject->FatalError(
                    Message => $Response->{Message},
                );
            }

            $Output .= $Response->{HTML};

            $RenderedFields{$CurrentField} = 1;
        }

        # render Article
        elsif ( $Self->{NameToID}->{$CurrentField} eq 'Article' ) {
            next DIALOGFIELD if $RenderedFields{ $Self->{NameToID}->{$CurrentField} };

            my $Response = $Self->_RenderArticle(
                ActivityDialogField => $ActivityDialog->{Fields}{$CurrentField},
                FieldName           => $CurrentField,
                DescriptionShort    => $ActivityDialog->{Fields}{$CurrentField}{DescriptionShort},
                DescriptionLong     => $ActivityDialog->{Fields}{$CurrentField}{DescriptionLong},
                Ticket              => \%Ticket,
                Error               => \%Error,
                FormID              => $Self->{FormID},
                GetParam            => $Param{GetParam},
                InformAgents        => $ActivityDialog->{Fields}->{Article}->{Config}->{InformAgents},
            );

            if ( !$Response->{Success} ) {

                # does not show header and footer again
                if ( $Self->{IsMainWindow} ) {
                    return $LayoutObject->Error(
                        Message => $Response->{Message},
                    );
                }

                $LayoutObject->FatalError(
                    Message => $Response->{Message},
                );
            }

            $Output .= $Response->{HTML};

            $RenderedFields{$CurrentField} = 1;
        }

        # render Type
        elsif ( $Self->{NameToID}->{$CurrentField} eq 'TypeID' ) {

            # We don't render Fields twice,
            # if there was already a Config without ID, skip this field
            next DIALOGFIELD if $RenderedFields{ $Self->{NameToID}->{$CurrentField} };

            my $Response = $Self->_RenderType(
                ActivityDialogField => $ActivityDialog->{Fields}{$CurrentField},
                FieldName           => $CurrentField,
                DescriptionShort    => $ActivityDialog->{Fields}{$CurrentField}{DescriptionShort},
                DescriptionLong     => $ActivityDialog->{Fields}{$CurrentField}{DescriptionLong},
                Ticket              => \%Ticket,
                Error               => \%Error,
                FormID              => $Self->{FormID},
                GetParam            => $Param{GetParam},
                AJAXUpdatableFields => $AJAXUpdatableFields,
            );

            if ( !$Response->{Success} ) {

                # does not show header and footer again
                if ( $Self->{IsMainWindow} ) {
                    return $LayoutObject->Error(
                        Message => $Response->{Message},
                    );
                }

                $LayoutObject->FatalError(
                    Message => $Response->{Message},
                );
            }

            $Output .= $Response->{HTML};

            $RenderedFields{ $Self->{NameToID}->{$CurrentField} } = 1;
        }
    }

    my $FooterCSSClass = 'Footer';

    if ( $Self->{IsAjaxRequest} ) {

        # Due to the initial loading of
        # the first ActivityDialog after Process selection
        # we have to bind the AjaxUpdate Function on
        # the selects, so we get the complete JSOnDocumentComplete code
        # and deliver it in the FooterJS block.
        # This Javascript Part is executed in
        # AgentTicketProcess.tt
        $LayoutObject->Block(
            Name => 'FooterJS',
        );

        $FooterCSSClass = 'Centered';
    }

    # set submit button data
    my $ButtonText  = 'Submit';
    my $ButtonTitle = 'Save';
    my $ButtonID    = 'Submit' . $ActivityActivityDialog->{ActivityDialog};
    if ( $ActivityDialog->{SubmitButtonText} ) {
        $ButtonText  = $ActivityDialog->{SubmitButtonText};
        $ButtonTitle = $ActivityDialog->{SubmitButtonText};
    }

    $LayoutObject->Block(
        Name => 'Footer',
        Data => {
            FooterCSSClass => $FooterCSSClass,
            ButtonText     => $ButtonText,
            ButtonTitle    => $ButtonTitle,
            ButtonID       => $ButtonID

        },
    );

    if ( $ActivityDialog->{SubmitAdviceText} ) {
        $LayoutObject->Block(
            Name => 'SubmitAdviceText',
            Data => {
                AdviceText => $ActivityDialog->{SubmitAdviceText},
            },
        );
    }

    # reload parent window
    if ( $Param{ParentReload} ) {
        $LayoutObject->AddJSData(
            Key   => 'ParentReload',
            Value => 1,
        );
    }

    # Add the FormFooter
    $Output .= $LayoutObject->Output(
        TemplateFile => 'ProcessManagement/ActivityDialogFooter',
        Data         => {},
    );

    # display regular footer only in non-ajax case
    if ( !$Self->{IsAjaxRequest} ) {
        $Output .= $LayoutObject->Footer( Type => $Self->{IsMainWindow} ? '' : 'Small' );
    }

    return $Output;
}

sub _RenderPendingTime {
    my ( $Self, %Param ) = @_;

    # get layout object
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    for my $Needed (qw(FormID)) {
        if ( !$Param{$Needed} ) {
            return {
                Success => 0,
                Message => $LayoutObject->{LanguageObject}
                    ->Translate( 'Parameter %s is missing in %s.', $Needed, '_RenderPendingTime' ),
            };
        }
    }
    if ( !IsHashRefWithData( $Param{ActivityDialogField} ) ) {
        return {
            Success => 0,
            Message => $LayoutObject->{LanguageObject}
                ->Translate( 'Parameter %s is missing in %s.', 'ActivityDialogField', '_RenderPendingTime' ),
        };
    }

    my %Data = (
        Label => (
            $LayoutObject->{LanguageObject}->Translate('Pending Date')
                . ' ('
                . $LayoutObject->{LanguageObject}->Translate('for pending* states') . ')'
        ),
        FieldID => 'ResponsibleID',
        FormID  => $Param{FormID},
    );

    my $Error = '';
    if ( IsHashRefWithData( $Param{Error} ) ) {
        if ( $Param{Error}->{'PendingtTimeDay'} ) {
            $Data{PendingtTimeDayError} = $LayoutObject->{LanguageObject}->Translate("Date invalid!");
            $Error = $Param{Error}->{'PendingtTimeDay'};
        }
        if ( $Param{Error}->{'PendingtTimeHour'} ) {
            $Data{PendingtTimeHourError} = $LayoutObject->{LanguageObject}->Translate("Date invalid!");
            $Error = $Param{Error}->{'PendingtTimeDay'};
        }
    }

    my $Calendar = '';

    # get ticket object
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    # get used calendar if we have ticket data
    if ( IsHashRefWithData( $Param{Ticket} ) ) {
        $Calendar = $TicketObject->TicketCalendarGet(
            %{ $Param{Ticket} },
        );
    }

    $Data{Content} = $LayoutObject->BuildDateSelection(
        Prefix => 'PendingTime',
        PendingTimeRequired =>
            (
            $Param{ActivityDialogField}->{Display} && $Param{ActivityDialogField}->{Display} == 2
            ) ? 1 : 0,
        Format           => 'DateInputFormatLong',
        YearPeriodPast   => 0,
        YearPeriodFuture => 5,
        DiffTime         => $Param{ActivityDialogField}->{DefaultValue}
            || $Kernel::OM->Get('Kernel::Config')->Get('Ticket::Frontend::PendingDiffTime')
            || 86400,
        Class                => $Error,
        Validate             => 1,
        ValidateDateInFuture => 1,
        Calendar             => $Calendar,
    );

    $LayoutObject->Block(
        Name => $Param{ActivityDialogField}->{LayoutBlock} || 'rw:PendingTime',
        Data => \%Data,
    );
    if ( $Param{DescriptionShort} ) {
        $LayoutObject->Block(
            Name => $Param{ActivityDialogField}->{LayoutBlock} || 'rw:PendingTime:DescriptionShort',
            Data => {
                DescriptionShort => $Param{DescriptionShort},
            },
        );
    }

    if ( $Param{DescriptionLong} ) {
        $LayoutObject->Block(
            Name => 'rw:PendingTime:DescriptionLong',
            Data => {
                DescriptionLong => $Param{DescriptionLong},
            },
        );
    }

    return {
        Success => 1,
        HTML    => $LayoutObject->Output( TemplateFile => 'ProcessManagement/PendingTime' ),
    };
}

sub _RenderDynamicField {
    my ( $Self, %Param ) = @_;

    # get layout object
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    for my $Needed (qw(FormID FieldName)) {
        if ( !$Param{$Needed} ) {
            return {
                Success => 0,
                Message => $LayoutObject->{LanguageObject}
                    ->Translate( 'Parameter %s is missing in %s.', $Needed, '_RenderDynamicField' ),
            };
        }
    }

    my $DynamicField = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldListGet(
        Valid      => 1,
        ObjectType => 'Ticket',
    );

    my $DynamicFieldConfig = ( grep { $_->{Name} eq $Param{FieldName} } @{$DynamicField} )[0];

    if ( !IsHashRefWithData($DynamicFieldConfig) ) {

        my $Message = "DynamicFieldConfig missing for field: $Param{FieldName}, or is not a Ticket Dynamic Field!";

        # log error but does not stop the execution as it could be an old Article
        # DynamicField, see bug#11666
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => $Message,
        );

        return {
            Success => 1,
            HTML    => '',
        };
    }

    my $PossibleValuesFilter;

    # get dynamic field backend object
    my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    my $IsACLReducible = $DynamicFieldBackendObject->HasBehavior(
        DynamicFieldConfig => $DynamicFieldConfig,
        Behavior           => 'IsACLReducible',
    );

    # get ticket object
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    if ($IsACLReducible) {

        # get PossibleValues
        my $PossibleValues = $DynamicFieldBackendObject->PossibleValuesGet(
            DynamicFieldConfig => $DynamicFieldConfig,
        );

        # All Ticket DynamicFields
        # used for ACL checking
        my %DynamicFieldCheckParam = map { $_ => $Param{GetParam}{$_} }
            grep {m{^DynamicField_}xms} ( keys %{ $Param{GetParam} } );

        # check if field has PossibleValues property in its configuration
        if ( IsHashRefWithData($PossibleValues) ) {

            # convert possible values key => value to key => key for ACLs using a Hash slice
            my %AclData = %{$PossibleValues};
            @AclData{ keys %AclData } = keys %AclData;

            # set possible values filter from ACLs
            my $ACL = $TicketObject->TicketAcl(
                %{ $Param{GetParam} },
                DynamicField  => \%DynamicFieldCheckParam,
                Action        => $Self->{Action},
                ReturnType    => 'Ticket',
                ReturnSubType => 'DynamicField_' . $DynamicFieldConfig->{Name},
                Data          => \%AclData,
                UserID        => $Self->{UserID},
            );
            if ($ACL) {
                my %Filter = $TicketObject->TicketAclData();

                # convert Filer key => key back to key => value using map
                %{$PossibleValuesFilter} = map { $_ => $PossibleValues->{$_} } keys %Filter;
            }
        }
    }

    my $ServerError;
    if ( IsHashRefWithData( $Param{Error} ) ) {
        if (
            defined $Param{Error}->{ $Param{FieldName} }
            && $Param{Error}->{ $Param{FieldName} } ne ''
            )
        {
            $ServerError = 1;
        }
    }

    # get stored dynamic field value (split)
    if ( $Self->{LinkTicketID} ) {

        my $Value = $DynamicFieldBackendObject->ValueGet(
            DynamicFieldConfig => $DynamicFieldConfig,
            ObjectID           => $Self->{LinkTicketID},
        );

        $Param{GetParam}->{ 'DynamicField_' . $Param{FieldName} } = $Value;
    }
    my $ErrorMessage = '';
    if ( IsHashRefWithData( $Param{ErrorMessages} ) ) {
        if (
            defined $Param{ErrorMessages}->{ $Param{FieldName} }
            && $Param{ErrorMessages}->{ $Param{FieldName} } ne ''
            )
        {
            $ErrorMessage = $Param{ErrorMessages}->{ $Param{FieldName} };
        }
    }

    my $DynamicFieldHTML = $DynamicFieldBackendObject->EditFieldRender(
        DynamicFieldConfig   => $DynamicFieldConfig,
        PossibleValuesFilter => $PossibleValuesFilter,
        Value                => $Param{GetParam}{ 'DynamicField_' . $Param{FieldName} },
        LayoutObject         => $LayoutObject,
        ParamObject          => $Kernel::OM->Get('Kernel::System::Web::Request'),
        AJAXUpdate           => 1,
        Mandatory            => $Param{ActivityDialogField}->{Display} == 2,
        UpdatableFields      => $Param{AJAXUpdatableFields},
        ServerError          => $ServerError,
        ErrorMessage         => $ErrorMessage,
    );

    my %Data = (
        Name    => $DynamicFieldConfig->{Name},
        Label   => $DynamicFieldHTML->{Label},
        Content => $DynamicFieldHTML->{Field},
    );

    $LayoutObject->Block(
        Name => $Param{ActivityDialogField}->{LayoutBlock} || 'rw:DynamicField',
        Data => \%Data,
    );
    if ( $Param{DescriptionShort} ) {
        $LayoutObject->Block(
            Name => $Param{ActivityDialogField}->{LayoutBlock}
                || 'rw:DynamicField:DescriptionShort',
            Data => {
                DescriptionShort => $Param{DescriptionShort},
            },
        );
    }

    if ( $Param{DescriptionLong} ) {
        $LayoutObject->Block(
            Name => 'rw:DynamicField:DescriptionLong',
            Data => {
                DescriptionLong => $Param{DescriptionLong},
            },
        );
    }

    return {
        Success => 1,
        HTML    => $LayoutObject->Output( TemplateFile => 'ProcessManagement/DynamicField' ),
    };
}

sub _RenderTitle {
    my ( $Self, %Param ) = @_;

    # get layout object
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    for my $Needed (qw(FormID)) {
        if ( !$Param{$Needed} ) {
            return {
                Success => 0,
                Message => $LayoutObject->{LanguageObject}
                    ->Translate( 'Parameter %s is missing in %s.', $Needed, '_RenderTitle' ),
            };
        }
    }
    if ( !IsHashRefWithData( $Param{ActivityDialogField} ) ) {
        return {
            Success => 0,
            Message => $LayoutObject->{LanguageObject}
                ->Translate( 'Parameter %s is missing in %s.', 'ActivityDialogField', '_RenderTitle' ),
        };
    }

    my $Title = $Param{Ticket}->{Title} // '';

    if ( !$Title && $Self->{LinkArticleData} ) {
        my %Ticket = $Kernel::OM->Get('Kernel::System::Ticket')->TicketGet(
            TicketID => $Self->{LinkArticleData}->{TicketID},
            UserID   => $Self->{UserID},
        );
        $Title = $Ticket{Title};
    }

    $Param{GetParam}->{Title} //= $Title;

    my %Data = (
        Label            => $LayoutObject->{LanguageObject}->Translate("Title"),
        FieldID          => 'Title',
        FormID           => $Param{FormID},
        Value            => $Param{GetParam}->{Title},
        Name             => 'Title',
        MandatoryClass   => '',
        ValidateRequired => '',
    );

    # If field is required put in the necessary variables for
    # ValidateRequired class input field, Mandatory class for the label
    if ( $Param{ActivityDialogField}->{Display} && $Param{ActivityDialogField}->{Display} == 2 ) {
        $Data{ValidateRequired} = 'Validate_Required';
        $Data{MandatoryClass}   = 'Mandatory';
    }

    # output server errors
    if ( IsHashRefWithData( $Param{Error} ) && $Param{Error}->{'Title'} ) {
        $Data{ServerError} = 'ServerError';
    }

    $LayoutObject->Block(
        Name => $Param{ActivityDialogField}->{LayoutBlock} || 'rw:Title',
        Data => \%Data,
    );

    # set mandatory label marker
    if ( $Data{MandatoryClass} && $Data{MandatoryClass} ne '' ) {
        $LayoutObject->Block(
            Name => 'LabelSpan',
            Data => {},
        );
    }

    if ( $Param{DescriptionShort} ) {
        $LayoutObject->Block(
            Name => $Param{ActivityDialogField}->{LayoutBlock} || 'rw:Title:DescriptionShort',
            Data => {
                DescriptionShort => $Param{DescriptionShort},
            },
        );
    }

    if ( $Param{DescriptionLong} ) {
        $LayoutObject->Block(
            Name => $Param{ActivityDialogField}->{LayoutBlock} || 'rw:Title:DescriptionLong',
            Data => {
                DescriptionLong => $Param{DescriptionLong},
            },
        );
    }

    return {
        Success => 1,
        HTML    => $LayoutObject->Output( TemplateFile => 'ProcessManagement/Title' ),
    };

}

sub _RenderArticle {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    for my $Needed (qw(FormID Ticket)) {
        if ( !$Param{$Needed} ) {
            return {
                Success => 0,
                Message => $LayoutObject->{LanguageObject}
                    ->Translate( 'Parameter %s is missing in %s.', $Needed, '_RenderArticle' ),
            };
        }
    }
    if ( !IsHashRefWithData( $Param{ActivityDialogField} ) ) {
        return {
            Success => 0,
            Message => $LayoutObject->{LanguageObject}
                ->Translate( 'Parameter %s is missing in %s.', 'ActivityDialogField', '_RenderArticle' ),
        };
    }

    if ( IsHashRefWithData( $Self->{LinkArticleData} ) ) {
        my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
        my $TicketNumber = $TicketObject->TicketNumberLookup(
            TicketID => $Self->{LinkArticleData}->{TicketID},
        );

        # prepare subject
        $Param{GetParam}->{Subject} = $TicketObject->TicketSubjectClean(
            TicketNumber => $TicketNumber,
            Subject      => $Self->{LinkArticleData}->{Subject} || '',
        );

        # body preparation for plain text processing
        $Param{GetParam}->{Body} = $LayoutObject->ArticleQuote(
            TicketID           => $Self->{LinkArticleData}->{TicketID},
            ArticleID          => $Self->{LinkArticleData}->{ArticleID},
            FormID             => $Self->{FormID},
            UploadCacheObject  => $Kernel::OM->Get('Kernel::System::Web::UploadCache'),
            AttachmentsInclude => 1,
        );

        my %SafetyCheckResult = $Kernel::OM->Get('Kernel::System::HTMLUtils')->Safety(
            String => $Param{GetParam}->{Body},

            # Strip out external content if BlockLoadingRemoteContent is enabled.
            NoExtSrcLoad => $ConfigObject->Get('Ticket::Frontend::BlockLoadingRemoteContent'),

            # Disallow potentially unsafe content.
            NoApplet     => 1,
            NoObject     => 1,
            NoEmbed      => 1,
            NoSVG        => 1,
            NoJavaScript => 1,
        );
        $Param{GetParam}->{Body} = $SafetyCheckResult{String};
    }

    # get all attachments meta data
    my @Attachments = $Kernel::OM->Get('Kernel::System::Web::UploadCache')->FormIDGetAllFilesMeta(
        FormID => $Self->{FormID},
    );

    # show attachments
    ATTACHMENT:
    for my $Attachment (@Attachments) {
        if (
            $Attachment->{ContentID}
            && $LayoutObject->{BrowserRichText}
            && ( $Attachment->{ContentType} =~ /image/i )
            && ( $Attachment->{Disposition} eq 'inline' )
            )
        {
            next ATTACHMENT;
        }

        push @{ $Param{AttachmentList} }, $Attachment;
    }

    my %Data = (
        Name             => 'Article',
        MandatoryClass   => '',
        ValidateRequired => '',
        Subject          => $Param{GetParam}->{Subject},
        Body             => $Param{GetParam}->{Body},
        LabelSubject     => $Param{ActivityDialogField}->{Config}->{LabelSubject}
            || $LayoutObject->{LanguageObject}->Translate("Subject"),
        LabelBody => $Param{ActivityDialogField}->{Config}->{LabelBody}
            || $LayoutObject->{LanguageObject}->Translate("Text"),
        AttachmentList => $Param{AttachmentList},
    );

    # If field is required put in the necessary variables for
    # ValidateRequired class input field, Mandatory class for the label
    if ( $Param{ActivityDialogField}->{Display} && $Param{ActivityDialogField}->{Display} == 2 ) {
        $Data{ValidateRequired} = 'Validate_Required';
        $Data{MandatoryClass}   = 'Mandatory';
    }

    # output server errors
    if ( IsHashRefWithData( $Param{Error} ) && $Param{Error}->{'ArticleSubject'} ) {
        $Data{SubjectServerError} = 'ServerError';
    }
    if ( IsHashRefWithData( $Param{Error} ) && $Param{Error}->{'ArticleBody'} ) {
        $Data{BodyServerError} = 'ServerError';
    }

    $LayoutObject->Block(
        Name => $Param{ActivityDialogField}->{LayoutBlock} || 'rw:Article',
        Data => \%Data,
    );

    # set mandatory label marker
    if ( $Data{MandatoryClass} && $Data{MandatoryClass} ne '' ) {
        $LayoutObject->Block(
            Name => 'LabelSpanSubject',
            Data => {},
        );
        $LayoutObject->Block(
            Name => 'LabelSpanBody',
            Data => {},
        );
    }

    # add rich text editor
    if ( $LayoutObject->{BrowserRichText} ) {

        # use height/width defined for this screen
        $Param{RichTextHeight} = $Self->{Config}->{RichTextHeight} || 0;
        $Param{RichTextWidth}  = $Self->{Config}->{RichTextWidth}  || 0;

        # set up rich text editor
        $LayoutObject->SetRichTextParameters(
            Data => \%Param,
        );
    }

    if ( $Param{DescriptionShort} ) {
        $LayoutObject->Block(
            Name => 'rw:Article:DescriptionShort',
            Data => {
                DescriptionShort => $Param{DescriptionShort},
            },
        );
    }

    if ( $Param{DescriptionLong} ) {
        $LayoutObject->Block(
            Name => 'rw:Article:DescriptionLong',
            Data => {
                DescriptionLong => $Param{DescriptionLong},
            },
        );
    }

    if ( $Param{InformAgents} ) {

        my %ShownUsers;
        my %AllGroupsMembers = $Kernel::OM->Get('Kernel::System::User')->UserList(
            Type  => 'Long',
            Valid => 1,
        );
        my $GID = $Kernel::OM->Get('Kernel::System::Queue')->GetQueueGroupID( QueueID => $Param{Ticket}->{QueueID} );
        my %MemberList = $Kernel::OM->Get('Kernel::System::Group')->PermissionGroupGet(
            GroupID => $GID,
            Type    => 'ro',
        );
        for my $UserID ( sort keys %MemberList ) {
            $ShownUsers{$UserID} = $AllGroupsMembers{$UserID};
        }
        $Param{OptionStrg} = $LayoutObject->BuildSelection(
            Data       => \%ShownUsers,
            SelectedID => '',
            Name       => 'InformUserID',
            Multiple   => 1,
            Size       => 3,
            Class      => 'Modernize',
        );
        $LayoutObject->Block(
            Name => 'rw:Article:InformAgent',
            Data => \%Param,
        );
    }

    # output server errors
    if ( IsHashRefWithData( $Param{Error} ) && $Param{Error}->{'TimeUnits'} ) {
        $Param{TimeUnitsInvalid} = 'ServerError';
    }

    # show time units
    if (
        $ConfigObject->Get('Ticket::Frontend::AccountTime')
        && $Param{ActivityDialogField}->{Config}->{TimeUnits}
        )
    {

        $Param{TimeUnitsRequired} = 1;
        if ( $Param{ActivityDialogField}->{Config}->{TimeUnits} == 2 ) {
            $Param{TimeUnitsRequired} = 1;
        }
        elsif ( $Param{ActivityDialogField}->{Config}->{TimeUnits} == 1 ) {
            $Param{TimeUnitsRequired} = 0;
        }

        # Get TimeUnits value.
        $Param{TimeUnits} = $Param{GetParam}->{TimeUnits};

        if ( !defined $Param{TimeUnits} && $Self->{ArticleID} ) {
            $Param{TimeUnits} = $Self->_GetTimeUnits(
                ArticleID => $Self->{ArticleID},
            );
        }

        $Param{TimeUnitsBlock} = $LayoutObject->TimeUnits(
            %Param,
        );
        $LayoutObject->Block(
            Name => 'TimeUnits',
            Data => \%Param,
        );
    }

    # show StandardTemplates
    if ( IsArrayRefWithData( $Param{ActivityDialogField}->{Config}->{StandardTemplateID} ) ) {
        my $StandardTemplateObject = $Kernel::OM->Get('Kernel::System::StandardTemplate');

        my %StandardTemplates = $StandardTemplateObject->StandardTemplateList(
            Valid => 1,
            Type  => 'ProcessManagement',
        );

        STANDARDTEMPLATEID:
        for my $StandardTemplateID ( sort keys %StandardTemplates ) {
            my $Exists
                = grep { $StandardTemplateID eq $_ } @{ $Param{ActivityDialogField}->{Config}->{StandardTemplateID} };
            next STANDARDTEMPLATEID if $Exists;

            delete $StandardTemplates{$StandardTemplateID};
        }

        if (%StandardTemplates) {
            $Param{StandardTemplateStrg} = $LayoutObject->BuildSelection(
                Data         => \%StandardTemplates,
                Name         => 'StandardTemplateID',
                SelectedID   => $Param{GetParam}->{StandardTemplateID} || '',
                Class        => 'Modernize',
                PossibleNone => 1,
                Sort         => 'AlphanumericValue',
                Translation  => 1,
                Max          => 200,
            );

            $LayoutObject->AddJSData(
                Key   => 'StandardTemplateAutoFill',
                Value => $Param{ActivityDialogField}->{Config}->{StandardTemplateAutoFill} || 0,
            );

            $LayoutObject->Block(
                Name => 'StandardTemplate',
                Data => \%Param,
            );
        }
    }

    return {
        Success => 1,
        HTML    => $LayoutObject->Output( TemplateFile => 'ProcessManagement/Article' ),
    };
}

sub _GetTimeUnits {
    my ( $Self, %Param ) = @_;

    my $AccountedTime = '';

    # Get accounted time if AccountTime config item is enabled.
    if ( $Kernel::OM->Get('Kernel::Config')->Get('Ticket::Frontend::AccountTime') && defined $Param{ArticleID} ) {
        $AccountedTime = $Kernel::OM->Get('Kernel::System::Ticket::Article')->ArticleAccountedTimeGet(
            ArticleID => $Param{ArticleID},
        );
    }

    return $AccountedTime ? $AccountedTime : '';
}

sub _RenderCustomer {
    my ( $Self, %Param ) = @_;

    # get layout object
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    for my $Needed (qw(FormID)) {
        if ( !$Param{$Needed} ) {
            return {
                Success => 0,
                Message => $LayoutObject->{LanguageObject}
                    ->Translate( 'Parameter %s is missing in %s.', $Needed, '_RenderCustomer' ),
            };
        }
    }
    if ( !IsHashRefWithData( $Param{ActivityDialogField} ) ) {
        return {
            Success => 0,
            Message => $LayoutObject->{LanguageObject}
                ->Translate( 'Parameter %s is missing in %s.', 'ActivityDialogField', '_RenderCustomer' ),
        };
    }

    my %CustomerUserData = ();

    my $SubmittedCustomerUserID = $Param{GetParam}{CustomerUserID};

    my %Data = (
        LabelCustomerUser => $LayoutObject->{LanguageObject}->Translate("Customer user"),
        LabelCustomerID   => $LayoutObject->{LanguageObject}->Translate("CustomerID"),
        FormID            => $Param{FormID},
        MandatoryClass    => '',
        ValidateRequired  => '',
    );

    # If field is required put in the necessary variables for
    # ValidateRequired class input field, Mandatory class for the label
    if ( $Param{ActivityDialogField}->{Display} && $Param{ActivityDialogField}->{Display} == 2 ) {
        $Data{ValidateRequired} = 'Validate_Required';
        $Data{MandatoryClass}   = 'Mandatory';
    }

    # output server errors
    if ( IsHashRefWithData( $Param{Error} ) && $Param{Error}->{CustomerUserID} ) {
        $Data{CustomerUserIDServerError} = 'ServerError';
    }
    if ( IsHashRefWithData( $Param{Error} ) && $Param{Error}->{CustomerID} ) {
        $Data{CustomerIDServerError} = 'ServerError';
    }

    if ( $Self->{LinkTicketData} ) {
        %CustomerUserData = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerUserDataGet(
            User => $Self->{LinkTicketData}->{CustomerUserID},
        );
    }

    if (
        ( IsHashRefWithData( $Param{Ticket} ) && $Param{Ticket}->{CustomerUserID} )
        || $SubmittedCustomerUserID
        )
    {
        %CustomerUserData = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerUserDataGet(
            User => $SubmittedCustomerUserID
                || $Param{Ticket}{CustomerUserID},
        );
    }

    # Customer user from article is preselected for new split ticket. See bug#12956.
    if (
        IsHashRefWithData( $Self->{LinkArticleData} )
        && $Self->{LinkArticleData}->{From}
        && $Self->{LinkArticleData}->{SenderType} eq 'customer'
        )
    {

        my @ArticleFromAddress = Mail::Address->parse( $Self->{LinkArticleData}->{From} );

        my $CustomerUserObject = $Kernel::OM->Get('Kernel::System::CustomerUser');
        my %List               = $CustomerUserObject->CustomerSearch(
            PostMasterSearch => $ArticleFromAddress[0]->address(),
            Valid            => 1,
        );

        my @CustomerUser = sort keys %List;
        %CustomerUserData = $CustomerUserObject->CustomerUserDataGet(
            User => $CustomerUser[0],
        );
    }

    # show customer field as "FirstName Lastname" <MailAddress>
    if ( IsHashRefWithData( \%CustomerUserData ) ) {
        $Data{CustomerUserID}       = "\"$CustomerUserData{UserFullname}" . "\" <$CustomerUserData{UserEmail}>";
        $Data{CustomerID}           = $CustomerUserData{UserCustomerID} || '';
        $Data{SelectedCustomerUser} = $CustomerUserData{UserID} || '';
    }

    # When there is no Customer in the DB, it could be unknown Customer, set it from the ticket.
    # See bug#12797 ( https://bugs.otrs.org/show_bug.cgi?id=12797 ).
    else {
        $Data{CustomerUserID} = $Param{Ticket}{CustomerUserID} || '';
        $Data{CustomerID}     = $Param{Ticket}{CustomerID}     || '';
    }

    # send data to JS
    $LayoutObject->AddJSData(
        Key   => 'CustomerFieldsToUpdate',
        Value => $Param{AJAXUpdatableFields},
    );

    if ( $Param{DescriptionShort} ) {
        $Data{DescriptionShort} = $Param{DescriptionShort};
    }

    $LayoutObject->Block(
        Name => $Param{ActivityDialogField}->{LayoutBlock} || 'rw:Customer',
        Data => \%Data,
    );

    # set mandatory label marker
    if ( $Data{MandatoryClass} && $Data{MandatoryClass} ne '' ) {
        $LayoutObject->Block(
            Name => 'LabelSpanCustomerUser',
            Data => {},
        );
    }

    if ( $Param{DescriptionLong} ) {
        $LayoutObject->Block(
            Name => 'rw:Customer:DescriptionLong',
            Data => {
                DescriptionLong => $Param{DescriptionLong},
            },
        );
    }

    return {
        Success => 1,
        HTML    => $LayoutObject->Output( TemplateFile => 'ProcessManagement/Customer' ),
    };
}

sub _RenderResponsible {
    my ( $Self, %Param ) = @_;

    # get layout object
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    for my $Needed (qw(FormID)) {
        if ( !$Param{$Needed} ) {
            return {
                Success => 0,
                Message => $LayoutObject->{LanguageObject}
                    ->Translate( 'Parameter %s is missing in %s.', $Needed, '_RenderResponsible' ),
            };
        }
    }
    if ( !IsHashRefWithData( $Param{ActivityDialogField} ) ) {
        return {
            Success => 0,
            Message => $LayoutObject->{LanguageObject}
                ->Translate( 'Parameter %s is missing in %s.', 'ActivityDialogField', '_RenderResponsible' ),
        };
    }

    if ( $Self->{LinkTicketData} ) {
        $Param{GetParam}->{ResponsibleAll} = 1;
    }

    my $Responsibles = $Self->_GetResponsibles( %{ $Param{GetParam} } );

    my %Data = (
        Label            => $LayoutObject->{LanguageObject}->Translate("Responsible"),
        FieldID          => 'ResponsibleID',
        FormID           => $Param{FormID},
        ResponsibleAll   => $Param{GetParam}{ResponsibleAll},
        MandatoryClass   => '',
        ValidateRequired => '',
    );

    # if field is required put in the necessary variables for
    #    ValidateRequired class input field, Mandatory class for the label
    if ( $Param{ActivityDialogField}->{Display} && $Param{ActivityDialogField}->{Display} == 2 ) {
        $Data{ValidateRequired} = 'Validate_Required';
        $Data{MandatoryClass}   = 'Mandatory';
    }

    my $SelectedValue;

    # get user object
    my $UserObject = $Kernel::OM->Get('Kernel::System::User');

    if ( $Param{ActivityDialogField}->{DefaultValue} ) {

        if ( $Param{FieldName} eq 'Responsible' ) {

            # Fetch DefaultValue from Config
            if ( !$SelectedValue ) {
                $SelectedValue = $UserObject->UserLookup(
                    UserLogin => $Param{ActivityDialogField}->{DefaultValue} || '',
                );
                if ($SelectedValue) {
                    $SelectedValue = $Param{ActivityDialogField}->{DefaultValue};
                }
            }
        }
        else {
            if ( !$SelectedValue ) {
                $SelectedValue = $UserObject->UserLookup(
                    UserID => $Param{ActivityDialogField}->{DefaultValue} || '',
                );
            }
        }
    }

    my $ResponsibleIDParam = $Param{GetParam}{ResponsibleID};
    if ( $ResponsibleIDParam && !$SelectedValue ) {
        $SelectedValue = $UserObject->UserLookup( UserID => $ResponsibleIDParam );
    }

    # if there is no user from GetParam or default and the field is mandatory get it from the ticket
    #    (if any)
    if (
        !$SelectedValue
        && $Param{ActivityDialogField}->{Display} == 2
        && IsHashRefWithData( $Param{Ticket} )
        )
    {
        $SelectedValue = $Param{Ticket}->{Responsible};
    }

    # if we have a user already and the field is not mandatory and it is the same as in ticket, then
    #    set it to none (as it doesn't need to be changed afterall)
    elsif (
        $SelectedValue
        && $Param{ActivityDialogField}->{Display} != 2
        && IsHashRefWithData( $Param{Ticket} )
        && $SelectedValue eq $Param{Ticket}->{Responsible}
        )
    {
        $SelectedValue = '';
    }

    # set server errors
    my $ServerError = '';
    if ( IsHashRefWithData( $Param{Error} ) && $Param{Error}->{'ResponsibleID'} ) {
        $ServerError = 'ServerError';
    }

    # look up $SelectedID
    my $SelectedID;
    if ($SelectedValue) {
        $SelectedID = $UserObject->UserLookup(
            UserLogin => $SelectedValue,
        );
    }

    if ( $Self->{LinkTicketData} ) {
        $SelectedID = $Self->{LinkTicketData}->{ResponsibleID};
    }

    # build Responsible string
    $Data{Content} = $LayoutObject->BuildSelection(
        Data         => $Responsibles,
        Name         => 'ResponsibleID',
        Translation  => 1,
        SelectedID   => $SelectedID,
        Class        => "Modernize $ServerError",
        PossibleNone => 1,
    );

    # send data to JS
    $LayoutObject->AddJSData(
        Key   => 'ResponsibleFieldsToUpdate',
        Value => $Param{AJAXUpdatableFields}
    );

    $LayoutObject->Block(
        Name => $Param{ActivityDialogField}->{LayoutBlock} || 'rw:Responsible',
        Data => \%Data,
    );

    # set mandatory label marker
    if ( $Data{MandatoryClass} && $Data{MandatoryClass} ne '' ) {
        $LayoutObject->Block(
            Name => 'LabelSpan',
            Data => {},
        );
    }

    if ( $Param{DescriptionShort} ) {
        $LayoutObject->Block(
            Name => $Param{ActivityDialogField}->{LayoutBlock} || 'rw:Responsible:DescriptionShort',
            Data => {
                DescriptionShort => $Param{DescriptionShort},
            },
        );
    }

    if ( $Param{DescriptionLong} ) {
        $LayoutObject->Block(
            Name => 'rw:Responsible:DescriptionLong',
            Data => {
                DescriptionLong => $Param{DescriptionLong},
            },
        );
    }

    return {
        Success => 1,
        HTML    => $LayoutObject->Output( TemplateFile => 'ProcessManagement/Responsible' ),
    };

}

sub _RenderOwner {
    my ( $Self, %Param ) = @_;

    # get layout object
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    for my $Needed (qw(FormID)) {
        if ( !$Param{$Needed} ) {
            return {
                Success => 0,
                Message => $LayoutObject->{LanguageObject}
                    ->Translate( 'Parameter %s is missing in %s.', $Needed, '_RenderOwner' ),
            };
        }
    }
    if ( !IsHashRefWithData( $Param{ActivityDialogField} ) ) {
        return {
            Success => 0,
            Message => $LayoutObject->{LanguageObject}
                ->Translate( 'Parameter %s is missing in %s.', 'ActivityDialogField', '_RenderOwner' ),
        };
    }

    if ( $Self->{LinkTicketData} ) {
        $Param{GetParam}->{OwnerAll} = 1;
    }

    my $Owners = $Self->_GetOwners( %{ $Param{GetParam} } );

    my %Data = (
        Label            => $LayoutObject->{LanguageObject}->Translate("Owner"),
        FieldID          => 'OwnerID',
        FormID           => $Param{FormID},
        OwnerAll         => $Param{GetParam}{OwnerAll},
        MandatoryClass   => '',
        ValidateRequired => '',
    );

    # if field is required put in the necessary variables for
    #    ValidateRequired class input field, Mandatory class for the label
    if ( $Param{ActivityDialogField}->{Display} && $Param{ActivityDialogField}->{Display} == 2 ) {
        $Data{ValidateRequired} = 'Validate_Required';
        $Data{MandatoryClass}   = 'Mandatory';
    }

    my $SelectedValue;

    # get user object
    my $UserObject = $Kernel::OM->Get('Kernel::System::User');

    if ( $Param{ActivityDialogField}->{DefaultValue} ) {

        if ( $Param{FieldName} eq 'Owner' ) {

            if ( !$SelectedValue ) {

                # Fetch DefaultValue from Config
                $SelectedValue = $UserObject->UserLookup(
                    UserLogin => $Param{ActivityDialogField}->{DefaultValue} || '',
                );
                if ($SelectedValue) {
                    $SelectedValue = $Param{ActivityDialogField}->{DefaultValue};
                }
            }
        }
        else {
            if ( !$SelectedValue ) {
                $SelectedValue = $UserObject->UserLookup(
                    UserID => $Param{ActivityDialogField}->{DefaultValue} || '',
                );
            }
        }
    }

    my $OwnerIDParam = $Param{GetParam}{OwnerID};
    if ( $OwnerIDParam && !$SelectedValue ) {
        $SelectedValue = $UserObject->UserLookup(
            UserID => $OwnerIDParam,
        );
    }

    # if there is no user from GetParam or default and the field is mandatory get it from the ticket
    #    (if any)
    if (
        !$SelectedValue
        && $Param{ActivityDialogField}->{Display} == 2
        && IsHashRefWithData( $Param{Ticket} )
        )
    {
        $SelectedValue = $Param{Ticket}->{Owner};
    }

    # if we have a user already and the field is not mandatory and it is the same as in ticket, then
    #    set it to none (as it doesn't need to be changed afterall)
    elsif (
        $SelectedValue
        && $Param{ActivityDialogField}->{Display} != 2
        && IsHashRefWithData( $Param{Ticket} )
        && $SelectedValue eq $Param{Ticket}->{Owner}
        )
    {
        $SelectedValue = '';
    }

    # set server errors
    my $ServerError = '';
    if ( IsHashRefWithData( $Param{Error} ) && $Param{Error}->{'OwnerID'} ) {
        $ServerError = 'ServerError';
    }

    if ( $Self->{LinkTicketData} ) {
        $SelectedValue = $Self->{LinkTicketData}->{OwnerID};
    }

    # look up $SelectedID
    my $SelectedID;
    if ($SelectedValue) {
        $SelectedID = $UserObject->UserLookup(
            UserLogin => $SelectedValue,
        );
    }

    # build Owner string
    $Data{Content} = $LayoutObject->BuildSelection(
        Data         => $Owners,
        Name         => 'OwnerID',
        Translation  => 1,
        SelectedID   => $SelectedID || '',
        Class        => "Modernize $ServerError",
        PossibleNone => 1,
    );

    # send data to JS
    $LayoutObject->AddJSData(
        Key   => 'OwnerFieldsToUpdate',
        Value => $Param{AJAXUpdatableFields}
    );

    $LayoutObject->Block(
        Name => $Param{ActivityDialogField}->{LayoutBlock} || 'rw:Owner',
        Data => \%Data,
    );

    # set mandatory label marker
    if ( $Data{MandatoryClass} && $Data{MandatoryClass} ne '' ) {
        $LayoutObject->Block(
            Name => 'LabelSpan',
            Data => {},
        );
    }

    if ( $Param{DescriptionShort} ) {
        $LayoutObject->Block(
            Name => $Param{ActivityDialogField}->{LayoutBlock} || 'rw:Owner:DescriptionShort',
            Data => {
                DescriptionShort => $Param{DescriptionShort},
            },
        );
    }

    if ( $Param{DescriptionLong} ) {
        $LayoutObject->Block(
            Name => 'rw:Owner:DescriptionLong',
            Data => {
                DescriptionLong => $Param{DescriptionLong},
            },
        );
    }

    return {
        Success => 1,
        HTML    => $LayoutObject->Output( TemplateFile => 'ProcessManagement/Owner' ),
    };
}

sub _RenderSLA {
    my ( $Self, %Param ) = @_;

    # get layout object
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    for my $Needed (qw(FormID)) {
        if ( !$Param{$Needed} ) {
            return {
                Success => 0,
                Message => $LayoutObject->{LanguageObject}
                    ->Translate( 'Parameter %s is missing in %s.', $Needed, '_RenderSLA' ),
            };
        }
    }
    if ( !IsHashRefWithData( $Param{ActivityDialogField} ) ) {
        return {
            Success => 0,
            Message => $LayoutObject->{LanguageObject}
                ->Translate( 'Parameter %s is missing in %s.', 'ActivityDialogField', '_RenderSLA' ),
        };
    }

    if ( $Self->{LinkTicketData} ) {
        $Param{GetParam}->{QueueID}        = $Self->{LinkTicketData}->{QueueID};
        $Param{GetParam}->{TicketID}       = $Self->{LinkTicketData}->{TicketID};
        $Param{GetParam}->{CustomerUserID} = $Self->{LinkTicketData}->{CustomerUserID};
    }

    # create a local copy of the GetParam
    my %GetServicesParam = %{ $Param{GetParam} };

    # use ticket information as a fall back if customer was already set, otherwise when the
    # activity dialog displays the service list will be initially empty, see bug#10059
    if ( IsHashRefWithData( $Param{Ticket} ) ) {
        $GetServicesParam{CustomerUserID} ||= $Param{Ticket}->{CustomerUserID} ||= '';
    }

    my $Services = $Self->_GetServices(
        %GetServicesParam,
    );

    if ( $Self->{LinkTicketData} ) {
        $Param{GetParam}->{Services}  = $Services;
        $Param{GetParam}->{ServiceID} = $Self->{LinkTicketData}->{ServiceID};
    }

    my $SLAs = $Self->_GetSLAs(
        %{ $Param{GetParam} },
        Services => $Services,
    );

    my %Data = (
        Label            => $LayoutObject->{LanguageObject}->Translate("SLA"),
        FieldID          => 'SLAID',
        FormID           => $Param{FormID},
        MandatoryClass   => '',
        ValidateRequired => '',
    );

    # If field is required put in the necessary variables for
    # ValidateRequired class input field, Mandatory class for the label
    if ( $Param{ActivityDialogField}->{Display} && $Param{ActivityDialogField}->{Display} == 2 ) {
        $Data{ValidateRequired} = 'Validate_Required';
        $Data{MandatoryClass}   = 'Mandatory';
    }

    my $SelectedValue;

    # get SLA object
    my $SLAObject = $Kernel::OM->Get('Kernel::System::SLA');

    my $SLAIDParam = $Param{GetParam}{SLAID};
    if ($SLAIDParam) {
        $SelectedValue = $SLAObject->SLALookup( SLAID => $SLAIDParam );
    }

    if ( $Param{FieldName} eq 'SLA' ) {

        if ( !$SelectedValue ) {

            # Fetch DefaultValue from Config
            if (
                defined $Param{ActivityDialogField}->{DefaultValue}
                && $Param{ActivityDialogField}->{DefaultValue} ne ''
                )
            {
                $SelectedValue = $SLAObject->SLALookup(
                    SLA => $Param{ActivityDialogField}->{DefaultValue},
                );
            }

            if ($SelectedValue) {
                $SelectedValue = $Param{ActivityDialogField}->{DefaultValue};
            }
        }
    }
    else {
        if ( !$SelectedValue ) {
            if (
                defined $Param{ActivityDialogField}->{DefaultValue}
                && $Param{ActivityDialogField}->{DefaultValue} ne ''
                )
            {
                $SelectedValue = $SLAObject->SLALookup(
                    SLA => $Param{ActivityDialogField}->{DefaultValue},
                );
            }
        }
    }

    # Get TicketValue
    if ( IsHashRefWithData( $Param{Ticket} ) && !$SelectedValue ) {
        $SelectedValue = $Param{Ticket}->{SLA};
    }

    # set server errors
    my $ServerError = '';
    if ( IsHashRefWithData( $Param{Error} ) && $Param{Error}->{'SLAID'} ) {
        $ServerError = 'ServerError';
    }

    if ( $Self->{LinkTicketData} ) {
        $SelectedValue = $Self->{LinkTicketData}->{SLA};
    }

    # build SLA string
    $Data{Content} = $LayoutObject->BuildSelection(
        Data          => $SLAs,
        Name          => 'SLAID',
        SelectedValue => $SelectedValue,
        PossibleNone  => 1,
        Sort          => 'AlphanumericValue',
        Translation   => 0,
        Class         => "Modernize $ServerError",
        Max           => 200,
    );

    # send data to JS
    $LayoutObject->AddJSData(
        Key   => 'SLAFieldsToUpdate',
        Value => $Param{AJAXUpdatableFields}
    );

    $LayoutObject->Block(
        Name => $Param{ActivityDialogField}->{LayoutBlock} || 'rw:SLA',
        Data => \%Data,
    );

    # set mandatory label marker
    if ( $Data{MandatoryClass} && $Data{MandatoryClass} ne '' ) {
        $LayoutObject->Block(
            Name => 'LabelSpan',
            Data => {},
        );
    }

    if ( $Param{DescriptionShort} ) {
        $LayoutObject->Block(
            Name => $Param{ActivityDialogField}->{LayoutBlock} || 'rw:SLA:DescriptionShort',
            Data => {
                DescriptionShort => $Param{DescriptionShort},
            },
        );
    }

    if ( $Param{DescriptionLong} ) {
        $LayoutObject->Block(
            Name => 'rw:SLA:DescriptionLong',
            Data => {
                DescriptionLong => $Param{DescriptionLong},
            },
        );
    }

    return {
        Success => 1,
        HTML    => $LayoutObject->Output( TemplateFile => 'ProcessManagement/SLA' ),
    };
}

sub _RenderService {
    my ( $Self, %Param ) = @_;

    # get layout object
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    for my $Needed (qw(FormID)) {
        if ( !$Param{$Needed} ) {
            return {
                Success => 0,
                Message => $LayoutObject->{LanguageObject}
                    ->Translate( 'Parameter %s is missing in %s.', $Needed, '_RenderService' ),
            };
        }
    }
    if ( !IsHashRefWithData( $Param{ActivityDialogField} ) ) {
        return {
            Success => 0,
            Message => $LayoutObject->{LanguageObject}
                ->Translate( 'Parameter %s is missing in %s.', 'ActivityDialogField', '_RenderService' ),
        };
    }

    if ( $Self->{LinkTicketData} ) {
        $Param{GetParam}->{QueueID}        = $Self->{LinkTicketData}->{QueueID};
        $Param{GetParam}->{TicketID}       = $Self->{LinkTicketData}->{TicketID};
        $Param{GetParam}->{CustomerUserID} = $Self->{LinkTicketData}->{CustomerUserID};
    }

    # create a local copy of the GetParam
    my %GetServicesParam = %{ $Param{GetParam} };

    # use ticket information as a fall back if customer was already set, otherwise when the
    # activity dialog displays the service list will be initially empty, see bug#10059
    if ( IsHashRefWithData( $Param{Ticket} ) ) {
        $GetServicesParam{CustomerUserID} ||= $Param{Ticket}->{CustomerUserID} ||= '';
    }

    my $Services = $Self->_GetServices(
        %GetServicesParam,
    );

    my %Data = (
        Label            => $LayoutObject->{LanguageObject}->Translate("Service"),
        FieldID          => 'ServiceID',
        FormID           => $Param{FormID},
        MandatoryClass   => '',
        ValidateRequired => '',
    );

    # If field is required put in the necessary variables for
    # ValidateRequired class input field, Mandatory class for the label
    if ( $Param{ActivityDialogField}->{Display} && $Param{ActivityDialogField}->{Display} == 2 ) {
        $Data{ValidateRequired} = 'Validate_Required';
        $Data{MandatoryClass}   = 'Mandatory';
    }

    my $SelectedValue;

    # get service object
    my $ServiceObject = $Kernel::OM->Get('Kernel::System::Service');

    my $ServiceIDParam = $Param{GetParam}{ServiceID};
    if ($ServiceIDParam) {
        $SelectedValue = $ServiceObject->ServiceLookup(
            ServiceID => $ServiceIDParam,
        );
    }

    if ( $Param{FieldName} eq 'Service' ) {

        if ( !$SelectedValue ) {

            # Fetch DefaultValue from Config
            if (
                defined $Param{ActivityDialogField}->{DefaultValue}
                && $Param{ActivityDialogField}->{DefaultValue} ne ''
                )
            {
                $SelectedValue = $ServiceObject->ServiceLookup(
                    Name => $Param{ActivityDialogField}->{DefaultValue},
                );
            }
            if ($SelectedValue) {
                $SelectedValue = $Param{ActivityDialogField}->{DefaultValue};
            }
        }
    }
    else {
        if ( !$SelectedValue ) {
            if (
                defined $Param{ActivityDialogField}->{DefaultValue}
                && $Param{ActivityDialogField}->{DefaultValue} ne ''
                )
            {
                $SelectedValue = $ServiceObject->ServiceLookup(
                    Service => $Param{ActivityDialogField}->{DefaultValue},
                );
            }
        }
    }

    # Get TicketValue
    if ( IsHashRefWithData( $Param{Ticket} ) && !$SelectedValue ) {
        $SelectedValue = $Param{Ticket}->{Service};
    }

    # set server errors
    my $ServerError = '';
    if ( IsHashRefWithData( $Param{Error} ) && $Param{Error}->{'ServiceID'} ) {
        $ServerError = 'ServerError';
    }

    # get list type
    my $TreeView = 0;
    if ( $Kernel::OM->Get('Kernel::Config')->Get('Ticket::Frontend::ListType') eq 'tree' ) {
        $TreeView = 1;
    }

    if ( $Self->{LinkTicketData} ) {
        $SelectedValue = $Self->{LinkTicketData}->{Service};
    }

    # build Service string
    $Data{Content} = $LayoutObject->BuildSelection(
        Data          => $Services,
        Name          => 'ServiceID',
        Class         => "Modernize $ServerError",
        SelectedValue => $SelectedValue,
        PossibleNone  => 1,
        TreeView      => $TreeView,
        Sort          => 'TreeView',
        Translation   => 0,
        Max           => 200,
    );

    # send data to JS
    $LayoutObject->AddJSData(
        Key   => 'ServiceFieldsToUpdate',
        Value => $Param{AJAXUpdatableFields}
    );

    $LayoutObject->Block(
        Name => $Param{ActivityDialogField}->{LayoutBlock} || 'rw:Service',
        Data => \%Data,
    );

    # set mandatory label marker
    if ( $Data{MandatoryClass} && $Data{MandatoryClass} ne '' ) {
        $LayoutObject->Block(
            Name => 'LabelSpan',
            Data => {},
        );
    }

    if ( $Param{DescriptionShort} ) {
        $LayoutObject->Block(
            Name => $Param{ActivityDialogField}->{LayoutBlock} || 'rw:Service:DescriptionShort',
            Data => {
                DescriptionShort => $Param{DescriptionShort},
            },
        );
    }

    if ( $Param{DescriptionLong} ) {
        $LayoutObject->Block(
            Name => 'rw:Service:DescriptionLong',
            Data => {
                DescriptionLong => $Param{DescriptionLong},
            },
        );
    }

    return {
        Success => 1,
        HTML    => $LayoutObject->Output( TemplateFile => 'ProcessManagement/Service' ),
    };

}

sub _RenderLock {

    # for lock states there's no ACL checking yet implemented so no checking...

    my ( $Self, %Param ) = @_;

    # get layout object
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    for my $Needed (qw(FormID)) {
        if ( !$Param{$Needed} ) {
            return {
                Success => 0,
                Message => $LayoutObject->{LanguageObject}
                    ->Translate( 'Parameter %s is missing in %s.', $Needed, '_RenderLock' ),
            };
        }
    }
    if ( !IsHashRefWithData( $Param{ActivityDialogField} ) ) {
        return {
            Success => 0,
            Message => $LayoutObject->{LanguageObject}
                ->Translate( 'Parameter %s is missing in %s.', 'ActivityDialogField', '_RenderLock' ),
        };
    }

    my $Locks = $Self->_GetLocks(
        %{ $Param{GetParam} },
    );

    my %Data = (
        Label            => $LayoutObject->{LanguageObject}->Translate("Lock state"),
        FieldID          => 'LockID',
        FormID           => $Param{FormID},
        MandatoryClass   => '',
        ValidateRequired => '',
    );

    # If field is required put in the necessary variables for
    # ValidateRequired class input field, Mandatory class for the label
    if ( $Param{ActivityDialogField}->{Display} && $Param{ActivityDialogField}->{Display} == 2 ) {
        $Data{ValidateRequired} = 'Validate_Required';
        $Data{MandatoryClass}   = 'Mandatory';
    }

    my $SelectedValue;

    # get lock object
    my $LockObject = $Kernel::OM->Get('Kernel::System::Lock');

    my $LockIDParam = $Param{GetParam}{LockID};
    $SelectedValue = $LockObject->LockLookup( LockID => $LockIDParam )
        if ($LockIDParam);

    if ( $Param{FieldName} eq 'Lock' ) {

        if ( !$SelectedValue ) {

            # Fetch DefaultValue from Config
            $SelectedValue = $LockObject->LockLookup(
                Lock => $Param{ActivityDialogField}->{DefaultValue} || '',
            );
            if ($SelectedValue) {
                $SelectedValue = $Param{ActivityDialogField}->{DefaultValue};
            }
        }
    }
    else {
        $SelectedValue = $LockObject->LockLookup(
            LockID => $Param{ActivityDialogField}->{DefaultValue} || ''
            )
            if !$SelectedValue;
    }

    # Get TicketValue
    if ( IsHashRefWithData( $Param{Ticket} ) && !$SelectedValue ) {
        $SelectedValue = $Param{Ticket}->{Lock};
    }

    # set server errors
    my $ServerError = '';
    if ( IsHashRefWithData( $Param{Error} ) && $Param{Error}->{'LockID'} ) {
        $ServerError = 'ServerError';
    }

    if ( $Self->{LinkTicketData} ) {
        $SelectedValue = $Self->{LinkTicketData}->{Lock};
    }

    # build lock string
    $Data{Content} = $LayoutObject->BuildSelection(
        Data          => $Locks,
        Name          => 'LockID',
        Translation   => 1,
        SelectedValue => $SelectedValue,
        Class         => "Modernize $ServerError",
    );

    # send data to JS
    $LayoutObject->AddJSData(
        Key   => 'LockFieldsToUpdate',
        Value => $Param{AJAXUpdatableFields}
    );

    $LayoutObject->Block(
        Name => $Param{ActivityDialogField}->{LayoutBlock} || 'rw:Lock',
        Data => \%Data,
    );

    # set mandatory label marker
    if ( $Data{MandatoryClass} && $Data{MandatoryClass} ne '' ) {
        $LayoutObject->Block(
            Name => 'LabelSpan',
            Data => {},
        );
    }

    if ( $Param{DescriptionShort} ) {
        $LayoutObject->Block(
            Name => $Param{ActivityDialogField}->{LayoutBlock} || 'rw:Lock:DescriptionShort',
            Data => {
                DescriptionShort => $Param{DescriptionShort},
            },
        );
    }

    if ( $Param{DescriptionLong} ) {
        $LayoutObject->Block(
            Name => 'rw:Lock:DescriptionLong',
            Data => {
                DescriptionLong => $Param{DescriptionLong},
            },
        );
    }

    return {
        Success => 1,
        HTML    => $LayoutObject->Output( TemplateFile => 'ProcessManagement/Lock' ),
    };
}

sub _RenderPriority {
    my ( $Self, %Param ) = @_;

    # get layout object
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    for my $Needed (qw(FormID)) {
        if ( !$Param{$Needed} ) {
            return {
                Success => 0,
                Message => $LayoutObject->{LanguageObject}
                    ->Translate( 'Parameter %s is missing in %s.', $Needed, '_RenderPriority' ),
            };
        }
    }
    if ( !IsHashRefWithData( $Param{ActivityDialogField} ) ) {
        return {
            Success => 0,
            Message => $LayoutObject->{LanguageObject}
                ->Translate( 'Parameter %s is missing in %s.', 'ActivityDialogField', '_RenderPriority' ),
        };
    }

    my $Priorities = $Self->_GetPriorities(
        %{ $Param{GetParam} },
    );

    my %Data = (
        Label            => $LayoutObject->{LanguageObject}->Translate("Priority"),
        FieldID          => 'PriorityID',
        FormID           => $Param{FormID},
        MandatoryClass   => '',
        ValidateRequired => '',
    );

    # If field is required put in the necessary variables for
    # ValidateRequired class input field, Mandatory class for the label
    if ( $Param{ActivityDialogField}->{Display} && $Param{ActivityDialogField}->{Display} == 2 ) {
        $Data{ValidateRequired} = 'Validate_Required';
        $Data{MandatoryClass}   = 'Mandatory';
    }

    my $SelectedValue;

    # get priority object
    my $PriorityObject = $Kernel::OM->Get('Kernel::System::Priority');

    my $PriorityIDParam = $Param{GetParam}{PriorityID};
    if ($PriorityIDParam) {
        $SelectedValue = $PriorityObject->PriorityLookup(
            PriorityID => $PriorityIDParam,
        );
    }

    if ( $Param{FieldName} eq 'Priority' ) {

        if ( !$SelectedValue ) {

            # Fetch DefaultValue from Config
            $SelectedValue = $PriorityObject->PriorityLookup(
                Priority => $Param{ActivityDialogField}->{DefaultValue} || '',
            );
            if ($SelectedValue) {
                $SelectedValue = $Param{ActivityDialogField}->{DefaultValue};
            }
        }
    }
    else {
        if ( !$SelectedValue ) {
            $SelectedValue = $PriorityObject->PriorityLookup(
                PriorityID => $Param{ActivityDialogField}->{DefaultValue} || '',
            );
        }
    }

    # Get TicketValue
    if ( IsHashRefWithData( $Param{Ticket} ) && !$SelectedValue ) {
        $SelectedValue = $Param{Ticket}->{Priority};
    }

    # set server errors
    my $ServerError = '';
    if ( IsHashRefWithData( $Param{Error} ) && $Param{Error}->{'PriorityID'} ) {
        $ServerError = 'ServerError';
    }

    if ( $Self->{LinkTicketData} ) {
        $SelectedValue = $Self->{LinkTicketData}->{Priority};
    }

    # build next Priorities string
    $Data{Content} = $LayoutObject->BuildSelection(
        Data          => $Priorities,
        Name          => 'PriorityID',
        Translation   => 1,
        SelectedValue => $SelectedValue,
        Class         => "Modernize $ServerError",
    );

    # send data to JS
    $LayoutObject->AddJSData(
        Key   => 'PriorityFieldsToUpdate',
        Value => $Param{AJAXUpdatableFields}
    );

    $LayoutObject->Block(
        Name => $Param{ActivityDialogField}->{LayoutBlock} || 'rw:Priority',
        Data => \%Data,
    );

    # set mandatory label marker
    if ( $Data{MandatoryClass} && $Data{MandatoryClass} ne '' ) {
        $LayoutObject->Block(
            Name => 'LabelSpan',
            Data => {},
        );
    }

    if ( $Param{DescriptionShort} ) {
        $LayoutObject->Block(
            Name => $Param{ActivityDialogField}->{LayoutBlock} || 'rw:Priority:DescriptionShort',
            Data => {
                DescriptionShort => $Param{DescriptionShort},
            },
        );
    }

    if ( $Param{DescriptionLong} ) {
        $LayoutObject->Block(
            Name => 'rw:Priority:DescriptionLong',
            Data => {
                DescriptionLong => $Param{DescriptionLong},
            },
        );
    }

    return {
        Success => 1,
        HTML    => $LayoutObject->Output( TemplateFile => 'ProcessManagement/Priority' ),
    };
}

sub _RenderQueue {
    my ( $Self, %Param ) = @_;

    # get layout object
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    for my $Needed (qw(FormID)) {
        if ( !$Param{$Needed} ) {
            return {
                Success => 0,
                Message => $LayoutObject->{LanguageObject}
                    ->Translate( 'Parameter %s is missing in %s.', $Needed, '_RenderQueue' ),
            };
        }
    }
    if ( !IsHashRefWithData( $Param{ActivityDialogField} ) ) {
        return {
            Success => 0,
            Message => $LayoutObject->{LanguageObject}
                ->Translate( 'Parameter %s is missing in %s.', 'ActivityDialogField', '_RenderQueue' ),
        };
    }

    my $Queues = $Self->_GetQueues(
        %{ $Param{GetParam} },
    );

    my %Data = (
        Label            => $LayoutObject->{LanguageObject}->Translate("To queue"),
        FieldID          => 'QueueID',
        FormID           => $Param{FormID},
        MandatoryClass   => '',
        ValidateRequired => '',
    );

    # If field is required put in the necessary variables for
    # ValidateRequired class input field, Mandatory class for the label
    if ( $Param{ActivityDialogField}->{Display} && $Param{ActivityDialogField}->{Display} == 2 ) {
        $Data{ValidateRequired} = 'Validate_Required';
        $Data{MandatoryClass}   = 'Mandatory';
    }
    my $SelectedValue;

    # get queue object
    my $QueueObject = $Kernel::OM->Get('Kernel::System::Queue');

    # if we got QueueID as Param from the GUI
    my $QueueIDParam = $Param{GetParam}{QueueID};
    if ($QueueIDParam) {
        $SelectedValue = $QueueObject->QueueLookup(
            QueueID => $QueueIDParam,
        );
    }

    if ( $Param{FieldName} eq 'Queue' ) {

        if ( !$SelectedValue ) {

            # Fetch DefaultValue from Config
            $SelectedValue = $QueueObject->QueueLookup(
                Queue => $Param{ActivityDialogField}->{DefaultValue} || '',
            );
            if ($SelectedValue) {
                $SelectedValue = $Param{ActivityDialogField}->{DefaultValue};
            }
        }
    }
    else {
        if ( !$SelectedValue ) {
            $SelectedValue = $QueueObject->QueueLookup(
                QueueID => $Param{ActivityDialogField}->{DefaultValue} || '',
            );
        }
    }

    # Get TicketValue
    if ( IsHashRefWithData( $Param{Ticket} ) && !$SelectedValue ) {
        $SelectedValue = $Param{Ticket}->{Queue};
    }

    # set server errors
    my $ServerError = '';
    if ( IsHashRefWithData( $Param{Error} ) && $Param{Error}->{'QueueID'} ) {
        $ServerError = 'ServerError';
    }

    # get list type
    my $TreeView = 0;
    if ( $Kernel::OM->Get('Kernel::Config')->Get('Ticket::Frontend::ListType') eq 'tree' ) {
        $TreeView = 1;
    }

    if ( $Self->{LinkTicketData} ) {
        $SelectedValue = $Self->{LinkTicketData}->{Queue};
    }

    # build next queues string
    $Data{Content} = $LayoutObject->BuildSelection(
        Data          => $Queues,
        Name          => 'QueueID',
        Translation   => 0,
        SelectedValue => $SelectedValue,
        Class         => "Modernize $ServerError",
        TreeView      => $TreeView,
        Sort          => 'TreeView',
        PossibleNone  => 1,
    );

    # send data to JS
    $LayoutObject->AddJSData(
        Key   => 'QueueFieldsToUpdate',
        Value => $Param{AJAXUpdatableFields}
    );

    $LayoutObject->Block(
        Name => $Param{ActivityDialogField}->{LayoutBlock} || 'rw:Queue',
        Data => \%Data,
    );

    # set mandatory label marker
    if ( $Data{MandatoryClass} && $Data{MandatoryClass} ne '' ) {
        $LayoutObject->Block(
            Name => 'LabelSpan',
            Data => {},
        );
    }

    if ( $Param{DescriptionShort} ) {
        $LayoutObject->Block(
            Name => $Param{ActivityDialogField}->{LayoutBlock} || 'rw:Queue:DescriptionShort',
            Data => {
                DescriptionShort => $Param{DescriptionShort},
            },
        );
    }

    if ( $Param{DescriptionLong} ) {
        $LayoutObject->Block(
            Name => 'rw:Queue:DescriptionLong',
            Data => {
                DescriptionLong => $Param{DescriptionLong},
            },
        );
    }

    return {
        Success => 1,
        HTML    => $LayoutObject->Output( TemplateFile => 'ProcessManagement/Queue' ),
    };
}

sub _RenderAttachment {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    NEEDED:
    for my $Needed (qw(FormID ActivityDialogField)) {
        next NEEDED if defined $Param{$Needed};
        return {
            Success => 0,
            Message => $LayoutObject->{LanguageObject}
                ->Translate( 'Parameter %s is missing in %s.', $Needed, '_RenderAttachment' ),
        };
    }

    if ( !IsHashRefWithData( $Param{ActivityDialogField} ) ) {
        return {
            Success => 0,
            Message => $LayoutObject->{LanguageObject}
                ->Translate( 'Parameter %s is missing in %s.', 'ActivityDialogField', '_RenderAttachment' ),
        };
    }

    my $AttachmentList = $Self->_GetAttachments(
        %{ $Param{GetParam} }
    );

    my %Data = (
        Label            => 'Attachments',
        FieldID          => 'Attachments',
        FormID           => $Param{FormID},
        MandatoryClass   => '',
        ValidateRequired => '',
    );

    if (
        $Param{ActivityDialogField}->{Display}
        && $Param{ActivityDialogField}->{Display} == 2
        )
    {
        $Data{ValidateRequired} = 'Validate_Required';
        $Data{MandatoryClass}   = 'Mandatory';
    }

    my $AttachmentsDynamicFieldName = $ConfigObject->Get('Process::DynamicFieldProcessManagementAttachment');

    my $AttachmentsParam = $Param{GetParam}->{ 'DynamicField_' . $AttachmentsDynamicFieldName };
    my @SelectedAttachments;
    if ($AttachmentsParam) {
        @SelectedAttachments = split( ',', $AttachmentsParam );
    }

    $Data{Content} = $LayoutObject->BuildSelection(
        Data        => $AttachmentList,
        Name        => 'Attachments',
        Translation => 0,
        SelectedID  => \@SelectedAttachments,
        Multiple    => 1,
        Class       => "Modernize $Data{ValidateRequired}",
    );

    $LayoutObject->Block(
        Name => $Param{ActivityDialogField}->{LayoutBlock} // 'rw:Attachment',
        Data => \%Data,
    );

    if ( $Data{MandatoryClass} && $Data{MandatoryClass} ne '' ) {
        $LayoutObject->Block(
            Name => 'LabelSpan',
        );
    }

    $Param{DescriptionShort} //= 'Attachments to be propagated to a subticket on creation.';

    $LayoutObject->Block(
        Name => $Param{ActivityDialogField}->{LayoutBlock} // 'rw:Attachment:DescriptionShort',
        Data => {
            DescriptionShort => $Param{DescriptionShort},
        },
    );

    if ( $Param{DescriptionLong} ) {
        $LayoutObject->Block(
            Name => 'rw:Attachment:DescriptionLong',
            Data => {
                DescriptionLong => $Param{DescriptionLong},
            },
        );
    }

    return {
        Success => 1,
        HTML    => $LayoutObject->Output( TemplateFile => 'ProcessManagement/Attachment' ),
    };
}

sub _RenderState {
    my ( $Self, %Param ) = @_;

    # get layout object
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    for my $Needed (qw(FormID)) {
        if ( !$Param{$Needed} ) {
            return {
                Success => 0,
                Message => $LayoutObject->{LanguageObject}
                    ->Translate( 'Parameter %s is missing in %s.', $Needed, '_RenderState' ),
            };
        }
    }
    if ( !IsHashRefWithData( $Param{ActivityDialogField} ) ) {
        return {
            Success => 0,
            Message => $LayoutObject->{LanguageObject}
                ->Translate( 'Parameter %s is missing in %s.', 'ActivityDialogField', '_RenderState' ),
        };
    }

    my $States = $Self->_GetStates( %{ $Param{GetParam} } );

    my %Data = (
        Label            => $LayoutObject->{LanguageObject}->Translate("Next ticket state"),
        FieldID          => 'StateID',
        FormID           => $Param{FormID},
        MandatoryClass   => '',
        ValidateRequired => '',
    );

    # If field is required put in the necessary variables for
    # ValidateRequired class input field, Mandatory class for the label
    if ( $Param{ActivityDialogField}->{Display} && $Param{ActivityDialogField}->{Display} == 2 ) {
        $Data{ValidateRequired} = 'Validate_Required';
        $Data{MandatoryClass}   = 'Mandatory';
    }
    my $SelectedValue;

    # get state object
    my $StateObject = $Kernel::OM->Get('Kernel::System::State');

    my $StateIDParam = $Param{GetParam}{StateID};
    if ($StateIDParam) {
        $SelectedValue = $StateObject->StateLookup( StateID => $StateIDParam );
    }

    if ( $Param{FieldName} eq 'State' ) {

        if ( !$SelectedValue ) {

            # Fetch DefaultValue from Config
            $SelectedValue = $StateObject->StateLookup(
                State => $Param{ActivityDialogField}->{DefaultValue} || '',
            );
            if ($SelectedValue) {
                $SelectedValue = $Param{ActivityDialogField}->{DefaultValue};
            }
        }
    }
    else {
        if ( !$SelectedValue ) {
            $SelectedValue = $StateObject->StateLookup(
                StateID => $Param{ActivityDialogField}->{DefaultValue} || '',
            );
        }
    }

    # Get TicketValue
    if ( IsHashRefWithData( $Param{Ticket} ) && !$SelectedValue ) {
        $SelectedValue = $Param{Ticket}->{State};
    }

    # set server errors
    my $ServerError = '';
    if ( IsHashRefWithData( $Param{Error} ) && $Param{Error}->{'StateID'} ) {
        $ServerError = 'ServerError';
    }

    # build next states string
    $Data{Content} = $LayoutObject->BuildSelection(
        Data          => $States,
        Name          => 'StateID',
        Translation   => 1,
        SelectedValue => $SelectedValue,
        Class         => "Modernize $ServerError",
    );

    # send data to JS
    $LayoutObject->AddJSData(
        Key   => 'StateFieldsToUpdate',
        Value => $Param{AJAXUpdatableFields}
    );

    $LayoutObject->Block(
        Name => $Param{ActivityDialogField}->{LayoutBlock} || 'rw:State',
        Data => \%Data,
    );

    # set mandatory label marker
    if ( $Data{MandatoryClass} && $Data{MandatoryClass} ne '' ) {
        $LayoutObject->Block(
            Name => 'LabelSpan',
            Data => {},
        );
    }

    if ( $Param{DescriptionShort} ) {
        $LayoutObject->Block(
            Name => $Param{ActivityDialogField}->{LayoutBlock} || 'rw:State:DescriptionShort',
            Data => {
                DescriptionShort => $Param{DescriptionShort},
            },
        );
    }

    if ( $Param{DescriptionLong} ) {
        $LayoutObject->Block(
            Name => 'rw:State:DescriptionLong',
            Data => {
                DescriptionLong => $Param{DescriptionLong},
            },
        );
    }

    return {
        Success => 1,
        HTML    => $LayoutObject->Output( TemplateFile => 'ProcessManagement/State' ),
    };
}

sub _RenderType {
    my ( $Self, %Param ) = @_;

    # get layout object
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    for my $Needed (qw(FormID)) {
        if ( !$Param{$Needed} ) {
            return {
                Success => 0,
                Message => $LayoutObject->{LanguageObject}
                    ->Translate( 'Parameter %s is missing in %s.', $Needed, '_RenderType' ),
            };
        }
    }
    if ( !IsHashRefWithData( $Param{ActivityDialogField} ) ) {
        return {
            Success => 0,
            Message => $LayoutObject->{LanguageObject}
                ->Translate( 'Parameter %s is missing in %s.', 'ActivityDialogField', '_RenderType' ),
        };
    }

    my $Types = $Self->_GetTypes(
        %{ $Param{GetParam} },
    );

    my %Data = (
        Label            => $LayoutObject->{LanguageObject}->Translate("Type"),
        FieldID          => 'TypeID',
        FormID           => $Param{FormID},
        MandatoryClass   => '',
        ValidateRequired => '',
    );

    # If field is required put in the necessary variables for
    # ValidateRequired class input field, Mandatory class for the label
    if ( $Param{ActivityDialogField}->{Display} && $Param{ActivityDialogField}->{Display} == 2 ) {
        $Data{ValidateRequired} = 'Validate_Required';
        $Data{MandatoryClass}   = 'Mandatory';
    }

    my $SelectedValue;

    # get type object
    my $TypeObject = $Kernel::OM->Get('Kernel::System::Type');

    my $TypeIDParam = $Param{GetParam}{TypeID};
    if ($TypeIDParam) {
        $SelectedValue = $TypeObject->TypeLookup(
            TypeID => $TypeIDParam,
        );
    }

    if ( $Param{FieldName} eq 'Type' ) {

        if ( !$SelectedValue ) {

            # Fetch DefaultValue from Config
            if (
                defined $Param{ActivityDialogField}->{DefaultValue}
                && $Param{ActivityDialogField}->{DefaultValue} ne ''
                )
            {
                $SelectedValue = $TypeObject->TypeLookup(
                    Type => $Param{ActivityDialogField}->{DefaultValue},
                );
            }
            if ($SelectedValue) {
                $SelectedValue = $Param{ActivityDialogField}->{DefaultValue};
            }
        }
    }
    else {
        if ( !$SelectedValue ) {
            if (
                defined $Param{ActivityDialogField}->{DefaultValue}
                && $Param{ActivityDialogField}->{DefaultValue} ne ''
                )
            {
                $SelectedValue = $TypeObject->TypeLookup(
                    Type => $Param{ActivityDialogField}->{DefaultValue},
                );
            }
        }
    }

    # Get TicketValue
    if ( IsHashRefWithData( $Param{Ticket} ) && !$SelectedValue ) {
        $SelectedValue = $Param{Ticket}->{Type};
    }

    # set server errors
    my $ServerError = '';
    if ( IsHashRefWithData( $Param{Error} ) && $Param{Error}->{'TypeID'} ) {
        $ServerError = 'ServerError';
    }

    if ( $Self->{LinkTicketData} ) {
        $SelectedValue = $Self->{LinkTicketData}->{Type};
    }

    # build Service string
    $Data{Content} = $LayoutObject->BuildSelection(
        Data          => $Types,
        Name          => 'TypeID',
        Class         => "Modernize $ServerError",
        SelectedValue => $SelectedValue,
        PossibleNone  => 1,
        Sort          => 'AlphanumericValue',
        Translation   => 0,
        Max           => 200,
    );

    # send data to JS
    $LayoutObject->AddJSData(
        Key   => 'TypeFieldsToUpdate',
        Value => $Param{AJAXUpdatableFields}
    );

    $LayoutObject->Block(
        Name => $Param{ActivityDialogField}->{LayoutBlock} || 'rw:Type',
        Data => \%Data,
    );

    # set mandatory label marker
    if ( $Data{MandatoryClass} && $Data{MandatoryClass} ne '' ) {
        $LayoutObject->Block(
            Name => 'LabelSpan',
            Data => {},
        );
    }

    if ( $Param{DescriptionShort} ) {
        $LayoutObject->Block(
            Name => $Param{ActivityDialogField}->{LayoutBlock} || 'rw:Type:DescriptionShort',
            Data => {
                DescriptionShort => $Param{DescriptionShort},
            },
        );
    }

    if ( $Param{DescriptionLong} ) {
        $LayoutObject->Block(
            Name => 'rw:Type:DescriptionLong',
            Data => {
                DescriptionLong => $Param{DescriptionLong},
            },
        );
    }

    return {
        Success => 1,
        HTML    => $LayoutObject->Output( TemplateFile => 'ProcessManagement/Type' ),
    };
}

sub _StoreActivityDialog {
    my ( $Self, %Param ) = @_;

    my $TicketID = $Param{GetParam}->{TicketID};
    my $ProcessStartpoint;
    my %Ticket;
    my $ProcessEntityID;
    my $ActivityEntityID;
    my %Error;
    my %ErrorMessages;

    my %TicketParam;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    my $ActivityDialogEntityID = $Param{GetParam}->{ActivityDialogEntityID};
    if ( !$ActivityDialogEntityID ) {
        $LayoutObject->FatalError(
            Message => Translatable('ActivityDialogEntityID missing!'),
        );
    }

    # get activity dialog object
    my $ActivityDialogObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::ActivityDialog');
    my $ActivityDialog       = $ActivityDialogObject->ActivityDialogGet(
        ActivityDialogEntityID => $ActivityDialogEntityID,
        Interface              => 'AgentInterface',
    );

    if ( !IsHashRefWithData($ActivityDialog) ) {
        $LayoutObject->FatalError(
            Message => $LayoutObject->{LanguageObject}->Translate(
                'Couldn\'t get Config for ActivityDialogEntityID "%s"!',
                $ActivityDialogEntityID,
            ),
        );
    }

    # get param object
    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');

    # get upload cache object
    my $UploadCacheObject = $Kernel::OM->Get('Kernel::System::Web::UploadCache');

    my $DynamicField = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldListGet(
        Valid      => 1,
        ObjectType => 'Ticket',
    );

    # get dynamic field backend object
    my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    # check each Field of an Activity Dialog and fill the error hash if something goes horribly wrong
    my %CheckedFields;
    DIALOGFIELD:
    for my $CurrentField ( @{ $ActivityDialog->{FieldOrder} } ) {
        if ( $CurrentField =~ m{^DynamicField_(.*)}xms ) {
            my $DynamicFieldName = $1;

            # Get the Config of the current DynamicField (the first element of the grep result array)
            my $DynamicFieldConfig = ( grep { $_->{Name} eq $DynamicFieldName } @{$DynamicField} )[0];

            if ( !IsHashRefWithData($DynamicFieldConfig) ) {

                my $Message
                    = "DynamicFieldConfig missing for field: $Param{FieldName}, or is not a Ticket Dynamic Field!";

                # log error but does not stop the execution as it could be an old Article
                # DynamicField, see bug#11666
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'error',
                    Message  => $Message,
                );

                next DIALOGFIELD;
            }

            # Will be extended later on for ACL Checking:
            my $PossibleValuesFilter;

            # if we have an invisible field, use config's default value
            if ( $ActivityDialog->{Fields}->{$CurrentField}->{Display} == 0 ) {
                if (
                    defined $ActivityDialog->{Fields}->{$CurrentField}->{DefaultValue}
                    && length $ActivityDialog->{Fields}->{$CurrentField}->{DefaultValue}
                    )
                {
                    $TicketParam{$CurrentField} = $ActivityDialog->{Fields}->{$CurrentField}->{DefaultValue};
                }
                else {
                    $TicketParam{$CurrentField} = '';
                }
            }

            # only validate visible fields
            else {
                # Check DynamicField Values
                my $ValidationResult = $DynamicFieldBackendObject->EditFieldValueValidate(
                    DynamicFieldConfig   => $DynamicFieldConfig,
                    PossibleValuesFilter => $PossibleValuesFilter,
                    ParamObject          => $ParamObject,
                    Mandatory            => $ActivityDialog->{Fields}->{$CurrentField}->{Display} == 2,
                );

                if ( !IsHashRefWithData($ValidationResult) ) {
                    $LayoutObject->FatalError(
                        Message => $LayoutObject->{LanguageObject}->Translate(
                            'Could not perform validation on field %s!',
                            $DynamicFieldConfig->{Label},
                        ),
                    );
                }

                if ( $ValidationResult->{ServerError} ) {
                    $Error{ $DynamicFieldConfig->{Name} }         = 1;
                    $ErrorMessages{ $DynamicFieldConfig->{Name} } = $ValidationResult->{ErrorMessage};
                }

                $TicketParam{$CurrentField} =
                    $DynamicFieldBackendObject->EditFieldValueGet(
                    DynamicFieldConfig => $DynamicFieldConfig,
                    ParamObject        => $ParamObject,
                    LayoutObject       => $LayoutObject,
                    );
            }

            # In case of DynamicFields there is no NameToID translation
            # so just take the DynamicField name
            $CheckedFields{$CurrentField} = 1;
        }
        elsif (
            $Self->{NameToID}->{$CurrentField} eq 'CustomerID'
            || $Self->{NameToID}->{$CurrentField} eq 'CustomerUserID'
            )
        {

            next DIALOGFIELD if $CheckedFields{ $Self->{NameToID}->{'CustomerID'} };

            # is not possible to a have an invisible field for this particular value
            # on agent interface
            if ( $ActivityDialog->{Fields}->{$CurrentField}->{Display} == 0 ) {
                $LayoutObject->FatalError(
                    Message => Translatable('Couldn\'t use CustomerID as an invisible field.'),
                    Comment => Translatable('Please contact the administrator.'),
                );
            }

            # CustomerID should not be mandatory as in other screens
            $TicketParam{CustomerID} = $Param{GetParam}->{CustomerID} || '';

            # Unfortunately TicketCreate needs 'CustomerUser' as param instead of 'CustomerUserID'
            my $CustomerUserID = $ParamObject->GetParam( Param => 'SelectedCustomerUser' );

            # fall-back, if customer auto-complete does not shown any results, then try to use
            # the content of the original field as customer user id
            if ( !$CustomerUserID ) {

                $CustomerUserID = $ParamObject->GetParam( Param => 'CustomerUserID' );

                # check email address
                for my $Email ( Mail::Address->parse($CustomerUserID) ) {
                    if (
                        !$Kernel::OM->Get('Kernel::System::CheckItem')->CheckEmail( Address => $Email->address() )
                        )
                    {
                        $Error{'CustomerUserID'} = 1;
                    }
                }
            }

            if ( !$CustomerUserID ) {
                $Error{'CustomerUserID'} = 1;
            }
            else {
                $TicketParam{CustomerUser} = $CustomerUserID;
            }
            $CheckedFields{ $Self->{NameToID}->{'CustomerID'} }     = 1;
            $CheckedFields{ $Self->{NameToID}->{'CustomerUserID'} } = 1;

        }
        elsif ( $CurrentField eq 'PendingTime' ) {
            my $Prefix = 'PendingTime';

            # Make sure we have Values otherwise take an empty string
            if (
                IsHashRefWithData( $Param{GetParam}->{PendingTime} )
                && defined $Param{GetParam}->{PendingTime}->{Year}
                && defined $Param{GetParam}->{PendingTime}->{Month}
                && defined $Param{GetParam}->{PendingTime}->{Day}
                && defined $Param{GetParam}->{PendingTime}->{Hour}
                && defined $Param{GetParam}->{PendingTime}->{Minute}
                )
            {
                $TicketParam{$CurrentField} = $Param{GetParam}->{PendingTime};
            }

            # if we have no Pending status we have no time to set
            else {
                $TicketParam{$CurrentField} = '';
            }
            $CheckedFields{'PendingTime'} = 1;
        }

        else {

            # skip if we've already checked ID or Name
            next DIALOGFIELD if $CheckedFields{ $Self->{NameToID}->{$CurrentField} };

            next DIALOGFIELD if $CurrentField eq 'Attachments';

            my $Result = $Self->_CheckField(
                Field => $Self->{NameToID}->{$CurrentField},
                %{ $ActivityDialog->{Fields}{$CurrentField} },
            );

            if ( !$Result ) {

                # special case for Article (Subject & Body)
                if ( $CurrentField eq 'Article' ) {
                    for my $ArticlePart (qw(Subject Body)) {
                        if ( !$Param{GetParam}->{$ArticlePart} ) {

                            # set error for each part (if any)
                            $Error{ 'Article' . $ArticlePart } = 1;
                        }
                    }
                }

                # all other fields
                elsif ( $ActivityDialog->{Fields}->{$CurrentField}->{Display} == 2 ) {
                    $Error{ $Self->{NameToID}->{$CurrentField} } = 1;
                }
            }

            if (
                $CurrentField eq 'Article'
                && $ActivityDialog->{Fields}->{$CurrentField}->{Config}->{TimeUnits}
                && $ActivityDialog->{Fields}->{$CurrentField}->{Config}->{TimeUnits} == 2
                )
            {
                if ( !$Param{GetParam}->{TimeUnits} ) {

                    # set error for the time-units (if any)
                    $Error{'TimeUnits'} = 1;
                }
            }

            elsif ($Result) {
                $TicketParam{ $Self->{NameToID}->{$CurrentField} } = $Result;
            }
            $CheckedFields{ $Self->{NameToID}->{$CurrentField} } = 1;
        }
    }

    # create process object
    $Kernel::OM->ObjectParamAdd(
        'Kernel::System::ProcessManagement::Process' => {
            ActivityObject         => $Kernel::OM->Get('Kernel::System::ProcessManagement::Activity'),
            ActivityDialogObject   => $ActivityDialogObject,
            TransitionObject       => $Kernel::OM->Get('Kernel::System::ProcessManagement::Transition'),
            TransitionActionObject => $Kernel::OM->Get('Kernel::System::ProcessManagement::TransitionAction'),
        }
    );
    my $ProcessObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::Process');

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    my @Notify;

    my $NewTicketID;
    my $NewOwnerID;
    if ( !$TicketID ) {

        $ProcessEntityID = $Param{GetParam}->{ProcessEntityID};
        if ( !$ProcessEntityID )
        {
            return $LayoutObject->FatalError(
                Message => Translatable('Missing ProcessEntityID, check your ActivityDialogHeader.tt!'),
            );
        }

        $ProcessStartpoint = $ProcessObject->ProcessStartpointGet(
            ProcessEntityID => $Param{ProcessEntityID},
        );

        if (
            !$ProcessStartpoint
            || !IsHashRefWithData($ProcessStartpoint)
            || !$ProcessStartpoint->{Activity} || !$ProcessStartpoint->{ActivityDialog}
            )
        {
            $LayoutObject->FatalError(
                Message => $LayoutObject->{LanguageObject}->Translate(
                    'No StartActivityDialog or StartActivityDialog for Process "%s" configured!',
                    $Param{ProcessEntityID},
                ),
            );
        }

        $ActivityEntityID = $ProcessStartpoint->{Activity};

        for my $Needed (qw(Queue State Lock Priority)) {

            if ( !$TicketParam{ $Self->{NameToID}->{$Needed} } ) {

                # if a required field has no value call _CheckField as filed is hidden
                # (No Display param = Display => 0) and no DefaultValue, to use global default as
                # fall-back. One reason for this to happen is that ActivityDialog DefaultValue tried
                # to set before, was not valid.
                my $Result = $Self->_CheckField(
                    Field => $Self->{NameToID}->{$Needed},
                );

                if ( !$Result ) {
                    $Error{ $Self->{NameToID}->{$Needed} } = ' ServerError';
                }
                elsif ($Result) {
                    $TicketParam{ $Self->{NameToID}->{$Needed} } = $Result;
                }
            }
        }

        # If we had no Errors, we can create the Ticket and Set ActivityEntityID as well as
        # ProcessEntityID
        if ( !IsHashRefWithData( \%Error ) ) {

            $TicketParam{UserID} = $Self->{UserID};

            if ( $TicketParam{OwnerID} ) {
                $NewOwnerID = $TicketParam{OwnerID};
            }

            # Set OwnerID to 1 on TicketCreate. This will be updated later on, so events can be triggered.
            $TicketParam{OwnerID} = 1;

            # if StartActivityDialog does not provide a ticket title set a default value
            if ( !$TicketParam{Title} ) {

                # get the current server Time-stamp
                my $DateTimeObject   = $Kernel::OM->Create('Kernel::System::DateTime');
                my $CurrentTimeStamp = $DateTimeObject->ToString();
                my $OTRSTimeZone     = $DateTimeObject->OTRSTimeZoneGet();
                $TicketParam{Title} = "$Param{ProcessName} - $CurrentTimeStamp ($OTRSTimeZone)";

                # use article subject from the web request if any
                if ( IsStringWithData( $Param{GetParam}->{Subject} ) ) {
                    $TicketParam{Title} = $Param{GetParam}->{Subject};
                }
            }

            # create a new ticket
            $TicketID = $TicketObject->TicketCreate(%TicketParam);

            if ( !$TicketID ) {
                $LayoutObject->FatalError(
                    Message => $LayoutObject->{LanguageObject}->Translate(
                        'Couldn\'t create ticket for Process with ProcessEntityID "%s"!',
                        $Param{ProcessEntityID},
                    ),
                );
            }

            my $Success = $ProcessObject->ProcessTicketProcessSet(
                ProcessEntityID => $Param{ProcessEntityID},
                TicketID        => $TicketID,
                UserID          => $Self->{UserID},
            );
            if ( !$Success ) {
                $LayoutObject->FatalError(
                    Message => $LayoutObject->{LanguageObject}->Translate(
                        'Couldn\'t set ProcessEntityID "%s" on TicketID "%s"!',
                        $Param{ProcessEntityID},
                        $TicketID,
                    ),
                );
            }

            $Success = undef;

            $Success = $ProcessObject->ProcessTicketActivitySet(
                ProcessEntityID  => $Param{ProcessEntityID},
                ActivityEntityID => $ProcessStartpoint->{Activity},
                TicketID         => $TicketID,
                UserID           => $Self->{UserID},
            );

            if ( !$Success ) {
                $LayoutObject->FatalError(
                    Message => $LayoutObject->{LanguageObject}->Translate(
                        'Couldn\'t set ActivityEntityID "%s" on TicketID "%s"!',
                        $Param{ProcessEntityID},
                        $TicketID,
                    ),
                    Comment => Translatable('Please contact the administrator.'),
                );
            }

            %Ticket = $TicketObject->TicketGet(
                TicketID      => $TicketID,
                UserID        => $Self->{UserID},
                DynamicFields => 1,
            );

            if ( !IsHashRefWithData( \%Ticket ) ) {
                $LayoutObject->FatalError(
                    Message => $LayoutObject->{LanguageObject}->Translate(
                        'Could not store ActivityDialog, invalid TicketID: %s!',
                        $TicketID,
                    ),
                    Comment => Translatable('Please contact the administrator.'),
                );
            }
            for my $DynamicFieldConfig (

                # 2. remove "DynamicField_" from string
                map {
                    my $Field = $_;
                    $Field =~ s{^DynamicField_(.*)}{$1}xms;

                    # 3. grep from the DynamicFieldConfigs the resulting DynamicFields without
                    # "DynamicField_"
                    grep { $_->{Name} eq $Field } @{$DynamicField}
                }

                # 1. grep all DynamicFields
                grep {m{^DynamicField_(.*)}xms} @{ $ActivityDialog->{FieldOrder} }
                )
            {

                # and now it's easy, just store the dynamic Field Values ;)
                $DynamicFieldBackendObject->ValueSet(
                    DynamicFieldConfig => $DynamicFieldConfig,
                    ObjectID           => $TicketID,
                    Value              => $TicketParam{ 'DynamicField_' . $DynamicFieldConfig->{Name} },
                    UserID             => $Self->{UserID},
                );
            }

            # remember new created TicketID
            $NewTicketID = $TicketID;
        }
    }

    elsif ( $TicketID && $Self->{IsProcessEnroll} ) {

        # use Error instead of FatalError as we are in a Pop-up window
        # Get Ticket to check TicketID was valid
        %Ticket = $TicketObject->TicketGet(
            TicketID      => $TicketID,
            UserID        => $Self->{UserID},
            DynamicFields => 0,
        );

        if ( !IsHashRefWithData( \%Ticket ) ) {
            $LayoutObject->Error(
                Message => $LayoutObject->{LanguageObject}->Translate( 'Invalid TicketID: %s!', $TicketID ),
            );
        }

        my $Success = $ProcessObject->ProcessTicketProcessSet(
            ProcessEntityID => $Param{ProcessEntityID},
            TicketID        => $TicketID,
            UserID          => $Self->{UserID},
        );
        if ( !$Success ) {
            $LayoutObject->Error(
                Message => $LayoutObject->{LanguageObject}->Translate(
                    'Couldn\'t set ProcessEntityID "%s" on TicketID "%s"!',
                    $Param{ProcessEntityID},
                    $TicketID,
                ),
            );
        }

        $Success = undef;

        $ProcessStartpoint = $ProcessObject->ProcessStartpointGet(
            ProcessEntityID => $Param{ProcessEntityID},
        );

        if (
            !$ProcessStartpoint
            || !IsHashRefWithData($ProcessStartpoint)
            || !$ProcessStartpoint->{Activity} || !$ProcessStartpoint->{ActivityDialog}
            )
        {
            $LayoutObject->Error(
                Message => $LayoutObject->{LanguageObject}->Translate(
                    'No StartActivityDialog or StartActivityDialog for Process "%s" configured!',
                    $Param{ProcessEntityID},
                ),
            );
        }

        $Success = $ProcessObject->ProcessTicketActivitySet(
            ProcessEntityID  => $Param{ProcessEntityID},
            ActivityEntityID => $ProcessStartpoint->{Activity},
            TicketID         => $TicketID,
            UserID           => $Self->{UserID},
        );

        if ( !$Success ) {
            $LayoutObject->Error(
                Message => $LayoutObject->{LanguageObject}->Translate(
                    'Couldn\'t set ActivityEntityID "%s" on TicketID "%s"!',
                    $Param{ProcessEntityID},
                    $TicketID,
                ),
                Comment => Translatable('Please contact the administrator.'),
            );
        }

        # use ProcessEntityID from the web request
        $ProcessEntityID = $Param{ProcessEntityID};

        # Check if we deal with a Ticket Update
        my $UpdateTicketID = $TicketID;
    }

    # If we had a TicketID, get the Ticket
    else {

        # Get Ticket to check TicketID was valid
        %Ticket = $TicketObject->TicketGet(
            TicketID      => $TicketID,
            UserID        => $Self->{UserID},
            DynamicFields => 1,
        );

        if ( !IsHashRefWithData( \%Ticket ) ) {
            $LayoutObject->FatalError(
                Message => $LayoutObject->{LanguageObject}->Translate(
                    'Could not store ActivityDialog, invalid TicketID: %s!',
                    $TicketID,
                ),
            );
        }

        $ActivityEntityID = $Ticket{
            'DynamicField_'
                . $ConfigObject->Get('Process::DynamicFieldProcessManagementActivityID')
        };
        if ( !$ActivityEntityID )
        {

            return $Self->_ShowDialogError(
                Message => $LayoutObject->{LanguageObject}->Translate(
                    'Missing ActivityEntityID in Ticket %s!',
                    $Ticket{TicketID},
                ),
                Comment => Translatable('Please contact the administrator.'),
            );
        }

        # Make sure the activity dialog to save is still the correct activity
        my $Activity = $Kernel::OM->Get('Kernel::System::ProcessManagement::Activity')->ActivityGet(
            ActivityEntityID => $ActivityEntityID,
            Interface        => ['AgentInterface'],
        );
        my %ActivityDialogs = reverse %{ $Activity->{ActivityDialog} // {} };
        if ( !$ActivityDialogs{$ActivityDialogEntityID} ) {

            my $TicketHook        = $ConfigObject->Get('Ticket::Hook');
            my $TicketHookDivider = $ConfigObject->Get('Ticket::HookDivider');

            $Error{WrongActivity} = 1;
            push @Notify, {
                Priority => 'Error',
                Data     => $LayoutObject->{LanguageObject}->Translate(
                    'This step does not belong anymore to the current activity in process for ticket \'%s%s%s\'! Another user changed this ticket in the meantime. Please close this window and reload the ticket.',
                    $TicketHook,
                    $TicketHookDivider,
                    $Ticket{TicketNumber},
                ),
            };
        }

        $ProcessEntityID = $Ticket{
            'DynamicField_'
                . $ConfigObject->Get('Process::DynamicFieldProcessManagementProcessID')
        };

        if ( !$ProcessEntityID )
        {
            return $Self->_ShowDialogError(
                Message => $LayoutObject->{LanguageObject}->Translate(
                    'Missing ProcessEntityID in Ticket %s!',
                    $Ticket{TicketID},
                ),
                Comment => Translatable('Please contact the administrator.'),
            );
        }
    }

    # if we got errors go back to displaying the ActivityDialog
    if ( IsHashRefWithData( \%Error ) ) {
        return $Self->_OutputActivityDialog(
            ProcessEntityID        => $ProcessEntityID,
            TicketID               => $TicketID || undef,
            ActivityDialogEntityID => $ActivityDialogEntityID,
            Error                  => \%Error,
            ErrorMessages          => \%ErrorMessages,
            GetParam               => $Param{GetParam},
            Notify                 => \@Notify,
        );
    }

    # Check if we deal with a Ticket Update
    my $UpdateTicketID = $Param{GetParam}->{TicketID};

    # We save only once, no matter if one or more configurations are set for the same param
    my %StoredFields;

    # Save loop for storing Ticket Values that were not required on the initial TicketCreate
    DIALOGFIELD:
    for my $CurrentField ( @{ $ActivityDialog->{FieldOrder} } ) {

        if ( !IsHashRefWithData( $ActivityDialog->{Fields}{$CurrentField} ) ) {
            $LayoutObject->FatalError(
                Message => $LayoutObject->{LanguageObject}->Translate(
                    'Can\'t get data for Field "%s" of ActivityDialog "%s"!',
                    $CurrentField,
                    $ActivityDialogEntityID,
                ),
            );
        }

        if ( $CurrentField =~ m{^DynamicField_(.*)}xms ) {
            my $DynamicFieldName   = $1;
            my $DynamicFieldConfig = ( grep { $_->{Name} eq $DynamicFieldName } @{$DynamicField} )[0];

            if ( !IsHashRefWithData($DynamicFieldConfig) ) {

                my $Message
                    = "DynamicFieldConfig missing for field: $Param{FieldName}, or is not a Ticket Dynamic Field!";

                # log error but does not stop the execution as it could be an old Article
                # DynamicField, see bug#11666
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'error',
                    Message  => $Message,
                );

                next DIALOGFIELD;
            }

            my $Success = $DynamicFieldBackendObject->ValueSet(
                DynamicFieldConfig => $DynamicFieldConfig,
                ObjectID           => $TicketID,
                Value              => $TicketParam{$CurrentField},
                UserID             => $Self->{UserID},
            );
            if ( !$Success ) {
                $LayoutObject->FatalError(
                    Message => $LayoutObject->{LanguageObject}->Translate(
                        'Could not set DynamicField value for %s of Ticket with ID "%s" in ActivityDialog "%s"!',
                        $CurrentField,
                        $TicketID,
                        $ActivityDialogEntityID,
                    ),
                );
            }
        }
        elsif ( $CurrentField eq 'Attachments' ) {
            if (
                IsArrayRefWithData( $Param{GetParam}->{Attachments} )
                || $Param{GetParam}->{Attachments} =~ m{\:\:}
                )
            {
                my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
                my $AttachmentsDynamicFieldName
                    = $ConfigObject->Get('Process::DynamicFieldProcessManagementAttachment');

                my $DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
                    Name => $AttachmentsDynamicFieldName,
                );

                next DIALOGFIELD if !IsHashRefWithData($DynamicFieldConfig);

                my $Value;
                if ( IsArrayRefWithData( $Param{GetParam}->{Attachments} ) ) {
                    $Value = join ',', @{ $Param{GetParam}->{Attachments} };
                }
                else {
                    $Value = $Param{GetParam}->{Attachments} // '';
                }

                my $Success = $DynamicFieldBackendObject->ValueSet(
                    DynamicFieldConfig => $DynamicFieldConfig,
                    ObjectID           => $TicketID,
                    Value              => $Value,
                    UserID             => $Self->{UserID},
                );
                next DIALOGFIELD if $Success;

                $LayoutObject->FatalError(
                    Message => $LayoutObject->{LanguageObject}->Translate(
                        'Could not set attachments for ticket with ID %s in activity dialog "%s"!',
                        $TicketID,
                        $ActivityDialogEntityID,
                    ),
                );
            }
        }
        elsif ( $CurrentField eq 'PendingTime' ) {

            # This Value is just set if Status was on a Pending state
            # so it has to be possible to store the ticket if this one's empty
            if ( IsHashRefWithData( $TicketParam{'PendingTime'} ) ) {
                my $Success = $TicketObject->TicketPendingTimeSet(
                    UserID   => $Self->{UserID},
                    TicketID => $TicketID,
                    %{ $TicketParam{'PendingTime'} },
                );
                if ( !$Success ) {
                    $LayoutObject->FatalError(
                        Message => $LayoutObject->{LanguageObject}->Translate(
                            'Could not set PendingTime for Ticket with ID "%s" in ActivityDialog "%s"!',
                            $TicketID,
                            $ActivityDialogEntityID,
                        ),
                    );
                }
            }
        }

        elsif ( $CurrentField eq 'Article' && ( $UpdateTicketID || $NewTicketID ) ) {

            my $TicketID = $UpdateTicketID || $NewTicketID;

            if ( $Param{GetParam}->{Subject} && $Param{GetParam}->{Body} ) {

                # add note
                my $ArticleID = '';
                my $MimeType  = 'text/plain';

                # get pre loaded attachment
                my @Attachments = $UploadCacheObject->FormIDGetAllFilesData(
                    FormID => $Self->{FormID},
                );

                # get submit attachment
                my %UploadStuff = $ParamObject->GetUploadAll(
                    Param => 'FileUpload',
                );
                if (%UploadStuff) {
                    push @Attachments, \%UploadStuff;
                }

                if ( $LayoutObject->{BrowserRichText} ) {
                    $MimeType = 'text/html';

                    # write attachments
                    my @NewAttachmentData;
                    ATTACHMENT:
                    for my $Attachment (@Attachments) {

                        # skip, deleted not used inline images
                        my $ContentID = $Attachment->{ContentID};
                        if (
                            $ContentID
                            && ( $Attachment->{ContentType} =~ /image/i )
                            && ( $Attachment->{Disposition} eq 'inline' )
                            )
                        {
                            my $ContentIDHTMLQuote = $LayoutObject->Ascii2Html(
                                Text => $ContentID,
                            );

                            # workaround for link encode of rich text editor, see bug#5053
                            my $ContentIDLinkEncode = $LayoutObject->LinkEncode($ContentID);
                            $Param{GetParam}->{Body} =~ s/(ContentID=)$ContentIDLinkEncode/$1$ContentID/g;

                            # ignore attachment if not linked in body
                            if ( $Param{GetParam}->{Body} !~ /(\Q$ContentIDHTMLQuote\E|\Q$ContentID\E)/i )
                            {
                                next ATTACHMENT;
                            }
                        }

                        # Remember inline images and normal attachments.
                        push @NewAttachmentData, \%{$Attachment};
                    }

                    @Attachments = @NewAttachmentData;

                    # verify html document
                    $Param{GetParam}->{Body} = $LayoutObject->RichTextDocumentComplete(
                        String => $Param{GetParam}->{Body},
                    );
                }

                my $CommunicationChannel = $ActivityDialog->{Fields}->{Article}->{Config}->{CommunicationChannel}
                    // 'Internal';

                my $ArticleBackendObject = $Kernel::OM->Get('Kernel::System::Ticket::Article')->BackendForChannel(
                    ChannelName => $CommunicationChannel,
                );

                # Change history type and comment accordingly to the process article.
                my $HistoryType    = 'AddNote';
                my $HistoryComment = '%%Note';
                if ( $CommunicationChannel eq 'Phone' ) {
                    $HistoryType    = 'PhoneCallAgent';
                    $HistoryComment = '%%';
                }

                my $From = "\"$Self->{UserFullname}\" <$Self->{UserEmail}>";
                $ArticleID = $ArticleBackendObject->ArticleCreate(
                    TicketID             => $TicketID,
                    SenderType           => 'agent',
                    IsVisibleForCustomer => $ActivityDialog->{Fields}->{Article}->{Config}->{IsVisibleForCustomer} // 0,
                    From                 => $From,
                    MimeType             => $MimeType,
                    Charset              => $LayoutObject->{UserCharset},
                    UserID               => $Self->{UserID},
                    HistoryType          => $HistoryType,
                    HistoryComment       => $HistoryComment,
                    Body                 => $Param{GetParam}{Body},
                    Subject              => $Param{GetParam}{Subject},
                    ForceNotificationToUserID => $ActivityDialog->{Fields}->{Article}->{Config}->{InformAgents}
                    ? $Param{GetParam}{InformUserID}
                    : [],
                );
                if ( !$ArticleID ) {
                    return $LayoutObject->ErrorScreen();
                }

                # write attachments
                for my $Attachment (@Attachments) {
                    $ArticleBackendObject->ArticleWriteAttachment(
                        %{$Attachment},
                        ArticleID => $ArticleID,
                        UserID    => $Self->{UserID},
                    );
                }

                # Remove pre submitted attachments.
                $UploadCacheObject->FormIDRemove( FormID => $Self->{FormID} );

                # time accounting
                if ( $Param{GetParam}->{TimeUnits} ) {
                    $TicketObject->TicketAccountTime(
                        TicketID  => $TicketID,
                        ArticleID => $ArticleID,
                        TimeUnit  => $Param{GetParam}{TimeUnits},
                        UserID    => $Self->{UserID},
                    );
                }
            }
        }

        # If we have to Update a ticket, update the transmitted values
        elsif ($UpdateTicketID) {

            my $Success;
            if ( $Self->{NameToID}->{$CurrentField} eq 'Title' ) {

                # if there is no title, nothing is needed to be done
                if (
                    !defined $TicketParam{'Title'}
                    || ( defined $TicketParam{'Title'} && $TicketParam{'Title'} eq '' )
                    )
                {
                    $Success = 1;
                }

                # otherwise set the ticket title
                else {
                    $Success = $TicketObject->TicketTitleUpdate(
                        Title    => $TicketParam{'Title'},
                        TicketID => $TicketID,
                        UserID   => $Self->{UserID},
                    );
                }
            }
            elsif (
                (
                    $Self->{NameToID}->{$CurrentField} eq 'CustomerID'
                    || $Self->{NameToID}->{$CurrentField} eq 'CustomerUserID'
                )
                )
            {
                next DIALOGFIELD if $StoredFields{ $Self->{NameToID}->{$CurrentField} };

                if ( $ActivityDialog->{Fields}->{$CurrentField}->{Display} == 1 ) {
                    $LayoutObject->FatalError(
                        Message => $LayoutObject->{LanguageObject}->Translate(
                            'Wrong ActivityDialog Field config: %s can\'t be Display => 1 / Show field (Please change its configuration to be Display => 0 / Do not show field or Display => 2 / Show field as mandatory)!',
                            $CurrentField,
                        ),
                    );
                }

                # skip TicketCustomerSet() if there is no change in the customer
                if (
                    $Ticket{CustomerID} eq $TicketParam{CustomerID}
                    && $Ticket{CustomerUserID} eq $TicketParam{CustomerUser}
                    )
                {

                    # In this case we don't want to call any additional stores
                    # on Customer, CustomerNo, CustomerID or CustomerUserID
                    # so make sure both fields are set to "Stored" ;)
                    $StoredFields{ $Self->{NameToID}->{'CustomerID'} }     = 1;
                    $StoredFields{ $Self->{NameToID}->{'CustomerUserID'} } = 1;
                    next DIALOGFIELD;
                }

                $Success = $TicketObject->TicketCustomerSet(
                    No => $TicketParam{CustomerID},

                    # here too: unfortunately TicketCreate takes Param 'CustomerUser'
                    # instead of CustomerUserID, so our TicketParam hash
                    # has the CustomerUser Key instead of 'CustomerUserID'
                    User     => $TicketParam{CustomerUser},
                    TicketID => $TicketID,
                    UserID   => $Self->{UserID},
                );

                # In this case we don't want to call any additional stores
                # on Customer, CustomerNo, CustomerID or CustomerUserID
                # so make sure both fields are set to "Stored" ;)
                $StoredFields{ $Self->{NameToID}->{'CustomerID'} }     = 1;
                $StoredFields{ $Self->{NameToID}->{'CustomerUserID'} } = 1;
            }
            else {
                next DIALOGFIELD if $StoredFields{ $Self->{NameToID}->{$CurrentField} };
                next DIALOGFIELD if $CurrentField eq 'Attachments';

                my $TicketFieldSetSub = $CurrentField;
                $TicketFieldSetSub =~ s{ID$}{}xms;
                $TicketFieldSetSub = 'Ticket' . $TicketFieldSetSub . 'Set';

                if ( $TicketObject->can($TicketFieldSetSub) )
                {
                    my $UpdateFieldName;

                    # sadly we need an exception for Owner(ID) and Responsible(ID), because the
                    # Ticket*Set subs need NewUserID as param
                    if (
                        scalar grep { $Self->{NameToID}->{$CurrentField} eq $_ }
                        qw( OwnerID ResponsibleID )
                        )
                    {
                        $UpdateFieldName = 'NewUserID';
                    }
                    else {
                        $UpdateFieldName = $Self->{NameToID}->{$CurrentField};
                    }

                    # to store if the field needs to be updated
                    my $FieldUpdate;

                    # only Service and SLA fields accepts empty values if the hash key is not
                    # defined set it to empty so the Ticket*Set function call will get the empty
                    # value
                    if (
                        ( $UpdateFieldName eq 'ServiceID' || $UpdateFieldName eq 'SLAID' )
                        && !defined $TicketParam{ $Self->{NameToID}->{$CurrentField} }
                        )
                    {
                        $TicketParam{ $Self->{NameToID}->{$CurrentField} } = '';
                        $FieldUpdate = 1;
                    }

                    # update Service an SLA fields if they have a defined value (even empty)
                    elsif ( $UpdateFieldName eq 'ServiceID' || $UpdateFieldName eq 'SLAID' )
                    {
                        $FieldUpdate = 1;
                    }

                    # update any other field that its value is defined and not empty
                    elsif (
                        $UpdateFieldName ne 'ServiceID'
                        && $UpdateFieldName ne 'SLAID'
                        && defined $TicketParam{ $Self->{NameToID}->{$CurrentField} }
                        && $TicketParam{ $Self->{NameToID}->{$CurrentField} } ne ''
                        )
                    {
                        $FieldUpdate = 1;
                    }

                    $Success = 1;

                    # check if field needs to be updated
                    if ($FieldUpdate) {
                        $Success = $TicketObject->$TicketFieldSetSub(
                            $UpdateFieldName => $TicketParam{ $Self->{NameToID}->{$CurrentField} },
                            TicketID         => $TicketID,
                            UserID           => $Self->{UserID},
                        );

                        # in case of a new service and no new SLA is to be set, check if current
                        # assigned SLA is still valid
                        if (
                            $UpdateFieldName eq 'ServiceID'
                            && !defined $TicketParam{SLAID}
                            )
                        {

                            # get ticket details
                            my %Ticket = $TicketObject->TicketGet(
                                TicketID      => $TicketID,
                                DynamicFields => 0,
                                UserID        => $Self->{UserID},
                            );

                            # if ticket already have an SLA assigned get the list SLAs for the new
                            # service
                            if ( IsPositiveInteger( $Ticket{SLAID} ) ) {
                                my %SLAList = $Kernel::OM->Get('Kernel::System::SLA')->SLAList(
                                    ServiceID => $TicketParam{ $Self->{NameToID}->{$CurrentField} },
                                    UserID    => $Self->{UserID},
                                );

                                # if the current SLA is not in the list of SLA for new service
                                # remove SLA from ticket
                                if ( !$SLAList{ $Ticket{SLAID} } ) {
                                    $TicketObject->TicketSLASet(
                                        SLAID    => '',
                                        TicketID => $TicketID,
                                        UserID   => $Self->{UserID},
                                    );
                                }
                            }
                        }
                    }
                }
            }
            if ( !$Success ) {
                $LayoutObject->FatalError(
                    Message => $LayoutObject->{LanguageObject}->Translate(
                        'Could not set %s for Ticket with ID "%s" in ActivityDialog "%s"!',
                        $CurrentField,
                        $TicketID,
                        $ActivityDialogEntityID,
                    ),
                );
            }
        }
    }

    # get the link ticket id if given
    my $LinkTicketID = $ParamObject->GetParam( Param => 'LinkTicketID' ) || '';

    # get screen config
    my $Config = $Kernel::OM->Get('Kernel::Config')->Get("Ticket::Frontend::$Self->{Action}");

    # link tickets
    if (
        $LinkTicketID
        && $Config->{SplitLinkType}
        && $Config->{SplitLinkType}->{LinkType}
        && $Config->{SplitLinkType}->{Direction}
        )
    {

        my $Access = $TicketObject->TicketPermission(
            Type     => 'ro',
            TicketID => $LinkTicketID,
            UserID   => $Self->{UserID}
        );

        if ( !$Access ) {
            return $LayoutObject->NoPermission(
                Message    => "You need ro permission!",
                WithHeader => 'yes',
            );
        }

        my $SourceKey = $LinkTicketID;
        my $TargetKey = $TicketID;

        if ( $Config->{SplitLinkType}->{Direction} eq 'Source' ) {
            $SourceKey = $TicketID;
            $TargetKey = $LinkTicketID;
        }

        # link the tickets
        $Kernel::OM->Get('Kernel::System::LinkObject')->LinkAdd(
            SourceObject => 'Ticket',
            SourceKey    => $SourceKey,
            TargetObject => 'Ticket',
            TargetKey    => $TargetKey,
            Type         => $Config->{SplitLinkType}->{LinkType} || 'Normal',
            State        => 'Valid',
            UserID       => $Self->{UserID},
        );
    }

    if ($NewOwnerID) {
        $TicketObject->TicketOwnerSet(
            TicketID  => $TicketID,
            NewUserID => $NewOwnerID,
            UserID    => $Self->{UserID},
        );
    }

    # Transitions will be handled by ticket event module (TicketProcessTransitions.pm).

    # if we were updating a ticket, close the pop-up and return to zoom
    # else (new ticket) just go to zoom to show the new ticket
    if ($UpdateTicketID) {

        # load new URL in parent window and close pop-up
        return $LayoutObject->PopupClose(
            URL => "Action=AgentTicketZoom;TicketID=$UpdateTicketID",
        );
    }

    return $LayoutObject->Redirect(
        OP => "Action=AgentTicketZoom;TicketID=$TicketID",
    );
}

sub _DisplayProcessList {
    my ( $Self, %Param ) = @_;

    # If we have a ProcessEntityID
    $Param{Errors}->{ProcessEntityIDInvalid} = ' ServerError'
        if ( $Param{ProcessEntityID} && !$Param{ProcessList}->{ $Param{ProcessEntityID} } );

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    my $Config = $ConfigObject->Get('Ticket::Frontend::AgentTicketProcess');

    $Param{ProcessList} = $LayoutObject->BuildSelection(
        Class        => 'Modernize Validate_Required' . ( $Param{Errors}->{ProcessEntityIDInvalid} || ' ' ),
        Data         => $Param{ProcessList},
        Name         => 'ProcessEntityID',
        SelectedID   => $Param{ProcessEntityID},
        PossibleNone => 1,
        Sort         => 'AlphanumericValue',
        Translation  => 1,
        TreeView     => $Config->{ProcessListTreeView} || 0,
        AutoComplete => 'off',
    );

    # add rich text editor
    if ( $LayoutObject->{BrowserRichText} ) {

        # use height/width defined for this screen
        $Param{RichTextHeight} = $Self->{Config}->{RichTextHeight} || 0;
        $Param{RichTextWidth}  = $Self->{Config}->{RichTextWidth}  || 0;

        # set up rich text editor
        $LayoutObject->SetRichTextParameters(
            Data => \%Param,
        );
    }

    if ( $Param{PreSelectProcess} && $Param{ProcessID} ) {

        # send data to JS
        $LayoutObject->AddJSData(
            Key   => 'ProcessID',
            Value => $Param{ProcessID},
        );
    }

    $LayoutObject->Block(
        Name => 'ProcessList',
        Data => {
            %Param,
            FormID => $Self->{FormID},
        },
    );

    # on initial screen from navbar there is no IsMainWinow but also no IsProcessEnroll,
    # then it must be a MainWindow
    if ( !$Self->{IsMainWindow} && !$Self->{IsProcessEnroll} ) {
        $Self->{IsMainWindow} = 1;
    }

    my $Type = $Self->{IsMainWindow} ? '' : 'Small';

    my $Output = $LayoutObject->Header(
        Type => $Type,
    );
    if ( $Self->{IsMainWindow} ) {
        $Output .= $LayoutObject->NavigationBar();
    }

    $Output .= $LayoutObject->Output(
        TemplateFile => 'AgentTicketProcess' . $Type,
        Data         => {
            %Param,
            FormID          => $Self->{FormID},
            IsProcessEnroll => $Self->{IsProcessEnroll},
        },
    );

    # workaround when activity dialog is loaded by AJAX as first activity dialog, if there is
    # a date field like Pending Time or Dynamic Fields Date/Time or Date, there is no way to set
    # this options in the footer again
    $LayoutObject->{HasDatepicker} = 1;

    $Output .= $LayoutObject->Footer( Type => $Type );

    return $Output;
}

# =cut
#
# _CheckField()
#
# checks all the possible ticket fields and returns the ID (if possible) value of the field, if valid
# and checks are successful
#
# if Display param is set to 0 or not given, it uses ActivityDialog field default value for all fields
# or global default value as fall-back only for certain fields
#
# if Display param is set to 1 or 2 it uses the value from the web request
#
#     my $PriorityID = $AgentTicketProcessObject->_CheckField(
#         Field        => 'PriorityID',
#         Display      => 1,                   # optional, 0 or 1 or 2
#         DefaultValue => '3 normal',          # ActivityDialog field default value (it uses global
#                                              #    default value as fall back for mandatory fields
#                                              #    (Queue, Sate, Lock and Priority)
#     );
#
# Returns:
#     $PriorityID = 1;                         # if PriorityID is set to 1 in the web request
#
#     my $PriorityID = $AgentTicketProcessObject->_CheckField(
#         Field        => 'PriorityID',
#         Display      => 0,
#         DefaultValue => '3 normal',
#     );
#
# Returns:
#     $PriorityID = 3;                        # since ActivityDialog default value is '3 normal' and
#                                             #     field is hidden
#
# =cut

sub _CheckField {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Field)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    # remove the ID and check if the given field is required for creating a ticket
    my $FieldWithoutID = $Param{Field};
    $FieldWithoutID =~ s{ID$}{}xms;
    my $TicketRequiredField = scalar grep { $_ eq $FieldWithoutID } qw(Queue State Lock Priority);

    my $Value;

    # get needed objects
    my $ParamObject  = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # if no Display (or Display == 0) is committed
    if ( !$Param{Display} ) {

        # Check if a DefaultValue is given
        if ( $Param{DefaultValue} ) {

            # check if the given field param is valid
            $Value = $Self->_LookupValue(
                Field => $FieldWithoutID,
                Value => $Param{DefaultValue},
            );
        }

        # if we got a required ticket field, check if we got a valid DefaultValue in the SysConfig
        if ( !$Value && $TicketRequiredField ) {
            $Value = $Kernel::OM->Get('Kernel::Config')->Get("Process::Default$FieldWithoutID");

            if ( !$Value ) {
                $LayoutObject->FatalError(
                    Message => $LayoutObject->{LanguageObject}->Translate(
                        'Default Config for Process::Default%s missing!',
                        $FieldWithoutID,
                    ),
                );
            }
            else {

                # check if the given field param is valid
                $Value = $Self->_LookupValue(
                    Field => $FieldWithoutID,
                    Value => $Value,
                );
                if ( !$Value ) {
                    $LayoutObject->FatalError(
                        Message => $LayoutObject->{LanguageObject}->Translate(
                            'Default Config for Process::Default%s invalid!',
                            $FieldWithoutID,
                        ),
                    );
                }
            }
        }
    }
    elsif ( $Param{Display} == 1 ) {

        # Display == 1 is logicality not possible for a ticket required field
        if ($TicketRequiredField) {
            $LayoutObject->FatalError(
                Message => $LayoutObject->{LanguageObject}->Translate(
                    'Wrong ActivityDialog Field config: %s can\'t be Display => 1 / Show field (Please change its configuration to be Display => 0 / Do not show field or Display => 2 / Show field as mandatory)!',
                    $Param{Field},
                ),
            );
        }

        # check if the given field param is valid
        if ( $Param{Field} eq 'Article' ) {

            $Value = 1;

            my ( $Body, $Subject, $AttachmentExists, $TimeUnits ) = (
                $ParamObject->GetParam( Param => 'Body' ),
                $ParamObject->GetParam( Param => 'Subject' ),
                $ParamObject->GetParam( Param => 'AttachmentExists' ),
                $ParamObject->GetParam( Param => 'TimeUnits' )
            );

            # If attachment exists and body and subject not, it is error (see bug#13081).
            if ( $AttachmentExists && ( !$Body && !$Subject ) ) {
                $Value = 0;
            }

            # If time units exists and body and subject not, it is error (see bug#13266).
            if ( $TimeUnits && ( !$Body && !$Subject ) ) {
                $Value = 0;
            }
        }
        else {

            $Value = $Self->_LookupValue(
                Field => $Param{Field},
                Value => $ParamObject->GetParam( Param => $Param{Field} ) || '',
            );
        }
    }
    elsif ( $Param{Display} == 2 ) {

        # check if the given field param is valid
        if ( $Param{Field} eq 'Article' ) {

            my ( $Body, $Subject ) = (
                $ParamObject->GetParam( Param => 'Body' ),
                $ParamObject->GetParam( Param => 'Subject' )
            );

            $Value = 0;
            if ( $Body && $Subject ) {
                $Value = 1;
            }
        }
        else {
            $Value = $Self->_LookupValue(
                Field => $Param{Field},
                Value => $ParamObject->GetParam( Param => $Param{Field} ) || '',
            );
        }
    }

    return $Value;
}

# =cut
#
# _LookupValue()
#
# returns the ID (if possible) of nearly all ticket fields and/or checks if its valid.
# Can handle IDs or Strings.
# Currently working with: State, Queue, Lock, Priority (possible more).
#
#     my $PriorityID = $AgentTicketProcessObject->_LookupValue(
#         PriorityID => 1,
#     );
#     $PriorityID = 1;
#
#     my $StateID = $AgentTicketProcessObject->_LookupValue(
#         State => 'open',
#     );
#     $StateID = 3;
#
#     my $PriorityID = $AgentTicketProcessObject->_LookupValue(
#         Priority => 'unknownpriority1234',
#     );
#     $PriorityID = undef;
#
# =cut

sub _LookupValue {
    my ( $Self, %Param ) = @_;

    # get log object
    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    # check needed stuff
    for my $Needed (qw(Field Value)) {
        if ( !defined $Param{$Needed} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    if ( !$Param{Field} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Field should not be empty!"
        );
        return;
    }

    # if there is no value, there is nothing to do
    return if !$Param{Value};

    # remove the ID for function name purpose
    my $FieldWithoutID = $Param{Field};
    $FieldWithoutID =~ s{ID$}{}xms;

    my $LookupFieldName;
    my $ObjectName;
    my $FunctionName;

    # owner(ID) and responsible(ID) lookup needs UserID as parameter
    if ( scalar grep { $Param{Field} eq $_ } qw( OwnerID ResponsibleID ) ) {
        $LookupFieldName = 'UserID';
        $ObjectName      = 'User';
        $FunctionName    = 'UserLookup';
    }

    # owner and responsible lookup needs UserLogin as parameter
    elsif ( scalar grep { $Param{Field} eq $_ } qw( Owner Responsible ) ) {
        $LookupFieldName = 'UserLogin';
        $ObjectName      = 'User';
        $FunctionName    = 'UserLookup';
    }

    # service and SLA lookup needs Name as parameter (While ServiceID an SLAID uses standard)
    elsif ( scalar grep { $Param{Field} eq $_ } qw( Service SLA ) ) {
        $LookupFieldName = 'Name';
        $ObjectName      = $FieldWithoutID;
        $FunctionName    = $FieldWithoutID . 'Lookup';
    }

    # other fields can use standard parameter names as Priority or PriorityID
    else {
        $LookupFieldName = $Param{Field};
        $ObjectName      = $FieldWithoutID;
        $FunctionName    = $FieldWithoutID . 'Lookup';
    }

    # get appropriate object of field
    my $FieldObject;
    if ( $Kernel::OM->Get('Kernel::System::Main')->Require( 'Kernel::System::' . $ObjectName, Silent => 1 ) ) {
        $FieldObject = $Kernel::OM->Get( 'Kernel::System::' . $ObjectName );
    }

    my $Value;

    # check if the backend module has the needed *Lookup sub
    if ( $FieldObject && $FieldObject->can($FunctionName) ) {

        # call the *Lookup sub and get the value
        $Value = $FieldObject->$FunctionName(
            $LookupFieldName => $Param{Value},
        );
    }

    # if we didn't have an object and the value has no ref a string e.g. Title and so on
    # return true
    elsif ( $Param{Field} eq $FieldWithoutID && !ref $Param{Value} ) {
        return $Param{Value};
    }
    else {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Error while checking with " . $FieldWithoutID . "Object!"
        );
        return;
    }

    return if ( !$Value );

    # return the given ID value if the *Lookup result was a string
    if ( $Param{Field} ne $FieldWithoutID ) {
        return $Param{Value};
    }

    # return the *Lookup string return value
    return $Value;
}

sub _GetResponsibles {
    my ( $Self, %Param ) = @_;

    # get users
    my %ShownUsers;
    my %AllGroupsMembers = $Kernel::OM->Get('Kernel::System::User')->UserList(
        Type  => 'Long',
        Valid => 1,
    );

    # get needed objects
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my $QueueObject  = $Kernel::OM->Get('Kernel::System::Queue');
    my $GroupObject  = $Kernel::OM->Get('Kernel::System::Group');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # Get available permissions and set permission group type accordingly.
    my $ConfigPermissions   = $ConfigObject->Get('System::Permission');
    my $PermissionGroupType = ( grep { $_ eq 'responsible' } @{$ConfigPermissions} ) ? 'responsible' : 'rw';

    # if we are updating a ticket show the full list of possible responsibles
    if ( $Param{TicketID} ) {
        if ( $Param{QueueID} && !$Param{AllUsers} ) {
            my $GID        = $QueueObject->GetQueueGroupID( QueueID => $Param{QueueID} );
            my %MemberList = $GroupObject->PermissionGroupGet(
                GroupID => $GID,
                Type    => $PermissionGroupType,
            );
            for my $UserID ( sort keys %MemberList ) {
                $ShownUsers{$UserID} = $AllGroupsMembers{$UserID};
            }
        }
    }
    else {

        # the StartActivityDialog does not provide a TicketID and it could be that also there
        # is no QueueID information. Get the default QueueID for this matters.
        if ( !$Param{QueueID} ) {
            my $Queue   = $ConfigObject->Get("Process::DefaultQueue");
            my $QueueID = $QueueObject->QueueLookup( Queue => $Queue );
            if ($QueueID) {
                $Param{QueueID} = $QueueID;
            }
        }

        # just show only users with selected custom queue
        if ( $Param{QueueID} && !$Param{ResponsibleAll} ) {
            my @UserIDs = $TicketObject->GetSubscribedUserIDsByQueueID(%Param);
            for my $KeyGroupMember ( sort keys %AllGroupsMembers ) {
                my $Hit = 0;
                for my $UID (@UserIDs) {
                    if ( $UID eq $KeyGroupMember ) {
                        $Hit = 1;
                    }
                }
                if ( !$Hit ) {
                    delete $AllGroupsMembers{$KeyGroupMember};
                }
            }
        }

        # show all system users
        if ( $ConfigObject->Get('Ticket::ChangeOwnerToEveryone') ) {
            %ShownUsers = %AllGroupsMembers;
        }

        # show all subscribed users who have the appropriate permission in the queue group
        elsif ( $Param{QueueID} ) {
            my $GID        = $QueueObject->GetQueueGroupID( QueueID => $Param{QueueID} );
            my %MemberList = $GroupObject->PermissionGroupGet(
                GroupID => $GID,
                Type    => $PermissionGroupType,
            );
            for my $KeyMember ( sort keys %MemberList ) {
                if ( $AllGroupsMembers{$KeyMember} ) {
                    $ShownUsers{$KeyMember} = $AllGroupsMembers{$KeyMember};
                }
            }
        }
    }

    # workflow
    my $ACL = $TicketObject->TicketAcl(
        %Param,
        Action        => $Self->{Action},
        ReturnType    => 'Ticket',
        ReturnSubType => 'Responsible',
        Data          => \%ShownUsers,
        UserID        => $Self->{UserID},
    );

    return { $TicketObject->TicketAclData() } if $ACL;

    return \%ShownUsers;
}

sub _GetOwners {
    my ( $Self, %Param ) = @_;

    # get users
    my %ShownUsers;
    my %AllGroupsMembers = $Kernel::OM->Get('Kernel::System::User')->UserList(
        Type  => 'Long',
        Valid => 1,
    );

    # get needed objects
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my $QueueObject  = $Kernel::OM->Get('Kernel::System::Queue');
    my $GroupObject  = $Kernel::OM->Get('Kernel::System::Group');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # Get available permissions and set permission group type accordingly.
    my $ConfigPermissions   = $ConfigObject->Get('System::Permission');
    my $PermissionGroupType = ( grep { $_ eq 'owner' } @{$ConfigPermissions} ) ? 'owner' : 'rw';

    # if we are updating a ticket show the full list of possible owners
    if ( $Param{TicketID} ) {
        if ( $Param{QueueID} && !$Param{AllUsers} ) {
            my $GID        = $QueueObject->GetQueueGroupID( QueueID => $Param{QueueID} );
            my %MemberList = $GroupObject->PermissionGroupGet(
                GroupID => $GID,
                Type    => $PermissionGroupType,
            );
            for my $UserID ( sort keys %MemberList ) {
                $ShownUsers{$UserID} = $AllGroupsMembers{$UserID};
            }
        }
    }
    else {

        # the StartActivityDialog does not provide a TicketID and it could be that also there
        # is no QueueID information. Get the default QueueID for this matters.
        if ( !$Param{QueueID} ) {
            my $Queue   = $ConfigObject->Get("Process::DefaultQueue");
            my $QueueID = $QueueObject->QueueLookup( Queue => $Queue );
            if ($QueueID) {
                $Param{QueueID} = $QueueID;
            }
        }

        # just show only users with selected custom queue
        if ( $Param{QueueID} && !$Param{OwnerAll} ) {
            my @UserIDs = $TicketObject->GetSubscribedUserIDsByQueueID(%Param);
            for my $KeyGroupMember ( sort keys %AllGroupsMembers ) {
                my $Hit = 0;
                for my $UID (@UserIDs) {
                    if ( $UID eq $KeyGroupMember ) {
                        $Hit = 1;
                    }
                }
                if ( !$Hit ) {
                    delete $AllGroupsMembers{$KeyGroupMember};
                }
            }
        }

        # show all system users
        if ( $ConfigObject->Get('Ticket::ChangeOwnerToEveryone') ) {
            %ShownUsers = %AllGroupsMembers;
        }

        # show all subscribed users who have the appropriate permission in the queue group
        elsif ( $Param{QueueID} ) {
            my $GID        = $QueueObject->GetQueueGroupID( QueueID => $Param{QueueID} );
            my %MemberList = $GroupObject->PermissionGroupGet(
                GroupID => $GID,
                Type    => $PermissionGroupType,
            );
            for my $KeyMember ( sort keys %MemberList ) {
                if ( $AllGroupsMembers{$KeyMember} ) {
                    $ShownUsers{$KeyMember} = $AllGroupsMembers{$KeyMember};
                }
            }
        }
    }

    # workflow
    my $ACL = $TicketObject->TicketAcl(
        %Param,
        Action        => $Self->{Action},
        ReturnType    => 'Ticket',
        ReturnSubType => 'Owner',
        Data          => \%ShownUsers,
        UserID        => $Self->{UserID},
    );

    return { $TicketObject->TicketAclData() } if $ACL;

    return \%ShownUsers;
}

sub _GetSLAs {
    my ( $Self, %Param ) = @_;

    # get sla
    my %SLA;
    if ( $Param{ServiceID} && $Param{Services} && %{ $Param{Services} } ) {
        if ( $Param{Services}->{ $Param{ServiceID} } ) {
            %SLA = $Kernel::OM->Get('Kernel::System::Ticket')->TicketSLAList(
                %Param,
                Action => $Self->{Action},
                UserID => $Self->{UserID},
            );
        }
    }
    return \%SLA;
}

sub _GetServices {
    my ( $Self, %Param ) = @_;

    # get service
    my %Service;

    # check needed
    return \%Service if !$Param{QueueID} && !$Param{TicketID};

    # get options for default services for unknown customers
    my $DefaultServiceUnknownCustomer
        = $Kernel::OM->Get('Kernel::Config')->Get('Ticket::Service::Default::UnknownCustomer');

    # check if no CustomerUserID is selected
    # if $DefaultServiceUnknownCustomer = 0 leave CustomerUserID empty, it will not get any services
    # if $DefaultServiceUnknownCustomer = 1 set CustomerUserID to get default services
    if ( !$Param{CustomerUserID} && $DefaultServiceUnknownCustomer ) {
        $Param{CustomerUserID} = '<DEFAULT>';
    }

    # get service list
    if ( $Param{CustomerUserID} ) {
        %Service = $Kernel::OM->Get('Kernel::System::Ticket')->TicketServiceList(
            %Param,
            Action => $Self->{Action},
            UserID => $Self->{UserID},
        );
    }
    return \%Service;
}

sub _GetLocks {
    my ( $Self, %Param ) = @_;

    my %Locks = $Kernel::OM->Get('Kernel::System::Lock')->LockList(
        UserID => $Self->{UserID},
    );

    return \%Locks;
}

sub _GetPriorities {
    my ( $Self, %Param ) = @_;

    my %Priorities;

    # Initially we have just the default Queue Parameter
    # so make sure to get the ID in that case
    my $QueueID;
    if ( !$Param{QueueID} && $Param{Queue} ) {
        $QueueID = $Kernel::OM->Get('Kernel::System::Queue')->QueueLookup( Queue => $Param{Queue} );
    }
    if ( $Param{QueueID} || $QueueID || $Param{TicketID} ) {
        %Priorities = $Kernel::OM->Get('Kernel::System::Ticket')->TicketPriorityList(
            %Param,
            Action => $Self->{Action},
            UserID => $Self->{UserID},
        );

    }
    return \%Priorities;
}

sub _GetQueues {
    my ( $Self, %Param ) = @_;

    # check which type of permission is needed: if the process ticket
    # already exists (= TicketID is present), we need the 'move_into'
    # permission otherwise the 'create' permission
    my $PermissionType = 'create';
    if ( $Param{TicketID} ) {
        $PermissionType = 'move_into';
    }

    # get config object
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # check own selection
    my %NewQueues;
    if ( $ConfigObject->Get('Ticket::Frontend::NewQueueOwnSelection') ) {
        %NewQueues = %{ $ConfigObject->Get('Ticket::Frontend::NewQueueOwnSelection') };
    }
    else {

        # SelectionType Queue or SystemAddress?
        my %Queues;
        if ( $ConfigObject->Get('Ticket::Frontend::NewQueueSelectionType') eq 'Queue' ) {
            %Queues = $Kernel::OM->Get('Kernel::System::Ticket')->MoveList(
                %Param,
                Type    => $PermissionType,
                Action  => $Self->{Action},
                QueueID => $Self->{QueueID},
                UserID  => $Self->{UserID},
            );
        }
        else {
            %Queues = $Kernel::OM->Get('Kernel::System::SystemAddress')->SystemAddressQueueList();
        }

        # get permission queues
        my %UserGroups = $Kernel::OM->Get('Kernel::System::Group')->PermissionUserGet(
            UserID => $Self->{UserID},
            Type   => $PermissionType,
        );

        # build selection string
        QUEUEID:
        for my $QueueID ( sort keys %Queues ) {
            my %QueueData = $Kernel::OM->Get('Kernel::System::Queue')->QueueGet( ID => $QueueID );

            # permission check, can we create new tickets in queue
            next QUEUEID if !$UserGroups{ $QueueData{GroupID} };

            my $String = $ConfigObject->Get('Ticket::Frontend::NewQueueSelectionString')
                || '<Realname> <<Email>> - Queue: <Queue>';
            $String =~ s/<Queue>/$QueueData{Name}/g;
            $String =~ s/<QueueComment>/$QueueData{Comment}/g;

            # remove trailing spaces
            $String =~ s{\s+\z}{} if !$QueueData{Comment};

            if ( $ConfigObject->Get('Ticket::Frontend::NewQueueSelectionType') ne 'Queue' )
            {
                my %SystemAddressData = $Self->{SystemAddress}->SystemAddressGet(
                    ID => $Queues{$QueueID},
                );
                $String =~ s/<Realname>/$SystemAddressData{Realname}/g;
                $String =~ s/<Email>/$SystemAddressData{Name}/g;
            }
            $NewQueues{$QueueID} = $String;
        }
    }

    return \%NewQueues;
}

sub _GetAttachments {
    my ( $Self, %Param ) = @_;

    my $ConfigObject  = $Kernel::OM->Get('Kernel::Config');
    my $LayoutObject  = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');

    my @Articles = $ArticleObject->ArticleList(
        TicketID => $Param{TicketID},
    );

    my %ArticleFileData;

    return \%ArticleFileData if !@Articles;

    my $FormatString = $ConfigObject->Get('Process::DynamicFieldProcessManagementAttachment::FormatString')
        // 'A#%1$d: %2$s';

    my $TranslatedObjectType      = $LayoutObject->{LanguageObject}->Translate('Article');
    my $TranslatedAttachmentLabel = $LayoutObject->{LanguageObject}->Translate('Attachment');

    ARTICLE:
    for my $Article (@Articles) {
        my %Index = $ArticleObject->ArticleAttachmentIndex(
            TicketID         => $Param{TicketID},
            ArticleID        => $Article->{ArticleID},
            ExcludePlainText => 1,
            ExcludeHTMLBody  => 1,
            ExcludeInline    => 0,
        );

        next ARTICLE if !%Index;

        for my $FileID ( sort keys %Index ) {

            # SelectionText results in something like: "#2: testfile.pdf"
            # $FormatString = '#%1$d: %2$s'
            my $SelectionText = sprintf $FormatString, $Article->{ArticleNumber}, $Index{$FileID}->{Filename},
                $TranslatedObjectType, $TranslatedAttachmentLabel;

            # Create a stringified structure to use data as key in HTML selection.
            # This info is needed to get the correct attachment from the backend.
            #
            # Stringified structure
            # 'ObjectType=Article;ObjectID=1;ID=5'
            # 'ObjectType=Article;ObjectID=1;ID=5,ObjectType=Article;ObjectID=3;ID=2'
            #
            # Parsed stringified structure
            # Data = {
            #     ObjectType => 'Article',
            #     ObjectID   => '1',
            #     ID         => '4',
            # }

            my $Key = 'ObjectType=Article;ObjectID=' . $Article->{ArticleID} . ';ID=' . $FileID;
            $ArticleFileData{$Key} = $SelectionText;
        }
    }

    return \%ArticleFileData;
}

sub _GetStates {
    my ( $Self, %Param ) = @_;

    my %States = $Kernel::OM->Get('Kernel::System::Ticket')->TicketStateList(
        %Param,

        # Set default values for new process ticket
        QueueID  => $Param{QueueID}  || 1,
        TicketID => $Param{TicketID} || '',

        # remove type, since if Ticket::Type is active in sysconfig, the Type parameter will
        # be sent and the TicketStateList will send the parameter as State Type
        Type => undef,

        Action => $Self->{Action},
        UserID => $Self->{UserID},
    );

    return \%States;
}

sub _GetTypes {
    my ( $Self, %Param ) = @_;

    # get type
    my %Type;
    if ( $Param{QueueID} || $Param{TicketID} ) {
        %Type = $Kernel::OM->Get('Kernel::System::Ticket')->TicketTypeList(
            %Param,
            Action => $Self->{Action},
            UserID => $Self->{UserID},
        );
    }
    return \%Type;
}

sub _GetAJAXUpdatableFields {
    my ( $Self, %Param ) = @_;

    my %DefaultUpdatableFields = (
        PriorityID    => 1,
        QueueID       => 1,
        ResponsibleID => 1,
        ServiceID     => 1,
        SLAID         => 1,
        StateID       => 1,
        OwnerID       => 1,
        LockID        => 1,
        TypeID        => 1,
    );

    my $DynamicField = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldListGet(
        Valid      => 1,
        ObjectType => 'Ticket',
    );

    # create a DynamicFieldLookupTable
    my %DynamicFieldLookup = map { 'DynamicField_' . $_->{Name} => $_ } @{$DynamicField};

    my @UpdatableFields;
    FIELD:
    for my $Field ( sort keys %{ $Param{ActivityDialogFields} } ) {

        my $FieldData = $Param{ActivityDialogFields}->{$Field};

        # skip hidden fields
        next FIELD if !$FieldData->{Display};

        # for Dynamic Fields check if is AJAXUpdatable
        if ( $Field =~ m{^DynamicField_(.*)}xms ) {
            my $DynamicFieldConfig = $DynamicFieldLookup{$Field};

            # skip any field with wrong config
            next FIELD if !IsHashRefWithData($DynamicFieldConfig);

            # skip field if is not IsACLReducible (updatable)
            my $IsACLReducible = $Kernel::OM->Get('Kernel::System::DynamicField::Backend')->HasBehavior(
                DynamicFieldConfig => $DynamicFieldConfig,
                Behavior           => 'IsACLReducible',
            );
            next FIELD if !$IsACLReducible;

            push @UpdatableFields, $Field;
        }

        # for all others use %DefaultUpdatableFields table
        else {

            # standarize the field name (e.g. use StateID for State field)
            my $FieldName = $Self->{NameToID}->{$Field};

            # skip if field name could not be converted (this means that field is unknown)
            next FIELD if !$FieldName;

            # skip if the field is not updatable via ajax
            next FIELD if !$DefaultUpdatableFields{$FieldName};

            push @UpdatableFields, $FieldName;
        }
    }

    return \@UpdatableFields;
}

sub _GetFieldsToUpdateStrg {
    my ( $Self, %Param ) = @_;

    my $FieldsToUpdate = '';
    if ( IsArrayRefWithData( $Param{AJAXUpdatableFields} ) ) {
        my $FirstItem = 1;
        FIELD:
        for my $Field ( @{ $Param{AJAXUpdatableFields} } ) {
            next FIELD if $Field eq $Param{TriggerField};
            if ($FirstItem) {
                $FirstItem = 0;
            }
            else {
                $FieldsToUpdate .= ', ';
            }
            $FieldsToUpdate .= "'" . $Field . "'";
        }
    }
    return $FieldsToUpdate;
}

sub _ShowDialogError {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    my $Output = $LayoutObject->Header( Type => 'Small' );
    $Output .= $LayoutObject->Error(%Param);
    $Output .= $LayoutObject->Footer( Type => 'Small' );
    return $Output;
}

1;
