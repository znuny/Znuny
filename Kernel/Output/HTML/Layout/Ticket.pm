# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Output::HTML::Layout::Ticket;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);
use Kernel::Language qw(Translatable);

our $ObjectManagerDisabled = 1;

=head1 NAME

Kernel::Output::HTML::Layout::Ticket - all Ticket-related HTML functions

=head1 DESCRIPTION

All Ticket-related HTML functions

=head1 PUBLIC INTERFACE

=head2 AgentCustomerViewTable()

=cut

sub AgentCustomerViewTable {
    my ( $Self, %Param ) = @_;

    # check customer params
    if ( ref $Param{Data} ne 'HASH' ) {
        $Self->FatalError( Message => 'Need Hash ref in Data param' );
    }
    elsif ( ref $Param{Data} eq 'HASH' && !%{ $Param{Data} } ) {
        return $Self->{LanguageObject}->Translate('none');
    }

    # add ticket params if given
    if ( $Param{Ticket} ) {
        %{ $Param{Data} } = ( %{ $Param{Data} }, %{ $Param{Ticket} } );
    }

    my @MapNew;
    my $Map = $Param{Data}->{Config}->{Map};
    if ($Map) {
        @MapNew = ( @{$Map} );
    }

    # check if customer company support is enabled
    if ( $Param{Data}->{Config}->{CustomerCompanySupport} ) {
        my $Map2 = $Param{Data}->{CompanyConfig}->{Map};
        if ($Map2) {
            push( @MapNew, @{$Map2} );
        }
    }

    my $ShownType = 1;
    if ( $Param{Type} && $Param{Type} eq Translatable('Lite') ) {
        $ShownType = 2;

        # check if min one lite view item is configured, if not, use
        # the normal view also
        my $Used = 0;
        for my $Field (@MapNew) {
            if ( $Field->[3] == 2 ) {
                $Used = 1;
            }
        }
        if ( !$Used ) {
            $ShownType = 1;
        }
    }

    # build html table
    $Self->Block(
        Name => 'Customer',
        Data => $Param{Data},
    );

    # get needed objects
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $MainObject   = $Kernel::OM->Get('Kernel::System::Main');

    # check Frontend::CustomerUser::Image
    my $CustomerImage = $ConfigObject->Get('Frontend::CustomerUser::Image');
    if ($CustomerImage) {
        my %Modules = %{$CustomerImage};

        MODULE:
        for my $Module ( sort keys %Modules ) {
            if ( !$MainObject->Require( $Modules{$Module}->{Module} ) ) {
                $Self->FatalDie();
            }

            my $Object = $Modules{$Module}->{Module}->new(
                %{$Self},
                LayoutObject => $Self,
            );

            # run module
            next MODULE if !$Object;

            $Object->Run(
                Config => $Modules{$Module},
                Data   => $Param{Data},
            );
        }
    }

    my $DynamicFieldConfigs = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldListGet(
        ObjectType => [ 'CustomerUser', 'CustomerCompany', ],
    );

    my %DynamicFieldLookup = map { $_->{Name} => $_ } @{$DynamicFieldConfigs};

    # Get dynamic field object.
    my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    # build table
    FIELD:
    for my $Field (@MapNew) {
        if ( $Field->[3] && $Field->[3] >= $ShownType && $Param{Data}->{ $Field->[0] } ) {
            my %Record = (
                %{ $Param{Data} },
                Key   => $Field->[1],
                Value => $Param{Data}->{ $Field->[0] },
            );

            # render dynamic field values
            if ( $Field->[5] eq 'dynamic_field' ) {
                if ( !IsArrayRefWithData( $Record{Value} ) ) {
                    $Record{Value} = [ $Record{Value} ];
                }

                my $DynamicFieldConfig = $DynamicFieldLookup{ $Field->[2] };

                next FIELD if !$DynamicFieldConfig;

                my @RenderedValues;
                VALUE:
                for my $Value ( @{ $Record{Value} } ) {
                    my $RenderedValue = $DynamicFieldBackendObject->DisplayValueRender(
                        DynamicFieldConfig => $DynamicFieldConfig,
                        Value              => $Value,
                        HTMLOutput         => 0,
                        LayoutObject       => $Self,
                    );

                    next VALUE if !IsHashRefWithData($RenderedValue) || !defined $RenderedValue->{Value};

                    # If there is configured show link in DF, save as map value.
                    $Field->[6] = $RenderedValue->{Link} ? $RenderedValue->{Link} : $Field->[6];

                    push @RenderedValues, $RenderedValue->{Value};
                }

                $Record{Value} = join ', ', @RenderedValues;
                $Record{Key}   = $DynamicFieldConfig->{Label};
            }

            if (
                $Field->[6]
                && (
                    $Param{Data}->{TicketID}
                    || $Param{Ticket}
                    || $Field->[6] !~ m{Env\("CGIHandle"\)}
                )
                )
            {
                $Record{LinkStart} = "<a href=\"$Field->[6]\"";
                if ( !$Param{Ticket} ) {
                    $Record{LinkStart} .= " target=\"_blank\"";
                }
                elsif ( $Field->[8] ) {
                    $Record{LinkStart} .= " target=\"$Field->[8]\"";
                }
                if ( $Field->[9] ) {
                    $Record{LinkStart} .= " class=\"$Field->[9]\"";
                }
                $Record{LinkStart} .= ">";
                $Record{LinkStop} = "</a>";
            }
            if ( $Field->[0] ) {
                $Record{ValueShort} = $Self->Ascii2Html(
                    Text => $Record{Value},
                    Max  => $Param{Max}
                );
            }
            $Self->Block(
                Name => 'CustomerRow',
                Data => \%Record,
            );

            if (
                $Param{Data}->{Config}->{CustomerCompanySupport}
                && $Field->[0] eq 'CustomerCompanyName'
                )
            {
                my $CompanyValidID = $Param{Data}->{CustomerCompanyValidID};

                if ($CompanyValidID) {
                    my @ValidIDs       = $Kernel::OM->Get('Kernel::System::Valid')->ValidIDsGet();
                    my $CompanyIsValid = grep { $CompanyValidID == $_ } @ValidIDs;

                    if ( !$CompanyIsValid ) {
                        $Self->Block(
                            Name => 'CustomerRowCustomerCompanyInvalid',
                        );
                    }
                }
            }

            if (
                $ConfigObject->Get('ChatEngine::Active')
                && $Field->[0] eq 'UserLogin'
                )
            {
                # Check if agent has permission to start chats with the customer users.
                my $EnableChat = 1;
                my $ChatStartingAgentsGroup
                    = $ConfigObject->Get('ChatEngine::PermissionGroup::ChatStartingAgents') || 'users';
                my $ChatStartingAgentsGroupPermission = $Kernel::OM->Get('Kernel::System::Group')->PermissionCheck(
                    UserID    => $Self->{UserID},
                    GroupName => $ChatStartingAgentsGroup,
                    Type      => 'rw',
                );

                if ( !$ChatStartingAgentsGroupPermission ) {
                    $EnableChat = 0;
                }
                if (
                    $EnableChat
                    && !$ConfigObject->Get('ChatEngine::ChatDirection::AgentToCustomer')
                    )
                {
                    $EnableChat = 0;
                }

                if ($EnableChat) {
                    my $VideoChatEnabled = 0;
                    my $VideoChatAgentsGroup
                        = $ConfigObject->Get('ChatEngine::PermissionGroup::VideoChatAgents') || 'users';
                    my $VideoChatAgentsGroupPermission = $Kernel::OM->Get('Kernel::System::Group')->PermissionCheck(
                        UserID    => $Self->{UserID},
                        GroupName => $VideoChatAgentsGroup,
                        Type      => 'rw',
                    );

                    # Enable the video chat feature if system is entitled and agent is a member of configured group.
                    if ($VideoChatAgentsGroupPermission) {
                        if ( $Kernel::OM->Get('Kernel::System::Main')
                            ->Require( 'Kernel::System::VideoChat', Silent => 1 ) )
                        {
                            $VideoChatEnabled = $Kernel::OM->Get('Kernel::System::VideoChat')->IsEnabled();
                        }
                    }

                    my $CustomerEnableChat = 0;
                    my $ChatAccess         = 0;
                    my $VideoChatAvailable = 0;
                    my $VideoChatSupport   = 0;

                    # Default status is offline.
                    my $UserState            = Translatable('Offline');
                    my $UserStateDescription = $Self->{LanguageObject}->Translate('User is currently offline.');

                    my $CustomerChatAvailability = $Kernel::OM->Get('Kernel::System::Chat')->CustomerAvailabilityGet(
                        UserID => $Param{Data}->{UserID},
                    );

                    my $CustomerUserObject = $Kernel::OM->Get('Kernel::System::CustomerUser');

                    my %CustomerUser = $CustomerUserObject->CustomerUserDataGet(
                        User => $Param{Data}->{UserID},
                    );
                    $CustomerUser{UserFullname} = $CustomerUserObject->CustomerName(
                        UserLogin => $Param{Data}->{UserID},
                    );
                    $VideoChatSupport = 1 if $CustomerUser{VideoChatHasWebRTC};

                    if ( $CustomerChatAvailability == 3 ) {
                        $UserState            = Translatable('Active');
                        $CustomerEnableChat   = 1;
                        $UserStateDescription = $Self->{LanguageObject}->Translate('User is currently active.');
                        $VideoChatAvailable   = 1;
                    }
                    elsif ( $CustomerChatAvailability == 2 ) {
                        $UserState            = Translatable('Away');
                        $CustomerEnableChat   = 1;
                        $UserStateDescription = $Self->{LanguageObject}->Translate('User was inactive for a while.');
                    }

                    $Self->Block(
                        Name => 'CustomerRowUserStatus',
                        Data => {
                            %CustomerUser,
                            UserState            => $UserState,
                            UserStateDescription => $UserStateDescription,
                        },
                    );

                    if ($CustomerEnableChat) {
                        $Self->Block(
                            Name => 'CustomerRowChatIcons',
                            Data => {
                                %{ $Param{Data} },
                                %CustomerUser,
                                VideoChatEnabled   => $VideoChatEnabled,
                                VideoChatAvailable => $VideoChatAvailable,
                                VideoChatSupport   => $VideoChatSupport,
                            },
                        );
                    }
                }
            }
        }
    }

    # check Frontend::CustomerUser::Item
    my $CustomerItem      = $ConfigObject->Get('Frontend::CustomerUser::Item');
    my $CustomerItemCount = 0;
    if ($CustomerItem) {
        $Self->Block(
            Name => 'CustomerItem',
        );
        my %Modules = %{$CustomerItem};

        MODULE:
        for my $Module ( sort keys %Modules ) {
            if ( !$MainObject->Require( $Modules{$Module}->{Module} ) ) {
                $Self->FatalDie();
            }

            my $Object = $Modules{$Module}->{Module}->new(
                %{$Self},
                LayoutObject => $Self,
            );

            # run module
            next MODULE if !$Object;

            my $Run = $Object->Run(
                Config => $Modules{$Module},
                Data   => $Param{Data},
            );

            next MODULE if !$Run;

            $CustomerItemCount++;
        }
    }

    # create & return output
    return $Self->Output(
        TemplateFile => 'AgentCustomerTableView',
        Data         => \%Param
    );
}

