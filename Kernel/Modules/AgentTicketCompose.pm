# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Modules::AgentTicketCompose;

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

    # get layout object
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # check needed stuff
    if ( !$Self->{TicketID} ) {
        return $LayoutObject->ErrorScreen(
            Message => Translatable('No TicketID is given!'),
            Comment => Translatable('Please contact the administrator.'),
        );
    }

    # get needed objects
    my $ConfigObject    = $Kernel::OM->Get('Kernel::Config');
    my $TicketObject    = $Kernel::OM->Get('Kernel::System::Ticket');
    my $ArticleObject   = $Kernel::OM->Get('Kernel::System::Ticket::Article');
    my $HTMLUtilsObject = $Kernel::OM->Get('Kernel::System::HTMLUtils');

    my $ArticleBackendObject = $ArticleObject->BackendForChannel( ChannelName => 'Email' );

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
        return $LayoutObject->NoPermission(
            Message => $LayoutObject->{LanguageObject}->Translate( 'You need %s permissions!', $Config->{Permission} ),
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

    my %Ticket = $TicketObject->TicketGet(
        TicketID      => $Self->{TicketID},
        DynamicFields => 1
    );

    # get lock state
    my $TicketBackType = 'TicketBack';
    if ( $Config->{RequiredLock} ) {
        if ( !$TicketObject->TicketLockGet( TicketID => $Self->{TicketID} ) ) {

            my $Lock = $TicketObject->TicketLockSet(
                TicketID => $Self->{TicketID},
                Lock     => 'lock',
                UserID   => $Self->{UserID}
            );

            # Set new owner if ticket owner is different then logged user.
            if ( $Lock && ( $Ticket{OwnerID} != $Self->{UserID} ) ) {

                # Remember previous owner, which will be used to restore ticket owner on undo action.
                $Ticket{PreviousOwner} = $Ticket{OwnerID};

                my $Success = $TicketObject->TicketOwnerSet(
                    TicketID  => $Self->{TicketID},
                    UserID    => $Self->{UserID},
                    NewUserID => $Self->{UserID},
                );

                # Show lock state.
                if ( !$Success ) {
                    return $LayoutObject->FatalError();
                }
            }

            $TicketBackType .= 'Undo';
        }
        else {
            my $AccessOk = $TicketObject->OwnerCheck(
                TicketID => $Self->{TicketID},
                OwnerID  => $Self->{UserID},
            );
            if ( !$AccessOk ) {
                my $Output = $LayoutObject->Header(
                    Value     => $Ticket{Number},
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
        }
    }

    # get param object
    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');

    # get params
    my %GetParam;
    for my $Needed (
        qw(
        To Cc Bcc Subject Body InReplyTo References ResponseID ReplyArticleID StateID ArticleID
        IsVisibleForCustomerPresent IsVisibleForCustomer TimeUnits Year Month Day Hour Minute FormID ReplyAll
        FormDraftID Title
        )
        )
    {
        $GetParam{$Needed} = $ParamObject->GetParam( Param => $Needed );
    }

    # Make sure sender is correct one. See bug#14872 ( https://bugs.otrs.org/show_bug.cgi?id=14872 ).
    $GetParam{From} = $Kernel::OM->Get('Kernel::System::TemplateGenerator')->Sender(
        QueueID => $Ticket{QueueID},
        UserID  => $Self->{UserID},
    );

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

    # get Dynamic fields form ParamObject
    my %DynamicFieldValues;

    # get backend object
    my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    # get the dynamic fields for this screen
    my $DynamicField = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldListGet(
        Valid       => 1,
        ObjectType  => [ 'Ticket', 'Article' ],
        FieldFilter => $Config->{DynamicField} || {},
    );

    # cycle trough the activated Dynamic Fields for this screen
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

    # get needed objects
    my $UploadCacheObject = $Kernel::OM->Get('Kernel::System::Web::UploadCache');
    my $MainObject        = $Kernel::OM->Get('Kernel::System::Main');

    # send email
    if ( $Self->{Subaction} eq 'SendEmail' || $Self->{LoadedFormDraftID} ) {

        # challenge token check for write action
        if ( !$Self->{LoadedFormDraftID} ) {
            $LayoutObject->ChallengeTokenCheck();
        }

        # get valid state id
        if ( !$GetParam{StateID} ) {
            my %Ticket = $TicketObject->TicketGet(
                TicketID => $Self->{TicketID},
                UserID   => 1,
            );
            $GetParam{StateID} = $Ticket{StateID};
        }

        my %StateData = $Kernel::OM->Get('Kernel::System::State')->StateGet( ID => $GetParam{StateID} );

        my %Error;

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

        if ( $Error{ToIsLocalAddress} ) {
            $LayoutObject->Block(
                Name => 'ToIsLocalAddressServerErrorMsg',
                Data => \%GetParam,
            );
        }

        if ( $Error{CcIsLocalAddress} ) {
            $LayoutObject->Block(
                Name => 'CcIsLocalAddressServerErrorMsg',
                Data => \%GetParam,
            );
        }

        if ( $Error{BccIsLocalAddress} ) {
            $LayoutObject->Block(
                Name => 'BccIsLocalAddressServerErrorMsg',
                Data => \%GetParam,
            );
        }

        # get all attachments meta data
        my @Attachments = $UploadCacheObject->FormIDGetAllFilesMeta(
            FormID => $Self->{FormID},
        );

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

        # check pending date
        if ( $StateData{TypeName} && $StateData{TypeName} =~ /^pending/i ) {

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

            if (
                ( !$PendingDateTimeObject || $PendingDateTimeObject < $CurSystemDateTimeObject )
                )
            {
                $Error{DateInvalid} = 'ServerError';
            }
        }

        # check if at least one recipient has been chosen
        if ( !$GetParam{To} ) {
            $Error{'ToInvalid'} = 'ServerError';
        }

        # check some values
        LINE:
        for my $Line (qw(To Cc Bcc)) {
            next LINE if !$GetParam{$Line};
            for my $Email ( Mail::Address->parse( $GetParam{$Line} ) ) {
                if ( !$CheckItemObject->CheckEmail( Address => $Email->address() ) ) {
                    $Error{ $Line . 'Invalid' } = 'ServerError';
                }
            }
        }

        # check subject
        if ( !$GetParam{Subject} ) {
            $Error{SubjectInvalid} = ' ServerError';
        }

        # check body
        if ( !$GetParam{Body} ) {
            $Error{BodyInvalid} = ' ServerError';
        }

        # check time units
        if (
            $ConfigObject->Get('Ticket::Frontend::AccountTime')
            && $ConfigObject->Get('Ticket::Frontend::NeedAccountedTime')
            && $GetParam{TimeUnits} eq ''
            )
        {
            $Error{TimeUnitsInvalid} = 'ServerError';
        }

        # prepare subject
        my $Tn = $TicketObject->TicketNumberLookup( TicketID => $Self->{TicketID} );
        $GetParam{Subject} = $TicketObject->TicketSubjectBuild(
            TicketNumber => $Tn,
            Subject      => $GetParam{Subject} || '',
        );

        my %ArticleParam;

        # run compose modules
        if ( ref $ConfigObject->Get('Ticket::Frontend::ArticleComposeModule') eq 'HASH' ) {

            # use ticket QueueID in compose modules
            $GetParam{QueueID} = $Ticket{QueueID};

            my %Jobs = %{ $ConfigObject->Get('Ticket::Frontend::ArticleComposeModule') };
            for my $Job ( sort keys %Jobs ) {

                # load module
                if ( !$MainObject->Require( $Jobs{$Job}->{Module} ) ) {
                    return $LayoutObject->FatalError();
                }
                my $Object = $Jobs{$Job}->{Module}->new( %{$Self}, Debug => $Self->{Debug} );

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

        # create html strings for all dynamic fields
        my %DynamicFieldHTML;

        # cycle trough the activated Dynamic Fields for this screen
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
                    Message => $LayoutObject->{LanguageObject}->Translate(
                        'Could not perform validation on field %s!',
                        $DynamicFieldConfig->{Label},
                    ),
                    Comment => Translatable('Please contact the administrator.'),
                );
            }

            # propagate validation error to the Error variable to be detected by the frontend
            if ( $ValidationResult->{ServerError} ) {
                $Error{ $DynamicFieldConfig->{Name} } = ' ServerError';
            }

            # get field html
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

        if ( $Self->{LoadedFormDraftID} ) {

            # Make sure we don't save form if a draft was loaded.
            %Error = ( LoadedFormDraft => 1 );
        }

        # check if there is an error
        if (%Error) {

            my $Output = $LayoutObject->Header(
                Value     => $Ticket{TicketNumber},
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

            $GetParam{StandardResponse} = $GetParam{Body};
            $Output .= $Self->_Mask(
                TicketID   => $Self->{TicketID},
                NextStates => $Self->_GetNextStates(
                    %GetParam,
                ),
                ResponseFormat      => $LayoutObject->Ascii2Html( Text => $GetParam{Body} ),
                Errors              => \%Error,
                MultipleCustomer    => \@MultipleCustomer,
                MultipleCustomerCc  => \@MultipleCustomerCc,
                MultipleCustomerBcc => \@MultipleCustomerBcc,
                Attachments         => \@Attachments,
                GetParam            => \%GetParam,
                TicketBackType      => $TicketBackType,
                %Ticket,
                DynamicFieldHTML => \%DynamicFieldHTML,
                %GetParam,
            );
            $Output .= $LayoutObject->Footer(
                Type => 'Small',
            );
            return $Output;
        }

        # replace <OTRS_TICKET_STATE> with next ticket state name
        if ( $StateData{Name} ) {
            $GetParam{Body} =~ s/<OTRS_TICKET_STATE>/$StateData{Name}/g;
            $GetParam{Body} =~ s/&lt;OTRS_TICKET_STATE&gt;/$StateData{Name}/g;
        }

        # get pre loaded attachments
        my @AttachmentData = $UploadCacheObject->FormIDGetAllFilesData(
            FormID => $Self->{FormID},
        );

        # get submit attachment
        my %UploadStuff = $ParamObject->GetUploadAll(
            Param => 'FileUpload',
        );
        if (%UploadStuff) {
            push @AttachmentData, \%UploadStuff;
        }

        # get recipients
        my $Recipients = '';
        LINE:
        for my $Line (qw(To Cc Bcc)) {

            next LINE if !$GetParam{$Line};

            if ($Recipients) {
                $Recipients .= ', ';
            }
            $Recipients .= $GetParam{$Line};
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

                    # IF the image is referenced in the body set it as inline.
                    if ( $GetParam{Body} =~ /(\Q$ContentIDHTMLQuote\E|\Q$ContentID\E)/i ) {
                        $Attachment->{Disposition} = 'inline';
                    }
                    elsif ( $Attachment->{Disposition} eq 'inline' ) {

                        # Ignore attachment if not linked in body.
                        next ATTACHMENT;
                    }
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

        my $IsVisibleForCustomer = $Config->{IsVisibleForCustomerDefault};
        if ( $GetParam{IsVisibleForCustomerPresent} ) {
            $IsVisibleForCustomer = $GetParam{IsVisibleForCustomer} ? 1 : 0;
        }

        # Get attributes like sender address
        my %Data = $Kernel::OM->Get('Kernel::System::TemplateGenerator')->Attributes(
            TicketID => $Self->{TicketID},
            Data     => {},
            UserID   => $Self->{UserID},
        );

        # send email
        my $ArticleID = $ArticleBackendObject->ArticleSend(
            IsVisibleForCustomer => $IsVisibleForCustomer,
            SenderType           => 'agent',
            TicketID             => $Self->{TicketID},
            HistoryType          => 'SendAnswer',
            HistoryComment       => "\%\%$Recipients",
            From                 => $Data{From},
            To                   => $GetParam{To},
            Cc                   => $GetParam{Cc},
            Bcc                  => $GetParam{Bcc},
            Subject              => $GetParam{Subject},
            UserID               => $Self->{UserID},
            Body                 => $GetParam{Body},
            InReplyTo            => $GetParam{InReplyTo},
            References           => $GetParam{References},
            Charset              => $LayoutObject->{UserCharset},
            MimeType             => $MimeType,
            Attachment           => \@AttachmentData,
            %ArticleParam,
        );

        # error page
        if ( !$ArticleID ) {
            return $LayoutObject->ErrorScreen();
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
        # cycle trough the activated Dynamic Fields for this screen
        DYNAMICFIELD:
        for my $DynamicFieldConfig ( @{$DynamicField} ) {
            next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

            # set the object ID (TicketID or ArticleID) depending on the field configration
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
        $TicketObject->TicketStateSet(
            TicketID  => $Self->{TicketID},
            ArticleID => $ArticleID,
            StateID   => $GetParam{StateID},
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
                Year     => $GetParam{Year},
                Month    => $GetParam{Month},
                Day      => $GetParam{Day},
                Hour     => $GetParam{Hour},
                Minute   => $GetParam{Minute},
            );
        }

        # log use response id and reply article id (useful for response diagnostics)
        $TicketObject->HistoryAdd(
            Name         => "ResponseTemplate ($GetParam{ResponseID}/$GetParam{ReplyArticleID}/$ArticleID)",
            HistoryType  => 'Misc',
            TicketID     => $Self->{TicketID},
            CreateUserID => $Self->{UserID},
        );

        # remove pre submited attachments
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
            $StateData{TypeName} =~ /^close/i
            && !$ConfigObject->Get('Ticket::Frontend::RedirectAfterCloseDisabled')
            )
        {
            return $LayoutObject->PopupClose(
                URL => ( $Self->{LastScreenOverview} || 'Action=AgentDashboard' ),
            );
        }

        # load new URL in parent window and close popup
        return $LayoutObject->PopupClose(
            URL => "Action=AgentTicketZoom;TicketID=$Self->{TicketID};ArticleID=$ArticleID",
        );
    }

    # check for SMIME / PGP if customer has changed
    elsif ( $Self->{Subaction} eq 'AJAXUpdate' ) {

        my @ExtendedData;

        # run compose modules
        if ( ref $ConfigObject->Get('Ticket::Frontend::ArticleComposeModule') eq 'HASH' ) {

            # use ticket QueueID in compose modules
            $GetParam{QueueID} = $Ticket{QueueID};

            my %Jobs = %{ $ConfigObject->Get('Ticket::Frontend::ArticleComposeModule') };
            JOB:
            for my $Job ( sort keys %Jobs ) {

                # load module
                next JOB if !$MainObject->Require( $Jobs{$Job}->{Module} );

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
                            Max          => 150,
                        }
                    );
                }
            }
        }

        my $NextStates = $Self->_GetNextStates(
            %GetParam,
        );

        # update Dynamic Fields Possible Values via AJAX
        my @DynamicFieldAJAX;

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
                @ExtendedData,
                {
                    Name         => 'StateID',
                    Data         => $NextStates,
                    SelectedID   => $GetParam{StateID},
                    Translation  => 1,
                    PossibleNone => 1,
                    Max          => 100,
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
    elsif ( $Self->{Subaction} eq 'CheckSubject' ) {

        # Inform a user that article subject will be empty if contains only the ticket hook (if nothing is modified).
        my $Message = $LayoutObject->{LanguageObject}->Translate(
            'Article subject will be empty if the subject contains only the ticket hook!'
        );

        my $Subject = $ParamObject->GetParam( Param => 'Subject' );

        my $CleanedSubject = $TicketObject->TicketSubjectClean(
            TicketNumber => $Ticket{TicketNumber},
            Subject      => $Subject,
        );

        my $Empty = !length $CleanedSubject;

        my $JSON = $LayoutObject->JSONEncode(
            Data => {
                Empty   => $Empty ? 1 : 0,
                Message => $Message,
            }
        );

        return $LayoutObject->Attachment(
            ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
            Content     => $JSON,
            Type        => 'inline',
            NoCache     => 1,
        );
    }
    else {
        my $Output = $LayoutObject->Header(
            Value     => $Ticket{TicketNumber},
            Type      => 'Small',
            BodyClass => 'Popup',
        );

        # get std attachment object
        my $StdAttachmentObject = $Kernel::OM->Get('Kernel::System::StdAttachment');

        # add std. attachments to email
        if ( $GetParam{ResponseID} ) {
            my %AllStdAttachments = $StdAttachmentObject->StdAttachmentStandardTemplateMemberList(
                StandardTemplateID => $GetParam{ResponseID},
            );
            for my $ID ( sort keys %AllStdAttachments ) {
                my %Data = $StdAttachmentObject->StdAttachmentGet( ID => $ID );
                $UploadCacheObject->FormIDAddFile(
                    FormID      => $Self->{FormID},
                    Disposition => 'attachment',
                    %Data,
                );
            }
        }

        # get all attachments meta data
        my @Attachments = $UploadCacheObject->FormIDGetAllFilesMeta(
            FormID => $Self->{FormID},
        );

        # get last customer article or selected article ...
        my @ArticleList;

        if ( $GetParam{ArticleID} ) {

            @ArticleList = $ArticleObject->ArticleList(
                TicketID  => $Self->{TicketID},
                ArticleID => $GetParam{ArticleID},
            );
        }
        else {

            @ArticleList = $ArticleObject->ArticleList(
                TicketID             => $Self->{TicketID},
                IsVisibleForCustomer => 1,
                OnlyLast             => 1,
            );
        }

        my %Data;

        ARTICLEMETADATA:
        for my $ArticleMetaData (@ArticleList) {

            next ARTICLEMETADATA if !$ArticleMetaData;
            next ARTICLEMETADATA if !IsHashRefWithData($ArticleMetaData);

            my $CurrentArticleBackendObject = $ArticleObject->BackendForArticle( %{$ArticleMetaData} );

            %Data = $CurrentArticleBackendObject->ArticleGet(
                TicketID  => $Self->{TicketID},
                ArticleID => $ArticleMetaData->{ArticleID},
            );

            $Data{CommunicationChannelName} = $CurrentArticleBackendObject->ChannelNameGet();

            last ARTICLEMETADATA;
        }

        # Merge ticket data with article data, see bug#13995 (https://bugs.otrs.org/show_bug.cgi?id=13995).
        %Data = ( %Ticket, %Data );

        # If article is not a MIMEBase article, get customer recipients from the backend.
        if ( !$Data{To} && !$Data{From} ) {
            my @CustomerUserIDs = $LayoutObject->ArticleCustomerRecipientsGet(
                TicketID  => $Self->{TicketID},
                ArticleID => $Data{ArticleID},
                UserID    => $Self->{UserID},
            );

            my $CustomerUserObject = $Kernel::OM->Get('Kernel::System::CustomerUser');

            my @CustomerRecipients;

            CUSTOMER_USER_ID:
            for my $CustomerUserID (@CustomerUserIDs) {
                my %Customer = $CustomerUserObject->CustomerUserDataGet(
                    User => $CustomerUserID,
                );
                next CUSTOMER_USER_ID if !%Customer;

                push @CustomerRecipients, "\"$Customer{UserFirstname} $Customer{UserLastname}\" <$Customer{UserEmail}>";
            }

            $Data{To} = join( ',', @CustomerRecipients ) // '';

            # Include sender name in 'From' field for correct quoting.
            my %ArticleFields = $LayoutObject->ArticleFields(
                TicketID  => $Self->{TicketID},
                ArticleID => $Data{ArticleID},
            );
            $Data{From} = $ArticleFields{Sender}->{Value} // '';
        }

        # set OrigFrom for correct email quoting (xxxx wrote)
        $Data{OrigFrom} = $Data{From};

        # check article type and replace To with From (in case)
        if ( $Data{SenderType} !~ /customer/ ) {

            # replace From/To, To/From because sender is agent
            my $To = $Data{To};
            $Data{To}   = $Data{From};
            $Data{From} = $To;

            $Data{ReplyTo} = '';
        }

        # build OrigFromName (to only use the realname)
        $Data{OrigFromName} = $Data{OrigFrom};
        $Data{OrigFromName} =~ s/<.*>|\(.*\)|\"|;|,//g;
        $Data{OrigFromName} =~ s/( $)|(  $)//g;

        # Fallback to OrigFrom if realname part is empty.
        if ( !$Data{OrigFromName} ) {
            $Data{OrigFromName} = $Data{OrigFrom};
        }

        # get customer data
        my %Customer;
        if ( $Ticket{CustomerUserID} ) {
            %Customer = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerUserDataGet(
                User => $Ticket{CustomerUserID}
            );
        }

        # get article to quote
        $Data{Body} = $LayoutObject->ArticleQuote(
            TicketID          => $Self->{TicketID},
            ArticleID         => $Data{ArticleID},
            FormID            => $Self->{FormID},
            UploadCacheObject => $UploadCacheObject,
        );

        my %SafetyCheckResult = $HTMLUtilsObject->Safety(
            String => $Data{Body},

            # Strip out external content if BlockLoadingRemoteContent is enabled.
            NoExtSrcLoad => $ConfigObject->Get('Ticket::Frontend::BlockLoadingRemoteContent'),

            # Disallow potentially unsafe content.
            NoApplet     => 1,
            NoObject     => 1,
            NoEmbed      => 1,
            NoSVG        => 1,
            NoJavaScript => 1,
        );
        $Data{Body} = $SafetyCheckResult{String};

        # restrict number of body lines if configured
        my $ResponseQuoteMaxLines = $ConfigObject->Get('Ticket::Frontend::ResponseQuoteMaxLines');
        if (
            IsStringWithData( $Data{Body} )
            && $ResponseQuoteMaxLines
            )
        {
            $Data{Body} = $HTMLUtilsObject->TruncateBodyQuote(
                Body       => $Data{Body},
                Limit      => $ResponseQuoteMaxLines,
                HTMLOutput => $LayoutObject->{BrowserRichText},
            ) // $Data{Body};
        }

        if ( $LayoutObject->{BrowserRichText} ) {

            # prepare body, subject, ReplyTo ...
            # rewrap body if exists
            if ( $Data{Body} ) {
                $Data{Body} =~ s/\t/ /g;

                my $Quote = $LayoutObject->Ascii2Html(
                    Text           => $ConfigObject->Get('Ticket::Frontend::Quote') || '',
                    HTMLResultMode => 1,
                );
                if ($Quote) {

                    # quote text
                    $Data{Body} = "<blockquote type=\"cite\">$Data{Body}</blockquote>\n";

                    # cleanup not compat. tags
                    $Data{Body} = $LayoutObject->RichTextDocumentCleanup(
                        String => $Data{Body},
                    );

                }
                else {
                    $Data{Body} = "<br/>" . $Data{Body};

                    if ( $Data{CreateTime} ) {
                        $Data{Body} = $LayoutObject->{LanguageObject}->Translate('Date') .
                            ": $Data{CreateTime}<br/>" . $Data{Body};
                    }

                    for my $Key (qw(Subject ReplyTo Reply-To Cc To From)) {
                        if ( $Data{$Key} ) {
                            $Data{Body} = $LayoutObject->{LanguageObject}->Translate($Key) .
                                ": $Data{$Key}<br/>" . $Data{Body};
                        }
                    }

                    my $From = $LayoutObject->Ascii2RichText(
                        String => $Data{From},
                    );

                    my $MessageFrom = $LayoutObject->{LanguageObject}->Translate('Message from');
                    my $EndMessage  = $LayoutObject->{LanguageObject}->Translate('End message');

                    $Data{Body} = "<br/>---- $MessageFrom $From ---<br/><br/>" . $Data{Body};
                    $Data{Body} .= "<br/>---- $EndMessage ---<br/>";
                }
            }
        }
        else {

            # prepare body, subject, ReplyTo ...
            # re-wrap body if exists
            if ( $Data{Body} ) {
                $Data{Body} =~ s/\t/ /g;

                my $Quote = $ConfigObject->Get('Ticket::Frontend::Quote');
                if ($Quote) {
                    $Data{Body} =~ s/\n/\n$Quote /g;
                    $Data{Body} = "\n$Quote " . $Data{Body};
                }
                else {
                    $Data{Body} = "\n" . $Data{Body};
                    if ( $Data{CreateTime} ) {
                        $Data{Body} = $LayoutObject->{LanguageObject}->Translate('Date') .
                            ": $Data{CreateTime}\n" . $Data{Body};
                    }

                    for my $Key (qw(Subject ReplyTo Reply-To Cc To From)) {
                        if ( $Data{$Key} ) {
                            $Data{Body} = $LayoutObject->{LanguageObject}->Translate($Key) .
                                ": $Data{$Key}\n" . $Data{Body};
                        }
                    }

                    my $MessageFrom = $LayoutObject->{LanguageObject}->Translate('Message from');
                    my $EndMessage  = $LayoutObject->{LanguageObject}->Translate('End message');

                    $Data{Body} = "\n---- $MessageFrom $Data{From} ---\n\n" . $Data{Body};
                    $Data{Body} .= "\n---- $EndMessage ---\n";
                }
            }
        }

        # get system address object
        my $SystemAddress = $Kernel::OM->Get('Kernel::System::SystemAddress');

        # add not local To addresses to Cc
        for my $Email ( Mail::Address->parse( $Data{To} ) ) {
            my $IsLocal = $SystemAddress->SystemAddressIsLocalAddress(
                Address => $Email->address(),
            );
            if ( !$IsLocal ) {
                if ( $Data{Cc} ) {
                    $Data{Cc} .= ', ';
                }
                $Data{Cc} .= $Email->format();
            }
        }

        # check ReplyTo
        if ( $Data{ReplyTo} ) {
            $Data{To} = $Data{ReplyTo};
        }
        else {
            $Data{To} = $Data{From};

            # try to remove some wrong text to from line (by way of ...)
            # added by some strange mail programs on bounce
            $Data{To} =~ s/(.+?\<.+?\@.+?\>)\s+\(by\s+way\s+of\s+.+?\)/$1/ig;
        }

        # get to email (just "some@example.com")
        for my $Email ( Mail::Address->parse( $Data{To} ) ) {
            $Data{ToEmail} = $Email->address();
        }

        # only reply to sender
        if ( !$GetParam{ReplyAll} ) {
            $Data{Cc}  = '';
            $Data{Bcc} = '';
        }

        # use customer database email
        # do not add customer email to cc, if article is visible for customer
        if (
            $ConfigObject->Get('Ticket::Frontend::ComposeAddCustomerAddress')
            && $Data{IsVisibleForCustomer}
            )
        {
            # check if customer is in recipient list
            if ( $Customer{UserEmail} && $Data{ToEmail} !~ /^\Q$Customer{UserEmail}\E$/i ) {

                if ( $Data{SenderType} eq 'agent' && !$Data{IsVisibleForCustomer} ) {
                    if ( $Data{To} ) {
                        $Data{To} .= ', ' . $Customer{UserEmail};
                    }
                    else {
                        $Data{To} = $Customer{UserEmail};
                    }
                }

                # replace To with customers database address
                elsif ( $ConfigObject->Get('Ticket::Frontend::ComposeReplaceSenderAddress') ) {

                    $Output .= $LayoutObject->Notify(
                        Data => $LayoutObject->{LanguageObject}->Translate(
                            'Address %s replaced with registered customer address.',
                            $Data{ToEmail},
                        ),

                    );
                    $Data{To} = $Customer{UserEmail};
                }

                # add customers database address to Cc
                else {
                    $Output .= $LayoutObject->Notify(
                        Info => Translatable("Customer user automatically added in Cc."),
                    );
                    if ( $Data{Cc} ) {
                        $Data{Cc} .= ', ' . $Customer{UserEmail};
                    }
                    else {
                        $Data{Cc} = $Customer{UserEmail};
                    }
                }
            }
        }

        # find duplicate addresses
        my %Recipient;
        for my $Type (qw(To Cc Bcc)) {
            if ( $Data{$Type} ) {
                my $NewLine = '';
                for my $Email ( Mail::Address->parse( $Data{$Type} ) ) {
                    my $Address = lc $Email->address();

                    # only use email addresses with @ inside
                    if ( $Address && $Address =~ /@/ && !$Recipient{$Address} ) {
                        $Recipient{$Address} = 1;
                        my $IsLocal = $SystemAddress->SystemAddressIsLocalAddress(
                            Address => $Address,
                        );
                        if ( !$IsLocal ) {
                            if ($NewLine) {
                                $NewLine .= ', ';
                            }
                            $NewLine .= $Email->format();
                        }
                    }
                }
                $Data{$Type} = $NewLine;
            }
        }

        # get template
        my $TemplateGenerator = $Kernel::OM->Get('Kernel::System::TemplateGenerator');

        # use key StdResponse to pass the data to the template for legacy reasons,
        #   because existing systems may have it in their configuration as that was
        #   the key used before the internal switch to StandardResponse And StandardTemplate

        $Data{StdResponse} = $TemplateGenerator->Template(
            TicketID   => $Self->{TicketID},
            ArticleID  => $GetParam{ArticleID},
            TemplateID => $GetParam{ResponseID},
            Data       => \%Data,
            UserID     => $Self->{UserID},
        );

        # get salutation
        $Data{Salutation} = $TemplateGenerator->Salutation(
            TicketID => $Self->{TicketID},
            Data     => \%Data,
            UserID   => $Self->{UserID},
        );

        # get signature
        $Data{Signature} = $TemplateGenerator->Signature(
            TicketID => $Self->{TicketID},
            Data     => \%Data,
            UserID   => $Self->{UserID},
        );

        # $TemplateGenerator->Attributes() does not overwrite %Data, but it adds more keys
        %Data = $TemplateGenerator->Attributes(
            TicketID  => $Self->{TicketID},
            ArticleID => $GetParam{ArticleID},
            Data      => \%Data,
            UserID    => $Self->{UserID},
        );

        my $ResponseFormat = $ConfigObject->Get('Ticket::Frontend::ResponseFormat');

        # make sure body is rich text
        my %DataHTML = %Data;
        if ( $LayoutObject->{BrowserRichText} ) {
            if ($ResponseFormat) {
                $ResponseFormat = $LayoutObject->Ascii2RichText(
                    String => $ResponseFormat,
                );

                # restore qdata formatting for Output replacement
                $ResponseFormat =~ s/&quot;/"/gi;

                # html quote to have it correct in edit area
                $ResponseFormat = $LayoutObject->Ascii2Html(
                    Text => $ResponseFormat,
                );

                # restore qdata formatting for Output replacement
                $ResponseFormat =~ s/&quot;/"/gi;
            }

            # quote all non html content to have it correct in edit area
            KEY:
            for my $Key ( sort keys %DataHTML ) {
                next KEY if !$DataHTML{$Key};
                next KEY if $Key eq 'Salutation';
                next KEY if $Key eq 'Body';
                next KEY if $Key eq 'StdResponse';
                next KEY if $Key eq 'Signature';
                $DataHTML{$Key} = $LayoutObject->Ascii2RichText(
                    String => $DataHTML{$Key},
                );
            }
        }

        # build new repsonse format based on template
        $Data{ResponseFormat} = $LayoutObject->Output(
            Template => $ResponseFormat,
            Data     => { %Param, %DataHTML },
        );

        # check some values
        my %Error;
        LINE:
        for my $Line (qw(To Cc Bcc)) {
            next LINE if !$Data{$Line};
            for my $Email ( Mail::Address->parse( $Data{$Line} ) ) {
                if ( !$CheckItemObject->CheckEmail( Address => $Email->address() ) ) {
                    $Error{ $Line . "Invalid" } = " ServerError";
                }
            }
        }
        if ( $Data{From} ) {
            for my $Email ( Mail::Address->parse( $Data{From} ) ) {
                if ( !$CheckItemObject->CheckEmail( Address => $Email->address() ) ) {
                    $Error{"FromInvalid"} .= $CheckItemObject->CheckError();
                }
            }
        }

        # create html strings for all dynamic fields
        my %DynamicFieldHTML;

        # cycle trough the activated Dynamic Fields for this screen
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
            # generates a new article, then article fields will be always empty at the beginign)
            if ( $DynamicFieldConfig->{ObjectType} eq 'Ticket' ) {

                # get value stored on the database from Ticket
                $Value = $Ticket{ 'DynamicField_' . $DynamicFieldConfig->{Name} };
            }

            # get field html
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

        # build references if exist
        my $References = ( $Data{MessageID} || '' ) . ( $Data{References} || '' );

        # run compose modules
        if ( ref $ConfigObject->Get('Ticket::Frontend::ArticleComposeModule') eq 'HASH' ) {

            # use ticket QueueID in compose modules
            $GetParam{QueueID} = $Ticket{QueueID};

            my %Jobs = %{ $ConfigObject->Get('Ticket::Frontend::ArticleComposeModule') };
            for my $Job ( sort keys %Jobs ) {

                # load module
                if ( !$MainObject->Require( $Jobs{$Job}->{Module} ) ) {
                    return $LayoutObject->FatalError();
                }
                my $Object = $Jobs{$Job}->{Module}->new( %{$Self}, Debug => $Self->{Debug} );

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
                my $NewParams = $Object->Run( %GetParam, Config => $Jobs{$Job} );

                if ($NewParams) {
                    for my $Parameter ( $Object->Option( %GetParam, Config => $Jobs{$Job} ) ) {
                        $GetParam{$Parameter} = $NewParams;
                    }
                }

                # get errors
                %Error = (
                    %Error,
                    $Object->Error( %GetParam, Config => $Jobs{$Job} ),
                );
            }
        }

        # build view ...
        $Output .= $Self->_Mask(
            TicketID   => $Self->{TicketID},
            NextStates => $Self->_GetNextStates(
                %GetParam,
            ),
            Attachments         => \@Attachments,
            Errors              => \%Error,
            MultipleCustomer    => \@MultipleCustomer,
            MultipleCustomerCc  => \@MultipleCustomerCc,
            MultipleCustomerBcc => \@MultipleCustomerBcc,
            GetParam            => \%GetParam,
            ResponseID          => $GetParam{ResponseID},
            ReplyArticleID      => $GetParam{ArticleID},
            %Ticket,
            %Data,
            InReplyTo        => $Data{MessageID},
            References       => "$References",
            TicketBackType   => $TicketBackType,
            DynamicFieldHTML => \%DynamicFieldHTML,
        );
        $Output .= $LayoutObject->Footer(
            Type => 'Small',
        );
        return $Output;
    }
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

    # get needed objects
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # get config for frontend module
    my $Config = $ConfigObject->Get("Ticket::Frontend::$Self->{Action}");

    my %State;
    if ( $Param{GetParam}->{StateID} ) {
        $State{SelectedID} = $Param{GetParam}->{StateID};
    }
    else {
        $State{SelectedValue} = $Config->{StateDefault};
    }
    $Param{NextStatesStrg} = $LayoutObject->BuildSelection(
        Data         => $Param{NextStates},
        Name         => 'StateID',
        PossibleNone => 1,
        %State,
        %Param,
        Class => 'Modernize',
    );

    my $IsVisibleForCustomer = $Config->{IsVisibleForCustomerDefault};
    if ( $Param{GetParam}->{IsVisibleForCustomerPresent} ) {
        $IsVisibleForCustomer = $Param{GetParam}->{IsVisibleForCustomer} ? 1 : 0;
    }

    $LayoutObject->Block(
        Name => 'IsVisibleForCustomer',
        Data => {
            IsVisibleForCustomer => $IsVisibleForCustomer,
        },
    );

    # prepare errors!
    if ( $Param{Errors} ) {
        for my $Error ( sort keys %{ $Param{Errors} } ) {
            $Param{$Error} = $LayoutObject->Ascii2Html(
                Text => $Param{Errors}->{$Error},
            );
        }
    }

    # get used calendar
    my $Calendar = $Kernel::OM->Get('Kernel::System::Ticket')->TicketCalendarGet(
        QueueID => $Param{QueueID},
        SLAID   => $Param{SLAID},
    );

    # pending data string
    $Param{PendingDateString} = $LayoutObject->BuildDateSelection(
        %Param,
        Format               => 'DateInputFormatLong',
        YearPeriodPast       => 0,
        YearPeriodFuture     => 5,
        DiffTime             => $ConfigObject->Get('Ticket::Frontend::PendingDiffTime') || 0,
        Class                => $Param{Errors}->{DateInvalid} || ' ',
        Validate             => 1,
        ValidateDateInFuture => 1,
        Calendar             => $Calendar,
    );

    # Multiple-Autocomplete
    $Param{To} = ( scalar @{ $Param{MultipleCustomer} } ? '' : $Param{To} );
    if ( defined $Param{To} && $Param{To} ne '' ) {
        $Param{ToInvalid} = '';
    }

    $Param{Cc} = ( scalar @{ $Param{MultipleCustomerCc} } ? '' : $Param{Cc} );
    if ( defined $Param{Cc} && $Param{Cc} ne '' ) {
        $Param{CcInvalid} = '';
    }

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
            CustomerCounter => $CustomerCounterCc,
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
            CustomerCounter => $CustomerCounter,
        },
    );

    if ( $Param{ToInvalid} && $Param{Errors} ) {
        $LayoutObject->Block(
            Name => 'ToServerErrorMsg',
        );
    }

    my $CustomerUserObject = $Kernel::OM->Get('Kernel::System::CustomerUser');

    # set preselected values for Cc field
    if ( $Param{Cc} && $Param{Cc} ne '' && !$CustomerCounterCc ) {

        # split Cc values
        my @EmailAddressesCc;
        for my $Email ( Mail::Address->parse( $Param{Cc} ) ) {

            my %CustomerSearch = $CustomerUserObject->CustomerSearch(
                PostMasterSearch => $Email->address(),
                Limit            => 1,
            );

            # CustomerSearch hash could have one item from each backend, so insert just the first one.
            if (%CustomerSearch) {
                CUSTOMERUSERID:
                for my $CustomerUserID ( sort keys %CustomerSearch ) {
                    push @EmailAddressesCc, {
                        CustomerKey        => $CustomerUserID,
                        CustomerTicketText => $CustomerSearch{$CustomerUserID},
                    };
                    last CUSTOMERUSERID;
                }
            }
            else {
                push @EmailAddressesCc, {
                    CustomerKey        => '',
                    CustomerTicketText => $Email->[0] ? "$Email->[0] <$Email->[1]>" : "$Email->[1]",
                };
            }
        }

        $LayoutObject->AddJSData(
            Key   => 'EmailAddressesCc',
            Value => \@EmailAddressesCc,
        );

        $Param{Cc} = '';
    }

    # set preselected values for To field
    if ( defined $Param{To} && $Param{To} ne '' && !$CustomerCounter ) {

        # split To values
        my @EmailAddressesTo;
        for my $Email ( Mail::Address->parse( $Param{To} ) ) {

            my %CustomerSearch = $CustomerUserObject->CustomerSearch(
                PostMasterSearch => $Email->address(),
                Limit            => 1,
            );

            # CustomerSearch hash could have one item from each backend, so insert just the first one.
            if (%CustomerSearch) {
                CUSTOMERUSERID:
                for my $CustomerUserID ( sort keys %CustomerSearch ) {
                    push @EmailAddressesTo, {
                        CustomerKey        => $CustomerUserID,
                        CustomerTicketText => $CustomerSearch{$CustomerUserID},
                    };
                    last CUSTOMERUSERID;
                }
            }
            else {
                push @EmailAddressesTo, {
                    CustomerKey        => '',
                    CustomerTicketText => $Email->[0] ? "$Email->[0] <$Email->[1]>" : "$Email->[1]",
                };
            }
        }

        $LayoutObject->AddJSData(
            Key   => 'EmailAddressesTo',
            Value => \@EmailAddressesTo,
        );

        $Param{To} = '';
    }

    $LayoutObject->Block(
        Name => $Param{TicketBackType},
        Data => {

            #            FormID => $Self->{FormID},
            %Param,
        },
    );

    # get the dynamic fields for this screen
    my $DynamicField = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldListGet(
        Valid       => 1,
        ObjectType  => [ 'Ticket', 'Article' ],
        FieldFilter => $Config->{DynamicField} || {},
    );

    # Dynamic fields
    # cycle trough the activated Dynamic Fields for this screen
    DYNAMICFIELD:
    for my $DynamicFieldConfig ( @{$DynamicField} ) {
        next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

        # skip fields that HTML could not be retrieved
        next DYNAMICFIELD if !IsHashRefWithData(
            $Param{DynamicFieldHTML}->{ $DynamicFieldConfig->{Name} }
        );

        # get the html strings form $Param
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

    # show attachments
    ATTACHMENT:
    for my $Attachment ( @{ $Param{Attachments} } ) {
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
        TemplateFile => 'AgentTicketCompose',
        Data         => {
            FormID         => $Self->{FormID},
            FormDraft      => $Config->{FormDraft},
            FormDraftID    => $Self->{LoadedFormDraftID},
            FormDraftTitle => $LoadedFormDraft ? $LoadedFormDraft->{Title} : '',
            FormDraftMeta  => $LoadedFormDraft,
            %Param,
        },
    );
}

sub _GetFieldsToUpdate {
    my ( $Self, %Param ) = @_;

    my @UpdatableFields;

    # set the fields that can be updatable via AJAXUpdate
    if ( !$Param{OnlyDynamicFields} ) {
        @UpdatableFields = qw( StateID );
    }

    my $Config = $Kernel::OM->Get('Kernel::Config')->Get("Ticket::Frontend::$Self->{Action}");

    # get the dynamic fields for this screen
    my $DynamicField = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldListGet(
        Valid       => 1,
        ObjectType  => [ 'Ticket', 'Article' ],
        FieldFilter => $Config->{DynamicField} || {},
    );

    # cycle trough the activated Dynamic Fields for this screen
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

1;
