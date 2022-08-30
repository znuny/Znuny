# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Modules::CustomerTicketZoom;

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

    # get form id
    $Self->{FormID} = $Kernel::OM->Get('Kernel::System::Web::Request')->GetParam( Param => 'FormID' );

    # create form id
    if ( !$Self->{FormID} ) {
        $Self->{FormID} = $Kernel::OM->Get('Kernel::System::Web::UploadCache')->FormIDCreate();
    }

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $ParamObject  = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    my $TicketNumber = $ParamObject->GetParam( Param => 'TicketNumber' );

    # ticket id lookup
    if ( !$Self->{TicketID} && $TicketNumber ) {
        $Self->{TicketID} = $TicketObject->TicketIDLookup(
            TicketNumber => $ParamObject->GetParam( Param => 'TicketNumber' ),
            UserID       => $Self->{UserID},
        );
    }

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # customers should not get to know that whether an ticket exists or not
    # if a ticket does not exist, show a "no permission" screen
    if ( $TicketNumber && !$Self->{TicketID} ) {
        return $LayoutObject->CustomerNoPermission( WithHeader => 'yes' );
    }

    # check needed stuff
    if ( !$Self->{TicketID} ) {
        my $Output = $LayoutObject->CustomerHeader(
            Title => Translatable('Error'),
        );
        $Output .= $LayoutObject->CustomerError(
            Message => Translatable('Need TicketID!'),
        );
        $Output .= $LayoutObject->CustomerFooter();
        return $Output;
    }

    # check permissions
    my $Access = $TicketObject->TicketCustomerPermission(
        Type     => 'ro',
        TicketID => $Self->{TicketID},
        UserID   => $Self->{UserID},
    );

    # error screen, don't show ticket
    if ( !$Access ) {
        return $LayoutObject->CustomerNoPermission( WithHeader => 'yes' );
    }

    # get ticket data
    my %Ticket = $TicketObject->TicketGet(
        TicketID      => $Self->{TicketID},
        DynamicFields => 1,
    );

    # get ACL restrictions
    my %PossibleActions;
    my $Counter = 0;

    # get config object
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # get all registered Actions
    if ( ref $ConfigObject->Get('CustomerFrontend::Module') eq 'HASH' ) {

        my %Actions = %{ $ConfigObject->Get('CustomerFrontend::Module') };

        # only use those Actions that starts with Customer
        %PossibleActions = map { ++$Counter => $_ }
            grep { substr( $_, 0, length 'Customer' ) eq 'Customer' }
            sort keys %Actions;
    }

    my $ACL = $TicketObject->TicketAcl(
        Data           => \%PossibleActions,
        Action         => $Self->{Action},
        TicketID       => $Self->{TicketID},
        ReturnType     => 'Action',
        ReturnSubType  => '-',
        CustomerUserID => $Self->{UserID},
    );

    my %AclAction = %PossibleActions;
    if ($ACL) {
        %AclAction = $TicketObject->TicketAclActionData();
    }

    # check if ACL restrictions exist
    my %AclActionLookup = reverse %AclAction;

    # show error screen if ACL prohibits this action
    if ( !$AclActionLookup{ $Self->{Action} } ) {
        return $LayoutObject->NoPermission( WithHeader => 'yes' );
    }

    my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');

    # get all articles of this ticket, that are visible for the customer
    my @ArticleList = $ArticleObject->ArticleList(
        TicketID             => $Self->{TicketID},
        IsVisibleForCustomer => 1,
        DynamicFields        => 0,
    );

    my @ArticleBox;
    my $ArticleBackendObject;

    ARTICLEMETADATA:
    for my $ArticleMetaData (@ArticleList) {

        next ARTICLEMETADATA if !$ArticleMetaData;
        next ARTICLEMETADATA if !IsHashRefWithData($ArticleMetaData);

        $ArticleBackendObject = $ArticleObject->BackendForArticle( %{$ArticleMetaData} );

        my %ArticleData = $ArticleBackendObject->ArticleGet(
            TicketID  => $Self->{TicketID},
            ArticleID => $ArticleMetaData->{ArticleID},
            RealNames => 1,
        );

        # Get channel specific fields
        my %ArticleFields = $LayoutObject->ArticleFields(
            TicketID  => $Self->{TicketID},
            ArticleID => $ArticleMetaData->{ArticleID},
        );

        $ArticleData{Subject}      = $ArticleFields{Subject};
        $ArticleData{FromRealname} = $ArticleFields{Sender};

        # Get attachment index.
        my %AtmIndex = $ArticleBackendObject->ArticleAttachmentIndex(
            ArticleID        => $ArticleMetaData->{ArticleID},
            ExcludePlainText => 1,
            ExcludeHTMLBody  => 1,
            ExcludeInline    => 1,
        );

        if ( IsHashRefWithData( \%AtmIndex ) ) {
            $ArticleData{Attachment} = \%AtmIndex;
        }

        push @ArticleBox, \%ArticleData;
    }

    my %GetParam;
    for my $Key (qw(Subject Body StateID PriorityID FromChatID FromChat)) {
        $GetParam{$Key} = $ParamObject->GetParam( Param => $Key );
    }

    # get Dynamic fields from ParamObject
    my %DynamicFieldValues;

    my $Config                     = $ConfigObject->Get("Ticket::Frontend::$Self->{Action}");
    my $FollowUpDynamicFieldFilter = $Config->{FollowUpDynamicField};

    if ( $GetParam{FromChatID} ) {
        if ( !$ConfigObject->Get('ChatEngine::Active') ) {
            return $LayoutObject->FatalError(
                Message => Translatable('Chat is not active.'),
            );
        }

        # Check chat participant
        my %ChatParticipant = $Kernel::OM->Get('Kernel::System::Chat')->ChatParticipantCheck(
            ChatID      => $GetParam{FromChatID},
            ChatterType => 'Customer',
            ChatterID   => $Self->{UserID},
        );

        if ( !%ChatParticipant ) {
            return $LayoutObject->FatalError(
                Message => Translatable('No permission.'),
            );
        }
    }

    # get the dynamic fields for ticket object
    my $FollowUpDynamicField = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldListGet(
        Valid       => 1,
        ObjectType  => [ 'Ticket', 'Article' ],
        FieldFilter => $FollowUpDynamicFieldFilter || {},
    );

    my $BackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    # cycle trough the activated Dynamic Fields for this screen
    DYNAMICFIELD:
    for my $DynamicFieldConfig ( @{$FollowUpDynamicField} ) {
        next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

        # extract the dynamic field value from the web request
        $DynamicFieldValues{ $DynamicFieldConfig->{Name} } = $BackendObject->EditFieldValueGet(
            DynamicFieldConfig => $DynamicFieldConfig,
            ParamObject        => $ParamObject,
            LayoutObject       => $LayoutObject,
        );
    }

    # convert dynamic field values into a structure for ACLs
    my %DynamicFieldACLParameters;
    DYNAMICFIELD:
    for my $DynamicField ( sort keys %DynamicFieldValues ) {
        next DYNAMICFIELD if !$DynamicField;
        next DYNAMICFIELD if !$DynamicFieldValues{$DynamicField};

        $DynamicFieldACLParameters{ 'DynamicField_' . $DynamicField } = $DynamicFieldValues{$DynamicField};
    }
    $GetParam{DynamicField} = \%DynamicFieldACLParameters;

    if ( $Self->{Subaction} eq 'AJAXUpdate' ) {

        # get TicketID
        if ( !$GetParam{TicketID} ) {
            $GetParam{TicketID} =
                $Self->{TicketID} ||
                $ParamObject->GetParam( Param => 'TicketID' );
        }

        my $CustomerUser = $Self->{UserID};

        my $Priorities = $Self->_GetPriorities(
            %GetParam,
            CustomerUserID => $CustomerUser || '',
            TicketID       => $Self->{TicketID},
        );
        my $NextStates = $Self->_GetNextStates(
            %GetParam,
            CustomerUserID => $CustomerUser || '',
            TicketID       => $Self->{TicketID},
        );

        # update Dynamic Fields Possible Values via AJAX
        my @DynamicFieldAJAX;

        # cycle trough the activated Dynamic Fields for this screen
        DYNAMICFIELD:
        for my $DynamicFieldConfig ( @{$FollowUpDynamicField} ) {
            next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

            my $IsACLReducible = $BackendObject->HasBehavior(
                DynamicFieldConfig => $DynamicFieldConfig,
                Behavior           => 'IsACLReducible',
            );
            next DYNAMICFIELD if !$IsACLReducible;

            my $PossibleValues = $BackendObject->PossibleValuesGet(
                DynamicFieldConfig => $DynamicFieldConfig,
            );

            # convert possible values key => value to key => key for ACLs using a Hash slice
            my %AclData = %{$PossibleValues};
            @AclData{ keys %AclData } = keys %AclData;

            # set possible values filter from ACLs
            my $ACL = $TicketObject->TicketAcl(
                %GetParam,
                Action         => $Self->{Action},
                ReturnType     => 'Ticket',
                ReturnSubType  => 'DynamicField_' . $DynamicFieldConfig->{Name},
                Data           => \%AclData,
                CustomerUserID => $Self->{UserID},
            );
            if ($ACL) {
                my %Filter = $TicketObject->TicketAclData();

                # convert Filer key => key back to key => value using map
                %{$PossibleValues} = map { $_ => $PossibleValues->{$_} } keys %Filter;
            }

            my $DataValues = $BackendObject->BuildSelectionDataGet(
                DynamicFieldConfig => $DynamicFieldConfig,
                PossibleValues     => $PossibleValues,
                Value              => $DynamicFieldValues{ $DynamicFieldConfig->{Name} },
            ) || $PossibleValues;

            # add dynamic field to the list of fields to update
            push @DynamicFieldAJAX, {
                Name        => 'DynamicField_' . $DynamicFieldConfig->{Name},
                Data        => $DataValues,
                SelectedID  => $DynamicFieldValues{ $DynamicFieldConfig->{Name} },
                Translation => $DynamicFieldConfig->{Config}->{TranslatableValues} || 0,
                Max         => 100,
            };
        }

        my $JSON = $LayoutObject->BuildSelectionJSON(
            [
                {
                    Name        => 'PriorityID',
                    Data        => $Priorities,
                    SelectedID  => $GetParam{PriorityID},
                    Translation => 1,
                    Max         => 100,
                },
                {
                    Name        => 'StateID',
                    Data        => $NextStates,
                    SelectedID  => $GetParam{StateID},
                    Translation => 1,
                    Max         => 100,
                },
                @DynamicFieldAJAX,
            ],
        );
        return $LayoutObject->Attachment(
            ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
            Content     => $JSON,
            Type        => 'inline',
            NoCache     => 1,
        );
    }

    #   end AJAX Update

    # save, if browser link message was closed
    elsif ( $Self->{Subaction} eq 'BrowserLinkMessage' ) {

        $Kernel::OM->Get('Kernel::System::CustomerUser')->SetPreferences(
            UserID => $Self->{UserID},
            Key    => 'UserCustomerDoNotShowBrowserLinkMessage',
            Value  => 1,
        );

        return $LayoutObject->Attachment(
            ContentType => 'text/html',
            Content     => 1,
            Type        => 'inline',
            NoCache     => 1,
        );
    }

    # check follow up
    elsif ( $Self->{Subaction} eq 'Store' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck( Type => 'Customer' );

        my $NextScreen = $Self->{NextScreen} || $Config->{NextScreenAfterFollowUp};
        my %Error;

        # get follow up option (possible or not)
        my $QueueObject      = $Kernel::OM->Get('Kernel::System::Queue');
        my $FollowUpPossible = $QueueObject->GetFollowUpOption(
            QueueID => $Ticket{QueueID},
        );

        # get lock option (should be the ticket locked - if closed - after the follow up)
        my $Lock = $QueueObject->GetFollowUpLockOption(
            QueueID => $Ticket{QueueID},
        );

        my $StateObject = $Kernel::OM->Get('Kernel::System::State');

        # get ticket state details
        my %State = $StateObject->StateGet(
            ID => $Ticket{StateID},
        );
        if ( $FollowUpPossible =~ /(new ticket|reject)/i && $State{TypeName} =~ /^close/i ) {
            my $Output = $LayoutObject->CustomerHeader(
                Title => Translatable('Error'),
            );
            $Output .= $LayoutObject->CustomerWarning(
                Message => Translatable('Can\'t reopen ticket, not possible in this queue!'),
                Comment => Translatable('Create a new ticket!'),
            );
            $Output .= $LayoutObject->CustomerFooter();
            return $Output;
        }

        # rewrap body if no rich text is used
        if ( $GetParam{Body} && !$LayoutObject->{BrowserRichText} ) {
            $GetParam{Body} = $LayoutObject->WrapPlainText(
                MaxCharacters => $ConfigObject->Get('Ticket::Frontend::TextAreaNote'),
                PlainText     => $GetParam{Body},
            );
        }

        my $UploadCacheObject = $Kernel::OM->Get('Kernel::System::Web::UploadCache');

        if ( $GetParam{FromChat} ) {
            $Error{FromChat}           = 1;
            $GetParam{FollowUpVisible} = 'Visible';
            if ( $GetParam{FromChatID} ) {
                my @ChatMessages = $Kernel::OM->Get('Kernel::System::Chat')->ChatMessageList(
                    ChatID => $GetParam{FromChatID},
                );
                if (@ChatMessages) {
                    for my $Message (@ChatMessages) {
                        $Message->{MessageText} = $LayoutObject->Ascii2Html(
                            Text        => $Message->{MessageText},
                            LinkFeature => 1,
                        );
                    }
                    $GetParam{ChatMessages} = \@ChatMessages;
                }
            }
        }

        if ( !$GetParam{FromChat} ) {
            if ( !$GetParam{Body} || $GetParam{Body} eq '<br />' ) {
                $Error{RichTextInvalid}    = 'ServerError';
                $GetParam{FollowUpVisible} = 'Visible';
            }
        }

        # create html strings for all dynamic fields
        my %DynamicFieldHTML;

        # cycle trough the activated Dynamic Fields for this screen
        DYNAMICFIELD:
        for my $DynamicFieldConfig ( @{$FollowUpDynamicField} ) {
            next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

            my $PossibleValuesFilter;

            my $IsACLReducible = $BackendObject->HasBehavior(
                DynamicFieldConfig => $DynamicFieldConfig,
                Behavior           => 'IsACLReducible',
            );

            if ($IsACLReducible) {

                # get PossibleValues
                my $PossibleValues = $BackendObject->PossibleValuesGet(
                    DynamicFieldConfig => $DynamicFieldConfig,
                );

                # check if field has PossibleValues property in its configuration
                if ( IsHashRefWithData($PossibleValues) ) {

                    # convert possible values key => value to key => key for ACLs using a Hash slice
                    my %AclData = %{$PossibleValues};
                    @AclData{ keys %AclData } = keys %AclData;

                    # set possible values filter from ACLs
                    my $ACL = $TicketObject->TicketAcl(
                        %GetParam,
                        Action         => $Self->{Action},
                        TicketID       => $Self->{TicketID},
                        ReturnType     => 'Ticket',
                        ReturnSubType  => 'DynamicField_' . $DynamicFieldConfig->{Name},
                        Data           => \%AclData,
                        CustomerUserID => $Self->{UserID},
                    );
                    if ($ACL) {
                        my %Filter = $TicketObject->TicketAclData();

                        # convert Filer key => key back to key => value using map
                        %{$PossibleValuesFilter} = map { $_ => $PossibleValues->{$_} }
                            keys %Filter;
                    }
                }
            }

            my $ValidationResult = $BackendObject->EditFieldValueValidate(
                DynamicFieldConfig   => $DynamicFieldConfig,
                PossibleValuesFilter => $PossibleValuesFilter,
                ParamObject          => $ParamObject,
                Mandatory =>
                    $Config->{FollowUpDynamicField}->{ $DynamicFieldConfig->{Name} }
                    == 2,
            );

            if ( !IsHashRefWithData($ValidationResult) ) {
                my $Output = $LayoutObject->CustomerHeader(
                    Title => Translatable('Error'),
                );
                $Output .= $LayoutObject->CustomerError(
                    Message => $LayoutObject->{LanguageObject}
                        ->Translate( 'Could not perform validation on field %s!', $DynamicFieldConfig->{Label} ),
                    Comment => Translatable('Please contact the administrator.'),
                );
                $Output .= $LayoutObject->CustomerFooter();
                return $Output;
            }

            # propagate validation error to the Error variable to be detected by the frontend
            if ( $ValidationResult->{ServerError} ) {
                $Error{ $DynamicFieldConfig->{Name} } = ' ServerError';

                # make FollowUp visible to correctly show the error
                $GetParam{FollowUpVisible} = 'Visible';
            }

            # get field html
            $DynamicFieldHTML{ $DynamicFieldConfig->{Name} } = $BackendObject->EditFieldRender(
                DynamicFieldConfig   => $DynamicFieldConfig,
                PossibleValuesFilter => $PossibleValuesFilter,
                Mandatory =>
                    $Config->{FollowUpDynamicField}->{ $DynamicFieldConfig->{Name} } == 2,
                ServerError  => $ValidationResult->{ServerError}  || '',
                ErrorMessage => $ValidationResult->{ErrorMessage} || '',
                LayoutObject => $LayoutObject,
                ParamObject  => $ParamObject,
                AJAXUpdate   => 1,
                UpdatableFields => $Self->_GetFieldsToUpdate(),
            );
        }

        # show edit again
        if (%Error) {

            # generate output
            my $Output = $LayoutObject->CustomerHeader( Value => $Ticket{TicketNumber} );
            $Output .= $LayoutObject->CustomerNavigationBar();
            $Output .= $Self->_Mask(
                TicketID   => $Self->{TicketID},
                ArticleBox => \@ArticleBox,
                Errors     => \%Error,
                %Ticket,
                TicketState   => $Ticket{State},
                TicketStateID => $Ticket{StateID},
                %GetParam,
                DynamicFieldHTML => \%DynamicFieldHTML,
            );
            $Output .= $LayoutObject->CustomerFooter();
            return $Output;
        }

        # unlock ticket if agent is on vacation or invalid
        my $LockAction;
        if ( $Ticket{OwnerID} ) {
            my %User = $Kernel::OM->Get('Kernel::System::User')->GetUserData(
                UserID => $Ticket{OwnerID},
            );
            if ( %User && ( $User{OutOfOfficeMessage} || $User{ValidID} ne '1' ) ) {
                $LockAction = 'unlock';
            }
        }

        # set lock if ticket was closed
        if (
            !$LockAction
            && $Lock
            && $State{TypeName} =~ /^close/i && $Ticket{OwnerID} ne '1'
            )
        {

            $LockAction = 'lock';
        }

        if ($LockAction) {
            $TicketObject->TicketLockSet(
                TicketID => $Self->{TicketID},
                Lock     => $LockAction,
                UserID   => $ConfigObject->Get('CustomerPanelUserID'),
            );
        }

        my $From     = "\"$Self->{UserFullname}\" <$Self->{UserEmail}>";
        my $MimeType = 'text/plain';
        if ( $LayoutObject->{BrowserRichText} ) {
            $MimeType = 'text/html';

            # verify html document
            $GetParam{Body} = $LayoutObject->RichTextDocumentComplete(
                String => $GetParam{Body},
            );
        }

        # set state
        my $NextState = $Config->{StateDefault} || 'open';
        if ( $GetParam{StateID} && $Config->{State} ) {
            my %NextStateData = $StateObject->StateGet( ID => $GetParam{StateID} );
            $NextState = $NextStateData{Name};
        }

        # change state if
        # customer set another state
        # or the ticket is not new
        if ( $Ticket{StateType} !~ /^new/ || $GetParam{StateID} ) {
            $TicketObject->StateSet(
                TicketID => $Self->{TicketID},
                State    => $NextState,
                UserID   => $ConfigObject->Get('CustomerPanelUserID'),
            );

            # set unlock on close state
            if ( $NextState =~ /^close/i ) {
                $TicketObject->TicketLockSet(
                    TicketID => $Self->{TicketID},
                    Lock     => 'unlock',
                    UserID   => $ConfigObject->Get('CustomerPanelUserID'),
                );
            }
        }

        # set priority
        if ( $Config->{Priority} && $GetParam{PriorityID} ) {
            $TicketObject->TicketPrioritySet(
                TicketID   => $Self->{TicketID},
                PriorityID => $GetParam{PriorityID},
                UserID     => $ConfigObject->Get('CustomerPanelUserID'),
            );
        }

        my $ArticleID = $Kernel::OM->Get('Kernel::System::Ticket::Article::Backend::Internal')->ArticleCreate(
            TicketID             => $Self->{TicketID},
            IsVisibleForCustomer => 1,
            SenderType           => $Config->{SenderType},
            From                 => $From,
            Subject              => $GetParam{Subject},
            Body                 => $GetParam{Body},
            MimeType             => $MimeType,
            Charset              => $LayoutObject->{UserCharset},
            UserID               => $ConfigObject->Get('CustomerPanelUserID'),
            OrigHeader           => {
                From    => $From,
                To      => 'System',
                Subject => $GetParam{Subject},
                Body    => $LayoutObject->RichText2Ascii( String => $GetParam{Body} ),
            },
            HistoryType      => $Config->{HistoryType},
            HistoryComment   => $Config->{HistoryComment} || '%%',
            AutoResponseType => ( $ConfigObject->Get('AutoResponseForWebTickets') ) ? 'auto follow up' : '',
        );
        if ( !$ArticleID ) {
            my $Output = $LayoutObject->CustomerHeader(
                Title => Translatable('Error'),
            );
            $Output .= $LayoutObject->CustomerError();
            $Output .= $LayoutObject->CustomerFooter();
            return $Output;
        }

        # get pre loaded attachment
        my @AttachmentData = $UploadCacheObject->FormIDGetAllFilesData(
            FormID => $Self->{FormID}
        );

        # get submit attachment
        my %UploadStuff = $ParamObject->GetUploadAll(
            Param => 'file_upload',
        );
        if (%UploadStuff) {
            push @AttachmentData, \%UploadStuff;
        }

        # write attachments
        ATTACHMENT:
        for my $Attachment (@AttachmentData) {

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
                $GetParam{Body} =~ s/(ContentID=)$ContentIDLinkEncode/$1$ContentID/g;

                # ignore attachment if not linked in body
                if ( $GetParam{Body} !~ /(\Q$ContentIDHTMLQuote\E|\Q$ContentID\E)/i ) {
                    next ATTACHMENT;
                }
            }

            # write existing file to backend
            $ArticleBackendObject->ArticleWriteAttachment(
                %{$Attachment},
                ArticleID => $ArticleID,
                UserID    => $ConfigObject->Get('CustomerPanelUserID'),
            );
        }

        # set ticket dynamic fields
        # cycle trough the activated Dynamic Fields for this screen
        DYNAMICFIELD:
        for my $DynamicFieldConfig ( @{$FollowUpDynamicField} ) {
            next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);
            next DYNAMICFIELD if $DynamicFieldConfig->{ObjectType} ne 'Ticket';

            # set the value
            my $Success = $BackendObject->ValueSet(
                DynamicFieldConfig => $DynamicFieldConfig,
                ObjectID           => $Self->{TicketID},
                Value              => $DynamicFieldValues{ $DynamicFieldConfig->{Name} },
                UserID             => $ConfigObject->Get('CustomerPanelUserID'),
            );
        }

        # set article dynamic fields
        # cycle trough the activated Dynamic Fields for this screen
        DYNAMICFIELD:
        for my $DynamicFieldConfig ( @{$FollowUpDynamicField} ) {
            next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);
            next DYNAMICFIELD if $DynamicFieldConfig->{ObjectType} ne 'Article';

            # set the value
            my $Success = $BackendObject->ValueSet(
                DynamicFieldConfig => $DynamicFieldConfig,
                ObjectID           => $ArticleID,
                Value              => $DynamicFieldValues{ $DynamicFieldConfig->{Name} },
                UserID             => $ConfigObject->Get('CustomerPanelUserID'),
            );
        }

        # if user clicked submit on the main screen
        # store also chat protocol
        if ( !$GetParam{FromChat} && $GetParam{FromChatID} ) {
            my $ChatObject = $Kernel::OM->Get('Kernel::System::Chat');
            my %Chat       = $ChatObject->ChatGet(
                ChatID => $GetParam{FromChatID},
            );
            my @ChatMessageList = $ChatObject->ChatMessageList(
                ChatID => $GetParam{FromChatID},
            );
            my $ChatArticleID;

            if (@ChatMessageList) {
                for my $Message (@ChatMessageList) {
                    $Message->{MessageText} = $LayoutObject->Ascii2Html(
                        Text        => $Message->{MessageText},
                        LinkFeature => 1,
                    );
                }

                my $ArticleChatBackend = $ArticleObject->BackendForChannel( ChannelName => 'Chat' );

                $ChatArticleID = $ArticleChatBackend->ArticleCreate(
                    TicketID             => $Self->{TicketID},
                    SenderType           => $Config->{SenderType},
                    ChatMessageList      => \@ChatMessageList,
                    IsVisibleForCustomer => 1,
                    UserID               => $ConfigObject->Get('CustomerPanelUserID'),
                    HistoryType          => $Config->{HistoryType},
                    HistoryComment       => $Config->{HistoryComment} || '%%',
                );
            }
            if ($ChatArticleID) {
                $ChatObject->ChatDelete(
                    ChatID => $GetParam{FromChatID},
                );
            }
        }

        # remove pre submited attachments
        $UploadCacheObject->FormIDRemove( FormID => $Self->{FormID} );

        # redirect to zoom view
        return $LayoutObject->Redirect(
            OP => "Action=$NextScreen;TicketID=$Self->{TicketID}",
        );
    }

    $Ticket{TmpCounter}      = 0;
    $Ticket{TicketTimeUnits} = $TicketObject->TicketAccountedTimeGet(
        TicketID => $Ticket{TicketID},
    );

    # set priority from ticket as fallback
    $GetParam{PriorityID} ||= $Ticket{PriorityID};

    # create html strings for all dynamic fields
    my %DynamicFieldHTML;

    # cycle trough the activated Dynamic Fields for this screen
    DYNAMICFIELD:
    for my $DynamicFieldConfig ( @{$FollowUpDynamicField} ) {
        next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

        my $PossibleValuesFilter;

        my $IsACLReducible = $BackendObject->HasBehavior(
            DynamicFieldConfig => $DynamicFieldConfig,
            Behavior           => 'IsACLReducible',
        );

        if ($IsACLReducible) {

            # get PossibleValues
            my $PossibleValues = $BackendObject->PossibleValuesGet(
                DynamicFieldConfig => $DynamicFieldConfig,
            );

            # check if field has PossibleValues property in its configuration
            if ( IsHashRefWithData($PossibleValues) ) {

                # convert possible values key => value to key => key for ACLs using a Hash slice
                my %AclData = %{$PossibleValues};
                @AclData{ keys %AclData } = keys %AclData;

                # set possible values filter from ACLs
                my $ACL = $TicketObject->TicketAcl(
                    %GetParam,
                    Action         => $Self->{Action},
                    TicketID       => $Self->{TicketID},
                    ReturnType     => 'Ticket',
                    ReturnSubType  => 'DynamicField_' . $DynamicFieldConfig->{Name},
                    Data           => \%AclData,
                    CustomerUserID => $Self->{UserID},
                );
                if ($ACL) {
                    my %Filter = $TicketObject->TicketAclData();

                    # convert Filer key => key back to key => value using map
                    %{$PossibleValuesFilter} = map { $_ => $PossibleValues->{$_} }
                        keys %Filter;
                }
            }
        }

        # get field html
        $DynamicFieldHTML{ $DynamicFieldConfig->{Name} } = $BackendObject->EditFieldRender(
            DynamicFieldConfig   => $DynamicFieldConfig,
            PossibleValuesFilter => $PossibleValuesFilter,
            Mandatory =>
                $Config->{FollowUpDynamicField}->{ $DynamicFieldConfig->{Name} } == 2,
            LayoutObject    => $LayoutObject,
            ParamObject     => $ParamObject,
            AJAXUpdate      => 1,
            UpdatableFields => $Self->_GetFieldsToUpdate(),
            Value           => $Ticket{ 'DynamicField_' . $DynamicFieldConfig->{Name} },
        );
    }

    # generate output
    my $Output = $LayoutObject->CustomerHeader( Value => $Ticket{TicketNumber} );
    $Output .= $LayoutObject->CustomerNavigationBar();

    # show ticket
    if ( $Self->{Subaction} eq 'ShowHTMLeMail' ) {

        # if it is a html email, drop normal header
        $Ticket{ShowHTMLeMail} = 1;
        $Output = '';
    }
    $Output .= $Self->_Mask(
        TicketID   => $Self->{TicketID},
        ArticleBox => \@ArticleBox,
        %Ticket,
        TicketState   => $Ticket{State},
        TicketStateID => $Ticket{StateID},
        %GetParam,
        AclAction        => \%AclAction,
        DynamicFieldHTML => \%DynamicFieldHTML,
    );

    # return if HTML email
    if ( $Self->{Subaction} eq 'ShowHTMLeMail' ) {
        return $Output;
    }

    # add footer
    $Output .= $LayoutObject->CustomerFooter();

    # return output
    return $Output;
}