sub AgentQueueListOption {
    my ( $Self, %Param ) = @_;

    my $Size           = $Param{Size}                      ? "size='$Param{Size}'"  : '';
    my $MaxLevel       = defined( $Param{MaxLevel} )       ? $Param{MaxLevel}       : 10;
    my $SelectedID     = defined( $Param{SelectedID} )     ? $Param{SelectedID}     : '';
    my $Selected       = defined( $Param{Selected} )       ? $Param{Selected}       : '';
    my $CurrentQueueID = defined( $Param{CurrentQueueID} ) ? $Param{CurrentQueueID} : '';
    my $Class          = defined( $Param{Class} )          ? $Param{Class}          : '';
    my $SelectedIDRefArray = $Param{SelectedIDRefArray} || '';
    my $Multiple           = $Param{Multiple} ? 'multiple = "multiple"' : '';
    my $TreeView           = $Param{TreeView} ? $Param{TreeView} : 0;
    my $OptionTitle        = defined( $Param{OptionTitle} ) ? $Param{OptionTitle} : 0;
    my $OnChangeSubmit     = defined( $Param{OnChangeSubmit} ) ? $Param{OnChangeSubmit} : '';

    if ($OnChangeSubmit) {
        $OnChangeSubmit = " onchange=\"submit();\"";
    }
    else {
        $OnChangeSubmit = '';
    }

    # set OnChange if AJAX is used
    if ( $Param{Ajax} ) {

        # get log object
        my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

        if ( !$Param{Ajax}->{Depend} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => 'Need Depend Param Ajax option!',
            );
            $Self->FatalError();
        }
        if ( !$Param{Ajax}->{Update} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => 'Need Update Param Ajax option()!',
            );
            $Self->FatalError();
        }
        $Param{OnChange} = "Core.AJAX.FormUpdate(\$('#"
            . $Param{Name} . "'), '"
            . $Param{Ajax}->{Subaction} . "',"
            . " '$Param{Name}',"
            . " ['"
            . join( "', '", @{ $Param{Ajax}->{Update} } ) . "']);";
    }

    if ( $Param{OnChange} ) {
        $OnChangeSubmit = " onchange=\"$Param{OnChange}\"";
    }

    # just show a simple list
    if ( $Kernel::OM->Get('Kernel::Config')->Get('Ticket::Frontend::ListType') eq 'list' ) {

        # transform data from Hash in Array because of ordering in frontend by Queue name
        # it was a problem with name like '(some_queue)'
        # see bug#10621 http://bugs.otrs.org/show_bug.cgi?id=10621
        my %QueueDataHash  = %{ $Param{Data} || {} };
        my @QueueDataArray = map {
            {
                Key   => $_,
                Value => $QueueDataHash{$_},
            }
        } sort { $QueueDataHash{$a} cmp $QueueDataHash{$b} } keys %QueueDataHash;

        # find index of first element in array @QueueDataArray for displaying in frontend
        # at the top should be element with ' $QueueDataArray[$_]->{Key} = 0' like "- Move -"
        # if such an element is found, it is moved to the top
        my $MoveStr             = $Self->{LanguageObject}->Translate('Move');
        my $ValueOfQueueNoKey   = '- ' . $MoveStr . ' -';
        my ($FirstElementIndex) = grep {
            $QueueDataArray[$_]->{Value} eq '-'
                || $QueueDataArray[$_]->{Value} eq $ValueOfQueueNoKey
        } 0 .. scalar(@QueueDataArray) - 1;
        if ($FirstElementIndex) {
            splice( @QueueDataArray, 0, 0, splice( @QueueDataArray, $FirstElementIndex, 1 ) );
        }
        $Param{Data} = \@QueueDataArray;

        $Param{MoveQueuesStrg} = $Self->BuildSelection(
            %Param,
            HTMLQuote     => 0,
            SelectedID    => $Param{SelectedID} || $Param{SelectedIDRefArray} || '',
            SelectedValue => $Param{Selected},
            Translation   => 0,
        );
        return $Param{MoveQueuesStrg};
    }

    # build tree list
    $Param{MoveQueuesStrg} = '<select name="'
        . $Param{Name}
        . '" id="'
        . $Param{Name}
        . '" class="'
        . $Class
        . '" data-tree="true"'
        . " $Size $Multiple $OnChangeSubmit>\n";
    my %UsedData;
    my %Data;

    if ( $Param{Data} && ref $Param{Data} eq 'HASH' ) {
        %Data = %{ $Param{Data} };
    }
    else {
        return 'Need Data Ref in AgentQueueListOption()!';
    }

    # add suffix for correct sorting
    my $KeyNoQueue;
    my $ValueNoQueue;
    my $MoveStr           = $Self->{LanguageObject}->Translate('Move');
    my $ValueOfQueueNoKey = "- " . $MoveStr . " -";

    DATA:
    for my $DataKey ( sort { $Data{$a} cmp $Data{$b} } keys %Data ) {

        # find value for default item in select box
        # it can be "-" or "Move"
        if (
            $Data{$DataKey} eq "-"
            || $Data{$DataKey} eq $ValueOfQueueNoKey
            )
        {
            $KeyNoQueue   = $DataKey;
            $ValueNoQueue = $Data{$DataKey};
            next DATA;
        }
        $Data{$DataKey} .= '::';
    }

    # get HTML utils object
    my $HTMLUtilsObject = $Kernel::OM->Get('Kernel::System::HTMLUtils');

    # set default item of select box
    if ($ValueNoQueue) {
        $Param{MoveQueuesStrg} .= '<option value="'
            . $HTMLUtilsObject->ToHTML(
            String             => $KeyNoQueue,
            ReplaceDoubleSpace => 0,
            )
            . '">'
            . $ValueNoQueue
            . "</option>\n";
    }

    # build selection string
    KEY:
    for my $DataKey ( sort { $Data{$a} cmp $Data{$b} } keys %Data ) {

        # default item of select box has set already
        next KEY if ( $Data{$DataKey} eq "-" || $Data{$DataKey} eq $ValueOfQueueNoKey );

        my @Queue = split( /::/, $Param{Data}->{$DataKey} );
        $UsedData{ $Param{Data}->{$DataKey} } = 1;
        my $UpQueue = $Param{Data}->{$DataKey};
        $UpQueue =~ s/^(.*)::.+?$/$1/g;
        if ( !$Queue[$MaxLevel] && $Queue[-1] ne '' ) {
            $Queue[-1] = $Self->Ascii2Html(
                Text => $Queue[-1],
                Max  => 50 - $#Queue
            );
            my $Space = '';
            for ( my $i = 0; $i < $#Queue; $i++ ) {
                $Space .= '&nbsp;&nbsp;';
            }

            # check if SelectedIDRefArray exists
            if ($SelectedIDRefArray) {
                for my $ID ( @{$SelectedIDRefArray} ) {
                    if ( $ID eq $DataKey ) {
                        $Param{SelectedIDRefArrayOK}->{$DataKey} = 1;
                    }
                }
            }

            if ( !$UsedData{$UpQueue} ) {

                # integrate the not selectable parent and root queues of this queue
                # useful for ACLs and complex permission settings
                for my $Index ( 0 .. ( scalar @Queue - 2 ) ) {

                    # get the Full Queue Name (with all its parents separated by '::') this will
                    # make a unique name and will be used to set the %DisabledQueueAlreadyUsed
                    # using unique names will prevent erroneous hide of Sub-Queues with the
                    # same name, refer to bug#8148
                    my $FullQueueName;
                    for my $Counter ( 0 .. $Index ) {
                        $FullQueueName .= $Queue[$Counter];
                        if ( int $Counter < int $Index ) {
                            $FullQueueName .= '::';
                        }
                    }

                    if ( !$UsedData{$FullQueueName} ) {
                        my $DSpace               = '&nbsp;&nbsp;' x $Index;
                        my $OptionTitleHTMLValue = '';
                        if ($OptionTitle) {
                            my $HTMLValue = $HTMLUtilsObject->ToHTML(
                                String             => $Queue[$Index],
                                ReplaceDoubleSpace => 0,
                            );
                            $OptionTitleHTMLValue = ' title="' . $HTMLValue . '"';
                        }
                        $Param{MoveQueuesStrg}
                            .= '<option value="-" disabled="disabled"'
                            . $OptionTitleHTMLValue
                            . '>'
                            . $DSpace
                            . $Queue[$Index]
                            . "</option>\n";
                        $UsedData{$FullQueueName} = 1;
                    }
                }
            }

            # create selectable elements
            my $String               = $Space . $Queue[-1];
            my $OptionTitleHTMLValue = '';
            if ($OptionTitle) {
                my $HTMLValue = $HTMLUtilsObject->ToHTML(
                    String             => $Queue[-1],
                    ReplaceDoubleSpace => 0,
                );
                $OptionTitleHTMLValue = ' title="' . $HTMLValue . '"';
            }
            my $HTMLValue = $HTMLUtilsObject->ToHTML(
                String             => $DataKey,
                ReplaceDoubleSpace => 0,
            );
            if (
                $SelectedID eq $DataKey
                || $Selected eq $Param{Data}->{$DataKey}
                || $Param{SelectedIDRefArrayOK}->{$DataKey}
                )
            {
                $Param{MoveQueuesStrg}
                    .= '<option selected="selected" value="'
                    . $HTMLValue . '"'
                    . $OptionTitleHTMLValue . '>'
                    . $String
                    . "</option>\n";
            }
            elsif ( $CurrentQueueID eq $DataKey )
            {
                $Param{MoveQueuesStrg}
                    .= '<option value="-" disabled="disabled"'
                    . $OptionTitleHTMLValue . '>'
                    . $String
                    . "</option>\n";
            }
            else {
                $Param{MoveQueuesStrg}
                    .= '<option value="'
                    . $HTMLValue . '"'
                    . $OptionTitleHTMLValue . '>'
                    . $String
                    . "</option>\n";
            }
        }
    }
    $Param{MoveQueuesStrg} .= "</select>\n";

    if ( $Param{TreeView} ) {
        my $TreeSelectionMessage = $Self->{LanguageObject}->Translate("Show Tree Selection");
        $Param{MoveQueuesStrg}
            .= ' <a href="#" title="'
            . $TreeSelectionMessage
            . '" class="ShowTreeSelection"><span>'
            . $TreeSelectionMessage . '</span><i class="fa fa-sitemap"></i></a>';
    }

    return $Param{MoveQueuesStrg};
}

