# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Modules::AgentTicketPhoneCommon;

use strict;
use warnings;

use Mail::Address;
use Kernel::System::VariableCheck qw(:all);
use Kernel::Language qw(Translatable);

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

    my $OutputNotify = '';

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
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # get ticket data
    my %Ticket = $TicketObject->TicketGet(
        TicketID      => $Self->{TicketID},
        DynamicFields => 1,
    );

    # get config of frontend module
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

    # show lock state
    $OutputNotify .= $LayoutObject->Notify(
        Data => "$Ticket{TicketNumber}: "
            . $LayoutObject->{LanguageObject}->Translate("Ticket locked."),
    );

    # get lock state && write (lock) permissions
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
                        TicketID => $Self->{TicketID}
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
            Data => { %Param, %Ticket, },
        );
    }

    # get param object
    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');

    # get params
    my %GetParam;
    for my $Key (
        qw(Body Subject TimeUnits NextStateID Year Month Day Hour Minute StandardTemplateID FormDraftID Title)
        )
    {
        $GetParam{$Key} = $ParamObject->GetParam( Param => $Key );
    }

    # get dynamic field values form http request
    my %DynamicFieldValues;

    # get the dynamic fields for this screen
    my $DynamicField = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldListGet(
        Valid       => 1,
        ObjectType  => [ 'Ticket', 'Article' ],
        FieldFilter => $Config->{DynamicField} || {},
    );

    # get backend object
    my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

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
    DYNAMICFIELDNAME:
    for my $DynamicFieldName ( sort keys %DynamicFieldValues ) {
        next DYNAMICFIELDNAME if !$DynamicFieldName;
        next DYNAMICFIELDNAME if !$DynamicFieldValues{$DynamicFieldName};

        $DynamicFieldACLParameters{ 'DynamicField_' . $DynamicFieldName } = $DynamicFieldValues{$DynamicFieldName};
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
    my $CustomerUserObject = $Kernel::OM->Get('Kernel::System::CustomerUser');
    my $UploadCacheObject  = $Kernel::OM->Get('Kernel::System::Web::UploadCache');

    if (
        !$Self->{Subaction}
        && !$Self->{LoadedFormDraftID}
        )
    {

        # get ticket info
        my %CustomerData;
        if ( $ConfigObject->Get('Ticket::Frontend::CustomerInfoCompose') ) {
            if ( $Ticket{CustomerUserID} ) {
                %CustomerData = $CustomerUserObject->CustomerUserDataGet(
                    User => $Ticket{CustomerUserID},
                );
            }
            elsif ( $Ticket{CustomerID} ) {
                %CustomerData = $CustomerUserObject->CustomerUserDataGet(
                    CustomerID => $Ticket{CustomerID},
                );
            }
        }

        # create html strings for all dynamic fields
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

        # get and format default subject and body
        my $Subject = $LayoutObject->Output(
            Template => $Config->{Subject} || '',
        );
        my $Body = $LayoutObject->Output(
            Template => $Config->{Body} || '',
        );
        if ( $LayoutObject->{BrowserRichText} ) {
            $Body = $LayoutObject->Ascii2RichText(
                String => $Body,
            );
        }

        # print form ...
        my $Output = $LayoutObject->Header(
            Type      => 'Small',
            BodyClass => 'Popup',
        );
        $Output .= $Self->_MaskPhone(
            TicketID     => $Self->{TicketID},
            QueueID      => $Self->{QueueID} || $Ticket{QueueID},
            SLAID        => $Ticket{SLAID},
            TicketNumber => $Ticket{TicketNumber},
            Title        => $Ticket{Title},
            NextStates   => $Self->_GetNextStates(
                %GetParam,
            ),
            StandardTemplates => $Self->_GetStandardTemplates(%Ticket),
            CustomerData      => \%CustomerData,
            Subject           => $Subject,
            Body              => $Body,
            DynamicFieldHTML  => \%DynamicFieldHTML,
        );
        $Output .= $LayoutObject->Footer(
            Type => 'Small',
        );
        return $Output;
    }

    # save new phone article to existing ticket
    elsif (
        $Self->{Subaction} eq 'Store'
        || $Self->{LoadedFormDraftID}
        )
    {

        # challenge token check for write action
        if ( !$Self->{LoadedFormDraftID} ) {

            $LayoutObject->ChallengeTokenCheck();

        }

        my %Error;

        # rewrap body if no rich text is used
        if ( $GetParam{Body} && !$LayoutObject->{BrowserRichText} ) {
            $GetParam{Body} = $LayoutObject->WrapPlainText(
                MaxCharacters => $ConfigObject->Get('Ticket::Frontend::TextAreaNote'),
                PlainText     => $GetParam{Body},
            );
        }

        # If is an action about attachments
        my $IsUpload = 0;

        # attachment delete
        my @AttachmentIDs = map {
            my ($ID) = $_ =~ m{ \A AttachmentDelete (\d+) \z }xms;
            $ID ? $ID : ();
        } $ParamObject->GetParamNames();

        COUNT:
        for my $Count ( reverse sort @AttachmentIDs ) {
            my $Delete = $ParamObject->GetParam( Param => "AttachmentDelete$Count" );
            next COUNT if !$Delete;
            $Error{AttachmentDelete} = 1;
            $UploadCacheObject->FormIDRemoveFile(
                FormID => $Self->{FormID},
                FileID => $Count,
            );
            $IsUpload = 1;
        }

        # attachment upload
        if ( $ParamObject->GetParam( Param => 'AttachmentUpload' ) ) {
            $IsUpload                = 1;
            %Error                   = ();
            $Error{AttachmentUpload} = 1;
            my %UploadStuff = $ParamObject->GetUploadAll(
                Param => 'FileUpload',
            );
            $UploadCacheObject->FormIDAddFile(
                FormID      => $Self->{FormID},
                Disposition => 'attachment',
                %UploadStuff,
            );
        }

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
                    $IsUpload = 1;
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

        # check subject
        for my $Key (qw(Body Subject)) {
            if ( $GetParam{$Key} eq '' ) {
                $Error{ $Key . 'Invalid' } = 'ServerError';
            }
        }
        if (
            $ConfigObject->Get('Ticket::Frontend::AccountTime')
            && $ConfigObject->Get('Ticket::Frontend::NeedAccountedTime')
            )
        {
            if ( $GetParam{TimeUnits} eq '' ) {
                $Error{'TimeUnitsInvalid'} = 'ServerError';
            }
        }

        # get all attachments meta data
        my @Attachments = $UploadCacheObject->FormIDGetAllFilesMeta(
            FormID => $Self->{FormID},
        );

        # check if date is valid
        my %StateData;
        $GetParam{NextStateID} ||= '';
        if ( $GetParam{NextStateID} ) {
            my $StateObject = $Kernel::OM->Get('Kernel::System::State');
            %StateData = $StateObject->StateGet( ID => $GetParam{NextStateID} );

            if ( $StateData{TypeName} =~ /^pending/i ) {

                # create a datetime object based on pending date
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
                    $Error{'DateInvalid'} = 'ServerError';
                }
            }
        }

        # create html strings for all dynamic fields
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

        # Make sure we don't save form if a draft was loaded.
        if ( $Self->{LoadedFormDraftID} ) {
            %Error = ( LoadedFormDraft => 1 );
        }

        if (%Error) {

            # get ticket info if ticket id is given
            my %Ticket = $TicketObject->TicketGet( TicketID => $Self->{TicketID} );

            # check permissions if it's a existing ticket
            if (
                !$TicketObject->TicketPermission(
                    Type     => 'ro',
                    TicketID => $Self->{TicketID},
                    UserID   => $Self->{UserID},
                )
                )
            {

                # error screen, don't show ticket
                return $LayoutObject->NoPermission( WithHeader => 'yes' );
            }

            # get ticket info
            my $Tn = $Ticket{TicketNumber};
            my %CustomerData;
            if ( $ConfigObject->Get('Ticket::Frontend::CustomerInfoCompose') ) {
                if ( $Ticket{CustomerUserID} ) {
                    %CustomerData = $CustomerUserObject->CustomerUserDataGet(
                        User => $Ticket{CustomerUserID},
                    );
                }
                elsif ( $Ticket{CustomerID} ) {
                    %CustomerData = $CustomerUserObject->CustomerUserDataGet(
                        CustomerID => $Ticket{CustomerID},
                    );
                }
            }

            # header
            my $Output = $LayoutObject->Header(
                Type      => 'Small',
                BodyClass => 'Popup',
            );
            $Output .= $OutputNotify;
            $Output .= $Self->_MaskPhone(
                TicketID     => $Self->{TicketID},
                TicketNumber => $Tn,
                QueueID      => $Ticket{QueueID},
                SLAID        => $Ticket{SLAID},
                Title        => $Ticket{Title},
                NextStates   => $Self->_GetNextStates(
                    %GetParam,
                ),
                StandardTemplates => $Self->_GetStandardTemplates(%Ticket),
                CustomerData      => \%CustomerData,
                Attachments       => \@Attachments,
                %GetParam,
                DynamicFieldHTML => \%DynamicFieldHTML,
                Errors           => \%Error,
            );
            $Output .= $LayoutObject->Footer(
                Type => 'Small',
            );
            return $Output;
        }
        else {

            # get pre loaded attachment
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

            my $MimeType = 'text/plain';
            if ( $LayoutObject->{BrowserRichText} ) {
                $MimeType = 'text/html';

                # remove unused inline images
                my @NewAttachmentData;
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
                        next ATTACHMENT
                            if $GetParam{Body} !~ /(\Q$ContentIDHTMLQuote\E|\Q$ContentID\E)/i;
                    }

                    # remember inline images and normal attachments
                    push @NewAttachmentData, \%{$Attachment};
                }
                @AttachmentData = @NewAttachmentData;

                # verify html document
                $GetParam{Body} = $LayoutObject->RichTextDocumentComplete(
                    String => $GetParam{Body},
                );
            }

            my $From;

            my $ArticleObject        = $Kernel::OM->Get('Kernel::System::Ticket::Article');
            my $ArticleBackendObject = $ArticleObject->BackendForChannel( ChannelName => 'Phone' );

            if ( lc $Config->{SenderType} eq 'customer' ) {

                # get customer email address
                if ( $Ticket{CustomerUserID} ) {
                    my %CustomerUserData = $CustomerUserObject->CustomerUserDataGet(
                        User => $Ticket{CustomerUserID}
                    );

                    # use data from customer user (if customer user is in database)
                    if ( IsHashRefWithData( \%CustomerUserData ) ) {
                        $From = '"' . $CustomerUserData{UserFullname} . '"' . '<' . $CustomerUserData{UserEmail} . '>';
                    }
                }
                else {
                    # Use customer data as From, if possible.
                    my @MetaArticles = $ArticleObject->ArticleList(
                        SenderType => 'customer',
                        OnlyLast   => 1,
                    );
                    if (@MetaArticles) {
                        my %LastCustomerArticle
                            = $ArticleObject->BackendForArticle( %{ $MetaArticles[0] } )->ArticleGet(
                            %{ $MetaArticles[0] },
                            DynamicFields => 0,
                            );
                        $From = $LastCustomerArticle{From};
                    }
                }
            }

            # If we don't have a customer article, or if SenderType is "agent", use the agent as From.
            if ( !$From ) {
                my $TemplateGenerator = $Kernel::OM->Get('Kernel::System::TemplateGenerator');
                $From = $TemplateGenerator->Sender(
                    QueueID => $Ticket{QueueID},
                    UserID  => $Self->{UserID},
                );
            }

            my $ArticleID = $ArticleBackendObject->ArticleCreate(
                TicketID             => $Self->{TicketID},
                IsVisibleForCustomer => 1,
                SenderType           => $Config->{SenderType},
                From                 => $From,
                Subject              => $GetParam{Subject},
                Body                 => $GetParam{Body},
                MimeType             => $MimeType,
                Charset              => $LayoutObject->{UserCharset},
                UserID               => $Self->{UserID},
                HistoryType          => $Config->{HistoryType},
                HistoryComment       => $Config->{HistoryComment} || '%%',
                UnlockOnAway         => 1,
            );

            # show error of creating article
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

            # write attachments
            for my $Attachment (@AttachmentData) {
                $ArticleBackendObject->ArticleWriteAttachment(
                    %{$Attachment},
                    TicketID  => $Self->{TicketID},
                    ArticleID => $ArticleID,
                    UserID    => $Self->{UserID},
                );
            }

            # remove pre submitted attachments
            $UploadCacheObject->FormIDRemove( FormID => $Self->{FormID} );

            # set dynamic fields
            # cycle through the activated Dynamic Fields for this screen
            DYNAMICFIELD:
            for my $DynamicFieldConfig ( @{$DynamicField} ) {
                next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

                # set the object ID (TicketID or ArticleID) depending on the field configuration
                my $ObjectID = $DynamicFieldConfig->{ObjectType} eq 'Article'
                    ? $ArticleID
                    : $Self->{TicketID};

                # set the value
                my $Success = $DynamicFieldBackendObject->ValueSet(
                    DynamicFieldConfig => $DynamicFieldConfig,
                    ObjectID           => $ObjectID,
                    Value              => $DynamicFieldValues{ $DynamicFieldConfig->{Name} },
                    UserID             => $Self->{UserID},
                );
            }

            # set state
            if ( $StateData{ID} ) {
                $TicketObject->TicketStateSet(
                    TicketID  => $Self->{TicketID},
                    ArticleID => $ArticleID,
                    StateID   => $StateData{ID},
                    UserID    => $Self->{UserID},
                );
            }

            # should i set an unlock? yes if the ticket is closed
            if ( $StateData{TypeName} =~ /^close/i ) {

                # set lock
                $TicketObject->TicketLockSet(
                    TicketID => $Self->{TicketID},
                    Lock     => 'unlock',
                    UserID   => $Self->{UserID},
                );
            }

            # set pending time if next state is a pending state
            elsif ( $StateData{TypeName} =~ /^pending/i ) {

                # set pending time
                $TicketObject->TicketPendingTimeSet(
                    UserID   => $Self->{UserID},
                    TicketID => $Self->{TicketID},
                    %GetParam,
                );
            }

            # redirect to last screen (e. g. zoom view) and to queue view if
            # the ticket is closed (move to the next task).
            if (
                $StateData{TypeName} =~ /^close/i
                && !$ConfigObject->Get('Ticket::Frontend::RedirectAfterCloseDisabled')
                )
            {
                return $LayoutObject->PopupClose(
                    URL => ( $Self->{LastScreenOverview} || 'Action=AgentDashboard' ),
                );
            }

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

            return $LayoutObject->PopupClose(
                URL => "Action=AgentTicketZoom;TicketID=$Self->{TicketID};ArticleID=$ArticleID",
            );
        }
    }
    elsif ( $Self->{Subaction} eq 'AJAXUpdate' ) {
        my $ElementChanged = $ParamObject->GetParam( Param => 'ElementChanged' ) || '';

        my $NextStates = $Self->_GetNextStates(
            %GetParam,
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

        my @TemplateAJAX;

        # update ticket body and attachements if needed.
        if ( $ElementChanged eq 'StandardTemplateID' ) {
            my @TicketAttachments;
            my $TemplateText;

            # remove all attachments from the Upload cache
            my $RemoveSuccess = $UploadCacheObject->FormIDRemove(
                FormID => $Self->{FormID},
            );
            if ( !$RemoveSuccess ) {
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'error',
                    Message  => "Form attachments could not be deleted!",
                );
            }

            # get the template text and set new attachments if a template is selected
            if ( IsPositiveInteger( $GetParam{StandardTemplateID} ) ) {
                my $TemplateGenerator = $Kernel::OM->Get('Kernel::System::TemplateGenerator');

                # set template text, replace smart tags (limited as ticket is not created)
                $TemplateText = $TemplateGenerator->Template(
                    TicketID   => $Self->{TicketID},
                    TemplateID => $GetParam{StandardTemplateID},
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
                        FormID      => $Self->{FormID},
                        Disposition => 'attachment',
                        %AttachmentsData,
                    );
                }

                # send a list of attachments in the upload cache back to the clientside JavaScript
                # which renders then the list of currently uploaded attachments
                @TicketAttachments = $UploadCacheObject->FormIDGetAllFilesMeta(
                    FormID => $Self->{FormID},
                );

                for my $Attachment (@TicketAttachments) {
                    $Attachment->{Filesize} = $LayoutObject->HumanReadableDataSize(
                        Size => $Attachment->{Filesize},
                    );
                }
            }

            @TemplateAJAX = (
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
                    Name         => 'NextStateID',
                    Data         => $NextStates,
                    SelectedID   => $GetParam{NextStateID},
                    Translation  => 1,
                    PossibleNone => 1,
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
    return $LayoutObject->ErrorScreen(
        Message => Translatable('No Subaction!'),
        Comment => Translatable('Please contact the administrator.'),
    );
}

sub _GetNextStates {
    my ( $Self, %Param ) = @_;

    my %NextStates = $Kernel::OM->Get('Kernel::System::Ticket')->TicketStateList(
        TicketID => $Self->{TicketID},
        Action   => $Self->{Action},
        UserID   => $Self->{UserID},
        %Param,
    );
    return \%NextStates;
}

sub _GetUsers {
    my ( $Self, %Param ) = @_;

    # get users
    my %ShownUsers;
    my %AllGroupsMembers = $Kernel::OM->Get('Kernel::System::User')->UserList(
        Type  => 'Long',
        Valid => 1,
    );

    # just show only users with selected custom queue
    if ( $Param{QueueID} && !$Param{AllUsers} ) {
        my @UserIDs = $Kernel::OM->Get('Kernel::System::Ticket')->GetSubscribedUserIDsByQueueID(%Param);
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
    if ( $Kernel::OM->Get('Kernel::Config')->Get('Ticket::ChangeOwnerToEveryone') ) {
        %ShownUsers = %AllGroupsMembers;
    }

    # show all users who are rw in the queue group
    elsif ( $Param{QueueID} ) {
        my $GID        = $Kernel::OM->Get('Kernel::System::Queue')->GetQueueGroupID( QueueID => $Param{QueueID} );
        my %MemberList = $Kernel::OM->Get('Kernel::System::Group')->PermissionGroupGet(
            GroupID => $GID,
            Type    => 'rw',
        );
        for my $KeyMember ( sort keys %MemberList ) {
            $ShownUsers{$KeyMember} = $AllGroupsMembers{$KeyMember};
        }
    }
    return \%ShownUsers;
}

sub _GetStandardTemplates {
    my ( $Self, %Param ) = @_;

    # get create templates
    my %Templates;

    # check needed
    return \%Templates if !$Param{QueueID} && !$Param{TicketID};

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
    return \%Templates if !IsHashRefWithData( $StandardTemplates{PhoneCall} );

    # return just the templates for this screen
    return $StandardTemplates{PhoneCall};
}

sub _MaskPhone {
    my ( $Self, %Param ) = @_;

    $Param{FormID} = $Self->{FormID};

    my $DynamicFieldNames = $Self->_GetFieldsToUpdate(
        OnlyDynamicFields => 1
    );

    # get needed objects
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # get config of frontend module
    my $Config = $ConfigObject->Get("Ticket::Frontend::$Self->{Action}");

    # send data to JS
    $LayoutObject->AddJSData(
        Key   => 'DynamicFieldNames',
        Value => $DynamicFieldNames,
    );

    # build next states string
    my %Selected;
    if ( $Param{NextStateID} ) {
        $Selected{SelectedID} = $Param{NextStateID};
    }
    elsif ( $Config->{State} ) {
        $Selected{SelectedValue} = $Config->{State};
    }
    $Param{NextStatesStrg} = $LayoutObject->BuildSelection(
        Data         => $Param{NextStates},
        Name         => 'NextStateID',
        Class        => 'Modernize',
        Translation  => 1,
        PossibleNone => 1,
        %Selected,
    );

    # customer info string
    if ( $ConfigObject->Get('Ticket::Frontend::CustomerInfoCompose') ) {
        my %TicketData = $Kernel::OM->Get('Kernel::System::Ticket')->TicketGet( TicketID => $Self->{TicketID} );
        $Param{CustomerTable} = $LayoutObject->AgentCustomerViewTable(
            Data   => $Param{CustomerData},
            Ticket => \%TicketData,
            Max    => $ConfigObject->Get('Ticket::Frontend::CustomerInfoComposeMaxSize'),
        );

        $LayoutObject->Block(
            Name => 'CustomerTable',
            Data => \%Param,
        );
    }

    # check if exists create templates regardless the queue
    my %StandardTemplates = $Kernel::OM->Get('Kernel::System::StandardTemplate')->StandardTemplateList(
        Valid => 1,
        Type  => 'PhoneCall',
    );

    # build text template string
    if ( IsHashRefWithData( \%StandardTemplates ) ) {
        $Param{StandardTemplateStrg} = $LayoutObject->BuildSelection(
            Data         => $Param{StandardTemplates} || {},
            Name         => 'StandardTemplateID',
            SelectedID   => $Param{StandardTemplateID} || '',
            PossibleNone => 1,
            Sort         => 'AlphanumericValue',
            Translation  => 0,
            Max          => 200,
            Class        => 'Modernize',
        );
        $LayoutObject->Block(
            Name => 'StandardTemplate',
            Data => {%Param},
        );
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
        Class                => $Param{Errors}->{DateInvalid},
        Validate             => 1,
        ValidateDateInFuture => 1,
        Calendar             => $Calendar,
    );

    # do html quoting
    for my $Parameter (qw(From To Cc)) {
        $Param{$Parameter} = $LayoutObject->Ascii2Html( Text => $Param{$Parameter} ) || '';
    }

    # prepare errors!
    if ( $Param{Errors} ) {
        for my $KeyError ( sort keys %{ $Param{Errors} } ) {
            $Param{$KeyError} = '* ' . $LayoutObject->Ascii2Html( Text => $Param{Errors}->{$KeyError} );
        }
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

    # get output back
    return $LayoutObject->Output(
        TemplateFile => 'AgentTicketPhoneCommon',
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
        @UpdatableFields = qw( NextStateID StandardTemplateID );
    }

    # get config of frontend module
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

1;
