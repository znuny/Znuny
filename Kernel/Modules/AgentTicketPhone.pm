# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Modules::AgentTicketPhone;
## nofilter(TidyAll::Plugin::OTRS::Perl::DBObject)

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

    #get config object
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # get the dynamic fields for this screen
    $Self->{DynamicField} = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldListGet(
        Valid       => 1,
        ObjectType  => [ 'Ticket', 'Article' ],
        FieldFilter => $ConfigObject->Get("Ticket::Frontend::$Self->{Action}")->{DynamicField} || {},
    );

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

    # get params
    my %GetParam;

    # get param object
    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');

    for my $Key (
        qw(ArticleID LinkTicketID PriorityID NewUserID
        From Subject Body NextStateID TimeUnits
        Year Month Day Hour Minute
        NewResponsibleID ResponsibleAll OwnerAll TypeID ServiceID SLAID
        StandardTemplateID FromChatID Dest
        )
        )
    {
        $GetParam{$Key} = $ParamObject->GetParam( Param => $Key );
    }

    # ACL compatibility translation
    my %ACLCompatGetParam;
    $ACLCompatGetParam{OwnerID} = $GetParam{NewUserID};

    # MultipleCustomer From-field
    my @MultipleCustomer;
    my $CustomersNumber = $ParamObject->GetParam( Param => 'CustomerTicketCounterFromCustomer' ) || 0;
    my $Selected        = $ParamObject->GetParam( Param => 'CustomerSelected' )                  || '';

    # hash for check duplicated entries
    my %AddressesList;

    # get check item object
    my $CheckItemObject = $Kernel::OM->Get('Kernel::System::CheckItem');

    if ($CustomersNumber) {
        my $CustomerCounter = 1;
        for my $Count ( 1 ... $CustomersNumber ) {
            my $CustomerElement  = $ParamObject->GetParam( Param => 'CustomerTicketText_' . $Count );
            my $CustomerSelected = ( $Selected eq $Count ? 'checked="checked"' : '' );
            my $CustomerKey      = $ParamObject->GetParam( Param => 'CustomerKey_' . $Count )
                || '';

            if ($CustomerElement) {

                my $CountAux         = $CustomerCounter++;
                my $CustomerError    = '';
                my $CustomerErrorMsg = 'CustomerGenericServerErrorMsg';
                my $CustomerDisabled = '';

                if ( $GetParam{From} ) {
                    $GetParam{From} .= ', ' . $CustomerElement;
                }
                else {
                    $GetParam{From} = $CustomerElement;
                }

                # check email address
                for my $Email ( Mail::Address->parse($CustomerElement) ) {
                    if ( !$CheckItemObject->CheckEmail( Address => $Email->address() ) )
                    {
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

                if ( $CustomerError ne '' ) {
                    $CustomerDisabled = 'disabled="disabled"';
                    $CountAux         = $Count . 'Error';
                }

                push @MultipleCustomer, {
                    Count            => $CountAux,
                    CustomerElement  => $CustomerElement,
                    CustomerSelected => $CustomerSelected,
                    CustomerKey      => $CustomerKey,
                    CustomerError    => $CustomerError,
                    CustomerErrorMsg => $CustomerErrorMsg,
                    CustomerDisabled => $CustomerDisabled,
                };
                $AddressesList{$CustomerElement} = 1;
            }
        }
    }

    # get Dynamic fields form ParamObject
    my %DynamicFieldValues;

    # get needed objects
    my $LayoutObject              = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
    my $ConfigObject              = $Kernel::OM->Get('Kernel::Config');
    my $CustomerUserObject        = $Kernel::OM->Get('Kernel::System::CustomerUser');
    my $UploadCacheObject         = $Kernel::OM->Get('Kernel::System::Web::UploadCache');
    my $TicketObject              = $Kernel::OM->Get('Kernel::System::Ticket');
    my $QueueObject               = $Kernel::OM->Get('Kernel::System::Queue');

    my $Config = $ConfigObject->Get("Ticket::Frontend::$Self->{Action}");

    # cycle trough the activated Dynamic Fields for this screen
    DYNAMICFIELD:
    for my $DynamicFieldConfig ( @{ $Self->{DynamicField} } ) {
        next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

        # extract the dynamic field value from the web request
        $DynamicFieldValues{ $DynamicFieldConfig->{Name} } = $DynamicFieldBackendObject->EditFieldValueGet(
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

    if ( $GetParam{FromChatID} ) {
        if ( !$ConfigObject->Get('ChatEngine::Active') ) {
            return $LayoutObject->FatalError(
                Message => Translatable('Chat is not active.'),
            );
        }

        # Ok, take the chat
        my %ChatParticipant = $Kernel::OM->Get('Kernel::System::Chat')->ChatParticipantCheck(
            ChatID        => $GetParam{FromChatID},
            ChatterType   => 'User',
            ChatterID     => $Self->{UserID},
            ChatterActive => 1,
        );

        if ( !%ChatParticipant ) {
            return $LayoutObject->FatalError(
                Message => Translatable('No permission.'),
            );
        }

        # Get permissions
        my $PermissionLevel = $Kernel::OM->Get('Kernel::System::Chat')->ChatPermissionLevelGet(
            ChatID => $GetParam{FromChatID},
            UserID => $Self->{UserID},
        );

        # Check if observer
        if ( $PermissionLevel ne 'Owner' && $PermissionLevel ne 'Participant' ) {
            return $LayoutObject->FatalError(
                Message => Translatable('No permission.'),
                Comment => $PermissionLevel,
            );
        }
    }

    if ( !$Self->{Subaction} || $Self->{Subaction} eq 'Created' ) {
        my %Ticket;
        if ( $Self->{TicketID} ) {
            %Ticket = $TicketObject->TicketGet( TicketID => $Self->{TicketID} );
        }

        # header
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();

        # if there is no ticket id!
        if ( $Self->{TicketID} && $Self->{Subaction} eq 'Created' ) {

            # notify info
            $Output .= $LayoutObject->Notify(
                Info => $LayoutObject->{LanguageObject}->Translate(
                    'Ticket "%s" created!',
                    $Ticket{TicketNumber},
                ),
                Link => $LayoutObject->{Baselink}
                    . 'Action=AgentTicketZoom;TicketID='
                    . $Ticket{TicketID},
            );
        }

        # store last queue screen
        if (
            $Self->{LastScreenOverview}
            && $Self->{LastScreenOverview} !~ /Action=AgentTicketPhone/
            && $Self->{RequestedURL}       !~ /Action=AgentTicketPhone.*LinkTicketID=/
            )
        {
            $Kernel::OM->Get('Kernel::System::AuthSession')->UpdateSessionID(
                SessionID => $Self->{SessionID},
                Key       => 'LastScreenOverview',
                Value     => $Self->{RequestedURL},
            );
        }

        # get split article if given
        # get ArticleID
        my %Article;
        my %CustomerData;
        my $ArticleFrom = '';
        my %SplitTicketData;
        if ( $GetParam{ArticleID} ) {

            my $Access = $TicketObject->TicketPermission(
                Type     => 'ro',
                TicketID => $Self->{TicketID},
                UserID   => $Self->{UserID}
            );

            if ( !$Access ) {
                return $LayoutObject->NoPermission(
                    Message    => Translatable('You need ro permission!'),
                    WithHeader => 'yes',
                );
            }

            # Get information from original ticket (SplitTicket).
            %SplitTicketData = $TicketObject->TicketGet(
                TicketID      => $Self->{TicketID},
                DynamicFields => 1,
                UserID        => $Self->{UserID},
            );

            my $ArticleBackendObject = $Kernel::OM->Get('Kernel::System::Ticket::Article')->BackendForArticle(
                TicketID  => $Self->{TicketID},
                ArticleID => $GetParam{ArticleID},
            );

            %Article = $ArticleBackendObject->ArticleGet(
                TicketID  => $Self->{TicketID},
                ArticleID => $GetParam{ArticleID},
            );

            # check if article is from the same TicketID as we checked permissions for.
            if ( $Article{TicketID} ne $Self->{TicketID} ) {
                return $LayoutObject->ErrorScreen(
                    Message => $LayoutObject->{LanguageObject}
                        ->Translate( 'Article does not belong to ticket %s!', $Self->{TicketID} ),
                );
            }

            $Article{Subject} = $TicketObject->TicketSubjectClean(
                TicketNumber => $Ticket{TicketNumber},
                Subject      => $Article{Subject} || '',
            );

            # save article from for addresses list
            $ArticleFrom = $Article{From};

            # if To is present
            # and is no a queue
            # and also is no a system address
            # set To as article from
            if ( IsStringWithData( $Article{To} ) ) {
                my %Queues = $QueueObject->QueueList();

                if ( $ConfigObject->{CustomerPanelOwnSelection} ) {
                    for my $Queue ( sort keys %{ $ConfigObject->{CustomerPanelOwnSelection} } ) {
                        my $Value = $ConfigObject->{CustomerPanelOwnSelection}->{$Queue};
                        $Queues{$Queue} = $Value;
                    }
                }

                my %QueueLookup = reverse %Queues;
                my %SystemAddressLookup
                    = reverse $Kernel::OM->Get('Kernel::System::SystemAddress')->SystemAddressList();
                my @ArticleFromAddress;
                my $SystemAddressEmail;

                if ($ArticleFrom) {
                    @ArticleFromAddress = Mail::Address->parse($ArticleFrom);
                    $SystemAddressEmail = $ArticleFromAddress[0]->address();
                }

                if ( !defined $QueueLookup{ $Article{To} } && defined $SystemAddressLookup{$SystemAddressEmail} ) {
                    $ArticleFrom = $Article{To};
                }
            }

            # body preparation for plain text processing
            $Article{Body} = $LayoutObject->ArticleQuote(
                TicketID           => $Article{TicketID},
                ArticleID          => $GetParam{ArticleID},
                FormID             => $Self->{FormID},
                UploadCacheObject  => $UploadCacheObject,
                AttachmentsInclude => 1,
            );
            if ( $LayoutObject->{BrowserRichText} ) {
                $Article{ContentType} = 'text/html';
            }
            else {
                $Article{ContentType} = 'text/plain';
            }

            my %SafetyCheckResult = $Kernel::OM->Get('Kernel::System::HTMLUtils')->Safety(
                String => $Article{Body},

                # Strip out external content if BlockLoadingRemoteContent is enabled.
                NoExtSrcLoad => $ConfigObject->Get('Ticket::Frontend::BlockLoadingRemoteContent'),

                # Disallow potentially unsafe content.
                NoApplet     => 1,
                NoObject     => 1,
                NoEmbed      => 1,
                NoSVG        => 1,
                NoJavaScript => 1,
            );
            $Article{Body} = $SafetyCheckResult{String};

            # show customer info
            if ( $ConfigObject->Get('Ticket::Frontend::CustomerInfoCompose') ) {
                if ( $SplitTicketData{CustomerUserID} ) {
                    %CustomerData = $CustomerUserObject->CustomerUserDataGet(
                        User => $SplitTicketData{CustomerUserID},
                    );
                }
                elsif ( $SplitTicketData{CustomerID} ) {
                    %CustomerData = $CustomerUserObject->CustomerUserDataGet(
                        CustomerID => $SplitTicketData{CustomerID},
                    );
                }
            }
            if ( $SplitTicketData{CustomerUserID} ) {
                my %CustomerUserList = $CustomerUserObject->CustomerSearch(
                    UserLogin => $SplitTicketData{CustomerUserID},
                );
                for my $KeyCustomerUserList ( sort keys %CustomerUserList ) {
                    $Article{From} = $CustomerUserList{$KeyCustomerUserList};
                }
            }
        }

        # multiple addresses list
        # check email address
        my $CountFrom = scalar @MultipleCustomer || 1;
        my %CustomerDataFrom;
        if ( $Article{CustomerUserID} ) {
            %CustomerDataFrom = $CustomerUserObject->CustomerUserDataGet(
                User => $Article{CustomerUserID},
            );
        }

        for my $Email ( Mail::Address->parse($ArticleFrom) ) {

            my $CountAux         = $CountFrom;
            my $CustomerError    = '';
            my $CustomerErrorMsg = 'CustomerGenericServerErrorMsg';
            my $CustomerDisabled = '';
            my $CustomerSelected = $CountFrom eq '1' ? 'checked="checked"' : '';
            my $EmailAddress     = $Email->address();
            if ( !$CheckItemObject->CheckEmail( Address => $EmailAddress ) )
            {
                $CustomerErrorMsg = $CheckItemObject->CheckErrorType()
                    . 'ServerErrorMsg';
                $CustomerError = 'ServerError';
            }

            # check for duplicated entries
            if ( defined $AddressesList{$Email} && $CustomerError eq '' ) {
                $CustomerErrorMsg = 'IsDuplicatedServerErrorMsg';
                $CustomerError    = 'ServerError';
            }

            if ( $CustomerError ne '' ) {
                $CustomerDisabled = 'disabled="disabled"';
                $CountAux         = $CountFrom . 'Error';
            }

            my $Phrase = '';
            if ( $Email->phrase() ) {
                $Phrase = $Email->phrase();
            }

            my $CustomerKey = '';
            if (
                defined $CustomerDataFrom{UserEmail}
                && $CustomerDataFrom{UserEmail} eq $EmailAddress
                )
            {
                $CustomerKey = $Article{CustomerUserID};
            }
            elsif ($EmailAddress) {
                my %List = $CustomerUserObject->CustomerSearch(
                    PostMasterSearch => $EmailAddress,
                );

                for my $UserLogin ( sort keys %List ) {

                    # Set right one if there is more than one customer user with the same email address.
                    if ( $Phrase && $List{$UserLogin} =~ /$Phrase/ ) {
                        $CustomerKey = $UserLogin;
                    }
                }
            }

            my $CustomerElement = $EmailAddress;
            if ($Phrase) {
                $CustomerElement = $Phrase . " <$EmailAddress>";
            }

            if ( $CustomerSelected && $CustomerKey ) {
                %CustomerData = $CustomerUserObject->CustomerUserDataGet(
                    User => $CustomerKey,
                );
            }

            push @MultipleCustomer, {
                Count            => $CountAux,
                CustomerElement  => $CustomerElement,
                CustomerSelected => $CustomerSelected,
                CustomerKey      => $CustomerKey,
                CustomerError    => $CustomerError,
                CustomerErrorMsg => $CustomerErrorMsg,
                CustomerDisabled => $CustomerDisabled,
            };
            $AddressesList{$EmailAddress} = 1;
            $CountFrom++;
        }

        # get user preferences
        my %UserPreferences = $Kernel::OM->Get('Kernel::System::User')->GetUserData(
            UserID => $Self->{UserID},
        );

        # store the dynamic fields default values or used specific default values to be used as
        # ACLs info for all fields
        my %DynamicFieldDefaults;

        # cycle trough the activated Dynamic Fields for this screen
        DYNAMICFIELD:
        for my $DynamicFieldConfig ( @{ $Self->{DynamicField} } ) {
            next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);
            next DYNAMICFIELD if !IsHashRefWithData( $DynamicFieldConfig->{Config} );
            next DYNAMICFIELD if !$DynamicFieldConfig->{Name};

            # get default value from dynamic field config (if any)
            my $DefaultValue = $DynamicFieldConfig->{Config}->{DefaultValue} || '';

            # override the value from user preferences if is set
            if ( $UserPreferences{ 'UserDynamicField_' . $DynamicFieldConfig->{Name} } ) {
                $DefaultValue = $UserPreferences{ 'UserDynamicField_' . $DynamicFieldConfig->{Name} };
            }

            next DYNAMICFIELD if $DefaultValue eq '';
            next DYNAMICFIELD if ref $DefaultValue eq 'ARRAY' && !IsArrayRefWithData($DefaultValue);

            $DynamicFieldDefaults{ 'DynamicField_' . $DynamicFieldConfig->{Name} } = $DefaultValue;
        }
        $GetParam{DynamicField} = \%DynamicFieldDefaults;

        # create html strings for all dynamic fields
        my %DynamicFieldHTML;

        my %SplitTicketParam;

        # in case of split a TicketID and ArticleID are always given, send the TicketID to calculate
        # ACLs based on parent information
        if ( $Self->{TicketID} && $Article{ArticleID} ) {
            $SplitTicketParam{TicketID} = $Self->{TicketID};
        }

        # fix to bug# 8068 Field & DynamicField preselection on TicketSplit
        # when splitting a ticket the selected attributes must remain in the new ticket screen
        # this information will be available in the SplitTicketParam hash
        if ( $SplitTicketParam{TicketID} ) {

            # Get information from original ticket (SplitTicket).
            my %SplitTicketData = $TicketObject->TicketGet(
                TicketID      => $SplitTicketParam{TicketID},
                DynamicFields => 1,
                UserID        => $Self->{UserID},
            );

            # set simple IDs to pass them to the mask
            for my $SplitedParam (qw(TypeID ServiceID SLAID PriorityID)) {
                $SplitTicketParam{$SplitedParam} = $SplitTicketData{$SplitedParam};
            }

            # set StateID as NextStateID
            $SplitTicketParam{NextStateID} = $SplitTicketData{StateID};

            # set Owner and Responsible
            $SplitTicketParam{UserSelected}            = $SplitTicketData{OwnerID};
            $SplitTicketParam{ResponsibleUserSelected} = $SplitTicketData{ResponsibleID};

            # set additional information needed for Owner and Responsible
            if ( $SplitTicketData{QueueID} ) {
                $SplitTicketParam{QueueID} = $SplitTicketData{QueueID};
            }
            $SplitTicketParam{AllUsers} = 1;

            # set the selected queue in format ID||Name
            $SplitTicketParam{ToSelected} = $SplitTicketData{QueueID} . '||' . $SplitTicketData{Queue};

            for my $Key ( sort keys %SplitTicketData ) {
                if ( $Key =~ /DynamicField\_(.*)/ ) {
                    $SplitTicketParam{DynamicField}{$1} = $SplitTicketData{$Key};
                    delete $SplitTicketParam{$Key};
                }
            }
        }

        # cycle through the activated Dynamic Fields for this screen
        DYNAMICFIELD:
        for my $DynamicFieldConfig ( @{ $Self->{DynamicField} } ) {
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
                        %SplitTicketParam,
                        Action        => $Self->{Action},
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

            # in case of split a TicketID and ArticleID are always given, Get the value
            # from DB this cases
            if ( $Self->{TicketID} && $Article{ArticleID} ) {

                # select TicketID or ArticleID to get the value depending on dynamic field configuration
                my $ObjectID = $DynamicFieldConfig->{ObjectType} eq 'Ticket'
                    ? $Self->{TicketID}
                    : $Article{ArticleID};

                # get value stored on the database (split)
                $Value = $DynamicFieldBackendObject->ValueGet(
                    DynamicFieldConfig => $DynamicFieldConfig,
                    ObjectID           => $ObjectID,
                );
            }

            # otherwise (on a new ticket). Check if the user has a user specific default value for
            # the dynamic field, otherwise will use Dynamic Field default value
            else {

                # override the value from user preferences if is set
                if ( $UserPreferences{ 'UserDynamicField_' . $DynamicFieldConfig->{Name} } ) {
                    $Value = $UserPreferences{ 'UserDynamicField_' . $DynamicFieldConfig->{Name} };
                }
            }

            # get field html
            $DynamicFieldHTML{ $DynamicFieldConfig->{Name} } = $DynamicFieldBackendObject->EditFieldRender(
                DynamicFieldConfig   => $DynamicFieldConfig,
                PossibleValuesFilter => $PossibleValuesFilter,
                Value                => $Value,
                LayoutObject         => $LayoutObject,
                ParamObject          => $ParamObject,
                AJAXUpdate           => 1,
                UpdatableFields      => $Self->_GetFieldsToUpdate(),
                Mandatory            => $Config->{DynamicField}->{ $DynamicFieldConfig->{Name} } == 2,
            );
        }

        # get all attachments meta data
        my @Attachments = $UploadCacheObject->FormIDGetAllFilesMeta(
            FormID => $Self->{FormID},
        );

        # get and format default subject and body
        my $Subject = $Article{Subject};
        if ( !$Subject ) {
            $Subject = $LayoutObject->Output(
                Template => $Config->{Subject} || '',
            );
        }
        my $Body = $Article{Body} || '';
        if ( !$Body ) {
            $Body = $LayoutObject->Output(
                Template => $Config->{Body} || '',
            );
        }

        # make sure body is rich text (if body is based on config)
        if ( !$GetParam{ArticleID} && $LayoutObject->{BrowserRichText} ) {
            $Body = $LayoutObject->Ascii2RichText(
                String => $Body,
            );
        }

        # in case of ticket split set $Self->{QueueID} as the QueueID of the original ticket,
        # in order to set correct ACLs on page load (initial). See bug 8687.
        if (
            IsHashRefWithData( \%SplitTicketParam )
            && $SplitTicketParam{QueueID}
            && !$Self->{QueueID}
            )
        {
            $Self->{QueueID} = $SplitTicketParam{QueueID};
        }

        # Get predefined QueueID (if no queue from split ticket is set).
        if ( !$Self->{QueueID} && $GetParam{Dest} ) {

            my @QueueParts = split( /\|\|/, $GetParam{Dest} );
            $Self->{QueueID} = $QueueParts[0];
            $SplitTicketParam{ToSelected} = $GetParam{Dest};
        }

        # html output
        my $Services = $Self->_GetServices(
            %GetParam,
            %ACLCompatGetParam,
            %SplitTicketParam,
            CustomerUserID => $CustomerData{UserLogin} || '',
            QueueID        => $Self->{QueueID}         || 1,
        );
        my $SLAs = $Self->_GetSLAs(
            %GetParam,
            %ACLCompatGetParam,
            %SplitTicketParam,
            CustomerUserID => $CustomerData{UserLogin} || '',
            QueueID        => $Self->{QueueID}         || 1,
            Services       => $Services,
        );
        $Output .= $Self->_MaskPhoneNew(
            QueueID    => $Self->{QueueID},
            NextStates => $Self->_GetNextStates(
                %GetParam,
                %ACLCompatGetParam,
                %SplitTicketParam,
                CustomerUserID => $CustomerData{UserLogin} || '',
                QueueID        => $Self->{QueueID}         || 1,
            ),
            Priorities => $Self->_GetPriorities(
                %GetParam,
                %ACLCompatGetParam,
                %SplitTicketParam,
                CustomerUserID => $CustomerData{UserLogin} || '',
                QueueID        => $Self->{QueueID}         || 1,
            ),
            Types => $Self->_GetTypes(
                %GetParam,
                %ACLCompatGetParam,
                %SplitTicketParam,
                CustomerUserID => $CustomerData{UserLogin} || '',
                QueueID        => $Self->{QueueID}         || 1,
            ),
            Services          => $Services,
            SLAs              => $SLAs,
            StandardTemplates => $Self->_GetStandardTemplates(
                %GetParam,
                %ACLCompatGetParam,
                %SplitTicketParam,
                QueueID => $Self->{QueueID} || '',
            ),
            Users => $Self->_GetUsers(
                %GetParam,
                %ACLCompatGetParam,
                QueueID => $Self->{QueueID},
                %SplitTicketParam,
            ),
            ResponsibleUsers => $Self->_GetResponsibles(
                %GetParam,
                %ACLCompatGetParam,
                QueueID => $Self->{QueueID},
                %SplitTicketParam,
            ),
            To => $Self->_GetTos(
                %GetParam,
                %ACLCompatGetParam,
                %SplitTicketParam,
                CustomerUserID => $CustomerData{UserLogin} || '',
                QueueID        => $Self->{QueueID},
            ),
            TimeUnits => $Self->_GetTimeUnits(
                %GetParam,
                %ACLCompatGetParam,
                %SplitTicketParam,
                ArticleID => $Article{ArticleID},
            ),
            From         => $Article{From},
            Subject      => $Subject,
            Body         => $Body,
            CustomerUser => $SplitTicketData{CustomerUserID},
            CustomerID   => $SplitTicketData{CustomerID},
            CustomerData => \%CustomerData,
            Attachments  => \@Attachments,
            LinkTicketID => $GetParam{LinkTicketID} || '',
            FromChatID   => $GetParam{FromChatID} || '',
            %SplitTicketParam,
            DynamicFieldHTML => \%DynamicFieldHTML,
            MultipleCustomer => \@MultipleCustomer,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }

    # create new ticket and article
    elsif ( $Self->{Subaction} eq 'StoreNew' ) {

        my %Error;
        my %StateData;
        if ( $GetParam{NextStateID} ) {
            %StateData = $Kernel::OM->Get('Kernel::System::State')->StateGet(
                ID => $GetParam{NextStateID},
            );
        }
        my $NextState = $StateData{Name}                          || '';
        my $Dest      = $ParamObject->GetParam( Param => 'Dest' ) || '';

        # see if only a name has been passed
        if ( $Dest && $Dest !~ m{ \A (\d+)? \| \| .+ \z }xms ) {

            # see if we can get an ID for this queue name
            my $DestID = $QueueObject->QueueLookup(
                Queue => $Dest,
            );

            if ($DestID) {
                $Dest = $DestID . '||' . $Dest;
            }
            else {
                $Dest = '';
            }
        }

        my ( $NewQueueID, $To ) = split( /\|\|/, $Dest );
        $GetParam{QueueID} = $NewQueueID;

        my $CustomerUser = $ParamObject->GetParam( Param => 'CustomerUser' )
            || $ParamObject->GetParam( Param => 'PreSelectedCustomerUser' )
            || $ParamObject->GetParam( Param => 'SelectedCustomerUser' )
            || '';
        my $SelectedCustomerUser = $ParamObject->GetParam( Param => 'SelectedCustomerUser' )
            || '';
        my $CustomerID         = $ParamObject->GetParam( Param => 'CustomerID' ) || '';
        my $ExpandCustomerName = $ParamObject->GetParam( Param => 'ExpandCustomerName' )
            || 0;
        my %FromExternalCustomer;
        $FromExternalCustomer{Customer} = $ParamObject->GetParam( Param => 'PreSelectedCustomerUser' )
            || $ParamObject->GetParam( Param => 'CustomerUser' )
            || '';

        if ( $ParamObject->GetParam( Param => 'OwnerAllRefresh' ) ) {
            $GetParam{OwnerAll} = 1;
            $ExpandCustomerName = 3;
        }
        if ( $ParamObject->GetParam( Param => 'ResponsibleAllRefresh' ) ) {
            $GetParam{ResponsibleAll} = 1;
            $ExpandCustomerName = 3;
        }
        if ( $ParamObject->GetParam( Param => 'ClearFrom' ) ) {
            $GetParam{From} = '';
            $ExpandCustomerName = 3;
        }
        for my $Count ( 1 .. 2 ) {
            my $Item = $ParamObject->GetParam( Param => "ExpandCustomerName$Count" ) || 0;
            if ( $Count == 1 && $Item ) {
                $ExpandCustomerName = 1;
            }
            elsif ( $Count == 2 && $Item ) {
                $ExpandCustomerName = 2;
            }
        }

        # rewrap body if no rich text is used
        if ( $GetParam{Body} && !$LayoutObject->{BrowserRichText} ) {
            $GetParam{Body} = $LayoutObject->WrapPlainText(
                MaxCharacters => $ConfigObject->Get('Ticket::Frontend::TextAreaNote'),
                PlainText     => $GetParam{Body},
            );
        }

        # get all attachments meta data
        my @Attachments = $UploadCacheObject->FormIDGetAllFilesMeta(
            FormID => $Self->{FormID},
        );

        # check pending date
        if ( !$ExpandCustomerName && $StateData{TypeName} && $StateData{TypeName} =~ /^pending/i ) {

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
            if ( !$PendingDateTimeObject || $PendingDateTimeObject < $CurSystemDateTimeObject ) {
                $Error{'DateInvalid'} = 'ServerError';
            }
        }

        # create html strings for all dynamic fields
        my %DynamicFieldHTML;

        # cycle through the activated Dynamic Fields for this screen
        DYNAMICFIELD:
        for my $DynamicFieldConfig ( @{ $Self->{DynamicField} } ) {
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
                        CustomerUserID => $CustomerUser || '',
                        Action         => $Self->{Action},
                        ReturnType     => 'Ticket',
                        ReturnSubType  => 'DynamicField_' . $DynamicFieldConfig->{Name},
                        Data           => \%AclData,
                        UserID         => $Self->{UserID},
                    );
                    if ($ACL) {
                        my %Filter = $TicketObject->TicketAclData();

                        # convert Filer key => key back to key => value using map
                        %{$PossibleValuesFilter} = map { $_ => $PossibleValues->{$_} }
                            keys %Filter;
                    }
                }
            }

            my $ValidationResult;

            # do not validate on attachment upload
            if ( !$ExpandCustomerName ) {

                $ValidationResult = $DynamicFieldBackendObject->EditFieldValueValidate(
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
            }

            # get field html
            $DynamicFieldHTML{ $DynamicFieldConfig->{Name} } = $DynamicFieldBackendObject->EditFieldRender(
                DynamicFieldConfig   => $DynamicFieldConfig,
                PossibleValuesFilter => $PossibleValuesFilter,
                ServerError          => $ValidationResult->{ServerError} || '',
                ErrorMessage         => $ValidationResult->{ErrorMessage} || '',
                LayoutObject         => $LayoutObject,
                ParamObject          => $ParamObject,
                AJAXUpdate           => 1,
                UpdatableFields      => $Self->_GetFieldsToUpdate(),
                Mandatory            => $Config->{DynamicField}->{ $DynamicFieldConfig->{Name} } == 2,
            );
        }

        # expand customer name
        my %CustomerUserData;
        if ( $ExpandCustomerName == 1 ) {

            # search customer
            my %CustomerUserList;
            %CustomerUserList = $CustomerUserObject->CustomerSearch(
                Search           => $GetParam{From},
                CustomerUserOnly => 1,
            );

            # check if just one customer user exists
            # if just one, fillup CustomerUserID and CustomerID
            $Param{CustomerUserListCount} = 0;
            for my $KeyCustomerUser ( sort keys %CustomerUserList ) {
                $Param{CustomerUserListCount}++;
                $Param{CustomerUserListLast}     = $CustomerUserList{$KeyCustomerUser};
                $Param{CustomerUserListLastUser} = $KeyCustomerUser;
            }
            if ( $Param{CustomerUserListCount} == 1 ) {
                $GetParam{From}            = $Param{CustomerUserListLast};
                $Error{ExpandCustomerName} = 1;
                my %CustomerUserData = $CustomerUserObject->CustomerUserDataGet(
                    User => $Param{CustomerUserListLastUser},
                );
                if ( $CustomerUserData{UserCustomerID} ) {
                    $CustomerID = $CustomerUserData{UserCustomerID};
                }
                if ( $CustomerUserData{UserLogin} ) {
                    $CustomerUser = $CustomerUserData{UserLogin};
                    $FromExternalCustomer{Customer} = $CustomerUserData{UserLogin};
                }
                if ( $FromExternalCustomer{Customer} ) {
                    my %ExternalCustomerUserData = $CustomerUserObject->CustomerUserDataGet(
                        User => $FromExternalCustomer{Customer},
                    );
                    $FromExternalCustomer{Email} = $ExternalCustomerUserData{UserEmail};
                }
            }

            # if more than one customer user exist, show list
            # and clean CustomerUserID and CustomerID
            else {

                # don't check email syntax on multi customer select
                $ConfigObject->Set(
                    Key   => 'CheckEmailAddresses',
                    Value => 0
                );
                $CustomerID = '';

                # clear from if there is no customer found
                if ( !%CustomerUserList ) {
                    $GetParam{From} = '';
                }
                $Error{ExpandCustomerName} = 1;
            }
        }

        # get from and customer id if customer user is given
        elsif ( $ExpandCustomerName == 2 ) {
            %CustomerUserData = $CustomerUserObject->CustomerUserDataGet(
                User => $CustomerUser,
            );
            my %CustomerUserList = $CustomerUserObject->CustomerSearch(
                UserLogin => $CustomerUser,
            );
            for my $KeyCustomerUser ( sort keys %CustomerUserList ) {
                $GetParam{From} = $CustomerUserList{$KeyCustomerUser};
            }
            if ( $CustomerUserData{UserCustomerID} ) {
                $CustomerID = $CustomerUserData{UserCustomerID};
            }
            if ( $CustomerUserData{UserLogin} ) {
                $CustomerUser = $CustomerUserData{UserLogin};
            }
            if ( $FromExternalCustomer{Customer} ) {
                my %ExternalCustomerUserData = $CustomerUserObject->CustomerUserDataGet(
                    User => $FromExternalCustomer{Customer},
                );
                $FromExternalCustomer{Email} = $ExternalCustomerUserData{UserMailString};
            }
            $Error{ExpandCustomerName} = 1;
        }

        # if a new destination queue is selected
        elsif ( $ExpandCustomerName == 3 ) {
            $Error{NoSubmit} = 1;
            $CustomerUser = $SelectedCustomerUser;
        }

        # 'just' no submit
        elsif ( $ExpandCustomerName == 4 ) {
            $Error{NoSubmit} = 1;
        }

        # show customer info
        my %CustomerData;
        if ( $ConfigObject->Get('Ticket::Frontend::CustomerInfoCompose') ) {
            if ( $CustomerUser || $SelectedCustomerUser ) {
                %CustomerData = $CustomerUserObject->CustomerUserDataGet(
                    User => $CustomerUser || $SelectedCustomerUser,
                );
            }
            elsif ($CustomerID) {
                %CustomerData = $CustomerUserObject->CustomerUserDataGet(
                    CustomerID => $CustomerID,
                );
            }
        }

        # check email address
        for my $Email ( Mail::Address->parse( $GetParam{From} ) ) {
            if ( !$CheckItemObject->CheckEmail( Address => $Email->address() ) ) {
                $Error{ErrorType}   = $CheckItemObject->CheckErrorType() . 'ServerErrorMsg';
                $Error{FromInvalid} = ' ServerError';
            }
        }

        if ( !$ExpandCustomerName ) {
            if ( !$GetParam{From} )
            {
                $Error{'FromInvalid'} = ' ServerError';
            }
            if ( !$GetParam{Subject} ) {
                $Error{'SubjectInvalid'} = ' ServerError';
            }
            if ( !$NewQueueID ) {
                $Error{'DestinationInvalid'} = ' ServerError';
            }
            if (
                $ConfigObject->Get('Ticket::Service')
                && $GetParam{SLAID}
                && !$GetParam{ServiceID}
                )
            {
                $Error{'ServiceInvalid'} = ' ServerError';
            }

            # check mandatory service
            if (
                $ConfigObject->Get('Ticket::Service')
                && $Config->{ServiceMandatory}
                && !$GetParam{ServiceID}
                )
            {
                $Error{'ServiceInvalid'} = ' ServerError';
            }

            # check mandatory sla
            if (
                $ConfigObject->Get('Ticket::Service')
                && $Config->{SLAMandatory}
                && !$GetParam{SLAID}
                )
            {
                $Error{'SLAInvalid'} = ' ServerError';
            }

            if ( ( !$GetParam{TypeID} ) && ( $ConfigObject->Get('Ticket::Type') ) ) {
                $Error{'TypeIDInvalid'} = ' ServerError';
            }
            if ( !$GetParam{Body} ) {
                $Error{'RichTextInvalid'} = ' ServerError';
            }
            if (
                $ConfigObject->Get('Ticket::Frontend::AccountTime')
                && $ConfigObject->Get('Ticket::Frontend::NeedAccountedTime')
                && $GetParam{TimeUnits} eq ''
                )
            {
                $Error{'TimeUnitsInvalid'} = ' ServerError';
            }
        }

        if (%Error) {

            # get and format default subject and body
            my $Subject = $LayoutObject->Output(
                Template => $Config->{Subject} || '',
            );

            my $Body = $LayoutObject->Output(
                Template => $Config->{Body} || '',
            );

            # make sure body is rich text
            if ( $LayoutObject->{BrowserRichText} ) {
                $Body = $LayoutObject->Ascii2RichText(
                    String => $Body,
                );
            }

            #set Body and Subject parameters for Output
            if ( !$GetParam{Subject} ) {
                $GetParam{Subject} = $Subject;
            }

            if ( !$GetParam{Body} ) {
                $GetParam{Body} = $Body;
            }

            # get services
            my $Services = $Self->_GetServices(
                %GetParam,
                %ACLCompatGetParam,
                CustomerUserID => $CustomerUser || '',
                QueueID        => $NewQueueID   || 1,
            );

            # reset previous ServiceID to reset SLA-List if no service is selected
            if ( !$GetParam{ServiceID} || !$Services->{ $GetParam{ServiceID} } ) {
                $GetParam{ServiceID} = '';
            }

            my $SLAs = $Self->_GetSLAs(
                %GetParam,
                %ACLCompatGetParam,
                CustomerUserID => $CustomerUser || $SelectedCustomerUser || '',
                QueueID        => $NewQueueID   || 1,
                Services       => $Services,
            );

            # header
            my $Output = $LayoutObject->Header();
            $Output .= $LayoutObject->NavigationBar();

            # html output
            $Output .= $Self->_MaskPhoneNew(
                QueueID => $Self->{QueueID},
                Users   => $Self->_GetUsers(
                    %GetParam,
                    %ACLCompatGetParam,
                    QueueID  => $NewQueueID,
                    AllUsers => $GetParam{OwnerAll},
                ),
                UserSelected     => $GetParam{NewUserID},
                ResponsibleUsers => $Self->_GetResponsibles(
                    %GetParam,
                    %ACLCompatGetParam,
                    QueueID  => $NewQueueID,
                    AllUsers => $GetParam{ResponsibleAll}
                ),
                ResponsibleUserSelected => $GetParam{NewResponsibleID},
                NextStates              => $Self->_GetNextStates(
                    %GetParam,
                    %ACLCompatGetParam,
                    CustomerUserID => $CustomerUser || $SelectedCustomerUser || '',
                    QueueID        => $NewQueueID   || 1,
                ),
                NextState  => $NextState,
                Priorities => $Self->_GetPriorities(
                    %GetParam,
                    %ACLCompatGetParam,
                    CustomerUserID => $CustomerUser || $SelectedCustomerUser || '',
                    QueueID        => $NewQueueID   || 1,
                ),
                Types => $Self->_GetTypes(
                    %GetParam,
                    %ACLCompatGetParam,
                    CustomerUserID => $CustomerUser || $SelectedCustomerUser || '',
                    QueueID        => $NewQueueID   || 1,
                ),
                Services          => $Services,
                SLAs              => $SLAs,
                StandardTemplates => $Self->_GetStandardTemplates(
                    %GetParam,
                    %ACLCompatGetParam,
                    QueueID => $NewQueueID || '',
                ),
                CustomerID   => $LayoutObject->Ascii2Html( Text => $CustomerID ),
                CustomerUser => $CustomerUser,
                CustomerData => \%CustomerData,
                To           => $Self->_GetTos(
                    %GetParam,
                    %ACLCompatGetParam,
                    QueueID => $NewQueueID
                ),
                ToSelected  => $Dest,
                Errors      => \%Error,
                Attachments => \@Attachments,
                %GetParam,
                DynamicFieldHTML     => \%DynamicFieldHTML,
                MultipleCustomer     => \@MultipleCustomer,
                FromExternalCustomer => \%FromExternalCustomer,
            );

            $Output .= $LayoutObject->Footer();
            return $Output;
        }

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        # create new ticket, do db insert
        my $TicketID = $TicketObject->TicketCreate(
            Title        => $GetParam{Subject},
            QueueID      => $NewQueueID,
            Subject      => $GetParam{Subject},
            Lock         => 'unlock',
            TypeID       => $GetParam{TypeID},
            ServiceID    => $GetParam{ServiceID},
            SLAID        => $GetParam{SLAID},
            StateID      => $GetParam{NextStateID},
            PriorityID   => $GetParam{PriorityID},
            OwnerID      => 1,
            CustomerNo   => $CustomerID,
            CustomerUser => $SelectedCustomerUser,
            UserID       => $Self->{UserID},
        );

        # set ticket dynamic fields
        # cycle through the activated Dynamic Fields for this screen
        DYNAMICFIELD:
        for my $DynamicFieldConfig ( @{ $Self->{DynamicField} } ) {
            next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);
            next DYNAMICFIELD if $DynamicFieldConfig->{ObjectType} ne 'Ticket';

            # set the value
            my $Success = $DynamicFieldBackendObject->ValueSet(
                DynamicFieldConfig => $DynamicFieldConfig,
                ObjectID           => $TicketID,
                Value              => $DynamicFieldValues{ $DynamicFieldConfig->{Name} },
                UserID             => $Self->{UserID},
            );
        }

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

        my $PlainBody = $GetParam{Body};

        if ( $LayoutObject->{BrowserRichText} ) {
            $PlainBody = $LayoutObject->RichText2Ascii( String => $GetParam{Body} );
        }

        # check if new owner is given (then send no agent notify)
        my $NoAgentNotify = 0;
        if ( $GetParam{NewUserID} ) {
            $NoAgentNotify = 1;
        }
        my $ArticleObject        = $Kernel::OM->Get('Kernel::System::Ticket::Article');
        my $ArticleBackendObject = $ArticleObject->BackendForChannel( ChannelName => 'Phone' );
        my $ArticleID            = $ArticleBackendObject->ArticleCreate(
            NoAgentNotify        => $NoAgentNotify,
            TicketID             => $TicketID,
            SenderType           => $Config->{SenderType},
            IsVisibleForCustomer => $Config->{IsVisibleForCustomer},
            From                 => $GetParam{From},
            To                   => $To,
            Subject              => $GetParam{Subject},
            Body                 => $GetParam{Body},
            MimeType             => $MimeType,
            Charset              => $LayoutObject->{UserCharset},
            UserID               => $Self->{UserID},
            HistoryType          => $Config->{HistoryType},
            HistoryComment       => $Config->{HistoryComment} || '%%',
            AutoResponseType     => ( $ConfigObject->Get('AutoResponseForWebTickets') )
            ? 'auto reply'
            : '',
            OrigHeader => {
                From    => $GetParam{From},
                To      => $GetParam{To},
                Subject => $GetParam{Subject},
                Body    => $PlainBody,

            },
            Queue => $QueueObject->QueueLookup( QueueID => $NewQueueID ),
        );
        if ( !$ArticleID ) {
            return $LayoutObject->ErrorScreen();
        }

        # set article dynamic fields
        # cycle through the activated Dynamic Fields for this screen
        DYNAMICFIELD:
        for my $DynamicFieldConfig ( @{ $Self->{DynamicField} } ) {
            next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);
            next DYNAMICFIELD if $DynamicFieldConfig->{ObjectType} ne 'Article';

            # set the value
            my $Success = $DynamicFieldBackendObject->ValueSet(
                DynamicFieldConfig => $DynamicFieldConfig,
                ObjectID           => $ArticleID,
                Value              => $DynamicFieldValues{ $DynamicFieldConfig->{Name} },
                UserID             => $Self->{UserID},
            );
        }

        # Permissions check were done earlier
        if ( $GetParam{FromChatID} ) {
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
                    TicketID             => $TicketID,
                    SenderType           => $Config->{SenderType},
                    ChatMessageList      => \@ChatMessageList,
                    IsVisibleForCustomer => $Config->{IsVisibleForCustomer},
                    UserID               => $Self->{UserID},
                    HistoryType          => $Config->{HistoryType},
                    HistoryComment       => $Config->{HistoryComment} || '%%',
                );
            }
            if ($ChatArticleID) {

                # check is customer actively present
                # it means customer has accepted this chat and not left it!
                my $CustomerPresent = $ChatObject->CustomerPresent(
                    ChatID => $GetParam{FromChatID},
                    Active => 1,
                );

                my $Success;

                # if there is no customer present in the chat
                # just remove the chat
                if ( !$CustomerPresent ) {
                    $Success = $ChatObject->ChatDelete(
                        ChatID => $GetParam{FromChatID},
                    );
                }

                # otherwise set chat status to closed and inform other agents
                else {
                    $Success = $ChatObject->ChatUpdate(
                        ChatID     => $GetParam{FromChatID},
                        Status     => 'closed',
                        Deprecated => 1,
                    );

                    # get user data
                    my %User = $Kernel::OM->Get('Kernel::System::User')->GetUserData(
                        UserID => $Self->{UserID},
                    );

                    my $RequesterName = $User{UserFullname};
                    $RequesterName ||= $Self->{UserID};

                    my $LeaveMessage = $Kernel::OM->Get('Kernel::Language')->Translate(
                        "%s has left the chat.",
                        $RequesterName,
                    );

                    $Success = $ChatObject->ChatMessageAdd(
                        ChatID          => $GetParam{FromChatID},
                        ChatterID       => $Self->{UserID},
                        ChatterType     => 'User',
                        MessageText     => $LeaveMessage,
                        SystemGenerated => 1,
                    );

                    # time after chat will be removed
                    my $ChatTTL = $Kernel::OM->Get('Kernel::Config')->Get('ChatEngine::ChatTTL');

                    my $ChatClosedMessage = $Kernel::OM->Get('Kernel::Language')->Translate(
                        "This chat has been closed and will be removed in %s hours.",
                        $ChatTTL,
                    );

                    $Success = $ChatObject->ChatMessageAdd(
                        ChatID          => $GetParam{FromChatID},
                        ChatterID       => $Self->{UserID},
                        ChatterType     => 'User',
                        MessageText     => $ChatClosedMessage,
                        SystemGenerated => 1,
                    );

                    # remove all AGENT participants from chat
                    my @ParticipantsList = $ChatObject->ChatParticipantList(
                        ChatID => $GetParam{FromChatID},
                    );
                    CHATPARTICIPANT:
                    for my $ChatParticipant (@ParticipantsList) {

                        # skip it this participant is not agent
                        next CHATPARTICIPANT if $ChatParticipant->{ChatterType} ne 'User';

                        # remove this participants from the chat
                        $Success = $ChatObject->ChatParticipantRemove(
                            ChatID      => $GetParam{FromChatID},
                            ChatterID   => $ChatParticipant->{ChatterID},
                            ChatterType => 'User',
                        );
                    }
                }
            }
        }

        # set owner (if new user id is given)
        if ( $GetParam{NewUserID} ) {
            $TicketObject->TicketOwnerSet(
                TicketID  => $TicketID,
                NewUserID => $GetParam{NewUserID},
                UserID    => $Self->{UserID},
            );

            # set lock
            $TicketObject->TicketLockSet(
                TicketID => $TicketID,
                Lock     => 'lock',
                UserID   => $Self->{UserID},
            );
        }

        # else set owner to current agent but do not lock it
        else {
            $TicketObject->TicketOwnerSet(
                TicketID           => $TicketID,
                NewUserID          => $Self->{UserID},
                SendNoNotification => 1,
                UserID             => $Self->{UserID},
            );
        }

        # set responsible (if new user id is given)
        if ( $GetParam{NewResponsibleID} ) {
            $TicketObject->TicketResponsibleSet(
                TicketID  => $TicketID,
                NewUserID => $GetParam{NewResponsibleID},
                UserID    => $Self->{UserID},
            );
        }

        # time accounting
        if ( $GetParam{TimeUnits} ) {
            $TicketObject->TicketAccountTime(
                TicketID  => $TicketID,
                ArticleID => $ArticleID,
                TimeUnit  => $GetParam{TimeUnits},
                UserID    => $Self->{UserID},
            );
        }

        # write attachments
        for my $Attachment (@AttachmentData) {
            $ArticleBackendObject->ArticleWriteAttachment(
                %{$Attachment},
                TicketID  => $TicketID,
                ArticleID => $ArticleID,
                UserID    => $Self->{UserID},
            );
        }

        # remove pre submited attachments
        $UploadCacheObject->FormIDRemove( FormID => $Self->{FormID} );

        # link tickets
        if (
            $GetParam{LinkTicketID}
            && $Config->{SplitLinkType}
            && $Config->{SplitLinkType}->{LinkType}
            && $Config->{SplitLinkType}->{Direction}
            )
        {
            my $Access = $TicketObject->TicketPermission(
                Type     => 'ro',
                TicketID => $GetParam{LinkTicketID},
                UserID   => $Self->{UserID}
            );

            if ( !$Access ) {
                return $LayoutObject->NoPermission(
                    Message    => Translatable('You need ro permission!'),
                    WithHeader => 'yes',
                );
            }

            my $SourceKey = $GetParam{LinkTicketID};
            my $TargetKey = $TicketID;

            if ( $Config->{SplitLinkType}->{Direction} eq 'Source' ) {
                $SourceKey = $TicketID;
                $TargetKey = $GetParam{LinkTicketID};
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

        # closed tickets get unlocked
        if ( $StateData{TypeName} =~ /^close/i ) {

            # set lock
            $TicketObject->TicketLockSet(
                TicketID => $TicketID,
                Lock     => 'unlock',
                UserID   => $Self->{UserID},
            );
        }

        # set pending time
        elsif ( $StateData{TypeName} =~ /^pending/i ) {

            # set pending time
            $TicketObject->TicketPendingTimeSet(
                UserID   => $Self->{UserID},
                TicketID => $TicketID,
                %GetParam,
            );
        }

        # get redirect screen
        my $NextScreen = $Self->{UserCreateNextMask} || 'AgentTicketPhone';

        # redirect
        return $LayoutObject->Redirect(
            OP => "Action=$NextScreen;Subaction=Created;TicketID=$TicketID",
        );
    }
    elsif ( $Self->{Subaction} eq 'AJAXUpdate' ) {
        my $Dest           = $ParamObject->GetParam( Param => 'Dest' ) || '';
        my $CustomerUser   = $ParamObject->GetParam( Param => 'SelectedCustomerUser' );
        my $ElementChanged = $ParamObject->GetParam( Param => 'ElementChanged' ) || '';
        my $QueueID = '';
        if ( $Dest =~ /^(\d{1,100})\|\|.+?$/ ) {
            $QueueID = $1;
        }

        # get list type
        my $TreeView = 0;
        if ( $ConfigObject->Get('Ticket::Frontend::ListType') eq 'tree' ) {
            $TreeView = 1;
        }

        my $Tos = $Self->_GetTos(
            %GetParam,
            %ACLCompatGetParam,
            CustomerUserID => $CustomerUser || '',
            QueueID        => $QueueID,
        );

        my $NewTos;

        if ($Tos) {
            TOs:
            for my $KeyTo ( sort keys %{$Tos} ) {
                next TOs if ( $Tos->{$KeyTo} eq '-' );
                $NewTos->{"$KeyTo||$Tos->{$KeyTo}"} = $Tos->{$KeyTo};
            }
        }
        my $Users = $Self->_GetUsers(
            %GetParam,
            %ACLCompatGetParam,
            QueueID  => $QueueID,
            AllUsers => $GetParam{OwnerAll},
        );
        my $ResponsibleUsers = $Self->_GetResponsibles(
            %GetParam,
            %ACLCompatGetParam,
            QueueID  => $QueueID,
            AllUsers => $GetParam{ResponsibleAll},
        );
        my $NextStates = $Self->_GetNextStates(
            %GetParam,
            %ACLCompatGetParam,
            CustomerUserID => $CustomerUser || '',
            QueueID        => $QueueID      || 1,
        );
        my $Priorities = $Self->_GetPriorities(
            %GetParam,
            %ACLCompatGetParam,
            CustomerUserID => $CustomerUser || '',
            QueueID        => $QueueID      || 1,
        );
        my $Services = $Self->_GetServices(
            %GetParam,
            %ACLCompatGetParam,
            CustomerUserID => $CustomerUser || '',
            QueueID        => $QueueID      || 1,
        );
        my $SLAs = $Self->_GetSLAs(
            %GetParam,
            %ACLCompatGetParam,
            CustomerUserID => $CustomerUser || '',
            QueueID        => $QueueID      || 1,
            Services       => $Services,
        );
        my $StandardTemplates = $Self->_GetStandardTemplates(
            %GetParam,
            %ACLCompatGetParam,
            QueueID => $QueueID || '',
        );
        my $Types = $Self->_GetTypes(
            %GetParam,
            %ACLCompatGetParam,
            CustomerUserID => $CustomerUser || '',
            QueueID        => $QueueID      || 1,
        );

        # update Dynamic Fields Possible Values via AJAX
        my @DynamicFieldAJAX;

        # cycle through the activated Dynamic Fields for this screen
        DYNAMICFIELD:
        for my $DynamicFieldConfig ( @{ $Self->{DynamicField} } ) {
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
                %ACLCompatGetParam,
                CustomerUserID => $CustomerUser || '',
                Action         => $Self->{Action},
                QueueID        => $QueueID || 0,
                ReturnType     => 'Ticket',
                ReturnSubType  => 'DynamicField_' . $DynamicFieldConfig->{Name},
                Data           => \%AclData,
                UserID         => $Self->{UserID},
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
            push @DynamicFieldAJAX, {
                Name        => 'DynamicField_' . $DynamicFieldConfig->{Name},
                Data        => $DataValues,
                SelectedID  => $DynamicFieldValues{ $DynamicFieldConfig->{Name} },
                Translation => $DynamicFieldConfig->{Config}->{TranslatableValues} || 0,
                Max         => 100,
            };
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
                    TemplateID     => $GetParam{StandardTemplateID},
                    UserID         => $Self->{UserID},
                    CustomerUserID => $CustomerUser,
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
                    Name => 'UseTemplateCreate',
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
                    Name         => 'Dest',
                    Data         => $NewTos,
                    SelectedID   => $Dest,
                    Translation  => 0,
                    PossibleNone => 1,
                    TreeView     => $TreeView,
                    Max          => 100,
                },
                {
                    Name         => 'NewUserID',
                    Data         => $Users,
                    SelectedID   => $GetParam{NewUserID},
                    Translation  => 0,
                    PossibleNone => 1,
                    Max          => 100,
                },
                {
                    Name         => 'NewResponsibleID',
                    Data         => $ResponsibleUsers,
                    SelectedID   => $GetParam{NewResponsibleID},
                    Translation  => 0,
                    PossibleNone => 1,
                    Max          => 100,
                },
                {
                    Name        => 'NextStateID',
                    Data        => $NextStates,
                    SelectedID  => $GetParam{NextStateID},
                    Translation => 1,
                    Max         => 100,
                },
                {
                    Name        => 'PriorityID',
                    Data        => $Priorities,
                    SelectedID  => $GetParam{PriorityID},
                    Translation => 1,
                    Max         => 100,
                },
                {
                    Name         => 'ServiceID',
                    Data         => $Services,
                    SelectedID   => $GetParam{ServiceID},
                    PossibleNone => 1,
                    Translation  => 0,
                    TreeView     => $TreeView,
                    Max          => 100,
                },
                {
                    Name         => 'SLAID',
                    Data         => $SLAs,
                    SelectedID   => $GetParam{SLAID},
                    PossibleNone => 1,
                    Translation  => 0,
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
                {
                    Name         => 'TypeID',
                    Data         => $Types,
                    SelectedID   => $GetParam{TypeID},
                    PossibleNone => 1,
                    Translation  => 0,
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
    else {
        return $LayoutObject->ErrorScreen(
            Message => Translatable('No Subaction!'),
            Comment => Translatable('Please contact the administrator.'),
        );
    }
}

sub _GetNextStates {
    my ( $Self, %Param ) = @_;

    my %NextStates;
    if ( $Param{QueueID} || $Param{TicketID} ) {
        %NextStates = $Kernel::OM->Get('Kernel::System::Ticket')->TicketStateList(
            %Param,
            Action => $Self->{Action},
            UserID => $Self->{UserID},
        );
    }
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

    # get ticket object
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    # just show only users with selected custom queue
    if ( $Param{QueueID} && !$Param{AllUsers} ) {
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
    if ( $Kernel::OM->Get('Kernel::Config')->Get('Ticket::ChangeOwnerToEveryone') ) {
        %ShownUsers = %AllGroupsMembers;
    }

    # show all users who are owner or rw in the queue group
    elsif ( $Param{QueueID} ) {
        my $GID        = $Kernel::OM->Get('Kernel::System::Queue')->GetQueueGroupID( QueueID => $Param{QueueID} );
        my %MemberList = $Kernel::OM->Get('Kernel::System::Group')->PermissionGroupGet(
            GroupID => $GID,
            Type    => 'owner',
        );
        for my $KeyMember ( sort keys %MemberList ) {
            if ( $AllGroupsMembers{$KeyMember} ) {
                $ShownUsers{$KeyMember} = $AllGroupsMembers{$KeyMember};
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

sub _GetResponsibles {
    my ( $Self, %Param ) = @_;

    # get users
    my %ShownUsers;
    my %AllGroupsMembers = $Kernel::OM->Get('Kernel::System::User')->UserList(
        Type  => 'Long',
        Valid => 1,
    );

    # get ticket object
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    # just show only users with selected custom queue
    if ( $Param{QueueID} && !$Param{AllUsers} ) {
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
    if ( $Kernel::OM->Get('Kernel::Config')->Get('Ticket::ChangeOwnerToEveryone') ) {
        %ShownUsers = %AllGroupsMembers;
    }

    # show all users who are responsible or rw in the queue group
    elsif ( $Param{QueueID} ) {
        my $GID        = $Kernel::OM->Get('Kernel::System::Queue')->GetQueueGroupID( QueueID => $Param{QueueID} );
        my %MemberList = $Kernel::OM->Get('Kernel::System::Group')->PermissionGroupGet(
            GroupID => $GID,
            Type    => 'responsible',
        );
        for my $KeyMember ( sort keys %MemberList ) {
            if ( $AllGroupsMembers{$KeyMember} ) {
                $ShownUsers{$KeyMember} = $AllGroupsMembers{$KeyMember};
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

sub _GetPriorities {
    my ( $Self, %Param ) = @_;

    # get priority
    my %Priorities;
    if ( $Param{QueueID} || $Param{TicketID} ) {
        %Priorities = $Kernel::OM->Get('Kernel::System::Ticket')->TicketPriorityList(
            %Param,
            Action => $Self->{Action},
            UserID => $Self->{UserID},
        );
    }
    return \%Priorities;
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

sub _GetTos {
    my ( $Self, %Param ) = @_;

    # get config object
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # check own selection
    my %NewTos;
    if ( $ConfigObject->Get('Ticket::Frontend::NewQueueOwnSelection') ) {
        %NewTos = %{ $ConfigObject->Get('Ticket::Frontend::NewQueueOwnSelection') };
    }
    else {

        # SelectionType Queue or SystemAddress?
        my %Tos;
        if ( $ConfigObject->Get('Ticket::Frontend::NewQueueSelectionType') eq 'Queue' ) {
            %Tos = $Kernel::OM->Get('Kernel::System::Ticket')->MoveList(
                %Param,
                Type    => 'create',
                Action  => $Self->{Action},
                QueueID => $Self->{QueueID},
                UserID  => $Self->{UserID},
            );
        }
        else {
            %Tos = $Kernel::OM->Get('Kernel::System::SystemAddress')->SystemAddressQueueList();
        }

        # get create permission queues
        my %UserGroups = $Kernel::OM->Get('Kernel::System::Group')->PermissionUserGet(
            UserID => $Self->{UserID},
            Type   => 'create',
        );

        my $SystemAddressObject = $Kernel::OM->Get('Kernel::System::SystemAddress');
        my $QueueObject         = $Kernel::OM->Get('Kernel::System::Queue');

        # build selection string
        QUEUEID:
        for my $QueueID ( sort keys %Tos ) {

            my %QueueData = $QueueObject->QueueGet( ID => $QueueID );

            # permission check, can we create new tickets in queue
            next QUEUEID if !$UserGroups{ $QueueData{GroupID} };

            my $String = $ConfigObject->Get('Ticket::Frontend::NewQueueSelectionString')
                || '<Realname> <<Email>> - Queue: <Queue>';
            $String =~ s/<Queue>/$QueueData{Name}/g;
            $String =~ s/<QueueComment>/$QueueData{Comment}/g;

            # remove trailing spaces
            if ( !$QueueData{Comment} ) {
                $String =~ s{\s+\z}{};
            }

            if ( $ConfigObject->Get('Ticket::Frontend::NewQueueSelectionType') ne 'Queue' ) {
                my %SystemAddressData = $SystemAddressObject->SystemAddressGet(
                    ID => $Tos{$QueueID},
                );
                $String =~ s/<Realname>/$SystemAddressData{Realname}/g;
                $String =~ s/<Email>/$SystemAddressData{Name}/g;
            }
            $NewTos{$QueueID} = $String;
        }
    }

    # add empty selection
    $NewTos{''} = '-';
    return \%NewTos;
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

sub _GetStandardTemplates {
    my ( $Self, %Param ) = @_;

    my %Templates;
    my $QueueID = $Param{QueueID} || '';

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $QueueObject  = $Kernel::OM->Get('Kernel::System::Queue');

    if ( !$QueueID ) {
        my $UserDefaultQueue = $ConfigObject->Get('Ticket::Frontend::UserDefaultQueue') || '';

        if ($UserDefaultQueue) {
            $QueueID = $QueueObject->QueueLookup( Queue => $UserDefaultQueue );
        }
    }

    # check needed
    return \%Templates if !$QueueID && !$Param{TicketID};

    if ( !$QueueID && $Param{TicketID} ) {

        # get QueueID from the ticket
        my %Ticket = $Kernel::OM->Get('Kernel::System::Ticket')->TicketGet(
            TicketID      => $Param{TicketID},
            DynamicFields => 0,
            UserID        => $Self->{UserID},
        );
        $QueueID = $Ticket{QueueID} || '';
    }

    # fetch all std. templates
    my %StandardTemplates = $QueueObject->QueueStandardTemplateMemberList(
        QueueID       => $QueueID,
        TemplateTypes => 1,
    );

    # return empty hash if there are no templates for this screen
    return \%Templates if !IsHashRefWithData( $StandardTemplates{Create} );

    # return just the templates for this screen
    return $StandardTemplates{Create};
}

sub _MaskPhoneNew {
    my ( $Self, %Param ) = @_;

    $Param{FormID} = $Self->{FormID};

    # get config object
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # get list type
    my $TreeView = 0;
    if ( $ConfigObject->Get('Ticket::Frontend::ListType') eq 'tree' ) {
        $TreeView = 1;
    }

    # get layout object
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # set JS data
    $LayoutObject->AddJSData(
        Key   => 'CustomerSearch',
        Value => {
            ShowCustomerTickets => $ConfigObject->Get('Ticket::Frontend::ShowCustomerTickets'),
            AllowMultipleFrom   => $ConfigObject->Get('Ticket::Frontend::AgentTicketPhone::AllowMultipleFrom'),
        },
    );

    # build string
    $Param{OptionStrg} = $LayoutObject->BuildSelection(
        Data         => $Param{Users},
        SelectedID   => $Param{UserSelected},
        Class        => 'Modernize',
        Translation  => 0,
        Name         => 'NewUserID',
        PossibleNone => 1,
    );

    my $Config = $ConfigObject->Get("Ticket::Frontend::$Self->{Action}");

    # build next states string
    $Param{NextStatesStrg} = $LayoutObject->BuildSelection(
        Data          => $Param{NextStates},
        Name          => 'NextStateID',
        Class         => 'Modernize',
        Translation   => 1,
        SelectedValue => $Param{NextState} || $Config->{StateDefault},
    );

    # build to string
    my %NewTo;
    if ( $Param{To} ) {
        for my $KeyTo ( sort keys %{ $Param{To} } ) {
            $NewTo{"$KeyTo||$Param{To}->{$KeyTo}"} = $Param{To}->{$KeyTo};
        }
    }
    if ( !$Param{ToSelected} ) {
        my $UserDefaultQueue = $ConfigObject->Get('Ticket::Frontend::UserDefaultQueue') || '';

        if ($UserDefaultQueue) {
            my $QueueID = $Kernel::OM->Get('Kernel::System::Queue')->QueueLookup( Queue => $UserDefaultQueue );
            if ($QueueID) {
                $Param{ToSelected} = "$QueueID||$UserDefaultQueue";
            }
        }
    }
    if ( $ConfigObject->Get('Ticket::Frontend::NewQueueSelectionType') eq 'Queue' ) {
        $Param{ToStrg} = $LayoutObject->AgentQueueListOption(
            Class          => 'Validate_Required Modernize',
            Data           => \%NewTo,
            Multiple       => 0,
            Size           => 0,
            Name           => 'Dest',
            TreeView       => $TreeView,
            SelectedID     => $Param{ToSelected},
            OnChangeSubmit => 0,
        );
    }
    else {
        $Param{ToStrg} = $LayoutObject->BuildSelection(
            Class       => 'Validate_Required Modernize',
            Data        => \%NewTo,
            Name        => 'Dest',
            TreeView    => $TreeView,
            SelectedID  => $Param{ToSelected},
            Translation => 0,
        );
    }

    # customer info string
    if ( $ConfigObject->Get('Ticket::Frontend::CustomerInfoCompose') ) {
        $Param{CustomerTable} = $LayoutObject->AgentCustomerViewTable(
            Data => $Param{CustomerData},
            Max  => $ConfigObject->Get('Ticket::Frontend::CustomerInfoComposeMaxSize'),
        );
        $LayoutObject->Block(
            Name => 'CustomerTable',
            Data => \%Param,
        );
    }

    # prepare errors!
    if ( $Param{Errors} ) {
        for my $KeyError ( sort keys %{ $Param{Errors} } ) {
            $Param{$KeyError} = '* ' . $LayoutObject->Ascii2Html( Text => $Param{Errors}->{$KeyError} );
        }
    }

    # From external
    my $ShowErrors = 1;
    if (
        defined $Param{FromExternalCustomer} &&
        defined $Param{FromExternalCustomer}->{Email} &&
        defined $Param{FromExternalCustomer}->{Customer}
        )
    {
        $ShowErrors = 0;
        $LayoutObject->AddJSData(
            Key   => 'FromExternalCustomerName',
            Value => $Param{FromExternalCustomer}->{Customer},
        );
        $LayoutObject->AddJSData(
            Key   => 'FromExternalCustomerEmail',
            Value => $Param{FromExternalCustomer}->{Email},
        );
    }
    my $CustomerCounter = 0;
    if ( $Param{MultipleCustomer} ) {
        for my $Item ( @{ $Param{MultipleCustomer} } ) {
            if ( !$ShowErrors ) {

                # set empty values for errors
                $Item->{CustomerError}    = '';
                $Item->{CustomerDisabled} = '';
                $Item->{CustomerErrorMsg} = 'CustomerGenericServerErrorMsg';
            }
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

    if ( $Param{FromInvalid} && $Param{Errors} && !$Param{Errors}->{FromErrorType} ) {
        $LayoutObject->Block( Name => 'FromServerErrorMsg' );
    }
    if ( $Param{Errors}->{FromErrorType} || !$ShowErrors ) {
        $Param{FromInvalid} = '';
    }

    my $DynamicFieldNames = $Self->_GetFieldsToUpdate(
        OnlyDynamicFields => 1
    );

    # send data to JS
    $LayoutObject->AddJSData(
        Key   => 'DynamicFieldNames',
        Value => $DynamicFieldNames,
    );

    # build type string
    if ( $ConfigObject->Get('Ticket::Type') ) {
        $Param{TypeStrg} = $LayoutObject->BuildSelection(
            Class        => 'Modernize Validate_Required' . ( $Param{Errors}->{TypeIDInvalid} || ' ' ),
            Data         => $Param{Types},
            Name         => 'TypeID',
            SelectedID   => $Param{TypeID},
            PossibleNone => 1,
            Sort         => 'AlphanumericValue',
            Translation  => 0,
        );
        $LayoutObject->Block(
            Name => 'TicketType',
            Data => {%Param},
        );
    }

    # build service string
    if ( $ConfigObject->Get('Ticket::Service') ) {

        $Param{ServiceStrg} = $LayoutObject->BuildSelection(
            Data  => $Param{Services},
            Name  => 'ServiceID',
            Class => 'Modernize '
                . ( $Config->{ServiceMandatory} ? 'Validate_Required ' : '' )
                . ( $Param{Errors}->{ServiceIDInvalid} || '' ),
            SelectedID   => $Param{ServiceID},
            PossibleNone => 1,
            TreeView     => $TreeView,
            Sort         => 'TreeView',
            Translation  => 0,
            Max          => 200,
        );
        $LayoutObject->Block(
            Name => 'TicketService',
            Data => {
                ServiceMandatory => $Config->{ServiceMandatory} || 0,
                %Param,
            },
        );

        $Param{SLAStrg} = $LayoutObject->BuildSelection(
            Data       => $Param{SLAs},
            Name       => 'SLAID',
            SelectedID => $Param{SLAID},
            Class      => 'Modernize '
                . ( $Config->{SLAMandatory} ? 'Validate_Required ' : '' )
                . ( $Param{Errors}->{SLAInvalid} || '' ),
            PossibleNone => 1,
            Sort         => 'AlphanumericValue',
            Translation  => 0,
            Max          => 200,
        );
        $LayoutObject->Block(
            Name => 'TicketSLA',
            Data => {
                SLAMandatory => $Config->{SLAMandatory} || 0,
                %Param
            },
        );
    }

    # check if exists create templates regardless the queue
    my %StandardTemplates = $Kernel::OM->Get('Kernel::System::StandardTemplate')->StandardTemplateList(
        Valid => 1,
        Type  => 'Create',
    );

    # build text template string
    if ( IsHashRefWithData( \%StandardTemplates ) ) {
        $Param{StandardTemplateStrg} = $LayoutObject->BuildSelection(
            Data         => $Param{StandardTemplates} || {},
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

    # build priority string
    if ( !$Param{PriorityID} ) {
        $Param{Priority} = $Config->{Priority};
    }
    $Param{PriorityStrg} = $LayoutObject->BuildSelection(
        Data          => $Param{Priorities},
        Name          => 'PriorityID',
        SelectedID    => $Param{PriorityID},
        SelectedValue => $Param{Priority},
        Class         => 'Modernize',
        Translation   => 1,
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
    );

    # show owner selection
    if ( $ConfigObject->Get('Ticket::Frontend::NewOwnerSelection') ) {
        $LayoutObject->Block(
            Name => 'OwnerSelection',
            Data => \%Param,
        );
    }

    # show responsible selection
    if (
        $ConfigObject->Get('Ticket::Responsible')
        && $ConfigObject->Get('Ticket::Frontend::NewResponsibleSelection')
        )
    {
        $Param{ResponsibleUsers}->{''} = '-';
        $Param{ResponsibleOptionStrg} = $LayoutObject->BuildSelection(
            Data       => $Param{ResponsibleUsers},
            SelectedID => $Param{ResponsibleUserSelected},
            Name       => 'NewResponsibleID',
            Class      => 'Modernize',
        );
        $LayoutObject->Block(
            Name => 'ResponsibleSelection',
            Data => \%Param,
        );
    }

    # Dynamic fields
    # cycle trough the activated Dynamic Fields for this screen
    DYNAMICFIELD:
    for my $DynamicFieldConfig ( @{ $Self->{DynamicField} } ) {
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

    # show customer edit link
    my $OptionCustomer = $LayoutObject->Permission(
        Action => 'AdminCustomerUser',
        Type   => 'rw',
    );

    my $ShownOptionsBlock;

    if ($OptionCustomer) {

        # check if need to call Options block
        if ( !$ShownOptionsBlock ) {
            $LayoutObject->Block(
                Name => 'TicketOptions',
                Data => {
                    %Param,
                },
            );

            # set flag to "true" in order to prevent calling the Options block again
            $ShownOptionsBlock = 1;
        }

        $LayoutObject->Block(
            Name => 'OptionCustomer',
            Data => {
                %Param,
            },
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

    # Permissions have been checked before in Run()
    if ( $Param{FromChatID} ) {
        my @ChatMessages = $Kernel::OM->Get('Kernel::System::Chat')->ChatMessageList(
            ChatID => $Param{FromChatID},
        );

        for my $Message (@ChatMessages) {
            $Message->{MessageText} = $LayoutObject->Ascii2Html(
                Text        => $Message->{MessageText},
                LinkFeature => 1,
            );
        }

        $LayoutObject->Block(
            Name => 'ChatArticlePreview',
            Data => {
                ChatMessages => \@ChatMessages,
            },
        );
    }

    # get output back
    return $LayoutObject->Output(
        TemplateFile => 'AgentTicketPhone',
        Data         => \%Param,
    );
}

sub _GetFieldsToUpdate {
    my ( $Self, %Param ) = @_;

    my @UpdatableFields;

    # set the fields that can be updatable via AJAXUpdate
    if ( !$Param{OnlyDynamicFields} ) {
        @UpdatableFields = qw(
            TypeID
            Dest
            ServiceID
            SLAID
            NewUserID
            NewResponsibleID
            NextStateID
            PriorityID
            StandardTemplateID
        );
    }

    # cycle trough the activated Dynamic Fields for this screen
    DYNAMICFIELD:
    for my $DynamicFieldConfig ( @{ $Self->{DynamicField} } ) {
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