sub TicketListShow {
    my ( $Self, %Param ) = @_;

    # take object ref to local, remove it from %Param (prevent memory leak)
    my $Env = $Param{Env};
    delete $Param{Env};

    # lookup latest used view mode
    if ( !$Param{View} && $Self->{ 'UserTicketOverview' . $Env->{Action} } ) {
        $Param{View} = $Self->{ 'UserTicketOverview' . $Env->{Action} };
    }

    # set default view mode to 'small'
    my $View = $Param{View} || 'Small';

    # set default view mode for AgentTicketQueue or AgentTicketService
    if (
        !$Param{View}
        && (
            $Env->{Action} eq 'AgentTicketQueue'
            || $Env->{Action} eq 'AgentTicketService'
        )
        )
    {
        $View = 'Preview';
    }

    # store latest view mode
    $Kernel::OM->Get('Kernel::System::AuthSession')->UpdateSessionID(
        SessionID => $Self->{SessionID},
        Key       => 'UserTicketOverview' . $Env->{Action},
        Value     => $View,
    );

    # get config object
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # update preferences if needed
    my $Key = 'UserTicketOverview' . $Env->{Action};
    if ( !$ConfigObject->Get('DemoSystem') && ( $Self->{$Key} // '' ) ne $View ) {
        $Kernel::OM->Get('Kernel::System::User')->SetPreferences(
            UserID => $Self->{UserID},
            Key    => $Key,
            Value  => $View,
        );
    }

    # check backends
    my $Backends = $ConfigObject->Get('Ticket::Frontend::Overview');
    if ( !$Backends ) {
        return $Self->FatalError(
            Message => 'Need config option Ticket::Frontend::Overview',
        );
    }
    if ( ref $Backends ne 'HASH' ) {
        return $Self->FatalError(
            Message => 'Config option Ticket::Frontend::Overview need to be HASH ref!',
        );
    }

    # check if selected view is available
    if ( !$Backends->{$View} ) {

        # try to find fallback, take first configured view mode
        KEY:
        for my $Key ( sort keys %{$Backends} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "No Config option found for view mode $View, took $Key instead!",
            );
            $View = $Key;
            last KEY;
        }
    }

    # get layout object
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    $LayoutObject->AddJSData(
        Key   => 'View',
        Value => $View,
    );

    # load overview backend module
    if ( !$Kernel::OM->Get('Kernel::System::Main')->Require( $Backends->{$View}->{Module} ) ) {
        return $Env->{LayoutObject}->FatalError();
    }
    my $Object = $Backends->{$View}->{Module}->new( %{$Env} );
    return if !$Object;

    # retrieve filter values
    if ( $Param{FilterContentOnly} ) {
        return $Object->FilterContent(
            %Param,
        );
    }

    # run action row backend module
    $Param{ActionRow} = $Object->ActionRow(
        %Param,
        Config => $Backends->{$View},
    );

    # run overview backend module
    $Param{SortOrderBar} = $Object->SortOrderBar(
        %Param,
        Config => $Backends->{$View},
    );

    # check start option, if higher then tickets available, set
    # it to the last ticket page (Thanks to Stefan Schmidt!)
    my $StartHit = $Kernel::OM->Get('Kernel::System::Web::Request')->GetParam( Param => 'StartHit' ) || 1;

    # get personal page shown count
    my $PageShownPreferencesKey = 'UserTicketOverview' . $View . 'PageShown';
    my $PageShown               = $Self->{$PageShownPreferencesKey} || 10;
    my $Group                   = 'TicketOverview' . $View . 'PageShown';

    # get data selection
    my %Data;
    my $Config = $ConfigObject->Get('PreferencesGroups');
    if ( $Config && $Config->{$Group} && $Config->{$Group}->{Data} ) {
        %Data = %{ $Config->{$Group}->{Data} };
    }

    # calculate max. shown per page
    if ( $StartHit > $Param{Total} ) {
        my $Pages = int( ( $Param{Total} / $PageShown ) + 0.99999 );
        $StartHit = ( ( $Pages - 1 ) * $PageShown ) + 1;
    }

    # build nav bar
    my $Limit   = $Param{Limit} || 20_000;
    my %PageNav = $Self->PageNavBar(
        Limit     => $Limit,
        StartHit  => $StartHit,
        PageShown => $PageShown,
        AllHits   => $Param{Total} || 0,
        Action    => 'Action=' . $Self->{Action},
        Link      => $Param{LinkPage},
        IDPrefix  => $Self->{Action},
    );

    # build shown ticket per page
    $Param{RequestedURL}    = $Param{RequestedURL} || "Action=$Self->{Action}";
    $Param{Group}           = $Group;
    $Param{PreferencesKey}  = $PageShownPreferencesKey;
    $Param{PageShownString} = $Self->BuildSelection(
        Name        => $PageShownPreferencesKey,
        SelectedID  => $PageShown,
        Translation => 0,
        Data        => \%Data,
        Sort        => 'NumericValue',
        Class       => 'Modernize',
    );

    # nav bar at the beginning of a overview
    $Param{View} = $View;
    $Self->Block(
        Name => 'OverviewNavBar',
        Data => \%Param,
    );

    # back link
    if ( $Param{LinkBack} ) {
        $Self->Block(
            Name => 'OverviewNavBarPageBack',
            Data => \%Param,
        );
        $LayoutObject->AddJSData(
            Key   => 'Profile',
            Value => $Param{Profile},
        );
    }

    # filter selection
    if ( $Param{Filters} ) {
        my @NavBarFilters;
        for my $Prio ( sort keys %{ $Param{Filters} } ) {
            push @NavBarFilters, $Param{Filters}->{$Prio};
        }
        $Self->Block(
            Name => 'OverviewNavBarFilter',
            Data => {
                %Param,
            },
        );
        my $Count = 0;
        for my $Filter (@NavBarFilters) {
            $Count++;
            if ( $Count == scalar @NavBarFilters ) {
                $Filter->{CSS} = 'Last';
            }
            $Self->Block(
                Name => 'OverviewNavBarFilterItem',
                Data => {
                    %Param,
                    %{$Filter},
                },
            );
            if ( $Filter->{Filter} eq $Param{Filter} ) {
                $Self->Block(
                    Name => 'OverviewNavBarFilterItemSelected',
                    Data => {
                        %Param,
                        %{$Filter},
                    },
                );
            }
            else {
                $Self->Block(
                    Name => 'OverviewNavBarFilterItemSelectedNot',
                    Data => {
                        %Param,
                        %{$Filter},
                    },
                );
            }
        }
    }

    # view mode
    for my $Backend (
        sort { $Backends->{$a}->{ModulePriority} <=> $Backends->{$b}->{ModulePriority} }
        keys %{$Backends}
        )
    {

        $Self->Block(
            Name => 'OverviewNavBarViewMode',
            Data => {
                %Param,
                %{ $Backends->{$Backend} },
                Filter => $Param{Filter},
                View   => $Backend,
            },
        );
        if ( $View eq $Backend ) {
            $Self->Block(
                Name => 'OverviewNavBarViewModeSelected',
                Data => {
                    %Param,
                    %{ $Backends->{$Backend} },
                    Filter => $Param{Filter},
                    View   => $Backend,
                },
            );
        }
        else {
            $Self->Block(
                Name => 'OverviewNavBarViewModeNotSelected',
                Data => {
                    %Param,
                    %{ $Backends->{$Backend} },
                    Filter => $Param{Filter},
                    View   => $Backend,
                },
            );
        }
    }

    if (%PageNav) {
        $Self->Block(
            Name => 'OverviewNavBarPageNavBar',
            Data => \%PageNav,
        );

        # don't show context settings in AJAX case (e. g. in customer ticket history),
        #   because the submit with page reload will not work there
        if ( !$Param{AJAX} ) {
            $Self->Block(
                Name => 'ContextSettings',
                Data => {
                    %PageNav,
                    %Param,
                },
            );

            # show column filter preferences
            if ( $View eq 'Small' ) {

                # set preferences keys
                my $PrefKeyColumns = 'UserFilterColumnsEnabled' . '-' . $Env->{Action};

                # create extra needed objects
                my $JSONObject = $Kernel::OM->Get('Kernel::System::JSON');

                # configure columns
                my @ColumnsEnabled = @{ $Object->{ColumnsEnabled} };
                my @ColumnsAvailable;

                # remove duplicate columns
                my %UniqueColumns;
                my @ColumnsEnabledAux;

                for my $Column (@ColumnsEnabled) {
                    if ( !$UniqueColumns{$Column} ) {
                        push @ColumnsEnabledAux, $Column;
                    }
                    $UniqueColumns{$Column} = 1;
                }

                # set filtered column list
                @ColumnsEnabled = @ColumnsEnabledAux;

                for my $ColumnName ( sort { $a cmp $b } @{ $Object->{ColumnsAvailable} } ) {
                    if ( !grep { $_ eq $ColumnName } @ColumnsEnabled ) {
                        push @ColumnsAvailable, $ColumnName;
                    }
                }

                my %Columns;
                for my $ColumnName ( sort @ColumnsAvailable ) {
                    $Columns{Columns}->{$ColumnName} = ( grep { $ColumnName eq $_ } @ColumnsEnabled ) ? 1 : 0;
                }

                $Self->Block(
                    Name => 'FilterColumnSettings',
                    Data => {
                        Columns          => $JSONObject->Encode( Data => \%Columns ),
                        ColumnsEnabled   => $JSONObject->Encode( Data => \@ColumnsEnabled ),
                        ColumnsAvailable => $JSONObject->Encode( Data => \@ColumnsAvailable ),
                        NamePref         => $PrefKeyColumns,
                        Desc             => Translatable('Shown Columns'),
                        Name             => $Env->{Action},
                        View             => $View,
                        GroupName        => 'TicketOverviewFilterSettings',
                        %Param,
                    },
                );
            }
        }    # end show column filters preferences

        # check if there was stored filters, and print a link to delete them
        if ( IsHashRefWithData( $Object->{StoredFilters} ) ) {
            $Self->Block(
                Name => 'DocumentActionRowRemoveColumnFilters',
                Data => {
                    CSS => "ContextSettings RemoveFilters",
                    %Param,
                },
            );
        }
    }

    if ( $Param{NavBar} ) {
        if ( $Param{NavBar}->{MainName} ) {
            $Self->Block(
                Name => 'OverviewNavBarMain',
                Data => $Param{NavBar},
            );
        }
    }

    my $OutputNavBar = $Self->Output(
        TemplateFile => 'AgentTicketOverviewNavBar',
        Data         => { %Param, },
    );
    my $OutputRaw = '';
    if ( !$Param{Output} ) {
        $Self->Print( Output => \$OutputNavBar );
    }
    else {
        $OutputRaw .= $OutputNavBar;
    }

    # run overview backend module
    my $Output = $Object->Run(
        %Param,
        Config    => $Backends->{$View},
        Limit     => $Limit,
        StartHit  => $StartHit,
        PageShown => $PageShown,
        AllHits   => $Param{Total} || 0,
        Output    => $Param{Output} || '',
    );
    if ( !$Param{Output} ) {
        $Self->Print( Output => \$Output );
    }
    else {
        $OutputRaw .= $Output;
    }

    return $OutputRaw;
}

