# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Modules::AgentTicketEmailOutbound;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);
use Kernel::Language qw(Translatable);
use Mail::Address;

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    # Try to load draft if requested.
    if (
        $Kernel::OM->Get('Kernel::Config')->Get("Ticket::Frontend::$Self->{Action}")->{FormDraft}
        && $Kernel::OM->Get('Kernel::System::Web::Request')->GetParam( Param => 'LoadFormDraft' )
        && $Kernel::OM->Get('Kernel::System::Web::Request')->GetParam( Param => 'FormDraftID' )
        )
    {
        $Self->{LoadedFormDraftID} = $Kernel::OM->Get('Kernel::System::Web::Request')->LoadFormDraft(
            FormDraftID => $Kernel::OM->Get('Kernel::System::Web::Request')->GetParam( Param => 'FormDraftID' ),
            UserID      => $Self->{UserID},
        );
    }

    $Self->{Debug} = $Param{Debug} || 0;

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $Output;

    # get ticket object
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    # get ACL restrictions
    $TicketObject->TicketAcl(
        Data          => '-',
        TicketID      => $Self->{TicketID},
        ReturnType    => 'Action',
        ReturnSubType => '-',
        UserID        => $Self->{UserID},
    );
    my %AclAction = $TicketObject->TicketAclActionData();

    # get layout object
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # check if ACL restrictions exist
    if ( IsHashRefWithData( \%AclAction ) ) {

        # show error screen if ACL prohibits this action
        if ( defined $AclAction{ $Self->{Action} } && $AclAction{ $Self->{Action} } eq '0' ) {

            return $LayoutObject->NoPermission( WithHeader => 'yes' );
        }
    }

    # Check for failed draft loading request.
    if (
        $Kernel::OM->Get('Kernel::System::Web::Request')->GetParam( Param => 'LoadFormDraft' )
        && !$Self->{LoadedFormDraftID}
        )
    {
        return $LayoutObject->ErrorScreen(
            Message => Translatable('Loading draft failed!'),
            Comment => Translatable('Please contact the administrator.'),
        );
    }

    if ( $Self->{Subaction} eq 'SendEmail' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        $Output = $Self->SendEmail();
    }
    elsif ( $Self->{Subaction} eq 'AJAXUpdateTemplate' ) {

        my %GetParam;
        for my $Key (
            qw(
            NewStateID NewPriorityID TimeUnits IsVisibleForCustomer Title Body Subject NewQueueID
            Year Month Day Hour Minute NewOwnerID NewOwnerType OldOwnerID NewResponsibleID
            TypeID ServiceID SLAID Expand ReplyToArticle StandardTemplateID CreateArticle
            FormID ElementChanged
            )
            )
        {
            $GetParam{$Key} = $Kernel::OM->Get('Kernel::System::Web::Request')->GetParam( Param => $Key );
        }

        my %Ticket       = $TicketObject->TicketGet( TicketID => $Self->{TicketID} );
        my $CustomerUser = $Ticket{CustomerUserID};
        my $QueueID      = $Ticket{QueueID};

        # get dynamic field values form http request
        my %DynamicFieldValues;

        # convert dynamic field values into a structure for ACLs
        my %DynamicFieldACLParameters;
        DYNAMICFIELD:
        for my $DynamicFieldItem ( sort keys %DynamicFieldValues ) {
            next DYNAMICFIELD if !$DynamicFieldItem;
            next DYNAMICFIELD if !defined $DynamicFieldValues{$DynamicFieldItem};

            $DynamicFieldACLParameters{ 'DynamicField_' . $DynamicFieldItem } = $DynamicFieldValues{$DynamicFieldItem};
        }

        # get config object
        my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

        # get list type
        my $TreeView = 0;
        if ( $ConfigObject->Get('Ticket::Frontend::ListType') eq 'tree' ) {
            $TreeView = 1;
        }

        my $NextStates = $Self->_GetNextStates(
            %GetParam,
            CustomerUserID => $CustomerUser || '',
            QueueID        => $QueueID,
        );

        # update Dynamic Fields Possible Values via AJAX
        my @DynamicFieldAJAX;

        # get config for frontend module
        my $Config = $ConfigObject->Get("Ticket::Frontend::$Self->{Action}");

        # get the dynamic fields for this screen
        my $DynamicField = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldListGet(
            Valid       => 1,
            ObjectType  => [ 'Ticket', 'Article' ],
            FieldFilter => $Config->{DynamicField} || {},
        );

        # get dynamic field backend object
        my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

        # cycle trough the activated Dynamic Fields for this screen
        DYNAMICFIELD:
        for my $DynamicFieldConfig ( @{$DynamicField} ) {
            next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

            my $IsACLReducible = $DynamicFieldBackendObject->HasBehavior(
                DynamicFieldConfig => $DynamicFieldConfig,
                Behavior           => 'IsACLReducible',
            );
            next DYNAMICFIELD if !$IsACLReducible;

            my $PossibleValues = $DynamicFieldBackendObject->PossibleValuesGet(
                DynamicFieldConfig => $DynamicFieldConfig,
            );

            # convert possible values key => value to key => key for ACLs using a Hash slice
            my %AclData = %{$PossibleValues};
            @AclData{ keys %AclData } = keys %AclData;

            # set possible values filter from ACLs
            my $ACL = $TicketObject->TicketAcl(
                %GetParam,
                Action        => $Self->{Action},
                TicketID      => $Self->{TicketID},
                QueueID       => $QueueID,
                ReturnType    => 'Ticket',
                ReturnSubType => 'DynamicField_' . $DynamicFieldConfig->{Name},
                Data          => \%AclData,
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

            # add dynamic field to the list of fields to update
            push(
                @DynamicFieldAJAX,
                {
                    Name        => 'DynamicField_' . $DynamicFieldConfig->{Name},
                    Data        => $DataValues,
                    SelectedID  => $DynamicFieldValues{ $DynamicFieldConfig->{Name} },
                    Translation => $DynamicFieldConfig->{Config}->{TranslatableValues} || 0,
                    Max         => 100,
                }
            );
        }

        my $StandardTemplates = $Self->_GetStandardTemplates(
            TicketID => $Self->{TicketID},
            %GetParam,
            QueueID => $QueueID || '',
        );

        my @TemplateAJAX;

        # get upload cache object
        my $UploadCacheObject = $Kernel::OM->Get('Kernel::System::Web::UploadCache');

        # update ticket body and attachments if needed.
        if ( $GetParam{ElementChanged} eq 'StandardTemplateID' ) {
            my @TicketAttachments;
            my $TemplateText;

            # remove all attachments from the Upload cache
            my $RemoveSuccess = $UploadCacheObject->FormIDRemove(
                FormID => $GetParam{FormID},
            );
            if ( !$RemoveSuccess ) {
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'error',
                    Message  => "Form attachments could not be deleted!",
                );
            }

            # get the template text and set new attachments if a template is selected
            my $TemplateGenerator = $Kernel::OM->Get('Kernel::System::TemplateGenerator');

            if ( IsPositiveInteger( $GetParam{StandardTemplateID} ) ) {

                # set template text, replace smart tags (limited as ticket is not created)
                $TemplateText = $TemplateGenerator->Template(
                    TemplateID => $GetParam{StandardTemplateID},
                    TicketID   => $Self->{TicketID},
                    UserID     => $Self->{UserID},
                );

                # create StdAttachmentObject
                my $StdAttachmentObject = $Kernel::OM->Get('Kernel::System::StdAttachment');

                # add std. attachments to ticket
                my %AllStdAttachments = $StdAttachmentObject->StdAttachmentStandardTemplateMemberList(
                    StandardTemplateID => $GetParam{StandardTemplateID},
                );
                for my $ID ( sort keys %AllStdAttachments ) {
                    my %AttachmentsData = $StdAttachmentObject->StdAttachmentGet( ID => $ID );
                    $UploadCacheObject->FormIDAddFile(
                        FormID      => $GetParam{FormID},
                        Disposition => 'attachment',
                        %AttachmentsData,
                    );
                }

                # send a list of attachments in the upload cache back to the client side JavaScript
                # which renders then the list of currently uploaded attachments
                @TicketAttachments = $UploadCacheObject->FormIDGetAllFilesMeta(
                    FormID => $GetParam{FormID},
                );

                for my $Attachment (@TicketAttachments) {
                    $Attachment->{Filesize} = $LayoutObject->HumanReadableDataSize(
                        Size => $Attachment->{Filesize},
                    );
                }
            }

            # Get the first article of the ticket.
            my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');
            my @ArticleIDs    = $ArticleObject->ArticleIndex(
                TicketID => $Self->{TicketID},
            );

            my %Article;
            if (@ArticleIDs) {
                %Article = $ArticleObject->ArticleGet(
                    TicketID  => $Self->{TicketID},
                    ArticleID => $ArticleIDs[0],
                );
            }

            # get the matching signature for the current user
            my $Signature = $TemplateGenerator->Signature(
                TicketID  => $Self->{TicketID},
                ArticleID => $Article{ArticleID},
                Data      => \%Article,
                UserID    => $Self->{UserID},
            );

            # append the signature to the body text
            if ( $LayoutObject->{BrowserRichText} ) {
                $TemplateText = $TemplateText . '<br><br>' . $Signature;
            }
            else {
                $TemplateText = $TemplateText . "\n\n" . $Signature;
            }

            @TemplateAJAX = (
                {
                    Name => 'UseTemplateNote',
                    Data => '0',
                },
                {
                    Name => 'RichText',
                    Data => $TemplateText || '',
                },
                {
                    Name     => 'TicketAttachments',
                    Data     => \@TicketAttachments,
                    KeepData => 1,
                },
            );
        }

        my $JSON = $LayoutObject->BuildSelectionJSON(
            [
                {
                    Name         => 'NewStateID',
                    Data         => $NextStates,
                    SelectedID   => $GetParam{NewStateID},
                    Translation  => 1,
                    PossibleNone => $Config->{StateDefault} ? 0 : 1,
                    Max          => 100,
                },
                {
                    Name         => 'StandardTemplateID',
                    Data         => $StandardTemplates,
                    SelectedID   => $GetParam{StandardTemplateID},
                    PossibleNone => 1,
                    Translation  => 1,
                    Max          => 100,
                },
                @DynamicFieldAJAX,
                @TemplateAJAX,
            ],
        );

        return $LayoutObject->Attachment(
            ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
            Content     => $JSON,
            Type        => 'inline',
            NoCache     => 1,
        );
    }
    elsif ( $Self->{Subaction} eq 'AJAXUpdate' ) {
        $Output = $Self->AjaxUpdate();
    }
    elsif ( $Self->{LoadedFormDraftID} ) {
        $Output = $Self->SendEmail();
    }
    else {
        $Output = $Self->Form();
    }

    return $Output;
}