sub _GetNextStates {
    my ( $Self, %Param ) = @_;

    my %NextStates;
    if ( $Param{TicketID} ) {
        %NextStates = $Kernel::OM->Get('Kernel::System::Ticket')->TicketStateList(
            %Param,
            Action         => $Self->{Action},
            CustomerUserID => $Self->{UserID},

            # %Param could contain Ticket Type as only Type, it should not be sent
            Type => undef,
        );
    }
    return \%NextStates;
}

sub _GetPriorities {
    my ( $Self, %Param ) = @_;

    # get priority
    my %Priorities;
    if ( $Param{TicketID} ) {
        %Priorities = $Kernel::OM->Get('Kernel::System::Ticket')->TicketPriorityList(
            %Param,
            Action         => $Self->{Action},
            CustomerUserID => $Self->{UserID},
        );
    }
    return \%Priorities;
}

sub _Mask {
    my ( $Self, %Param ) = @_;

    my $ParamObject       = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $UploadCacheObject = $Kernel::OM->Get('Kernel::System::Web::UploadCache');

    my %AclActionLookup;
    if ( $Param{AclAction} ) {
        %AclActionLookup = reverse %{ $Param{AclAction} };
    }

    $Param{FormID} = $Self->{FormID};

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # show back link
    if ( $Self->{LastScreenOverview} ) {
        $LayoutObject->Block(
            Name => 'Back',
            Data => \%Param,
        );
    }

    # build article stuff
    my $SelectedArticleID = $ParamObject->GetParam( Param => 'ArticleID' ) || '';
    my $BaseLink          = $LayoutObject->{Baselink} . "TicketID=$Self->{TicketID}&";
    my @ArticleBox        = @{ $Param{ArticleBox} };

    # prepare errors!
    if ( $Param{Errors} ) {
        for my $KeyError ( sort keys %{ $Param{Errors} } ) {
            $Param{$KeyError} = $LayoutObject->Ascii2Html( Text => $Param{Errors}->{$KeyError} );
        }
    }

    my $ArticleID           = '';
    my $LastCustomerArticle = '';
    if (@ArticleBox) {

        # get last customer article
        my $CounterArray = 0;
        my $LastCustomerArticleID;
        $LastCustomerArticle = $#ArticleBox;

        for my $ArticleTmp (@ArticleBox) {
            my %Article = %{$ArticleTmp};

            # if it is a customer article
            if ( $Article{SenderType} eq 'customer' ) {
                $LastCustomerArticleID = $Article{ArticleID};
                $LastCustomerArticle   = $CounterArray;
            }
            $CounterArray++;
            if ( ($SelectedArticleID) && ( $SelectedArticleID eq $Article{ArticleID} ) ) {
                $ArticleID = $Article{ArticleID};
            }
        }

        # try to use the latest non internal agent article
        if ( !$ArticleID ) {
            $ArticleID         = $ArticleBox[-1]->{ArticleID};
            $SelectedArticleID = $ArticleID;
        }

        # try to use the latest customer article
        if ( !$ArticleID && $LastCustomerArticleID ) {
            $ArticleID         = $LastCustomerArticleID;
            $SelectedArticleID = $ArticleID;
        }
    }

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # set display options
    $Param{Hook} = $ConfigObject->Get('Ticket::Hook') || 'Ticket#';

    my $Config = $ConfigObject->Get("Ticket::Frontend::$Self->{Action}");

    # ticket accounted time
    if ( $Config->{ZoomTimeDisplay} ) {
        $LayoutObject->Block(
            Name => 'TicketTimeUnits',
            Data => \%Param,
        );
    }

    # ticket priority flag
    if ( $Config->{AttributesView}->{Priority} ) {
        $LayoutObject->Block(
            Name => 'PriorityFlag',
            Data => \%Param,
        );
    }

    # ticket type
    if ( $ConfigObject->Get('Ticket::Type') && $Config->{AttributesView}->{Type} ) {

        my %Type = $Kernel::OM->Get('Kernel::System::Type')->TypeGet(
            Name => $Param{Type},
        );

        $LayoutObject->Block(
            Name => 'Type',
            Data => {
                Valid => $Type{ValidID},
                %Param,
            }
        );
    }

    # ticket service
    if (
        $Param{Service}
        &&
        $ConfigObject->Get('Ticket::Service')
        && $Config->{AttributesView}->{Service}
        )
    {
        $LayoutObject->Block(
            Name => 'Service',
            Data => \%Param,
        );
        if (
            $Param{SLA}
            && $ConfigObject->Get('Ticket::Service')
            && $Config->{AttributesView}->{SLA}
            )
        {
            $LayoutObject->Block(
                Name => 'SLA',
                Data => \%Param,
            );
        }
    }

    # ticket state
    if ( $Config->{AttributesView}->{State} ) {
        $LayoutObject->Block(
            Name => 'State',
            Data => \%Param,
        );
    }

    # ticket priority
    if ( $Config->{AttributesView}->{Priority} ) {
        $LayoutObject->Block(
            Name => 'Priority',
            Data => \%Param,
        );
    }

    # ticket queue
    if ( $Config->{AttributesView}->{Queue} ) {
        $LayoutObject->Block(
            Name => 'Queue',
            Data => \%Param,
        );
    }

    my $AgentUserObject = $Kernel::OM->Get('Kernel::System::User');

    # ticket owner
    if ( $Config->{AttributesView}->{Owner} ) {
        my $OwnerName = $AgentUserObject->UserName(
            UserID => $Param{OwnerID},
        );
        $LayoutObject->Block(
            Name => 'Owner',
            Data => { OwnerName => $OwnerName },
        );
    }

    # ticket responsible
    if (
        $ConfigObject->Get('Ticket::Responsible')
        &&
        $Config->{AttributesView}->{Responsible}
        )
    {
        my $ResponsibleName = $AgentUserObject->UserName(
            UserID => $Param{ResponsibleID},
        );
        $LayoutObject->Block(
            Name => 'Responsible',
            Data => {
                ResponsibleName => $ResponsibleName,
            },
        );
    }

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    # check if ticket is normal or process ticket
    my $IsProcessTicket = $TicketObject->TicketCheckForProcessType(
        'TicketID' => $Self->{TicketID},
    );

    # show process widget  and activity dialogs on process tickets
    if ($IsProcessTicket) {

        # get the DF where the ProcessEntityID is stored
        my $ProcessEntityIDField = 'DynamicField_'
            . $ConfigObject->Get("Process::DynamicFieldProcessManagementProcessID");

        # get the DF where the AtivityEntityID is stored
        my $ActivityEntityIDField = 'DynamicField_'
            . $ConfigObject->Get("Process::DynamicFieldProcessManagementActivityID");

        # create additional objects for process management
        my $ActivityObject       = $Kernel::OM->Get('Kernel::System::ProcessManagement::Activity');
        my $ActivityDialogObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::ActivityDialog');
        my $ProcessObject        = $Kernel::OM->Get('Kernel::System::ProcessManagement::Process');
        my $ProcessData          = $ProcessObject->ProcessGet(
            ProcessEntityID => $Param{$ProcessEntityIDField},
        );

        my $ActivityData = $ActivityObject->ActivityGet(
            Interface        => 'CustomerInterface',
            ActivityEntityID => $Param{$ActivityEntityIDField},
        );

        # output process information in the sidebar
        $LayoutObject->Block(
            Name => 'ProcessData',
            Data => {
                Process  => $ProcessData->{Name}  || '',
                Activity => $ActivityData->{Name} || '',
            },
        );

        # output the process widget the the main screen
        $LayoutObject->Block(
            Name => 'ProcessWidget',
            Data => {
                WidgetTitle => $Param{WidgetTitle},
            },
        );

        # get next activity dialogs
        my $NextActivityDialogs;
        if ( $Param{$ActivityEntityIDField} ) {
            $NextActivityDialogs = $ActivityData;
        }

        if ( IsHashRefWithData($NextActivityDialogs) ) {

            # we don't need the whole Activity config,
            # just the Activity Dialogs of the current Activity
            if ( IsHashRefWithData( $NextActivityDialogs->{ActivityDialog} ) ) {
                %{$NextActivityDialogs} = %{ $NextActivityDialogs->{ActivityDialog} };
            }
            else {
                $NextActivityDialogs = {};
            }

            # we have to check if the current user has the needed permissions to view the
            # different activity dialogs, so we loop over every activity dialog and check if there
            # is a permission configured. If there is a permission configured we check this
            # and display/hide the activity dialog link
            my %PermissionRights;
            my %PermissionActivityDialogList;
            ACTIVITYDIALOGPERMISSION:
            for my $Index ( sort { $a <=> $b } keys %{$NextActivityDialogs} ) {
                my $CurrentActivityDialogEntityID = $NextActivityDialogs->{$Index};
                my $CurrentActivityDialog         = $ActivityDialogObject->ActivityDialogGet(
                    ActivityDialogEntityID => $CurrentActivityDialogEntityID,
                    Interface              => 'CustomerInterface',
                );

                # create an interface lookup-list
                my %InterfaceLookup = map { $_ => 1 } @{ $CurrentActivityDialog->{Interface} };

                next ACTIVITYDIALOGPERMISSION if !$InterfaceLookup{CustomerInterface};

                if ( $CurrentActivityDialog->{Permission} ) {

                    # performance-boost/cache
                    if ( !defined $PermissionRights{ $CurrentActivityDialog->{Permission} } ) {
                        $PermissionRights{ $CurrentActivityDialog->{Permission} }
                            = $TicketObject->TicketCustomerPermission(
                            Type     => $CurrentActivityDialog->{Permission},
                            TicketID => $Param{TicketID},
                            UserID   => $Self->{UserID},
                            );
                    }

                    if ( !$PermissionRights{ $CurrentActivityDialog->{Permission} } ) {
                        next ACTIVITYDIALOGPERMISSION;
                    }
                }

                $PermissionActivityDialogList{$Index} = $CurrentActivityDialogEntityID;
            }

            # reduce next activity dialogs to the ones that have permissions
            $NextActivityDialogs = \%PermissionActivityDialogList;

            # get ACL restrictions
            my $ACL = $TicketObject->TicketAcl(
                Data           => \%PermissionActivityDialogList,
                TicketID       => $Param{TicketID},
                Action         => $Self->{Action},
                ReturnType     => 'ActivityDialog',
                ReturnSubType  => '-',
                CustomerUserID => $Self->{UserID},
            );

            if ($ACL) {
                %{$NextActivityDialogs} = $TicketObject->TicketAclData();
            }

            $LayoutObject->Block(
                Name => 'NextActivities',
            );

            for my $NextActivityDialogKey ( sort { $a <=> $b } keys %{$NextActivityDialogs} ) {
                my $ActivityDialogData = $ActivityDialogObject->ActivityDialogGet(
                    ActivityDialogEntityID => $NextActivityDialogs->{$NextActivityDialogKey},
                    Interface              => 'CustomerInterface',
                );
                $LayoutObject->Block(
                    Name => 'ActivityDialog',
                    Data => {
                        ActivityDialogEntityID => $NextActivityDialogs->{$NextActivityDialogKey},
                        Name                   => $ActivityDialogData->{Name},
                        ProcessEntityID        => $Param{$ProcessEntityIDField},
                        TicketID               => $Param{TicketID},
                    },
                );
            }

            if ( !IsHashRefWithData($NextActivityDialogs) ) {
                $LayoutObject->Block(
                    Name => 'NoActivityDialog',
                    Data => {},
                );
            }
        }
    }

    # get dynamic field config for frontend module
    my $DynamicFieldFilter         = $Config->{DynamicField};
    my $FollowUpDynamicFieldFilter = $Config->{FollowUpDynamicField};

    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');

    # get the dynamic fields for ticket object
    my $FollowUpDynamicField = $DynamicFieldObject->DynamicFieldListGet(
        Valid       => 1,
        ObjectType  => [ 'Ticket', 'Article' ],
        FieldFilter => $FollowUpDynamicFieldFilter || {},
    );

    my $BackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    # reduce the dynamic fields to only the ones that are designed for customer interface
    my @CustomerDynamicFields;
    DYNAMICFIELD:
    for my $DynamicFieldConfig ( @{$FollowUpDynamicField} ) {
        next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

        my $IsCustomerInterfaceCapable = $BackendObject->HasBehavior(
            DynamicFieldConfig => $DynamicFieldConfig,
            Behavior           => 'IsCustomerInterfaceCapable',
        );
        next DYNAMICFIELD if !$IsCustomerInterfaceCapable;

        push @CustomerDynamicFields, $DynamicFieldConfig;
    }
    $FollowUpDynamicField = \@CustomerDynamicFields;

    # get the dynamic fields for ticket object
    my $DynamicField = $DynamicFieldObject->DynamicFieldListGet(
        Valid       => 1,
        ObjectType  => ['Ticket'],
        FieldFilter => $DynamicFieldFilter || {},
    );

    # cycle trough the activated Dynamic Fields for ticket object
    DYNAMICFIELD:
    for my $DynamicFieldConfig ( @{$DynamicField} ) {
        next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

        # skip the dynamic field if is not designed for customer interface
        my $IsCustomerInterfaceCapable = $BackendObject->HasBehavior(
            DynamicFieldConfig => $DynamicFieldConfig,
            Behavior           => 'IsCustomerInterfaceCapable',
        );
        next DYNAMICFIELD if !$IsCustomerInterfaceCapable;

        my $Value = $BackendObject->ValueGet(
            DynamicFieldConfig => $DynamicFieldConfig,
            ObjectID           => $Param{TicketID},
        );

        next DYNAMICFIELD if !defined $Value;
        next DYNAMICFIELD if $Value eq "";

        # get print string for this dynamic field
        my $ValueStrg = $BackendObject->DisplayValueRender(
            DynamicFieldConfig => $DynamicFieldConfig,
            Value              => $Value,
            ValueMaxChars      => 25,
            LayoutObject       => $LayoutObject,
        );

        my $Label = $DynamicFieldConfig->{Label};

        $LayoutObject->Block(
            Name => 'TicketDynamicField',
            Data => {
                Label => $Label,
            },
        );

        if ( $DynamicFieldConfig->{Config}->{Link} ) {
            $LayoutObject->Block(
                Name => 'TicketDynamicFieldLink',
                Data => {
                    Value                       => $ValueStrg->{Value},
                    Title                       => $ValueStrg->{Title},
                    Link                        => $DynamicFieldConfig->{Config}->{Link},
                    LinkPreview                 => $DynamicFieldConfig->{Config}->{LinkPreview},
                    $DynamicFieldConfig->{Name} => $ValueStrg->{Title},
                },
            );
        }
        else {
            $LayoutObject->Block(
                Name => 'TicketDynamicFieldPlain',
                Data => {
                    Value => $ValueStrg->{Value},
                    Title => $ValueStrg->{Title},
                },
            );
        }

        # example of dynamic fields order customization
        $LayoutObject->Block(
            Name => 'TicketDynamicField_' . $DynamicFieldConfig->{Name},
            Data => {
                Label => $Label,
                Value => $ValueStrg->{Value},
                Title => $ValueStrg->{Title},
            },
        );
    }

    # check is chat available and is starting a chat from ticket zoom available
    my $ChatConfig = $ConfigObject->Get('Ticket::Customer::StartChatFromTicket');
    if (
        $ChatConfig->{Allowed}
        && $ConfigObject->Get('ChatEngine::Active')
        )
    {
        # get all queues to tickets relations
        my %QueueChatChannelRelations = $Kernel::OM->Get('Kernel::System::ChatChannel')->ChatChannelQueuesGet(
            CustomerInterface => 1,
        );

        # if a support chat channel is set for this queue
        if ( $QueueChatChannelRelations{ $Param{QueueID} } ) {

            # check is starting a chat from ticket zoom allowed to all user or only to ticket customer user_agent
            if (
                !$ChatConfig->{Permissions}
                || ( $Param{CustomerUserID} eq $Self->{UserID} )
                )
            {
                # add chat channelID to Param
                $Param{ChatChannelID} = $QueueChatChannelRelations{ $Param{QueueID} };

                if ( $Param{ChatChannelID} ) {

                    # check should chat be available only if there are available agents in this chat channelID
                    if ( !$ChatConfig->{AllowChatOnlyIfAgentsAvailable} ) {

                        # show start a chat icon
                        $LayoutObject->Block(
                            Name => 'Chat',
                            Data => {
                                %Param,
                            },
                        );
                    }
                    else {
                        # Get channels data
                        my %ChatChannelData = $Kernel::OM->Get('Kernel::System::ChatChannel')->ChatChannelGet(
                            ChatChannelID => $Param{ChatChannelID},
                        );

                        # Get all online users
                        my @OnlineUsers = $Kernel::OM->Get('Kernel::System::Chat')->OnlineUserList(
                            UserType => 'User',
                        );
                        my $AvailabilityCheck
                            = $Kernel::OM->Get('Kernel::Config')->Get("ChatEngine::CustomerFrontend::AvailabilityCheck")
                            || 0;
                        my %AvailableUsers;
                        if ($AvailabilityCheck) {
                            %AvailableUsers = $Kernel::OM->Get('Kernel::System::Chat')->AvailableUsersGet(
                                Key => 'ExternalChannels',
                            );
                        }

                        # Rename hash key: ChatChannelID => Key
                        $ChatChannelData{Key} = delete $ChatChannelData{ChatChannelID};

                        if ($AvailabilityCheck) {
                            my $UserAvailable = 0;

                            AVAILABLE_USER:
                            for my $AvailableUser ( sort keys %AvailableUsers ) {
                                if ( grep {/^$ChatChannelData{Key}$/} @{ $AvailableUsers{$AvailableUser} } ) {
                                    $UserAvailable = 1;
                                    last AVAILABLE_USER;
                                }
                            }

                            if ($UserAvailable) {
                                $LayoutObject->Block(
                                    Name => 'Chat',
                                    Data => {
                                        %Param,
                                    },
                                );
                            }
                        }
                    }
                }
            }
        }
    }

    # print option
    if (
        $ConfigObject->Get('CustomerFrontend::Module')->{CustomerTicketPrint}
        && $AclActionLookup{CustomerTicketPrint}
        )
    {
        $LayoutObject->Block(
            Name => 'Print',
            Data => \%Param,
        );
    }

    # get params
    my $ZoomExpand = $ParamObject->GetParam( Param => 'ZoomExpand' );
    if ( !defined $ZoomExpand ) {
        $ZoomExpand = $ConfigObject->Get('Ticket::Frontend::CustomerTicketZoom')->{CustomerZoomExpand} || '';
    }

    # Expand option
    my $ExpandOption = ( $ZoomExpand ? 'One'              : 'All' );
    my $ExpandText   = ( $ZoomExpand ? 'Show one article' : 'Show all articles' );
    $LayoutObject->Block(
        Name => 'Expand',
        Data => {
            ZoomExpand   => !$ZoomExpand,
            ExpandOption => $ExpandOption,
            ExpandText   => $ExpandText,
            %Param,
        },
    );

    my %Ticket = $TicketObject->TicketGet(
        TicketID => $Self->{TicketID},
        UserID   => $Self->{UserID},
    );

    my $CommunicationChannelObject = $Kernel::OM->Get('Kernel::System::CommunicationChannel');

    my $ShownArticles;
    my $LastSenderType = '';
    my $ArticleHTML    = '';

    for my $ArticleTmp (@ArticleBox) {
        my %Article = %$ArticleTmp;

        # check if article should be expanded (visible)
        if ( $SelectedArticleID eq $Article{ArticleID} || $ZoomExpand ) {
            $Article{Class} = 'Visible';
            $ShownArticles++;
        }

        # Calculate difference between article create time and now in seconds.
        my $ArticleCreateTimeObject = $Kernel::OM->Create(
            'Kernel::System::DateTime',
            ObjectParams => {
                String => $Article{CreateTime},
            },
        );
        my $Delta = $ArticleCreateTimeObject->Delta(
            DateTimeObject => $Kernel::OM->Create('Kernel::System::DateTime'),
        );

        # do some html quoting
        $Article{Age} = $LayoutObject->CustomerAge(
            Age   => $Delta->{AbsoluteSeconds},
            Space => ' ',
        );

        $Article{Subject} = $TicketObject->TicketSubjectClean(
            TicketNumber => $Ticket{TicketNumber},
            Subject      => $Article{Subject} || '',
            Size         => 150,
        );

        $LastSenderType = $Article{SenderType};

        if ( !defined $Self->{ShowBrowserLinkMessage} ) {
            my %UserPreferences = $Kernel::OM->Get('Kernel::System::CustomerUser')->GetPreferences(
                UserID => $Self->{UserID},
            );

            if ( $UserPreferences{UserCustomerDoNotShowBrowserLinkMessage} ) {
                $Self->{ShowBrowserLinkMessage} = 0;
            }
            else {
                $Self->{ShowBrowserLinkMessage} = 1;
            }
        }

        my $ArticleBackendObject = $Kernel::OM->Get('Kernel::System::Ticket::Article')->BackendForArticle(
            TicketID  => $Param{TicketID},
            ArticleID => $Article{ArticleID},
        );

        my $ChannelName = $ArticleBackendObject->ChannelNameGet();

        $ArticleHTML .= $Kernel::OM->Get("Kernel::Output::HTML::TicketZoom::Customer::$ChannelName")->ArticleRender(
            TicketID               => $Param{TicketID},
            ArticleID              => $Article{ArticleID},
            Class                  => $Article{Class},
            UserID                 => $Self->{UserID},
            ShowBrowserLinkMessage => $Self->{ShowBrowserLinkMessage},
            ArticleExpanded        => $SelectedArticleID eq $Article{ArticleID} || $ZoomExpand,
            ArticleAge             => $Article{Age},
        );
    }

    # TODO: Refactor
    # if there are no viewable articles show NoArticles message
    if ( !@ArticleBox ) {
        $Param{NoArticles} = 1;
    }

    my %Article;
    if (@ArticleBox) {

        my $ArticleOB = {};
        if ($LastCustomerArticle) {
            $ArticleOB = $ArticleBox[$LastCustomerArticle];
        }

        %Article = %$ArticleOB;

        # if no customer articles found use ticket values
        if ( !IsHashRefWithData( \%Article ) ) {
            %Article = %Param;
            if ( !$Article{StateID} ) {
                $Article{StateID} = $Param{TicketStateID};
            }
        }

        my $ArticleArray = 0;
        for my $ArticleTmp (@ArticleBox) {
            my %ArticleTmp1 = %$ArticleTmp;
            if ( $ArticleID eq $ArticleTmp1{ArticleID} ) {
                %Article = %ArticleTmp1;
            }
        }

        # just body if html email
        if ( $Param{ShowHTMLeMail} ) {

            # generate output
            return $LayoutObject->Attachment(
                Filename => $ConfigObject->Get('Ticket::Hook')
                    . "-$Ticket{TicketNumber}-$Self->{TicketID}-$Article{ArticleID}",
                Type        => 'inline',
                ContentType => "$Article{MimeType}; charset=$Article{Charset}",
                Content     => $Article{Body},
            );
        }
    }

    # fallback to ticket info if there is no article
    if ( !IsHashRefWithData( \%Article ) ) {
        %Article = %Param;
        if ( !$Article{StateID} ) {
            $Article{StateID} = $Param{TicketStateID};
        }
    }

    # check follow up permissions
    my $FollowUpPossible = $Kernel::OM->Get('Kernel::System::Queue')->GetFollowUpOption(
        QueueID => $Ticket{QueueID},
    );
    my %State = $Kernel::OM->Get('Kernel::System::State')->StateGet(
        ID => $Ticket{StateID},
    );
    if (
        $TicketObject->TicketCustomerPermission(
            Type     => 'update',
            TicketID => $Self->{TicketID},
            UserID   => $Self->{UserID},
        )
        && (
            ( $FollowUpPossible !~ /(new ticket|reject)/i && $State{TypeName} =~ /^close/i )
            || $State{TypeName} !~ /^close|merged/i
        )
        )
    {

        my $DynamicFieldNames = $Self->_GetFieldsToUpdate(
            OnlyDynamicFields => 1,
        );

        # send data to JS
        $LayoutObject->AddJSData(
            Key   => 'DynamicFieldNames',
            Value => $DynamicFieldNames,
        );

        # check subject
        if ( !$Param{Subject} ) {
            $Param{Subject} = "Re: " . ( $Param{Title} // '' );
        }
        $LayoutObject->Block(
            Name => 'FollowUp',
            Data => \%Param,
        );

        # add rich text editor
        if ( $LayoutObject->{BrowserRichText} ) {

            # use height/width defined for this screen
            $Param{RichTextHeight} = $Config->{RichTextHeight} || 0;
            $Param{RichTextWidth}  = $Config->{RichTextWidth}  || 0;

            # set up customer rich text editor
            $LayoutObject->CustomerSetRichTextParameters(
                Data => \%Param,
            );
        }

        # build next states string
        if ( $Config->{State} ) {
            my $NextStates = $Self->_GetNextStates(
                %Param,
                TicketID => $Self->{TicketID},
            );
            my %StateSelected;
            if ( $Param{StateID} ) {
                $StateSelected{SelectedID} = $Param{StateID};
            }
            else {
                $StateSelected{SelectedValue} = $Config->{StateDefault};
            }
            $Param{NextStatesStrg} = $LayoutObject->BuildSelection(
                Data => $NextStates,
                Name => 'StateID',
                %StateSelected,
                Class => 'Modernize',
            );
            $LayoutObject->Block(
                Name => 'FollowUpState',
                Data => \%Param,
            );
        }

        # get priority
        if ( $Config->{Priority} ) {
            my $Priorities = $Self->_GetPriorities(
                %Param,
                TicketID => $Self->{TicketID},
            );
            my %PrioritySelected;
            if ( $Param{PriorityID} ) {
                $PrioritySelected{SelectedID} = $Param{PriorityID};
            }
            else {
                $PrioritySelected{SelectedValue} = $Config->{PriorityDefault}
                    || '3 normal';
            }
            $Param{PriorityStrg} = $LayoutObject->BuildSelection(
                Data => $Priorities,
                Name => 'PriorityID',
                %PrioritySelected,
                Class => 'Modernize',
            );
            $LayoutObject->Block(
                Name => 'FollowUpPriority',
                Data => \%Param,
            );
        }

        # Dynamic fields
        # cycle trough the activated Dynamic Fields for this screen
        DYNAMICFIELD:
        for my $DynamicFieldConfig ( @{$FollowUpDynamicField} ) {
            next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

            # skip fields that HTML could not be retrieved
            next DYNAMICFIELD if !IsHashRefWithData(
                $Param{DynamicFieldHTML}->{ $DynamicFieldConfig->{Name} }
            );

            # get the html strings form $Param
            my $DynamicFieldHTML = $Param{DynamicFieldHTML}->{ $DynamicFieldConfig->{Name} };

            $LayoutObject->Block(
                Name => 'FollowUpDynamicField',
                Data => {
                    Name  => $DynamicFieldConfig->{Name},
                    Label => $DynamicFieldHTML->{Label},
                    Field => $DynamicFieldHTML->{Field},
                },
            );

            # example of dynamic fields order customization
            $LayoutObject->Block(
                Name => 'FollowUpDynamicField_' . $DynamicFieldConfig->{Name},
                Data => {
                    Name  => $DynamicFieldConfig->{Name},
                    Label => $DynamicFieldHTML->{Label},
                    Field => $DynamicFieldHTML->{Field},
                },
            );
        }

        # show attachments
        # get all attachments meta data
        my @Attachments = $UploadCacheObject->FormIDGetAllFilesMeta(
            FormID => $Self->{FormID},
        );

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
    }

    # select the output template
    return $LayoutObject->Output(
        TemplateFile => 'CustomerTicketZoom',
        Data         => {
            %Article,
            %Param,
            Articles => $ArticleHTML,
        },
    );
}

sub _GetFieldsToUpdate {
    my ( $Self, %Param ) = @_;

    my @UpdatableFields;

    # set the fields that can be updatable via AJAXUpdate
    if ( !$Param{OnlyDynamicFields} ) {
        @UpdatableFields = qw( ServiceID SLAID PriorityID StateID );
    }

    my $Config                     = $Kernel::OM->Get('Kernel::Config')->Get("Ticket::Frontend::$Self->{Action}");
    my $FollowUpDynamicFieldFilter = $Config->{FollowUpDynamicField};

    # get the dynamic fields for ticket object
    my $FollowUpDynamicField = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldListGet(
        Valid       => 1,
        ObjectType  => [ 'Ticket', 'Article' ],
        FieldFilter => $FollowUpDynamicFieldFilter || {},
    );

    # cycle trough the activated Dynamic Fields for this screen
    DYNAMICFIELD:
    for my $DynamicFieldConfig ( @{$FollowUpDynamicField} ) {
        next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

        my $IsACLReducible = $Kernel::OM->Get('Kernel::System::DynamicField::Backend')->HasBehavior(
            DynamicFieldConfig => $DynamicFieldConfig,
            Behavior           => 'IsACLReducible',
        );
        next DYNAMICFIELD if !$IsACLReducible;

        push @UpdatableFields, 'DynamicField_' . $DynamicFieldConfig->{Name};
    }

    return \@UpdatableFields;
}

1;