sub TicketMetaItemsCount {
    my ( $Self, %Param ) = @_;
    return ( 'Priority', 'New Article' );
}

sub TicketMetaItems {
    my ( $Self, %Param ) = @_;

    if ( ref $Param{Ticket} ne 'HASH' ) {
        $Self->FatalError( Message => 'Need Hash ref in Ticket param!' );
    }

    # return attributes
    my @Result;

    # show priority
    push @Result, {

        #            Image => $Image,
        Title      => $Param{Ticket}->{Priority},
        Class      => 'Flag',
        ClassSpan  => 'PriorityID-' . $Param{Ticket}->{PriorityID},
        ClassTable => 'Flags',
    };

    # get ticket object
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    my %Ticket = $TicketObject->TicketGet( TicketID => $Param{Ticket}->{TicketID} );

    # Show if new message is in there, but show archived tickets as read.
    my %TicketFlag;
    if ( $Ticket{ArchiveFlag} ne 'y' ) {
        %TicketFlag = $TicketObject->TicketFlagGet(
            TicketID => $Param{Ticket}->{TicketID},
            UserID   => $Self->{UserID},
        );
    }

    if ( $Ticket{ArchiveFlag} eq 'y' || $TicketFlag{Seen} ) {
        push @Result, undef;
    }
    else {

        # just show ticket flags if agent belongs to the ticket
        my $ShowMeta;
        if (
            $Self->{UserID} == $Param{Ticket}->{OwnerID}
            || $Self->{UserID} == $Param{Ticket}->{ResponsibleID}
            )
        {
            $ShowMeta = 1;
        }
        if ( !$ShowMeta && $Kernel::OM->Get('Kernel::Config')->Get('Ticket::Watcher') ) {
            my %Watch = $TicketObject->TicketWatchGet(
                TicketID => $Param{Ticket}->{TicketID},
            );
            if ( $Watch{ $Self->{UserID} } ) {
                $ShowMeta = 1;
            }
        }

        # show ticket flags
        my $Image = 'meta-new-inactive.png';
        if ($ShowMeta) {
            $Image = 'meta-new.png';
            push @Result, {
                Image      => $Image,
                Title      => Translatable('Unread article(s) available'),
                Class      => 'UnreadArticles',
                ClassSpan  => 'UnreadArticles Remarkable',
                ClassTable => 'UnreadArticles',
            };
        }
        else {
            push @Result, {
                Image      => $Image,
                Title      => Translatable('Unread article(s) available'),
                Class      => 'UnreadArticles',
                ClassSpan  => 'UnreadArticles Ordinary',
                ClassTable => 'UnreadArticles',
            };
        }
    }

    return @Result;
}