sub Form {
    my ( $Self, %Param ) = @_;

    my %Error;
    my %ACLCompatGetParam;

    # get param object
    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');

    # ACL compatibility translation
    $ACLCompatGetParam{NextStateID} = $ParamObject->GetParam( Param => 'NextStateID' );

    # get layout object
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # check needed stuff
    if ( !$Self->{TicketID} ) {

        return $LayoutObject->ErrorScreen(
            Message => Translatable('Got no TicketID!'),
            Comment => Translatable('System Error!'),
        );
    }

    # get needed objects
    my $TicketObject  = $Kernel::OM->Get('Kernel::System::Ticket');
    my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');

    # get ticket data
    my %Ticket = $TicketObject->TicketGet(
        TicketID      => $Self->{TicketID},
        DynamicFields => 1,
    );

    # get config object
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # get config for frontend module
    my $Config = $ConfigObject->Get("Ticket::Frontend::$Self->{Action}");

    # check permissions
    my $Access = $TicketObject->TicketPermission(
        Type     => $Config->{Permission},
        TicketID => $Self->{TicketID},
        UserID   => $Self->{UserID}
    );

    # error screen, don't show ticket
    if ( !$Access ) {

        return $LayoutObject->NoPermission( WithHeader => 'yes' );
    }

    my %GetParamExtended = $Self->_GetExtendedParams();

    my %GetParam            = %{ $GetParamExtended{GetParam} };
    my @MultipleCustomer    = @{ $GetParamExtended{MultipleCustomer} };
    my @MultipleCustomerCc  = @{ $GetParamExtended{MultipleCustomerCc} };
    my @MultipleCustomerBcc = @{ $GetParamExtended{MultipleCustomerBcc} };

    # get lock state
    my $Output = '';
    if ( $Config->{RequiredLock} ) {
        if ( !$TicketObject->TicketLockGet( TicketID => $Self->{TicketID} ) ) {

            my $Lock = $TicketObject->TicketLockSet(
                TicketID => $Self->{TicketID},
                Lock     => 'lock',
                UserID   => $Self->{UserID}
            );

            if ($Lock) {

                # Set new owner if ticket owner is different then logged user.
                if ( $Ticket{OwnerID} != $Self->{UserID} ) {

                    # Remember previous owner, which will be used to restore ticket owner on undo action.
                    $Param{PreviousOwner} = $Ticket{OwnerID};

                    $TicketObject->TicketOwnerSet(
                        TicketID  => $Self->{TicketID},
                        UserID    => $Self->{UserID},
                        NewUserID => $Self->{UserID},
                    );
                }

                # Show lock state.
                $LayoutObject->Block(
                    Name => 'PropertiesLock',
                    Data => {
                        %Param,
                        TicketID => $Self->{TicketID},
                    },
                );
            }
        }
        else {
            my $AccessOk = $TicketObject->OwnerCheck(
                TicketID => $Self->{TicketID},
                OwnerID  => $Self->{UserID},
            );
            if ( !$AccessOk ) {
                my $Output = $LayoutObject->Header(
                    Type      => 'Small',
                    BodyClass => 'Popup',
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
            else {
                $LayoutObject->Block(
                    Name => 'TicketBack',
                    Data => {
                        %Param,
                        TicketID => $Self->{TicketID},
                    },
                );
            }
        }
    }
    else {
        $LayoutObject->Block(
            Name => 'TicketBack',
            Data => {
                %Param,
                TicketID => $Self->{TicketID},
            },
        );
    }

    my %Data;

    # Get selected article.
    if ( $GetParam{ArticleID} ) {
        my $ArticleBackendObject = $ArticleObject->BackendForArticle(
            TicketID  => $Self->{TicketID},
            ArticleID => $GetParam{ArticleID},
        );
        %Data = $ArticleBackendObject->ArticleGet(
            TicketID      => $Self->{TicketID},
            ArticleID     => $GetParam{ArticleID},
            DynamicFields => 1,
        );

        # Check if article is from the same TicketID as we checked permissions for.
        if ( $Data{TicketID} ne $Self->{TicketID} ) {

            return $LayoutObject->ErrorScreen(
                Message => $LayoutObject->{LanguageObject}
                    ->Translate( 'Article does not belong to ticket %s!', $Self->{TicketID} ),
            );
        }
    }

    # Get the last customer article of the ticket.
    else {
        my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');
        my @MetaArticles  = $ArticleObject->ArticleList(
            TicketID   => $Self->{TicketID},
            SenderType => 'customer',
            OnlyLast   => 1,
            UserID     => $Self->{UserID},
        );
        if (@MetaArticles) {
            %Data = $ArticleObject->BackendForArticle( %{ $MetaArticles[0] } )->ArticleGet(
                TicketID => $Self->{TicketID},
                %{ $MetaArticles[0] },
                DynamicFields => 0,
            );
        }
    }

    # prepare signature
    my $TemplateGenerator = $Kernel::OM->Get('Kernel::System::TemplateGenerator');
    $Data{Signature} = $TemplateGenerator->Signature(
        TicketID  => $Self->{TicketID},
        ArticleID => $Data{ArticleID},
        Data      => \%Data,
        UserID    => $Self->{UserID},
    );

    if ( $GetParam{EmailTemplateID} ) {

        # get template
        $Data{StdTemplate} = $TemplateGenerator->Template(
            TicketID   => $Self->{TicketID},
            ArticleID  => $Data{ArticleID},
            TemplateID => $GetParam{EmailTemplateID},
            Data       => \%Data,
            UserID     => $Self->{UserID},
        );

        # get signature
        $Data{Signature} = $TemplateGenerator->Signature(
            TicketID => $Self->{TicketID},
            Data     => \%Data,
            UserID   => $Self->{UserID},
        );
    }

    # empty the body for preparation
    $Data{Body} = '';

    # prepare body for richtext or plaintext content
    if ( $LayoutObject->{BrowserRichText} ) {

        # add the temp
        if ( $GetParam{EmailTemplateID} ) {
            $Data{Body} = $Data{StdTemplate} . '<br/>' . $Data{Body};
        }

        $Data{Body} = $Data{Body} . $Data{Signature};
    }
    else {

        # add the temp
        if ( $GetParam{EmailTemplateID} ) {
            $Data{Body} = $Data{StdTemplate} . "\n" . $Data{Body};
        }

        $Data{Body} = $Data{Body} . $Data{Signature};

        # prepare body for plain text
        $Data{Body} =~ s/\t/ /g;
    }

    # get needed objects
    my $StdAttachmentObject = $Kernel::OM->Get('Kernel::System::StdAttachment');
    my $UploadCacheObject   = $Kernel::OM->Get('Kernel::System::Web::UploadCache');

    # add std. attachments to email
    if ( $GetParam{EmailTemplateID} ) {
        my %AllStdAttachments = $StdAttachmentObject->StdAttachmentStandardTemplateMemberList(
            StandardTemplateID => $GetParam{EmailTemplateID},
        );
        for my $ID ( sort keys %AllStdAttachments ) {
            my %AttachmentsData = $StdAttachmentObject->StdAttachmentGet( ID => $ID );
            $UploadCacheObject->FormIDAddFile(
                FormID => $GetParam{FormID},
                %AttachmentsData,
            );
        }
    }

    # get all attachments meta data
    my @Attachments = $Kernel::OM->Get('Kernel::System::Web::UploadCache')->FormIDGetAllFilesMeta(
        FormID => $GetParam{FormID},
    );

    # check some values
    for my $Recipient (qw(To Cc Bcc Subject)) {
        if ( $Data{$Recipient} ) {
            delete $Data{$Recipient};
        }
    }

    # put & get attributes like sender address
    %Data = $TemplateGenerator->Attributes(
        TicketID  => $Self->{TicketID},
        ArticleID => $GetParam{ArticleID},
        Data      => \%Data,
        UserID    => $Self->{UserID},
    );

    # prepare the subject
    $Data{Subject} =~ s{ \A (?: .*? : \s*) }{}xms;

    # run compose modules
    if ( ref( $ConfigObject->Get('Ticket::Frontend::ArticleComposeModule') ) eq 'HASH' ) {

        # use ticket QueueID in compose modules
        $GetParam{QueueID} = $Ticket{QueueID};

        my %Jobs = %{ $ConfigObject->Get('Ticket::Frontend::ArticleComposeModule') };
        for my $Job ( sort keys %Jobs ) {

            # load module
            if ( !$Kernel::OM->Get('Kernel::System::Main')->Require( $Jobs{$Job}->{Module} ) ) {

                return $LayoutObject->FatalError();
            }
            my $Object = $Jobs{$Job}->{Module}->new(
                %{$Self},
                Debug => $Self->{Debug},
            );

            # get params
            PARAMETER:
            for my $Parameter ( $Object->Option( %GetParam, Config => $Jobs{$Job} ) ) {

                if ( $Jobs{$Job}->{ParamType} && $Jobs{$Job}->{ParamType} ne 'Single' ) {
                    @{ $GetParam{$Parameter} } = $ParamObject->GetArray( Param => $Parameter );
                    next PARAMETER;
                }

                $GetParam{$Parameter} = $ParamObject->GetParam( Param => $Parameter );
            }

            # run module
            my $NewParams = $Object->Run( %Data, %GetParam, Config => $Jobs{$Job} );

            if ($NewParams) {
                for my $Parameter ( $Object->Option( %GetParam, Config => $Jobs{$Job} ) ) {
                    $GetParam{$Parameter} = $NewParams;
                }
            }

            # get errors
            %Error = ( %Error, $Object->Error( %GetParam, Config => $Jobs{$Job} ) );
        }
    }

    # create HTML strings for all dynamic fields
    my %DynamicFieldHTML;

    # get the dynamic fields for this screen
    my $DynamicField = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldListGet(
        Valid       => 1,
        ObjectType  => [ 'Ticket', 'Article' ],
        FieldFilter => $Config->{DynamicField} || {},
    );

    # get dynamic field backend object
    my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    # cycle through the activated Dynamic Fields for this screen
    DYNAMICFIELD:
    for my $DynamicFieldConfig ( @{$DynamicField} ) {
        next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

        my $PossibleValuesFilter;

        my $IsACLReducible = $DynamicFieldBackendObject->HasBehavior(
            DynamicFieldConfig => $DynamicFieldConfig,
            Behavior           => 'IsACLReducible',
        );

        if ($IsACLReducible) {

            # get PossibleValues
            my $PossibleValues = $DynamicFieldBackendObject->PossibleValuesGet(
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
                    %ACLCompatGetParam,
                    Action        => $Self->{Action},
                    TicketID      => $Self->{TicketID},
                    ReturnType    => 'Ticket',
                    ReturnSubType => 'DynamicField_' . $DynamicFieldConfig->{Name},
                    Data          => \%AclData,
                    UserID        => $Self->{UserID},
                );
                if ($ACL) {
                    my %Filter = $TicketObject->TicketAclData();

                    # convert Filer key => key back to key => value using map
                    %{$PossibleValuesFilter} = map { $_ => $PossibleValues->{$_} }
                        keys %Filter;
                }
            }
        }

        # to store dynamic field value from database (or undefined)
        my $Value;

        # only get values for Ticket fields (all screens based on AgentTickeActionCommon
        # create a new article, then article fields will be always empty at the beginning)
        if ( $DynamicFieldConfig->{ObjectType} eq 'Ticket' ) {

            # get value stored on the database from Ticket
            $Value = $Ticket{ 'DynamicField_' . $DynamicFieldConfig->{Name} };
        }

        # get field HTML
        $DynamicFieldHTML{ $DynamicFieldConfig->{Name} } =
            $DynamicFieldBackendObject->EditFieldRender(
            DynamicFieldConfig   => $DynamicFieldConfig,
            PossibleValuesFilter => $PossibleValuesFilter,
            Value                => $Value,
            Mandatory =>
                $Config->{DynamicField}->{ $DynamicFieldConfig->{Name} } == 2,
            LayoutObject    => $LayoutObject,
            ParamObject     => $ParamObject,
            AJAXUpdate      => 1,
            UpdatableFields => $Self->_GetFieldsToUpdate(),
            );
    }

    # build view ...
    # start with page ...
    $Output .= $LayoutObject->Header(
        Value     => $Ticket{TicketNumber},
        Type      => 'Small',
        BodyClass => 'Popup',
    );

    # Inform a user that article subject will be empty if contains only the ticket hook (if nothing is modified).
    $Output .= $LayoutObject->Notify(
        Priority => 'Warning',
        Info     => Translatable('Article subject will be empty if the subject contains only the ticket hook!'),
    );

    $Output .= $Self->_Mask(
        TicketNumber => $Ticket{TicketNumber},
        TicketID     => $Self->{TicketID},
        Title        => $Ticket{Title},
        QueueID      => $Ticket{QueueID},
        NextStates   => $Self->_GetNextStates(
            %GetParam,
            %ACLCompatGetParam,
        ),
        TimeUnitsRequired => (
            $ConfigObject->Get('Ticket::Frontend::NeedAccountedTime')
            ? 'Validate_Required'
            : ''
        ),
        Errors              => \%Error,
        MultipleCustomer    => \@MultipleCustomer,
        MultipleCustomerCc  => \@MultipleCustomerCc,
        MultipleCustomerBcc => \@MultipleCustomerBcc,
        Attachments         => \@Attachments,
        %Data,
        %GetParam,
        DynamicFieldHTML => \%DynamicFieldHTML,
    );
    $Output .= $LayoutObject->Footer(
        Type => 'Small',
    );

    return $Output;
}

sub SendEmail {
    my ( $Self, %Param ) = @_;

    my %Error;
    my %ACLCompatGetParam;

    # get param object
    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');

    # ACL compatibility translation
    $ACLCompatGetParam{NextStateID} = $ParamObject->GetParam( Param => 'NextStateID' );

    my %GetParamExtended = $Self->_GetExtendedParams();

    my %GetParam            = %{ $GetParamExtended{GetParam} };
    my @MultipleCustomer    = @{ $GetParamExtended{MultipleCustomer} };
    my @MultipleCustomerCc  = @{ $GetParamExtended{MultipleCustomerCc} };
    my @MultipleCustomerBcc = @{ $GetParamExtended{MultipleCustomerBcc} };

    my %DynamicFieldValues;

    # get config object
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # get config for frontend module
    my $Config = $ConfigObject->Get("Ticket::Frontend::$Self->{Action}");

    # get the dynamic fields for this screen
    my $DynamicField = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldListGet(
        Valid       => 1,
        ObjectType  => [ 'Ticket', 'Article' ],
        FieldFilter => $Config->{DynamicField} || {},
    );

    # get needed objects
    my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
    my $LayoutObject              = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # Get and validate draft action.
    my $FormDraftAction = $ParamObject->GetParam( Param => 'FormDraftAction' );
    if ( $FormDraftAction && !$Config->{FormDraft} ) {
        return $LayoutObject->ErrorScreen(
            Message => Translatable('FormDraft functionality disabled!'),
            Comment => Translatable('Please contact the administrator.'),
        );
    }

    my %FormDraftResponse;

    # Check draft name.
    if (
        $FormDraftAction
        && ( $FormDraftAction eq 'Add' || $FormDraftAction eq 'Update' )
        )
    {
        my $Title = $ParamObject->GetParam( Param => 'FormDraftTitle' );

        # A draft name is required.
        if ( !$Title ) {

            %FormDraftResponse = (
                Success      => 0,
                ErrorMessage => $Kernel::OM->Get('Kernel::Language')->Translate("Draft name is required!"),
            );
        }

        # Chosen draft name must be unique.
        else {
            my $FormDraftList = $Kernel::OM->Get('Kernel::System::FormDraft')->FormDraftListGet(
                ObjectType => 'Ticket',
                ObjectID   => $Self->{TicketID},
                Action     => $Self->{Action},
                UserID     => $Self->{UserID},
            );
            DRAFT:
            for my $FormDraft ( @{$FormDraftList} ) {

                # No existing draft with same name.
                next DRAFT if $Title ne $FormDraft->{Title};

                # Same name for update on existing draft.
                if (
                    $GetParam{FormDraftID}
                    && $FormDraftAction eq 'Update'
                    && $GetParam{FormDraftID} eq $FormDraft->{FormDraftID}
                    )
                {
                    next DRAFT;
                }

                # Another draft with the chosen name already exists.
                %FormDraftResponse = (
                    Success      => 0,
                    ErrorMessage => $Kernel::OM->Get('Kernel::Language')
                        ->Translate( "FormDraft name %s is already in use!", $Title ),
                );
                last DRAFT;
            }
        }
    }

    # Perform draft action instead of saving form data in ticket/article.
    if ( $FormDraftAction && !%FormDraftResponse ) {

        # Reset FormDraftID to prevent updating existing draft.
        if ( $FormDraftAction eq 'Add' && $GetParam{FormDraftID} ) {
            $ParamObject->{Query}->param(
                -name  => 'FormDraftID',
                -value => '',
            );
        }

        my $FormDraftActionOk;
        if (
            $FormDraftAction eq 'Add'
            ||
            ( $FormDraftAction eq 'Update' && $GetParam{FormDraftID} )
            )
        {
            $FormDraftActionOk = $ParamObject->SaveFormDraft(
                UserID     => $Self->{UserID},
                ObjectType => 'Ticket',
                ObjectID   => $Self->{TicketID},
            );
        }
        elsif ( $FormDraftAction eq 'Delete' && $GetParam{FormDraftID} ) {
            $FormDraftActionOk = $Kernel::OM->Get('Kernel::System::FormDraft')->FormDraftDelete(
                FormDraftID => $GetParam{FormDraftID},
                UserID      => $Self->{UserID},
            );
        }

        if ($FormDraftActionOk) {
            $FormDraftResponse{Success} = 1;
        }
        else {
            %FormDraftResponse = (
                Success      => 0,
                ErrorMessage => 'Could not perform requested draft action!',
            );
        }
    }

    if (%FormDraftResponse) {

        # build JSON output
        my $JSON = $LayoutObject->JSONEncode(
            Data => \%FormDraftResponse,
        );

        # send JSON response
        return $LayoutObject->Attachment(
            ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
            Content     => $JSON,
            Type        => 'inline',
            NoCache     => 1,
        );
    }

    # cycle through the activated Dynamic Fields for this screen
    DYNAMICFIELD:
    for my $DynamicFieldConfig ( @{$DynamicField} ) {
        next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

        # extract the dynamic field value from the web request
        $DynamicFieldValues{ $DynamicFieldConfig->{Name} } =
            $DynamicFieldBackendObject->EditFieldValueGet(
            DynamicFieldConfig => $DynamicFieldConfig,
            ParamObject        => $ParamObject,
            LayoutObject       => $LayoutObject,
            );
    }

    # convert dynamic field values into a structure for ACLs
    my %DynamicFieldACLParameters;
    DYNAMICFIELD:
    for my $DynamicFieldItem ( sort keys %DynamicFieldValues ) {
        next DYNAMICFIELD if !$DynamicFieldItem;
        next DYNAMICFIELD if !defined $DynamicFieldValues{$DynamicFieldItem};

        $DynamicFieldACLParameters{ 'DynamicField_' . $DynamicFieldItem } = $DynamicFieldValues{$DynamicFieldItem};
    }
    $GetParam{DynamicField} = \%DynamicFieldACLParameters;

    my $QueueID = $Self->{QueueID};
    my %StateData;

    if ( $GetParam{ComposeStateID} ) {
        %StateData = $Kernel::OM->Get('Kernel::System::State')->StateGet(
            ID => $GetParam{ComposeStateID},
        );
    }

    my $NextState = $StateData{Name};

    # check pending date
    if ( defined $StateData{TypeName} && $StateData{TypeName} =~ /^pending/i ) {

        # convert pending date to a datetime object
        my $PendingDateTimeObject = $Kernel::OM->Create(
            'Kernel::System::DateTime',
            ObjectParams => {
                %GetParam,
                Second => 0,
            },
        );

        # get current system epoch
        my $CurSystemDateTimeObject = $Kernel::OM->Create('Kernel::System::DateTime');

        if ( !$PendingDateTimeObject || $PendingDateTimeObject < $CurSystemDateTimeObject ) {
            $Error{'DateInvalid'} = 'ServerError';
        }
    }

    # check To
    if ( !$GetParam{To} ) {
        $Error{'ToInvalid'} = 'ServerError';
    }

    # check body
    if ( !$GetParam{Body} ) {
        $Error{'BodyInvalid'} = 'ServerError';
    }

    # check subject
    if ( !$GetParam{Subject} ) {
        $Error{'SubjectInvalid'} = 'ServerError';
    }

    if (
        $ConfigObject->Get('Ticket::Frontend::AccountTime')
        && $ConfigObject->Get('Ticket::Frontend::NeedAccountedTime')
        && $GetParam{TimeUnits} eq ''
        )
    {
        $Error{'TimeUnitsInvalid'} = 'ServerError';
    }

    # get ticket object
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    # prepare subject
    my %Ticket = $TicketObject->TicketGet(
        TicketID      => $Self->{TicketID},
        DynamicFields => 1,
    );

    # get upload cache object
    my $UploadCacheObject = $Kernel::OM->Get('Kernel::System::Web::UploadCache');

    # get all attachments meta data
    my @Attachments = $UploadCacheObject->FormIDGetAllFilesMeta(
        FormID => $GetParam{FormID},
    );

    # create HTML strings for all dynamic fields
    my %DynamicFieldHTML;

    # cycle through the activated Dynamic Fields for this screen
    DYNAMICFIELD:
    for my $DynamicFieldConfig ( @{$DynamicField} ) {
        next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

        my $PossibleValuesFilter;

        my $IsACLReducible = $DynamicFieldBackendObject->HasBehavior(
            DynamicFieldConfig => $DynamicFieldConfig,
            Behavior           => 'IsACLReducible',
        );

        if ($IsACLReducible) {

            # get PossibleValues
            my $PossibleValues = $DynamicFieldBackendObject->PossibleValuesGet(
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
                    %ACLCompatGetParam,
                    Action        => $Self->{Action},
                    TicketID      => $Self->{TicketID},
                    ReturnType    => 'Ticket',
                    ReturnSubType => 'DynamicField_' . $DynamicFieldConfig->{Name},
                    Data          => \%AclData,
                    UserID        => $Self->{UserID},
                );
                if ($ACL) {
                    my %Filter = $TicketObject->TicketAclData();

                    # convert Filer key => key back to key => value using map
                    %{$PossibleValuesFilter} = map { $_ => $PossibleValues->{$_} }
                        keys %Filter;
                }
            }
        }

        my $ValidationResult = $DynamicFieldBackendObject->EditFieldValueValidate(
            DynamicFieldConfig   => $DynamicFieldConfig,
            PossibleValuesFilter => $PossibleValuesFilter,
            ParamObject          => $ParamObject,
            Mandatory =>
                $Config->{DynamicField}->{ $DynamicFieldConfig->{Name} } == 2,
        );

        if ( !IsHashRefWithData($ValidationResult) ) {

            return $LayoutObject->ErrorScreen(
                Message =>
                    $LayoutObject->{LanguageObject}
                    ->Translate( 'Could not perform validation on field %s!', $DynamicFieldConfig->{Label} ),
                Comment => Translatable('Please contact the administrator.'),
            );
        }

        # propagate validation error to the Error variable to be detected by the frontend
        if ( $ValidationResult->{ServerError} ) {
            $Error{ $DynamicFieldConfig->{Name} } = ' ServerError';
        }

        # get field HTML
        $DynamicFieldHTML{ $DynamicFieldConfig->{Name} } =
            $DynamicFieldBackendObject->EditFieldRender(
            DynamicFieldConfig   => $DynamicFieldConfig,
            PossibleValuesFilter => $PossibleValuesFilter,
            Mandatory =>
                $Config->{DynamicField}->{ $DynamicFieldConfig->{Name} } == 2,
            ServerError  => $ValidationResult->{ServerError}  || '',
            ErrorMessage => $ValidationResult->{ErrorMessage} || '',
            LayoutObject => $LayoutObject,
            ParamObject  => $ParamObject,
            AJAXUpdate   => 1,
            UpdatableFields => $Self->_GetFieldsToUpdate(),
            );
    }

    # transform pending time, time stamp based on user time zone
    if (
        defined $GetParam{Year}
        && defined $GetParam{Month}
        && defined $GetParam{Day}
        && defined $GetParam{Hour}
        && defined $GetParam{Minute}
        )
    {
        %GetParam = $LayoutObject->TransformDateSelection(
            %GetParam,
        );
    }

    # get check item object
    my $CheckItemObject = $Kernel::OM->Get('Kernel::System::CheckItem');

    # check some values
    LINE:
    for my $Line (qw(To Cc Bcc)) {
        next LINE if !$GetParam{$Line};
        for my $Email ( Mail::Address->parse( $GetParam{$Line} ) ) {
            if ( !$CheckItemObject->CheckEmail( Address => $Email->address() ) ) {
                $Error{ $Line . 'ErrorType' } = $Line . $CheckItemObject->CheckErrorType() . 'ServerErrorMsg';
                $Error{ $Line . 'Invalid' }   = 'ServerError';
            }
            my $IsLocal = $Kernel::OM->Get('Kernel::System::SystemAddress')->SystemAddressIsLocalAddress(
                Address => $Email->address()
            );
            if ($IsLocal) {
                $Error{ $Line . 'IsLocalAddress' } = 'ServerError';
            }
        }
    }

    # Make sure sender is correct one. See bug#14872 ( https://bugs.otrs.org/show_bug.cgi?id=14872 ).
    $GetParam{From} = $Kernel::OM->Get('Kernel::System::TemplateGenerator')->Sender(
        QueueID => $Ticket{QueueID},
        UserID  => $Self->{UserID},
    );

    if ( $Self->{LoadedFormDraftID} ) {

        # Make sure we don't save form if a draft was loaded.
        %Error = ( LoadedFormDraft => 1 );
    }

    # run compose modules
    my %ArticleParam;

    if ( ref( $ConfigObject->Get('Ticket::Frontend::ArticleComposeModule') ) eq 'HASH' ) {
        my %Jobs = %{ $ConfigObject->Get('Ticket::Frontend::ArticleComposeModule') };
        for my $Job ( sort keys %Jobs ) {

            # load module
            if ( !$Kernel::OM->Get('Kernel::System::Main')->Require( $Jobs{$Job}->{Module} ) ) {
                return $LayoutObject->FatalError();
            }
            my $Object = $Jobs{$Job}->{Module}->new(
                %{$Self},
                Debug => $Self->{Debug},
            );

            my $Multiple;

            # get params
            PARAMETER:
            for my $Parameter ( $Object->Option( %GetParam, Config => $Jobs{$Job} ) ) {
                if ( $Jobs{$Job}->{ParamType} && $Jobs{$Job}->{ParamType} ne 'Single' ) {
                    @{ $GetParam{$Parameter} } = $ParamObject->GetArray( Param => $Parameter );
                    $Multiple = 1;
                    next PARAMETER;
                }

                $GetParam{$Parameter} = $ParamObject->GetParam( Param => $Parameter );
            }

            # run module
            $Object->Run(
                %GetParam,
                StoreNew => 1,
                Config   => $Jobs{$Job}
            );

            # get options that have been removed from the selection
            # and add them back to the selection so that the submit
            # will contain options that were hidden from the agent
            my $Key = $Object->Option( %GetParam, Config => $Jobs{$Job} );

            if ( $Object->can('GetOptionsToRemoveAJAX') ) {
                my @RemovedOptions = $Object->GetOptionsToRemoveAJAX(%GetParam);
                if (@RemovedOptions) {
                    if ($Multiple) {
                        for my $RemovedOption (@RemovedOptions) {
                            push @{ $GetParam{$Key} }, $RemovedOption;
                        }
                    }
                    else {
                        $GetParam{$Key} = shift @RemovedOptions;
                    }
                }
            }

            # ticket params
            %ArticleParam = (
                %ArticleParam,
                $Object->ArticleOption( %GetParam, %ArticleParam, Config => $Jobs{$Job} ),
            );

            # get errors
            %Error = (
                %Error,
                $Object->Error( %GetParam, Config => $Jobs{$Job} ),
            );
        }
    }

    # check if there is an error
    if (%Error) {

        my $QueueID = $TicketObject->TicketQueueID( TicketID => $Self->{TicketID} );
        my $Output  = $LayoutObject->Header(
            Type      => 'Small',
            BodyClass => 'Popup',
        );

        # When a draft is loaded, inform a user that article subject will be empty
        # if contains only the ticket hook (if nothing is modified).
        if ( $Error{LoadedFormDraft} ) {
            $Output .= $LayoutObject->Notify(
                Data => $LayoutObject->{LanguageObject}->Translate(
                    'Article subject will be empty if the subject contains only the ticket hook!'
                ),
            );
        }

        $Output .= $Self->_Mask(
            TicketNumber => $Ticket{TicketNumber},
            Title        => $Ticket{Title},
            TicketID     => $Self->{TicketID},
            QueueID      => $QueueID,
            NextStates   => $Self->_GetNextStates(
                %GetParam,
                %ACLCompatGetParam,
            ),
            Errors              => \%Error,
            MultipleCustomer    => \@MultipleCustomer,
            MultipleCustomerCc  => \@MultipleCustomerCc,
            MultipleCustomerBcc => \@MultipleCustomerBcc,
            Attachments         => \@Attachments,
            DynamicFieldHTML    => \%DynamicFieldHTML,
            %GetParam,
        );
        $Output .= $LayoutObject->Footer(
            Type => 'Small',
        );
        return $Output;
    }

    # replace <OTRS_TICKET_STATE> with next ticket state name
    if ($NextState) {
        $GetParam{Body} =~ s/(&lt;|<)OTRS_TICKET_STATE(&gt;|>)/$NextState/g;
    }

    # get pre loaded attachments
    my @AttachmentData = $UploadCacheObject->FormIDGetAllFilesData(
        FormID => $GetParam{FormID},
    );

    # get submit attachment
    my %UploadStuff = $ParamObject->GetUploadAll(
        Param => 'FileUpload',
    );
    if (%UploadStuff) {
        push @AttachmentData, \%UploadStuff;
    }

    my $MimeType = 'text/plain';
    if ( $LayoutObject->{BrowserRichText} ) {
        $MimeType = 'text/html';

        # remove unused inline images
        my @NewAttachmentData;

        ATTACHMENT:
        for my $Attachment (@AttachmentData) {
            my $ContentID = $Attachment->{ContentID};
            if ( $ContentID && ( $Attachment->{ContentType} =~ /image/i ) ) {
                my $ContentIDHTMLQuote = $LayoutObject->Ascii2Html(
                    Text => $ContentID,
                );

                # workaround for link encode of rich text editor, see bug#5053
                my $ContentIDLinkEncode = $LayoutObject->LinkEncode($ContentID);
                $GetParam{Body} =~ s/(ContentID=)$ContentIDLinkEncode/$1$ContentID/g;

                # ignore attachment if not linked in body
                next ATTACHMENT if $GetParam{Body} !~ /(\Q$ContentIDHTMLQuote\E|\Q$ContentID\E)/i;
            }

            # remember inline images and normal attachments
            push @NewAttachmentData, \%{$Attachment};
        }
        @AttachmentData = @NewAttachmentData;

        # verify HTML document
        $GetParam{Body} = $LayoutObject->RichTextDocumentComplete(
            String => $GetParam{Body},
        );
    }

    # send email
    my $To = '';

    KEY:
    for my $Key (qw(To Cc Bcc)) {
        next KEY if !$GetParam{$Key};
        if ($To) {
            $To .= ', ';
        }
        $To .= $GetParam{$Key};
    }

    # Get attributes like sender address.
    my %Data = $Kernel::OM->Get('Kernel::System::TemplateGenerator')->Attributes(
        TicketID => $Self->{TicketID},
        Data     => {},
        UserID   => $Self->{UserID},
    );

    my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');
    my $ArticleID     = $ArticleObject->BackendForChannel( ChannelName => 'Email' )->ArticleSend(
        SenderType           => 'agent',
        IsVisibleForCustomer => $GetParam{IsVisibleForCustomer} // 0,
        TicketID             => $Self->{TicketID},
        HistoryType          => 'EmailAgent',
        HistoryComment       => "\%\%$To",
        From                 => $Data{From},
        To                   => $GetParam{To},
        Cc                   => $GetParam{Cc},
        Bcc                  => $GetParam{Bcc},
        Subject              => $GetParam{Subject},
        UserID               => $Self->{UserID},
        Body                 => $GetParam{Body},

        # We start a new communication here, so don't send any references.
        #   This might lead to information disclosure (domain names; see bug#11246).
        InReplyTo  => '',
        References => '',
        Charset    => $LayoutObject->{UserCharset},
        MimeType   => $MimeType,
        Attachment => \@AttachmentData,
        %ArticleParam,
    );

    # error page
    if ( !$ArticleID ) {

        return $LayoutObject->ErrorScreen(
            Comment => Translatable('Please contact the administrator.'),
        );
    }

    # time accounting
    if ( $GetParam{TimeUnits} ) {
        $TicketObject->TicketAccountTime(
            TicketID  => $Self->{TicketID},
            ArticleID => $ArticleID,
            TimeUnit  => $GetParam{TimeUnits},
            UserID    => $Self->{UserID},
        );
    }

    # set dynamic fields
    # cycle through the activated Dynamic Fields for this screen
    DYNAMICFIELD:
    for my $DynamicFieldConfig ( @{$DynamicField} ) {
        next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

        # set the object ID (TicketID or ArticleID) depending on the field configuration
        my $ObjectID = $DynamicFieldConfig->{ObjectType} eq 'Article' ? $ArticleID : $Self->{TicketID};

        # set the value
        my $Success = $DynamicFieldBackendObject->ValueSet(
            DynamicFieldConfig => $DynamicFieldConfig,
            ObjectID           => $ObjectID,
            Value              => $DynamicFieldValues{ $DynamicFieldConfig->{Name} },
            UserID             => $Self->{UserID},
        );
    }

    # set state
    if ($NextState) {
        $TicketObject->TicketStateSet(
            TicketID  => $Self->{TicketID},
            ArticleID => $ArticleID,
            State     => $NextState,
            UserID    => $Self->{UserID},
        );

        # should I set an unlock?
        if ( $StateData{TypeName} =~ /^close/i ) {
            $TicketObject->TicketLockSet(
                TicketID => $Self->{TicketID},
                Lock     => 'unlock',
                UserID   => $Self->{UserID},
            );
        }

        # set pending time
        elsif ( $StateData{TypeName} =~ /^pending/i ) {
            $TicketObject->TicketPendingTimeSet(
                UserID   => $Self->{UserID},
                TicketID => $Self->{TicketID},
                %GetParam,
            );
        }
    }

    # remove pre-submitted attachments
    $UploadCacheObject->FormIDRemove( FormID => $GetParam{FormID} );

    # If form was called based on a draft,
    #   delete draft since its content has now been used.
    if (
        $GetParam{FormDraftID}
        && !$Kernel::OM->Get('Kernel::System::FormDraft')->FormDraftDelete(
            FormDraftID => $GetParam{FormDraftID},
            UserID      => $Self->{UserID},
        )
        )
    {
        return $LayoutObject->ErrorScreen(
            Message => Translatable('Could not delete draft!'),
            Comment => Translatable('Please contact the administrator.'),
        );
    }

    # redirect
    if (
        defined $StateData{TypeName}
        && $StateData{TypeName} =~ /^close/i
        && !$ConfigObject->Get('Ticket::Frontend::RedirectAfterCloseDisabled')
        )
    {
        return $LayoutObject->PopupClose(
            URL => ( $Self->{LastScreenOverview} || 'Action=AgentDashboard' ),
        );
    }

    return $LayoutObject->PopupClose(
        URL => "Action=AgentTicketZoom;TicketID=$Self->{TicketID};ArticleID=$ArticleID",
    );
}