=head2 TimeUnits()

Returns HTML block consisting of label and field for time units.

    my $TimeUnitsBlock = $LayoutObject->TimeUnits(
        ID                => 'TimeUnits',       # (optional) the HTML ID for this element, if not provided, the name will be used as ID as well
        Name              => 'TimeUnits',       # name of element
        TimeUnits         => '123',
        TimeUnitsRequired => '1',
    );

Returns:

    my $TimeUnitsBlock =  '<label for="TimeUnits">Time units  (work units):</label>
    <div class="Field">
        <input type="text" name="TimeUnits" id="TimeUnits" value="" class="W50pc Validate_TimeUnits  "/>
        <div id="TimeUnitsError" class="TooltipErrorMessage"><p>Invalid time!</p></div>
        <div id="TimeUnitsServerError" class="TooltipErrorMessage"><p>This field is required.</p></div>
    </div>
    <div class="Clear"></div>'

=cut

sub TimeUnits {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    $Param{ID}                ||= 'TimeUnits';
    $Param{Name}              ||= 'TimeUnits';
    $Param{TimeUnitsRequired} ||= $ConfigObject->Get('Ticket::Frontend::NeedAccountedTime');

    my $Type = $ConfigObject->Get('Ticket::Frontend::AccountTimeType') || 'Text';

    if ( $Param{TimeUnitsRequired} ) {
        $Self->Block(
            Name => 'TimeUnitsLabelMandatory',
            Data => \%Param,
        );
        $Param{TimeUnitsRequiredClass} ||= 'Validate_Required';
    }
    else {
        $Self->Block(
            Name => 'TimeUnitsLabel',
            Data => \%Param,
        );
        $Param{TimeUnitsRequiredClass} = '';
    }

    $Self->Block(
        Name => 'TimeUnits' . $Type,
        Data => \%Param,
    );

    if ( $Type eq 'Dropdown' ) {

        my $Config = $ConfigObject->Get( 'Ticket::Frontend::AccountTime::' . $Type );
        my $DefaultTimeUnits;

        for my $Item ( sort keys %{$Config} ) {

            my $Label = $Config->{$Item}->{Label};
            $DefaultTimeUnits += $Config->{$Item}->{DataSelected} || 0;

            my $Field = $Self->BuildSelection(
                Class => $Param{ID} . ' TimeUnitDropdown Modernize ' . $Param{TimeUnitsRequiredClass},
                Data  => {
                    %{ $Config->{$Item}->{Data} },
                },
                ID           => $Param{ID} . $Label,
                Name         => $Param{Name} . $Label,
                SelectedID   => $Config->{$Item}->{DataSelected},
                PossibleNone => 1,
                Sort         => 'NumericValue',
                Translation  => 0,
                OnChange     => 'Core.Agent.TicketAction.SetTimeUnits(\'' . $Param{ID} . '\');',
            );

            $Self->Block(
                Name => $Type,
                Data => {
                    %Param,
                    Label => $Label,
                    Field => $Field,
                },
            );
        }

        $Param{TimeUnits} //= $DefaultTimeUnits;
        $Self->Block(
            Name => 'TimeUnits',
            Data => \%Param,
        );
    }

    my $TimeUnitsStrg = $Self->Output(
        TemplateFile => 'Ticket/TimeUnits',
        Data         => {
            %Param,
        },
    );

    return $TimeUnitsStrg;
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