sub AjaxUpdate {
    my ( $Self, %Param ) = @_;

    my %Error;
    my %ACLCompatGetParam;

    # get param object
    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');

    # ACL compatibility translation
    $ACLCompatGetParam{NextStateID} = $ParamObject->GetParam( Param => 'NextStateID' );

    my %GetParamExtended = $Self->_GetExtendedParams();

    my %GetParam            = %{ $GetParamExtended{GetParam} };
    my @MultipleCustomer    = @{ $GetParamExtended{MultipleCustomer} };
    my @MultipleCustomerCc  = @{ $GetParamExtended{MultipleCustomerCc} };
    my @MultipleCustomerBcc = @{ $GetParamExtended{MultipleCustomerBcc} };

    my %Ticket = $Kernel::OM->Get('Kernel::System::Ticket')->TicketGet( TicketID => $Self->{TicketID} );

    # Make sure sender is correct one. See bug#14872 ( https://bugs.otrs.org/show_bug.cgi?id=14872 ).
    $GetParam{From} = $Kernel::OM->Get('Kernel::System::TemplateGenerator')->Sender(
        QueueID => $Ticket{QueueID},
        UserID  => $Self->{UserID},
    );

    my @ExtendedData;

    # get config object
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # run compose modules
    if ( ref $ConfigObject->Get('Ticket::Frontend::ArticleComposeModule') eq 'HASH' ) {
        my %Jobs = %{ $ConfigObject->Get('Ticket::Frontend::ArticleComposeModule') };

        JOB:
        for my $Job ( sort keys %Jobs ) {

            # load module
            next JOB if !$Kernel::OM->Get('Kernel::System::Main')->Require( $Jobs{$Job}->{Module} );

            my $Object = $Jobs{$Job}->{Module}->new(
                %{$Self},
                Debug => $Self->{Debug},
            );

            my $Multiple;

            # get params
            PARAMETER:
            for my $Parameter ( $Object->Option( %GetParam, Config => $Jobs{$Job} ) ) {
                if ( $Jobs{$Job}->{ParamType} && $Jobs{$Job}->{ParamType} ne 'Single' ) {
                    @{ $GetParam{$Parameter} } = $ParamObject->GetArray( Param => $Parameter );
                    $Multiple = 1;
                    next PARAMETER;
                }

                $GetParam{$Parameter} = $ParamObject->GetParam( Param => $Parameter );
            }

            # run module
            my %Data = $Object->Data( %GetParam, Config => $Jobs{$Job} );

            # get AJAX param values
            if ( $Object->can('GetParamAJAX') ) {
                %GetParam = ( %GetParam, $Object->GetParamAJAX(%GetParam) );
            }

            # get options that have to be removed from the selection visible
            # to the agent. These options will be added again on submit.
            if ( $Object->can('GetOptionsToRemoveAJAX') ) {
                my @OptionsToRemove = $Object->GetOptionsToRemoveAJAX(%GetParam);

                for my $OptionToRemove (@OptionsToRemove) {
                    delete $Data{$OptionToRemove};
                }
            }

            my $Key = $Object->Option( %GetParam, Config => $Jobs{$Job} );
            if ($Key) {
                push(
                    @ExtendedData,
                    {
                        Name         => $Key,
                        Data         => \%Data,
                        SelectedID   => $GetParam{$Key},
                        Translation  => 1,
                        PossibleNone => 1,
                        Multiple     => $Multiple,
                        Max          => 100,
                    }
                );
            }
        }
    }

    my %DynamicFieldValues;

    # get config for frontend module
    my $Config = $ConfigObject->Get("Ticket::Frontend::$Self->{Action}");

    # get the dynamic fields for this screen
    my $DynamicField = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldListGet(
        Valid       => 1,
        ObjectType  => [ 'Ticket', 'Article' ],
        FieldFilter => $Config->{DynamicField} || {},
    );

    # get needed objects
    my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
    my $LayoutObject              = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # cycle through the activated Dynamic Fields for this screen
    DYNAMICFIELD:
    for my $DynamicFieldConfig ( @{$DynamicField} ) {
        next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

        # extract the dynamic field value from the web request
        $DynamicFieldValues{ $DynamicFieldConfig->{Name} } =
            $DynamicFieldBackendObject->EditFieldValueGet(
            DynamicFieldConfig => $DynamicFieldConfig,
            ParamObject        => $ParamObject,
            LayoutObject       => $LayoutObject,
            );
    }

    # convert dynamic field values into a structure for ACLs
    my %DynamicFieldACLParameters;
    DYNAMICFIELD:
    for my $DynamicFieldItem ( sort keys %DynamicFieldValues ) {
        next DYNAMICFIELD if !$DynamicFieldItem;
        next DYNAMICFIELD if !defined $DynamicFieldValues{$DynamicFieldItem};

        $DynamicFieldACLParameters{ 'DynamicField_' . $DynamicFieldItem } = $DynamicFieldValues{$DynamicFieldItem};
    }
    $GetParam{DynamicField} = \%DynamicFieldACLParameters;

    my $NextStates = $Self->_GetNextStates(
        %GetParam,
        %ACLCompatGetParam,
    );

    # update Dynamic Fields Possible Values via AJAX
    my @DynamicFieldAJAX;

    # cycle through the activated Dynamic Fields for this screen
    DYNAMICFIELD:
    for my $DynamicFieldConfig ( @{$DynamicField} ) {
        next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

        my $IsACLReducible = $DynamicFieldBackendObject->HasBehavior(
            DynamicFieldConfig => $DynamicFieldConfig,
            Behavior           => 'IsACLReducible',
        );
        next DYNAMICFIELD if !$IsACLReducible;

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
            %GetParam,
            %ACLCompatGetParam,
            Action        => $Self->{Action},
            TicketID      => $Self->{TicketID},
            QueueID       => $Self->{QueueID},
            ReturnType    => 'Ticket',
            ReturnSubType => 'DynamicField_' . $DynamicFieldConfig->{Name},
            Data          => \%AclData,
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

        # add dynamic field to the list of fields to update
        push(
            @DynamicFieldAJAX,
            {
                Name        => 'DynamicField_' . $DynamicFieldConfig->{Name},
                Data        => $DataValues,
                SelectedID  => $DynamicFieldValues{ $DynamicFieldConfig->{Name} },
                Translation => $DynamicFieldConfig->{Config}->{TranslatableValues} || 0,
                Max         => 100,
            }
        );
    }

    my $JSON = $LayoutObject->BuildSelectionJSON(
        [
            {
                Name         => 'ComposeStateID',
                Data         => $NextStates,
                SelectedID   => $GetParam{ComposeStateID},
                Translation  => 1,
                PossibleNone => 1,
                Max          => 100,
            },
            @ExtendedData,
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

sub _GetNextStates {
    my ( $Self, %Param ) = @_;

    # get next states
    my %NextStates = $Kernel::OM->Get('Kernel::System::Ticket')->TicketStateList(
        %Param,
        Action   => $Self->{Action},
        TicketID => $Self->{TicketID},
        UserID   => $Self->{UserID},
    );

    return \%NextStates;
}

sub _Mask {
    my ( $Self, %Param ) = @_;

    my $DynamicFieldNames = $Self->_GetFieldsToUpdate(
        OnlyDynamicFields => 1
    );

    # get config object
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # get config for frontend module
    my $Config = $ConfigObject->Get("Ticket::Frontend::$Self->{Action}");

    # build next states string
    my %State;
    if ( !$Param{ComposeStateID} ) {
        $State{SelectedValue} = $Config->{StateDefault};
    }
    else {
        $State{SelectedID} = $Param{ComposeStateID};
    }

    # get layout object
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    $Param{NextStatesStrg} = $LayoutObject->BuildSelection(
        Data         => $Param{NextStates},
        Name         => 'ComposeStateID',
        PossibleNone => 1,
        Class        => 'Modernize',
        %State,
    );

    if ( !$Param{IsVisibleForCustomerPresent} ) {
        $Param{IsVisibleForCustomer} = $Config->{IsVisibleForCustomerDefault};
    }

    # prepare errors!
    if ( $Param{Errors} ) {
        for my $Error ( sort keys %{ $Param{Errors} } ) {
            $Param{$Error} = $LayoutObject->Ascii2Html( Text => $Param{Errors}->{$Error} );
        }
    }

    # pending data string
    $Param{PendingDateString} = $LayoutObject->BuildDateSelection(
        %Param,
        YearPeriodPast       => 0,
        YearPeriodFuture     => 5,
        Format               => 'DateInputFormatLong',
        DiffTime             => $ConfigObject->Get('Ticket::Frontend::PendingDiffTime') || 0,
        Class                => $Param{Errors}->{DateInvalid} || ' ',
        Validate             => 1,
        ValidateDateInFuture => 1,
    );

    # Multiple-Autocomplete
    # Cc
    my $CustomerCounterCc = 0;
    if ( $Param{MultipleCustomerCc} ) {
        for my $Item ( @{ $Param{MultipleCustomerCc} } ) {
            $LayoutObject->Block(
                Name => 'CcMultipleCustomer',
                Data => $Item,
            );
            $LayoutObject->Block(
                Name => 'Cc' . $Item->{CustomerErrorMsg},
                Data => $Item,
            );
            if ( $Item->{CustomerError} ) {
                $LayoutObject->Block(
                    Name => 'CcCustomerErrorExplantion',
                );
            }
            $CustomerCounterCc++;
        }
    }

    if ( !$CustomerCounterCc ) {
        $Param{CcCustomerHiddenContainer} = 'Hidden';
    }

    # set customer counter
    $LayoutObject->Block(
        Name => 'CcMultipleCustomerCounter',
        Data => {
            CustomerCounter => $CustomerCounterCc++,
        },
    );

    # Bcc
    my $CustomerCounterBcc = 0;
    if ( $Param{MultipleCustomerBcc} ) {
        for my $Item ( @{ $Param{MultipleCustomerBcc} } ) {
            $LayoutObject->Block(
                Name => 'BccMultipleCustomer',
                Data => $Item,
            );
            $LayoutObject->Block(
                Name => 'Bcc' . $Item->{CustomerErrorMsg},
                Data => $Item,
            );
            if ( $Item->{CustomerError} ) {
                $LayoutObject->Block(
                    Name => 'BccCustomerErrorExplantion',
                );
            }
            $CustomerCounterBcc++;
        }
    }

    if ( !$CustomerCounterBcc ) {
        $Param{BccCustomerHiddenContainer} = 'Hidden';
    }

    # set customer counter
    $LayoutObject->Block(
        Name => 'BccMultipleCustomerCounter',
        Data => {
            CustomerCounter => $CustomerCounterBcc++,
        },
    );

    # To
    my $CustomerCounter = 0;
    if ( $Param{MultipleCustomer} ) {
        for my $Item ( @{ $Param{MultipleCustomer} } ) {
            $LayoutObject->Block(
                Name => 'MultipleCustomer',
                Data => $Item,
            );
            $LayoutObject->Block(
                Name => $Item->{CustomerErrorMsg},
                Data => $Item,
            );
            if ( $Item->{CustomerError} ) {
                $LayoutObject->Block(
                    Name => 'CustomerErrorExplantion',
                );
            }
            $CustomerCounter++;
        }
    }

    if ( !$CustomerCounter ) {
        $Param{CustomerHiddenContainer} = 'Hidden';
    }

    # set customer counter
    $LayoutObject->Block(
        Name => 'MultipleCustomerCounter',
        Data => {
            CustomerCounter => $CustomerCounter++,
        },
    );

    if ( $Param{ToInvalid} && $Param{Errors} && !$Param{Errors}->{ToErrorType} ) {
        $LayoutObject->Block(
            Name => 'ToServerErrorMsg',
        );
    }

    if ( $Param{ToIsLocalAddress} && $Param{Errors} && !$Param{Errors}->{ToErrorType} ) {
        $LayoutObject->Block(
            Name => 'ToIsLocalAddressServerErrorMsg',
            Data => \%Param,
        );
    }

    if ( $Param{CcInvalid} && $Param{Errors} && !$Param{Errors}->{CcErrorType} ) {
        $LayoutObject->Block(
            Name => 'CcServerErrorMsg',
        );
    }

    if ( $Param{CcIsLocalAddress} && $Param{Errors} && !$Param{Errors}->{CcErrorType} ) {
        $LayoutObject->Block(
            Name => 'CcIsLocalAddressServerErrorMsg',
            Data => \%Param,
        );
    }

    if ( $Param{BccInvalid} && $Param{Errors} && !$Param{Errors}->{BccErrorType} ) {
        $LayoutObject->Block(
            Name => 'BccServerErrorMsg',
        );
    }

    if ( $Param{BccIsLocalAddress} && $Param{Errors} && !$Param{Errors}->{BccErrorType} ) {
        $LayoutObject->Block(
            Name => 'BccIsLocalAddressServerErrorMsg',
            Data => \%Param,
        );
    }

    # get the dynamic fields for this screen
    my $DynamicField = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldListGet(
        Valid       => 1,
        ObjectType  => [ 'Ticket', 'Article' ],
        FieldFilter => $Config->{DynamicField} || {},
    );

    # Dynamic fields
    # cycle through the activated Dynamic Fields for this screen
    DYNAMICFIELD:
    for my $DynamicFieldConfig ( @{$DynamicField} ) {
        next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

        # skip fields that HTML could not be retrieved
        next DYNAMICFIELD if !IsHashRefWithData(
            $Param{DynamicFieldHTML}->{ $DynamicFieldConfig->{Name} }
        );

        # get the HTML strings form $Param
        my $DynamicFieldHTML = $Param{DynamicFieldHTML}->{ $DynamicFieldConfig->{Name} };

        $LayoutObject->Block(
            Name => 'DynamicField',
            Data => {
                Name  => $DynamicFieldConfig->{Name},
                Label => $DynamicFieldHTML->{Label},
                Field => $DynamicFieldHTML->{Field},
            },
        );

        # example of dynamic fields order customization
        $LayoutObject->Block(
            Name => 'DynamicField_' . $DynamicFieldConfig->{Name},
            Data => {
                Name  => $DynamicFieldConfig->{Name},
                Label => $DynamicFieldHTML->{Label},
                Field => $DynamicFieldHTML->{Field},
            },
        );
    }

    # show time accounting box
    if ( $ConfigObject->Get('Ticket::Frontend::AccountTime') ) {
        $Param{TimeUnitsBlock} = $LayoutObject->TimeUnits(
            %Param,
        );
        $LayoutObject->Block(
            Name => 'TimeUnits',
            Data => \%Param,
        );
    }

    # Show the customer user address book if the module is registered and java script support is available.
    if (
        $ConfigObject->Get('Frontend::Module')->{AgentCustomerUserAddressBook}
        && $LayoutObject->{BrowserJavaScriptSupport}
        )
    {
        $Param{OptionCustomerUserAddressBook} = 1;
    }

    my $QueueStandardTemplates = $Self->_GetStandardTemplates(
        %Param,
        TicketID => $Self->{TicketID} || '',
    );

    if ( IsHashRefWithData($QueueStandardTemplates) ) {
        $Param{StandardTemplateStrg} = $LayoutObject->BuildSelection(
            Data         => $QueueStandardTemplates || {},
            Name         => 'StandardTemplateID',
            SelectedID   => $Param{StandardTemplateID} || '',
            Class        => 'Modernize',
            PossibleNone => 1,
            Sort         => 'AlphanumericValue',
            Translation  => 1,
            Max          => 200,
        );
        $LayoutObject->Block(
            Name => 'StandardTemplate',
            Data => {%Param},
        );
    }

    # show attachments
    ATTACHMENT:
    for my $Attachment ( @{ $Param{Attachments} } ) {
        if (
            $Attachment->{ContentID}
            && $LayoutObject->{BrowserRichText}
            && ( $Attachment->{ContentType} =~ /image/i )
            )
        {
            next ATTACHMENT;
        }

        push @{ $Param{AttachmentList} }, $Attachment;
    }

    # add rich text editor
    if ( $LayoutObject->{BrowserRichText} ) {

        # use height/width defined for this screen
        $Param{RichTextHeight} = $Config->{RichTextHeight} || 0;
        $Param{RichTextWidth}  = $Config->{RichTextWidth}  || 0;

        # set up rich text editor
        $LayoutObject->SetRichTextParameters(
            Data => \%Param,
        );
    }

    $LayoutObject->AddJSData(
        Key   => 'DynamicFieldNames',
        Value => $DynamicFieldNames,
    );

    my $LoadedFormDraft;
    if ( $Self->{LoadedFormDraftID} ) {
        $LoadedFormDraft = $Kernel::OM->Get('Kernel::System::FormDraft')->FormDraftGet(
            FormDraftID => $Self->{LoadedFormDraftID},
            GetContent  => 0,
            UserID      => $Self->{UserID},
        );

        my @Articles = $Kernel::OM->Get('Kernel::System::Ticket::Article')->ArticleList(
            TicketID => $Self->{TicketID},
            OnlyLast => 1,
        );

        if (@Articles) {
            my $LastArticle = $Articles[0];

            my $LastArticleSystemTime;
            if ( $LastArticle->{CreateTime} ) {
                my $LastArticleSystemTimeObject = $Kernel::OM->Create(
                    'Kernel::System::DateTime',
                    ObjectParams => {
                        String => $LastArticle->{CreateTime},
                    },
                );
                $LastArticleSystemTime = $LastArticleSystemTimeObject->ToEpoch();
            }

            my $FormDraftSystemTimeObject = $Kernel::OM->Create(
                'Kernel::System::DateTime',
                ObjectParams => {
                    String => $LoadedFormDraft->{ChangeTime},
                },
            );
            my $FormDraftSystemTime = $FormDraftSystemTimeObject->ToEpoch();

            if ( !$LastArticleSystemTime || $FormDraftSystemTime <= $LastArticleSystemTime ) {
                $Param{FormDraftOutdated} = 1;
            }
        }
    }

    if ( IsHashRefWithData($LoadedFormDraft) ) {

        $LoadedFormDraft->{ChangeByName} = $Kernel::OM->Get('Kernel::System::User')->UserName(
            UserID => $LoadedFormDraft->{ChangeBy},
        );
    }

    # create & return output
    return $LayoutObject->Output(
        TemplateFile => 'AgentTicketEmailOutbound',
        Data         => {
            %Param,
            FormDraft      => $Config->{FormDraft},
            FormDraftID    => $Self->{LoadedFormDraftID},
            FormDraftTitle => $LoadedFormDraft ? $LoadedFormDraft->{Title} : '',
            FormDraftMeta  => $LoadedFormDraft,
        },
    );
}

sub _GetFieldsToUpdate {
    my ( $Self, %Param ) = @_;

    my @UpdatableFields;

    # set the fields that can be updateable via AJAXUpdate
    if ( !$Param{OnlyDynamicFields} ) {
        @UpdatableFields = qw( ComposeStateID );
    }

    # get config for frontend module
    my $Config = $Kernel::OM->Get('Kernel::Config')->Get("Ticket::Frontend::$Self->{Action}");

    # get the dynamic fields for this screen
    my $DynamicField = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldListGet(
        Valid       => 1,
        ObjectType  => [ 'Ticket', 'Article' ],
        FieldFilter => $Config->{DynamicField} || {},
    );

    # cycle through the activated Dynamic Fields for this screen
    DYNAMICFIELD:
    for my $DynamicFieldConfig ( @{$DynamicField} ) {
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

sub _GetExtendedParams {
    my ( $Self, %Param ) = @_;

    # get param object
    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');

    # get params
    my %GetParam;
    for my $Key (
        qw(To Cc Bcc Subject Body ComposeStateID IsVisibleForCustomer IsVisibleForCustomerPresent
        ArticleID TimeUnits Year Month Day Hour Minute FormID FormDraftID Title)
        )
    {
        my $Value = $ParamObject->GetParam( Param => $Key );
        if ( defined $Value ) {
            $GetParam{$Key} = $Value;
        }
    }

    $GetParam{EmailTemplateID} = $ParamObject->GetParam( Param => 'EmailTemplateID' ) || '';

    # create form id
    if ( !$GetParam{FormID} ) {
        $GetParam{FormID} = $Kernel::OM->Get('Kernel::System::Web::UploadCache')->FormIDCreate();
    }

    # hash for check duplicated entries
    my %AddressesList;
    my @MultipleCustomer;
    my $CustomersNumber = $ParamObject->GetParam( Param => 'CustomerTicketCounterToCustomer' ) || 0;
    my $Selected        = $ParamObject->GetParam( Param => 'CustomerSelected' )                || '';

    # get check item object
    my $CheckItemObject = $Kernel::OM->Get('Kernel::System::CheckItem');

    if ($CustomersNumber) {
        my $CustomerCounter = 1;
        for my $Count ( 1 ... $CustomersNumber ) {
            my $CustomerElement  = $ParamObject->GetParam( Param => 'CustomerTicketText_' . $Count );
            my $CustomerSelected = ( $Selected eq $Count ? 'checked="checked"' : '' );
            my $CustomerKey      = $ParamObject->GetParam( Param => 'CustomerKey_' . $Count )
                || '';
            my $CustomerQueue = $ParamObject->GetParam( Param => 'CustomerQueue_' . $Count )
                || '';
            if ($CustomerElement) {

                if ( $GetParam{To} ) {
                    $GetParam{To} .= ', ' . $CustomerElement;
                }
                else {
                    $GetParam{To} = $CustomerElement;
                }

                # check email address
                my $CustomerErrorMsg = 'CustomerGenericServerErrorMsg';
                my $CustomerError    = '';
                for my $Email ( Mail::Address->parse($CustomerElement) ) {
                    if ( !$CheckItemObject->CheckEmail( Address => $Email->address() ) ) {
                        $CustomerErrorMsg = $CheckItemObject->CheckErrorType()
                            . 'ServerErrorMsg';
                        $CustomerError = 'ServerError';
                    }
                }

                # check for duplicated entries
                if ( defined $AddressesList{$CustomerElement} && $CustomerError eq '' ) {
                    $CustomerErrorMsg = 'IsDuplicatedServerErrorMsg';
                    $CustomerError    = 'ServerError';
                }

                my $CustomerDisabled = '';
                my $CountAux         = $CustomerCounter++;
                if ( $CustomerError ne '' ) {
                    $CustomerDisabled = 'disabled="disabled"';
                    $CountAux         = $Count . 'Error';
                }

                if ( $CustomerQueue ne '' ) {
                    $CustomerQueue = $Count;
                }

                push @MultipleCustomer, {
                    Count            => $CountAux,
                    CustomerElement  => $CustomerElement,
                    CustomerSelected => $CustomerSelected,
                    CustomerKey      => $CustomerKey,
                    CustomerError    => $CustomerError,
                    CustomerErrorMsg => $CustomerErrorMsg,
                    CustomerDisabled => $CustomerDisabled,
                    CustomerQueue    => $CustomerQueue,
                };
                $AddressesList{$CustomerElement} = 1;
            }
        }
    }

    my @MultipleCustomerCc;
    my $CustomersNumberCc = $ParamObject->GetParam( Param => 'CustomerTicketCounterCcCustomer' ) || 0;

    if ($CustomersNumberCc) {
        my $CustomerCounterCc = 1;
        for my $Count ( 1 ... $CustomersNumberCc ) {
            my $CustomerElementCc = $ParamObject->GetParam( Param => 'CcCustomerTicketText_' . $Count );
            my $CustomerKeyCc     = $ParamObject->GetParam( Param => 'CcCustomerKey_' . $Count )
                || '';
            my $CustomerQueueCc = $ParamObject->GetParam( Param => 'CcCustomerQueue_' . $Count )
                || '';

            if ($CustomerElementCc) {

                if ( $GetParam{Cc} ) {
                    $GetParam{Cc} .= ', ' . $CustomerElementCc;
                }
                else {
                    $GetParam{Cc} = $CustomerElementCc;
                }

                # check email address
                my $CustomerErrorMsgCc = 'CustomerGenericServerErrorMsg';
                my $CustomerErrorCc    = '';
                for my $Email ( Mail::Address->parse($CustomerElementCc) ) {
                    if ( !$CheckItemObject->CheckEmail( Address => $Email->address() ) ) {
                        $CustomerErrorMsgCc = $CheckItemObject->CheckErrorType()
                            . 'ServerErrorMsg';
                        $CustomerErrorCc = 'ServerError';
                    }
                }

                # check for duplicated entries
                if ( defined $AddressesList{$CustomerElementCc} && $CustomerErrorCc eq '' ) {
                    $CustomerErrorMsgCc = 'IsDuplicatedServerErrorMsg';
                    $CustomerErrorCc    = 'ServerError';
                }

                my $CustomerDisabledCc = '';
                my $CountAuxCc         = $CustomerCounterCc++;
                if ( $CustomerErrorCc ne '' ) {
                    $CustomerDisabledCc = 'disabled="disabled"';
                    $CountAuxCc         = $Count . 'Error';
                }

                if ( $CustomerQueueCc ne '' ) {
                    $CustomerQueueCc = $Count;
                }

                push @MultipleCustomerCc, {
                    Count            => $CountAuxCc,
                    CustomerElement  => $CustomerElementCc,
                    CustomerKey      => $CustomerKeyCc,
                    CustomerError    => $CustomerErrorCc,
                    CustomerErrorMsg => $CustomerErrorMsgCc,
                    CustomerDisabled => $CustomerDisabledCc,
                    CustomerQueue    => $CustomerQueueCc,
                };
                $AddressesList{$CustomerElementCc} = 1;
            }
        }
    }

    my @MultipleCustomerBcc;
    my $CustomersNumberBcc = $ParamObject->GetParam( Param => 'CustomerTicketCounterBccCustomer' ) || 0;

    if ($CustomersNumberBcc) {
        my $CustomerCounterBcc = 1;
        for my $Count ( 1 ... $CustomersNumberBcc ) {
            my $CustomerElementBcc = $ParamObject->GetParam( Param => 'BccCustomerTicketText_' . $Count );
            my $CustomerKeyBcc     = $ParamObject->GetParam( Param => 'BccCustomerKey_' . $Count )
                || '';
            my $CustomerQueueBcc = $ParamObject->GetParam( Param => 'BccCustomerQueue_' . $Count )
                || '';

            if ($CustomerElementBcc) {

                if ( $GetParam{Bcc} ) {
                    $GetParam{Bcc} .= ', ' . $CustomerElementBcc;
                }
                else {
                    $GetParam{Bcc} = $CustomerElementBcc;
                }

                # check email address
                my $CustomerErrorMsgBcc = 'CustomerGenericServerErrorMsg';
                my $CustomerErrorBcc    = '';
                for my $Email ( Mail::Address->parse($CustomerElementBcc) ) {
                    if ( !$CheckItemObject->CheckEmail( Address => $Email->address() ) ) {
                        $CustomerErrorMsgBcc = $CheckItemObject->CheckErrorType()
                            . 'ServerErrorMsg';
                        $CustomerErrorBcc = 'ServerError';
                    }
                }

                # check for duplicated entries
                if ( defined $AddressesList{$CustomerElementBcc} && $CustomerErrorBcc eq '' ) {
                    $CustomerErrorMsgBcc = 'IsDuplicatedServerErrorMsg';
                    $CustomerErrorBcc    = 'ServerError';
                }

                my $CustomerDisabledBcc = '';
                my $CountAuxBcc         = $CustomerCounterBcc++;
                if ( $CustomerErrorBcc ne '' ) {
                    $CustomerDisabledBcc = 'disabled="disabled"';
                    $CountAuxBcc         = $Count . 'Error';
                }

                if ( $CustomerQueueBcc ne '' ) {
                    $CustomerQueueBcc = $Count;
                }

                push @MultipleCustomerBcc, {
                    Count            => $CountAuxBcc,
                    CustomerElement  => $CustomerElementBcc,
                    CustomerKey      => $CustomerKeyBcc,
                    CustomerError    => $CustomerErrorBcc,
                    CustomerErrorMsg => $CustomerErrorMsgBcc,
                    CustomerDisabled => $CustomerDisabledBcc,
                    CustomerQueue    => $CustomerQueueBcc,
                };
                $AddressesList{$CustomerElementBcc} = 1;
            }
        }
    }

    return (
        GetParam            => \%GetParam,
        MultipleCustomer    => \@MultipleCustomer,
        MultipleCustomerCc  => \@MultipleCustomerCc,
        MultipleCustomerBcc => \@MultipleCustomerBcc,
    );
}

sub _GetStandardTemplates {
    my ( $Self, %Param ) = @_;

    if ( !$Param{QueueID} && !$Param{TicketID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Parameter 'QueueID' or 'TicketID' is needed!",
        );
        return {};
    }

    my $QueueID = $Param{QueueID} || '';
    if ( !$Param{QueueID} && $Param{TicketID} ) {

        # get QueueID from the ticket
        my %Ticket = $Kernel::OM->Get('Kernel::System::Ticket')->TicketGet(
            TicketID      => $Param{TicketID},
            DynamicFields => 0,
            UserID        => $Self->{UserID},
        );
        $QueueID = $Ticket{QueueID} || '';
    }

    # fetch all std. templates
    my %StandardTemplates = $Kernel::OM->Get('Kernel::System::Queue')->QueueStandardTemplateMemberList(
        QueueID       => $QueueID,
        TemplateTypes => 1,
    );

    # return empty hash if there are no templates for this screen
    return {} if !IsHashRefWithData( $StandardTemplates{Email} );

    # return just the templates for this screen
    return $StandardTemplates{Email};
}

1;
