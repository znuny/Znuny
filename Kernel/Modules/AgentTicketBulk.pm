# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Modules::AgentTicketBulk;

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

    # get needed objects
    my $ParamObject  = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    if ( $Self->{Subaction} eq 'CancelAndUnlockTickets' ) {

        my @TicketIDs = grep {$_}
            $ParamObject->GetArray( Param => 'LockedTicketID' );

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        # check needed stuff
        if ( !@TicketIDs ) {
            return $LayoutObject->ErrorScreen(
                Message => Translatable('Can\'t lock Tickets, no TicketIDs are given!'),
                Comment => Translatable('Please contact the administrator.'),
            );
        }

        my $Message = '';

        TICKET_ID:
        for my $TicketID (@TicketIDs) {

            my $Access = $TicketObject->TicketPermission(
                Type     => 'lock',
                TicketID => $TicketID,
                UserID   => $Self->{UserID}
            );

            # error screen, don't show ticket
            if ( !$Access ) {
                return $LayoutObject->NoPermission( WithHeader => 'yes' );
            }

            # set unlock
            my $Lock = $TicketObject->TicketLockSet(
                TicketID => $TicketID,
                Lock     => 'unlock',
                UserID   => $Self->{UserID},
            );
            if ( !$Lock ) {
                $Message .= "$TicketID,";
            }
        }

        if ( $Message ne '' ) {
            return $LayoutObject->ErrorScreen(
                Message => $LayoutObject->{LanguageObject}->Translate( "Ticket (%s) is not unlocked!", $Message ),
            );
        }

        return $LayoutObject->Redirect(
            OP => $Self->{LastScreenOverview},
        );

    }

    elsif ( $Self->{Subaction} eq 'AJAXUpdate' ) {

        my $Config = $ConfigObject->Get("Ticket::Frontend::$Self->{Action}");

        # Get List type.
        my $TreeView = 0;
        if ( $ConfigObject->Get('Ticket::Frontend::ListType') eq 'tree' ) {
            $TreeView = 1;
        }

        my %GetParam;
        for my $Key (qw(OwnerID ResponsibleID PriorityID QueueID Queue TypeID StateID)) {
            $GetParam{$Key} = $ParamObject->GetParam( Param => $Key ) || '';
        }

        my %QueueList = $Self->_GetQueues(
            %GetParam,
            Type   => 'move_into',
            UserID => $Self->{UserID},
            Action => $Self->{Action},
        );
        my @JSONData = (
            {
                Name         => 'QueueID',
                Data         => \%QueueList,
                SelectedID   => $GetParam{QueueID},
                TreeView     => $TreeView,
                Translation  => 0,
                PossibleNone => 1,
            },
        );

        if ( $Config->{State} ) {
            my %State;
            my %StateList = $Self->_GetStates(
                %GetParam,
                StateType => $Config->{StateType},
                Action    => $Self->{Action},
                UserID    => $Self->{UserID},
            );
            if ( !$Config->{StateDefault} ) {
                $StateList{''} = '-';
            }

            push @JSONData, {
                Name       => 'StateID',
                Data       => \%StateList,
                SelectedID => $GetParam{StateID},
            };
        }

        if ( $ConfigObject->Get('Ticket::Type') && $Config->{TicketType} ) {

            my %TypeList = $Self->_GetTypes(
                %GetParam,
                Action => $Self->{Action},
                UserID => $Self->{UserID},
            );

            push @JSONData, {
                Name         => 'TypeID',
                Data         => \%TypeList,
                SelectedID   => $GetParam{TypeID},
                PossibleNone => 1,
                Translation  => 0,
            };
        }

        if ( $Config->{Owner} ) {
            my %OwnerList = $Self->_GetOwners(
                %GetParam,
                Action => $Self->{Action},
                UserID => $Self->{UserID},
            );

            push @JSONData, {
                Name         => 'OwnerID',
                Data         => \%OwnerList,
                SelectedID   => $GetParam{OwnerID},
                PossibleNone => 1,
            };
        }

        if ( $ConfigObject->Get('Ticket::Responsible') && $Config->{Responsible} ) {
            my %ResponsibleList = $Self->_GetResponsibles(
                %GetParam,
                Action => $Self->{Action},
                UserID => $Self->{UserID},
            );

            push @JSONData, {
                Name         => 'ResponsibleID',
                Data         => \%ResponsibleList,
                SelectedID   => $GetParam{ResponsibleID},
                PossibleNone => 1,
            };
        }

        if ( $Config->{Priority} ) {
            my %PriorityList = $Self->_GetPriorities(
                %GetParam,
                UserID => $Self->{UserID},
                Action => $Self->{Action},
            );
            if ( !$Config->{PriorityDefault} ) {
                $PriorityList{''} = '-';
            }

            push @JSONData, {
                Name       => 'PriorityID',
                Data       => \%PriorityList,
                SelectedID => $GetParam{PriorityID},
            };
        }

        # get bulk modules from SysConfig
        my $BulkModuleConfig = $Kernel::OM->Get('Kernel::Config')->Get('Ticket::Frontend::BulkModule') || {};

        # create bulk module objects
        my @BulkModules;
        MODULECONFIG:
        for my $ModuleConfig ( sort keys %{$BulkModuleConfig} ) {

            next MODULECONFIG if !$ModuleConfig;
            next MODULECONFIG if !$BulkModuleConfig->{$ModuleConfig};
            next MODULECONFIG if ref $BulkModuleConfig->{$ModuleConfig} ne 'HASH';
            next MODULECONFIG if !$BulkModuleConfig->{$ModuleConfig}->{Module};

            my $Module = $BulkModuleConfig->{$ModuleConfig}->{Module};

            my $ModuleObject;
            eval {
                $ModuleObject = $Kernel::OM->Get($Module);
            };

            if ( !$ModuleObject ) {
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'error',
                    Message  => "Could not create a new object for $Module!",
                );
                next MODULECONFIG;
            }

            if ( ref $ModuleObject ne $Module ) {
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'error',
                    Message  => "Object for $Module is invalid!",
                );
                next MODULECONFIG;
            }

            push @BulkModules, $ModuleObject;
        }

        # call AJAXUpdate() in all ticket bulk modules
        if (@BulkModules) {

            MODULEOBJECT:
            for my $ModuleObject (@BulkModules) {
                next MODULEOBJECT if !$ModuleObject->can('AJAXUpdate');

                my $ModuleAjaxUpdate = $ModuleObject->AJAXUpdate(
                    %GetParam,
                    Action => $Self->{Action},
                    UserID => $Self->{UserID},
                );

                next MODULEOBJECT if !IsHashRefWithData($ModuleAjaxUpdate);

                push @JSONData, $ModuleAjaxUpdate;
            }
        }

        my $JSON = $LayoutObject->BuildSelectionJSON( [@JSONData] );

        return $LayoutObject->Attachment(
            ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
            Content     => $JSON,
            Type        => 'inline',
            NoCache     => 1,
        );
    }

    elsif ( $Self->{Subaction} eq 'AJAXRecipientList' ) {

        # get ticket IDs
        my @Recipients;
        my $TicketIDs = $ParamObject->GetParam( Param => 'TicketIDs' );
        if ($TicketIDs) {
            $TicketIDs = $Kernel::OM->Get('Kernel::System::JSON')->Decode(
                Data => $TicketIDs
            );
            @Recipients = $Self->_GetRecipientList( TicketIDs => $TicketIDs );
        }

        return $LayoutObject->Attachment(
            ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
            Content     => $Kernel::OM->Get('Kernel::System::JSON')->Encode( Data => \@Recipients ),
            Type        => 'inline',
            NoCache     => 1,
        );
    }

    elsif ( $Self->{Subaction} eq 'AJAXIgnoreLockedTicketIDs' ) {

        my @ValidTicketIDs;
        my @IgnoreLockedTicketIDs;
        my $TicketIDs = $ParamObject->GetParam( Param => 'TicketIDs' );
        if ($TicketIDs) {
            $TicketIDs = $Kernel::OM->Get('Kernel::System::JSON')->Decode(
                Data => $TicketIDs
            );

        }

        my $Config        = $ConfigObject->Get("Ticket::Frontend::$Self->{Action}");
        my @TicketIDArray = split( /;/, $TicketIDs );

        if ( $Config->{RequiredLock} ) {
            for my $TicketID (@TicketIDArray) {
                if ( $TicketObject->TicketLockGet( TicketID => $TicketID ) ) {
                    my $AccessOk = $TicketObject->OwnerCheck(
                        TicketID => $TicketID,
                        OwnerID  => $Self->{UserID},
                    );
                    if ($AccessOk) {
                        push @ValidTicketIDs, $TicketID;
                    }
                    else {
                        push @IgnoreLockedTicketIDs, $TicketID;
                    }
                }
                else {
                    push @ValidTicketIDs, $TicketID;
                }
            }
        }
        else {
            @ValidTicketIDs = @TicketIDArray;
        }

        my %DialogWarning;
        my @IgnoreLockedTicketNumber;
        if ( @IgnoreLockedTicketIDs && !@ValidTicketIDs ) {
            for my $TicketID (@IgnoreLockedTicketIDs) {
                my $TicketNumber = $TicketObject->TicketNumberLookup(
                    TicketID => $TicketID,
                );
                push @IgnoreLockedTicketNumber, $TicketNumber;

            }

            if ( $Config->{RequiredLock} ) {
                if ( scalar @IgnoreLockedTicketNumber > 1 ) {
                    %DialogWarning = (
                        Message => $LayoutObject->{LanguageObject}->Translate(
                            "The following tickets were ignored because they are locked by another agent or you don't have write access to tickets: %s.",
                            join( ", ", @IgnoreLockedTicketNumber ),
                        )
                    );
                }
                else {
                    %DialogWarning = (
                        Message => $LayoutObject->{LanguageObject}->Translate(
                            "The following ticket was ignored because it is locked by another agent or you don't have write access to ticket: %s.",
                            join( ", ", @IgnoreLockedTicketNumber ),
                        )
                    );
                }
            }
            else {
                %DialogWarning = (
                    Message => Translatable('You need to select at least one ticket.'),
                );
            }
        }

        return $LayoutObject->Attachment(
            ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
            Content     => $Kernel::OM->Get('Kernel::System::JSON')->Encode(
                Data => {
                    Message => $DialogWarning{Message} || '',
                }
            ),
            Type    => 'inline',
            NoCache => 1,
        );

    }

    if ( !$Self->{Subaction} || $Self->{Subaction} ne 'AJAXRecipientList' ) {

        # check if bulk feature is enabled
        if ( !$ConfigObject->Get('Ticket::Frontend::BulkFeature') ) {
            return $LayoutObject->ErrorScreen(
                Message => Translatable('Bulk feature is not enabled!'),
            );
        }

        # get involved tickets, filtering empty TicketIDs
        my @ValidTicketIDs;
        my @IgnoreLockedTicketIDs;
        my @TicketIDs = sort grep {$_}
            $ParamObject->GetArray( Param => 'TicketID' );

        my $Config = $ConfigObject->Get("Ticket::Frontend::$Self->{Action}");

        # check if only locked tickets have been selected
        if ( $Config->{RequiredLock} ) {
            for my $TicketID (@TicketIDs) {
                if ( $TicketObject->TicketLockGet( TicketID => $TicketID ) ) {
                    my $AccessOk = $TicketObject->OwnerCheck(
                        TicketID => $TicketID,
                        OwnerID  => $Self->{UserID},
                    );
                    if ($AccessOk) {
                        push @ValidTicketIDs, $TicketID;
                    }
                    else {
                        push @IgnoreLockedTicketIDs, $TicketID;
                    }
                }
                else {
                    push @ValidTicketIDs, $TicketID;
                }
            }
        }
        else {
            @ValidTicketIDs = @TicketIDs;
        }

        # check needed stuff
        if ( !@ValidTicketIDs ) {
            if ( $Config->{RequiredLock} ) {
                return $LayoutObject->ErrorScreen(
                    Message => Translatable('No selectable TicketID is given!'),
                    Comment =>
                        Translatable('You either selected no ticket or only tickets which are locked by other agents.'),
                );
            }
            else {
                return $LayoutObject->ErrorScreen(
                    Message => Translatable('No TicketID is given!'),
                    Comment => Translatable('You need to select at least one ticket.'),
                );
            }
        }

        my $Output = $LayoutObject->Header(
            Type => 'Small',
        );

        # make the ticket IDs available in javascript
        $LayoutObject->AddJSData(
            Key   => 'ValidTicketIDs',
            Value => \@ValidTicketIDs,
        );

        # declare the variables for all the parameters
        my %Error;
        my %Time;
        my %GetParam;

        # get bulk modules from SysConfig
        my $BulkModuleConfig = $Kernel::OM->Get('Kernel::Config')->Get('Ticket::Frontend::BulkModule') || {};

        # create bulk module objects
        my @BulkModules;
        MODULECONFIG:
        for my $ModuleConfig ( sort keys %{$BulkModuleConfig} ) {

            next MODULECONFIG if !$ModuleConfig;
            next MODULECONFIG if !$BulkModuleConfig->{$ModuleConfig};
            next MODULECONFIG if ref $BulkModuleConfig->{$ModuleConfig} ne 'HASH';
            next MODULECONFIG if !$BulkModuleConfig->{$ModuleConfig}->{Module};

            my $Module = $BulkModuleConfig->{$ModuleConfig}->{Module};

            my $ModuleObject;
            eval {
                $ModuleObject = $Kernel::OM->Get($Module);
            };

            if ( !$ModuleObject ) {
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'error',
                    Message  => "Could not create a new object for $Module!",
                );
                next MODULECONFIG;
            }

            if ( ref $ModuleObject ne $Module ) {
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'error',
                    Message  => "Object for $Module is invalid!",
                );
                next MODULECONFIG;
            }

            push @BulkModules, $ModuleObject;
        }

        # get needed objects
        my $StateObject = $Kernel::OM->Get('Kernel::System::State');

        # get all parameters and check for errors
        if ( $Self->{Subaction} eq 'Do' ) {

            # challenge token check for write action
            $LayoutObject->ChallengeTokenCheck();

            # get all parameters
            for my $Key (
                qw(OwnerID Owner ResponsibleID Responsible PriorityID Priority QueueID Queue Subject
                Body IsVisibleForCustomer TypeID StateID State MergeToSelection MergeTo LinkTogether
                EmailSubject EmailBody EmailTimeUnits
                LinkTogetherParent Unlock MergeToChecked MergeToOldestChecked)
                )
            {
                $GetParam{$Key} = $ParamObject->GetParam( Param => $Key ) || '';
            }

            for my $Key (qw(TimeUnits)) {
                $GetParam{$Key} = $ParamObject->GetParam( Param => $Key );
            }

            # get time stamp based on user time zone
            %Time = $LayoutObject->TransformDateSelection(
                Year   => $ParamObject->GetParam( Param => 'Year' ),
                Month  => $ParamObject->GetParam( Param => 'Month' ),
                Day    => $ParamObject->GetParam( Param => 'Day' ),
                Hour   => $ParamObject->GetParam( Param => 'Hour' ),
                Minute => $ParamObject->GetParam( Param => 'Minute' ),
            );

            if ( $GetParam{'MergeToSelection'} eq 'OptionMergeTo' ) {
                $GetParam{'MergeToChecked'} = 'checked';
            }
            elsif ( $GetParam{'MergeToSelection'} eq 'OptionMergeToOldest' ) {
                $GetParam{'MergeToOldestChecked'} = 'checked';
            }

            # check some stuff
            if (
                $GetParam{Subject}
                && $ConfigObject->Get('Ticket::Frontend::AccountTime')
                && $ConfigObject->Get('Ticket::Frontend::NeedAccountedTime')
                && $GetParam{TimeUnits} eq ''
                )
            {
                $Error{'TimeUnitsInvalid'} = 'ServerError';
            }

            if (
                $GetParam{EmailSubject}
                && $ConfigObject->Get('Ticket::Frontend::AccountTime')
                && $ConfigObject->Get('Ticket::Frontend::NeedAccountedTime')
                && $GetParam{EmailTimeUnits} eq ''
                )
            {
                $Error{'EmailTimeUnitsInvalid'} = 'ServerError';
            }

            # Body and Subject must both be filled in or both be empty
            if ( $GetParam{Subject} eq '' && $GetParam{Body} ne '' ) {
                $Error{'SubjectInvalid'} = 'ServerError';
            }
            if ( $GetParam{Subject} ne '' && $GetParam{Body} eq '' ) {
                $Error{'BodyInvalid'} = 'ServerError';
            }

            # Email Body and Email Subject must both be filled in or both be empty
            if ( $GetParam{EmailSubject} eq '' && $GetParam{EmailBody} ne '' ) {
                $Error{'EmailSubjectInvalid'} = 'ServerError';
            }
            if ( $GetParam{EmailSubject} ne '' && $GetParam{EmailBody} eq '' ) {
                $Error{'EmailBodyInvalid'} = 'ServerError';
            }

            # check if pending date must be validated
            if ( $GetParam{StateID} || $GetParam{State} ) {
                my %StateData;
                if ( $GetParam{StateID} ) {
                    %StateData = $StateObject->StateGet(
                        ID => $GetParam{StateID},
                    );
                }
                else {
                    %StateData = $StateObject->StateGet(
                        Name => $GetParam{State},
                    );
                }

                if ( $StateData{TypeName} =~ /^pending/i ) {

                    # create datetime object
                    my $PendingDateTimeObject = $Kernel::OM->Create(
                        'Kernel::System::DateTime',
                        ObjectParams => {
                            %Time,
                            Second => 0,
                        },
                    );

                    # get current system epoch
                    my $CurSystemDateTimeObject = $Kernel::OM->Create('Kernel::System::DateTime');
                    if (
                        !$PendingDateTimeObject
                        || $PendingDateTimeObject < $CurSystemDateTimeObject
                        )
                    {
                        $Error{'DateInvalid'} = 'ServerError';
                    }
                }
            }

            # get check item object
            my $CheckItemObject = $Kernel::OM->Get('Kernel::System::CheckItem');

            if ( $GetParam{'MergeToSelection'} eq 'OptionMergeTo' && $GetParam{'MergeTo'} ) {
                $CheckItemObject->StringClean(
                    StringRef => \$GetParam{'MergeTo'},
                    TrimLeft  => 1,
                    TrimRight => 1,
                );
                my $TicketID = $TicketObject->TicketCheckNumber(
                    Tn => $GetParam{'MergeTo'},
                );
                if ( !$TicketID ) {
                    $Error{'MergeToInvalid'} = 'ServerError';
                }
            }
            if ( $GetParam{'LinkTogetherParent'} ) {
                $CheckItemObject->StringClean(
                    StringRef => \$GetParam{'LinkTogetherParent'},
                    TrimLeft  => 1,
                    TrimRight => 1,
                );
                my $TicketID = $TicketObject->TicketCheckNumber(
                    Tn => $GetParam{'LinkTogetherParent'},
                );
                if ( !$TicketID ) {
                    $Error{'LinkTogetherParentInvalid'} = 'ServerError';
                }
            }

            # call Validate() in all ticket bulk modules
            if (@BulkModules) {
                MODULEOBJECT:
                for my $ModuleObject (@BulkModules) {
                    next MODULEOBJECT if !$ModuleObject->can('Validate');

                    my @Result = $ModuleObject->Validate(
                        UserID => $Self->{UserID},
                    );

                    next MODULEOBJECT if !@Result;

                    # include all validation errors in the common error hash
                    for my $ValidationError (@Result) {
                        $Error{ $ValidationError->{ErrorKey} } = $ValidationError->{ErrorValue};
                    }
                }
            }
        }

        # process tickets
        my @TicketIDSelected;
        my $LockedTickets = '';
        my $ActionFlag    = 0;
        my $Counter       = 1;
        $Param{TicketsWereLocked} = 0;

        # if the tickets are to merged, precompute the ticket to merge to.
        # (it's the same for all tickets, so do it only once):
        my $MainTicketID;

        if ( ( $Self->{Subaction} eq 'Do' ) && ( !%Error ) ) {

            # merge to
            if ( $GetParam{'MergeToSelection'} eq 'OptionMergeTo' && $GetParam{'MergeTo'} ) {
                $MainTicketID = $TicketObject->TicketIDLookup(
                    TicketNumber => $GetParam{'MergeTo'},
                );
            }

            # merge to oldest
            elsif ( $GetParam{'MergeToSelection'} eq 'OptionMergeToOldest' ) {

                # find oldest
                my $OldestCreateTime;
                my $OldestTicketID;
                for my $TicketIDCheck (@TicketIDs) {
                    my %Ticket = $TicketObject->TicketGet(
                        TicketID      => $TicketIDCheck,
                        DynamicFields => 0,
                    );
                    if ( !defined $OldestCreateTime || $OldestCreateTime gt $Ticket{Created} ) {
                        $OldestCreateTime = $Ticket{Created};
                        $OldestTicketID   = $TicketIDCheck;
                    }
                }
                $MainTicketID = $OldestTicketID;
            }
        }

        my @TicketsWithError;
        my @TicketsWithLockNotice;
        my $Result;
        my @NonUpdatedTickets;

        my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');

        TICKET_ID:
        for my $TicketID (@TicketIDs) {
            my %Ticket = $TicketObject->TicketGet(
                TicketID      => $TicketID,
                DynamicFields => 0,
            );

            # check permissions
            my $Access = $TicketObject->TicketPermission(
                Type     => 'rw',
                TicketID => $TicketID,
                UserID   => $Self->{UserID}
            );
            if ( !$Access ) {

                # error screen, don't show ticket
                push @TicketsWithError, $Ticket{TicketNumber};
                next TICKET_ID;
            }

            # check if it's already locked by somebody else
            if ( $Config->{RequiredLock} ) {
                if ( grep ( { $_ eq $TicketID } @IgnoreLockedTicketIDs ) ) {
                    push @TicketsWithError, $Ticket{TicketNumber};
                    next TICKET_ID;
                }
                elsif ( $Ticket{Lock} eq 'unlock' ) {
                    $LockedTickets .= "LockedTicketID=" . $TicketID . ';';
                    $Param{TicketsWereLocked} = 1;

                    # set lock
                    $TicketObject->TicketLockSet(
                        TicketID => $TicketID,
                        Lock     => 'lock',
                        UserID   => $Self->{UserID},
                    );

                    # set user id
                    $Result = $TicketObject->TicketOwnerSet(
                        TicketID  => $TicketID,
                        UserID    => $Self->{UserID},
                        NewUserID => $Self->{UserID},
                    );

                    push @TicketsWithLockNotice, $Ticket{TicketNumber};

                    if ( !$Result ) {
                        push @NonUpdatedTickets, $Ticket{TicketNumber};
                    }
                }
            }

            # remember selected ticket ids
            push @TicketIDSelected, $TicketID;

            # do some actions on tickets
            if ( ( $Self->{Subaction} eq 'Do' ) && ( !%Error ) ) {

                # challenge token check for write action
                $LayoutObject->ChallengeTokenCheck();

                # Clean up 'TicketSearch' cache type if Bulk screen is reached from ticket search.
                if ( $Self->{LastScreenOverview} =~ /Action=AgentTicketSearch/ ) {
                    $Kernel::OM->Get('Kernel::System::Cache')->CleanUp(
                        Type => 'TicketSearch',
                    );
                }

                # set queue
                if ( $GetParam{'QueueID'} || $GetParam{'Queue'} ) {
                    $Result = $TicketObject->TicketQueueSet(
                        QueueID  => $GetParam{'QueueID'},
                        Queue    => $GetParam{'Queue'},
                        TicketID => $TicketID,
                        UserID   => $Self->{UserID},
                    );

                    if ( !$Result ) {
                        push @NonUpdatedTickets, $Ticket{TicketNumber};
                    }
                }

                # set owner
                if ( $Config->{Owner} && ( $GetParam{'OwnerID'} || $GetParam{'Owner'} ) ) {
                    $Result = $TicketObject->TicketOwnerSet(
                        TicketID  => $TicketID,
                        UserID    => $Self->{UserID},
                        NewUser   => $GetParam{'Owner'},
                        NewUserID => $GetParam{'OwnerID'},
                    );

                    if ( !$Result ) {
                        push @NonUpdatedTickets, $Ticket{TicketNumber};
                    }

                    if ( !$Config->{RequiredLock} && $Ticket{StateType} !~ /^close/i ) {
                        $TicketObject->TicketLockSet(
                            TicketID => $TicketID,
                            Lock     => 'lock',
                            UserID   => $Self->{UserID},
                        );
                    }
                }

                # set responsible
                if (
                    $ConfigObject->Get('Ticket::Responsible')
                    && $Config->{Responsible}
                    && ( $GetParam{'ResponsibleID'} || $GetParam{'Responsible'} )
                    )
                {
                    $Result = $TicketObject->TicketResponsibleSet(
                        TicketID  => $TicketID,
                        UserID    => $Self->{UserID},
                        NewUser   => $GetParam{'Responsible'},
                        NewUserID => $GetParam{'ResponsibleID'},
                    );

                    if ( !$Result ) {
                        push @NonUpdatedTickets, $Ticket{TicketNumber};
                    }
                }

                # set priority
                if (
                    $Config->{Priority}
                    && ( $GetParam{'PriorityID'} || $GetParam{'Priority'} )
                    )
                {
                    $Result = $TicketObject->TicketPrioritySet(
                        TicketID   => $TicketID,
                        UserID     => $Self->{UserID},
                        Priority   => $GetParam{'Priority'},
                        PriorityID => $GetParam{'PriorityID'},
                    );

                    if ( !$Result ) {
                        push @NonUpdatedTickets, $Ticket{TicketNumber};
                    }
                }

                # set type
                if ( $ConfigObject->Get('Ticket::Type') && $Config->{TicketType} ) {
                    if ( $GetParam{'TypeID'} ) {
                        $Result = $TicketObject->TicketTypeSet(
                            TypeID   => $GetParam{'TypeID'},
                            TicketID => $TicketID,
                            UserID   => $Self->{UserID},
                        );

                        if ( !$Result ) {
                            push @NonUpdatedTickets, $Ticket{TicketNumber};
                        }
                    }
                }

                # send email
                my $EmailArticleID;
                if (
                    $GetParam{'EmailSubject'}
                    && $GetParam{'EmailBody'}
                    )
                {
                    my $MimeType = 'text/plain';
                    if ( $LayoutObject->{BrowserRichText} ) {
                        $MimeType = 'text/html';

                        # verify html document
                        $GetParam{'EmailBody'} = $LayoutObject->RichTextDocumentComplete(
                            String => $GetParam{'EmailBody'},
                        );
                    }

                    my @Recipients = $Self->_GetRecipientList( TicketIDs => [ $Ticket{TicketID} ] );
                    my $Customer   = $Recipients[0];

                    # get template generator object
                    my $CustomerUserObject      = $Kernel::OM->Get('Kernel::System::CustomerUser');
                    my $TemplateGeneratorObject = $Kernel::OM->ObjectParamAdd(
                        'Kernel::System::TemplateGenerator' => {
                            CustomerUserObject => $CustomerUserObject,
                        },
                    );

                    $TemplateGeneratorObject = $Kernel::OM->Get('Kernel::System::TemplateGenerator');

                    # generate sender name
                    my $From = $TemplateGeneratorObject->Sender(
                        QueueID => $Ticket{QueueID},
                        UserID  => $Self->{UserID},
                    );

                    # generate subject
                    my $TicketNumber = $TicketObject->TicketNumberLookup( TicketID => $TicketID );

                    my $EmailSubject = $TicketObject->TicketSubjectBuild(
                        TicketNumber => $TicketNumber,
                        Subject      => $GetParam{EmailSubject} || '',
                    );

                    my $EmailArticleBackendObject = $ArticleObject->BackendForChannel( ChannelName => 'Email' );

                    $EmailArticleID = $EmailArticleBackendObject->ArticleSend(
                        TicketID             => $TicketID,
                        SenderType           => 'agent',
                        IsVisibleForCustomer => 1,
                        From                 => $From,
                        To                   => $Customer,
                        Subject              => $EmailSubject,
                        Body                 => $GetParam{EmailBody},
                        MimeType             => $MimeType,
                        Charset              => $LayoutObject->{UserCharset},
                        UserID               => $Self->{UserID},
                        HistoryType          => 'SendAnswer',
                        HistoryComment       => '%%' . $Customer,
                    );
                }

                # add note
                my $ArticleID;
                if (
                    $GetParam{'Subject'}
                    && $GetParam{'Body'}
                    )
                {
                    my $MimeType = 'text/plain';
                    if ( $LayoutObject->{BrowserRichText} ) {
                        $MimeType = 'text/html';

                        # verify html document
                        $GetParam{'Body'} = $LayoutObject->RichTextDocumentComplete(
                            String => $GetParam{'Body'},
                        );
                    }
                    my $InternalArticleBackendObject = $ArticleObject->BackendForChannel( ChannelName => 'Internal' );

                    $ArticleID = $InternalArticleBackendObject->ArticleCreate(
                        TicketID             => $TicketID,
                        SenderType           => 'agent',
                        IsVisibleForCustomer => $GetParam{IsVisibleForCustomer},
                        From                 => "\"$Self->{UserFullname}\" <$Self->{UserEmail}>",
                        Subject              => $GetParam{'Subject'},
                        Body                 => $GetParam{'Body'},
                        MimeType             => $MimeType,
                        Charset              => $LayoutObject->{UserCharset},
                        UserID               => $Self->{UserID},
                        HistoryType          => 'AddNote',
                        HistoryComment       => '%%Bulk',
                    );
                }

                # set state
                if ( $Config->{State} && ( $GetParam{'StateID'} || $GetParam{'State'} ) ) {
                    $Result = $TicketObject->TicketStateSet(
                        TicketID => $TicketID,
                        StateID  => $GetParam{'StateID'},
                        State    => $GetParam{'State'},
                        UserID   => $Self->{UserID},
                    );

                    if ( !$Result ) {
                        push @NonUpdatedTickets, $Ticket{TicketNumber};
                    }

                    my %Ticket = $TicketObject->TicketGet(
                        TicketID      => $TicketID,
                        DynamicFields => 0,
                    );
                    my %StateData = $StateObject->StateGet(
                        ID => $Ticket{StateID},
                    );

                    # should i set the pending date?
                    if ( $Ticket{StateType} =~ /^pending/i ) {

                        # set pending time
                        $TicketObject->TicketPendingTimeSet(
                            %Time,
                            TicketID => $TicketID,
                            UserID   => $Self->{UserID},
                        );
                    }

                    # should I set an unlock?
                    if ( $Ticket{StateType} =~ /^close/i ) {
                        $TicketObject->TicketLockSet(
                            TicketID => $TicketID,
                            Lock     => 'unlock',
                            UserID   => $Self->{UserID},
                        );
                    }
                }

                # time units for note
                if ( $GetParam{TimeUnits} && $ArticleID ) {
                    if ( $ConfigObject->Get('Ticket::Frontend::BulkAccountedTime') ) {
                        $TicketObject->TicketAccountTime(
                            TicketID  => $TicketID,
                            ArticleID => $ArticleID,
                            TimeUnit  => $GetParam{'TimeUnits'},
                            UserID    => $Self->{UserID},
                        );
                    }
                    elsif (
                        !$ConfigObject->Get('Ticket::Frontend::BulkAccountedTime')
                        && $Counter == 1
                        )
                    {
                        $TicketObject->TicketAccountTime(
                            TicketID  => $TicketID,
                            ArticleID => $ArticleID,
                            TimeUnit  => $GetParam{'TimeUnits'},
                            UserID    => $Self->{UserID},
                        );
                    }
                }

                # time units for email
                if ( $GetParam{EmailTimeUnits} && $EmailArticleID ) {
                    if ( $ConfigObject->Get('Ticket::Frontend::BulkAccountedTime') ) {
                        $TicketObject->TicketAccountTime(
                            TicketID  => $TicketID,
                            ArticleID => $EmailArticleID,
                            TimeUnit  => $GetParam{'EmailTimeUnits'},
                            UserID    => $Self->{UserID},
                        );
                    }
                    elsif (
                        !$ConfigObject->Get('Ticket::Frontend::BulkAccountedTime')
                        && $Counter == 1
                        )
                    {
                        $TicketObject->TicketAccountTime(
                            TicketID  => $TicketID,
                            ArticleID => $EmailArticleID,
                            TimeUnit  => $GetParam{'EmailTimeUnits'},
                            UserID    => $Self->{UserID},
                        );
                    }
                }

                # merge
                if ( $MainTicketID && $MainTicketID ne $TicketID ) {
                    $TicketObject->TicketMerge(
                        MainTicketID  => $MainTicketID,
                        MergeTicketID => $TicketID,
                        UserID        => $Self->{UserID},
                    );
                }

                # get link object
                my $LinkObject = $Kernel::OM->Get('Kernel::System::LinkObject');

                # link all tickets to a parent
                if ( $GetParam{'LinkTogetherParent'} ) {
                    my $MainTicketID = $TicketObject->TicketIDLookup(
                        TicketNumber => $GetParam{'LinkTogetherParent'},
                    );

                    for my $TicketIDPartner (@TicketIDs) {
                        if ( $MainTicketID ne $TicketID ) {
                            $LinkObject->LinkAdd(
                                SourceObject => 'Ticket',
                                SourceKey    => $MainTicketID,
                                TargetObject => 'Ticket',
                                TargetKey    => $TicketID,
                                Type         => 'ParentChild',
                                State        => 'Valid',
                                UserID       => $Self->{UserID},
                            );
                        }
                    }
                }

                # link together
                if ( $GetParam{'LinkTogether'} ) {
                    for my $TicketIDPartner (@TicketIDs) {
                        if ( $TicketID ne $TicketIDPartner ) {
                            $LinkObject->LinkAdd(
                                SourceObject => 'Ticket',
                                SourceKey    => $TicketID,
                                TargetObject => 'Ticket',
                                TargetKey    => $TicketIDPartner,
                                Type         => 'Normal',
                                State        => 'Valid',
                                UserID       => $Self->{UserID},
                            );
                        }
                    }
                }

                # should I unlock tickets at user request?
                if ( $GetParam{'Unlock'} ) {
                    $Result = $TicketObject->TicketLockSet(
                        TicketID => $TicketID,
                        Lock     => 'unlock',
                        UserID   => $Self->{UserID},
                    );

                    if ( !$Result ) {
                        push @NonUpdatedTickets, $Ticket{TicketNumber};
                    }
                }

                # call Store() in all ticket bulk modules
                if (@BulkModules) {

                    MODULEOBJECT:
                    for my $ModuleObject (@BulkModules) {
                        next MODULEOBJECT if !$ModuleObject->can('Store');

                        $ModuleObject->Store(
                            TicketID => $TicketID,
                            UserID   => $Self->{UserID},
                        );
                    }
                }

                $ActionFlag = 1;
            }
            $Counter++;
        }

        # notify user about actions (errors)
        if (@TicketsWithError) {
            my $NotificationError = $LayoutObject->{LanguageObject}->Translate(
                "The following tickets were ignored because they are locked by another agent or you don't have write access to these tickets: %s.",
                join( ", ", @TicketsWithError ),
            );

            $Output .= $LayoutObject->Notify(
                Priority => 'Error',
                Data     => $NotificationError,
            );
        }

        # notify user about actions (notices)
        if (@TicketsWithLockNotice) {
            my $NotificationNotice = $LayoutObject->{LanguageObject}->Translate(
                "The following tickets were locked: %s.",
                join( ", ", @TicketsWithLockNotice ),
            );

            $Output .= $LayoutObject->Notify(
                Priority => 'Notice',
                Data     => $NotificationNotice,
            );
        }

        # redirect
        if ($ActionFlag) {

            if ( IsArrayRefWithData( \@NonUpdatedTickets ) ) {
                my $NonUpdatedTicketsString = join ', ', @NonUpdatedTickets;
                $Kernel::OM->Get('Kernel::System::Cache')->Set(
                    Type  => 'Ticket',
                    TTL   => 60,
                    Key   => 'NonUpdatedTicketsString-' . $Self->{UserID},
                    Value => $NonUpdatedTicketsString,
                );
            }

            my $DestURL = defined $MainTicketID
                ? "Action=AgentTicketZoom;TicketID=$MainTicketID"
                : ( $Self->{LastScreenOverview} || 'Action=AgentDashboard' );

            return $LayoutObject->PopupClose(
                URL => $DestURL,
            );
        }

        $Output .= $Self->_Mask(
            %Param,
            %GetParam,
            %Time,
            TicketIDs     => \@TicketIDSelected,
            LockedTickets => $LockedTickets,
            Errors        => \%Error,
            BulkModules   => \@BulkModules,
        );
        $Output .= $LayoutObject->Footer(
            Type => 'Small',
        );
        return $Output;

    }

    return 1;
}

sub _GetRecipientList {

    my ( $Self, %Param ) = @_;

    my $ParamObject   = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject  = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $TicketObject  = $Kernel::OM->Get('Kernel::System::Ticket');
    my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');

    my @Recipients;

    TICKETID:
    for my $TicketID ( @{ $Param{TicketIDs} } ) {
        my $UserHasTicketPermission = $TicketObject->TicketPermission(
            Type     => 'ro',
            TicketID => $TicketID,
            UserID   => $Self->{UserID},
        );

        next TICKETID if !$UserHasTicketPermission;

        my %Ticket = $TicketObject->TicketGet(
            TicketID      => $TicketID,
            DynamicFields => 0,
        );

        my $CustomerUserObject = $Kernel::OM->Get('Kernel::System::CustomerUser');

        # Get customer email address.
        my $Customer;
        if ( $Ticket{CustomerUserID} ) {
            my %Customer = $CustomerUserObject->CustomerUserDataGet(
                User => $Ticket{CustomerUserID}
            );
            if ( $Customer{UserEmail} ) {
                $Customer = $Customer{UserEmail};
            }
        }

        # Check if we have an address, otherwise deduce it from the article.
        if ( !$Customer ) {

            # Get last customer article.
            my @Articles = $ArticleObject->ArticleList(
                TicketID   => $TicketID,
                SenderType => 'customer',
                OnlyLast   => 1,
            );

            # If the ticket has no customer article, get the last agent article.
            if ( !@Articles ) {
                @Articles = $ArticleObject->ArticleList(
                    TicketID   => $TicketID,
                    SenderType => 'agent',
                    OnlyLast   => 1,
                );
            }

            # Finally, if everything failed, get latest article.
            if ( !@Articles ) {
                @Articles = $ArticleObject->ArticleList(
                    TicketID => $TicketID,
                    OnlyLast => 1,
                );
            }

            my %Article;
            for my $Article (@Articles) {
                %Article = $ArticleObject->BackendForArticle( %{$Article} )->ArticleGet(
                    %{$Article},
                    DynamicFields => 0,
                );
            }

            # Use ReplyTo if set, otherwise use From.
            $Customer = $Article{ReplyTo} ? $Article{ReplyTo} : $Article{From};

            # Check article sender type and replace From with To (in case sender is not customer).
            if ( $Article{SenderType} !~ /customer/ ) {
                $Customer = $Article{To};
            }
        }

        # Skip to next ticket if no customer recipient was found.
        next TICKETID if !$Customer;

        # Customer recipients are unique.
        push @Recipients, $Customer if !grep { $_ eq $Customer } @Recipients;
    }

    return @Recipients;
}

sub _Mask {
    my ( $Self, %Param ) = @_;

    # get layout object
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # prepare errors!
    if ( $Param{Errors} ) {
        for my $KeyError ( sort keys %{ $Param{Errors} } ) {
            $Param{$KeyError} = $LayoutObject->Ascii2Html( Text => $Param{Errors}->{$KeyError} );
        }
    }

    $LayoutObject->Block(
        Name => 'BulkAction',
        Data => \%Param,
    );

    # remember ticket ids
    if ( $Param{TicketIDs} ) {
        for my $TicketID ( @{ $Param{TicketIDs} } ) {
            $LayoutObject->Block(
                Name => 'UsedTicketID',
                Data => {
                    TicketID => $TicketID,
                },
            );
        }
    }

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    my $Config = $ConfigObject->Get("Ticket::Frontend::$Self->{Action}");

    $Param{IsVisibleForCustomer} //= $Config->{IsVisibleForCustomerDefault} // 0;

    # build next states string
    if ( $Config->{State} ) {
        my %State;

        my %StateList = $Self->_GetStates(
            %Param,
            StateType => $Config->{StateType},
            Action    => $Self->{Action},
            UserID    => $Self->{UserID},
        );
        if ( !$Config->{StateDefault} ) {
            $StateList{''} = '-';
        }
        if ( !$Param{StateID} ) {
            if ( $Config->{StateDefault} ) {
                $State{SelectedValue} = $Config->{StateDefault};
            }
        }
        else {
            $State{SelectedID} = $Param{StateID};
        }

        $Param{NextStatesStrg} = $LayoutObject->BuildSelection(
            Data => \%StateList,
            Name => 'StateID',
            %State,
            Class => 'Modernize',
        );
        $LayoutObject->Block(
            Name => 'State',
            Data => \%Param,
        );

        my $StateObject = $Kernel::OM->Get('Kernel::System::State');

        STATE_ID:
        for my $StateID ( sort keys %StateList ) {
            next STATE_ID if !$StateID;
            my %StateData = $StateObject->StateGet( ID => $StateID );
            next STATE_ID if $StateData{TypeName} !~ /pending/i;
            $Param{DateString} = $LayoutObject->BuildDateSelection(
                %Param,
                Format               => 'DateInputFormatLong',
                DiffTime             => $ConfigObject->Get('Ticket::Frontend::PendingDiffTime') || 0,
                Class                => $Param{Errors}->{DateInvalid} || '',
                Validate             => 1,
                ValidateDateInFuture => 1,
            );
            $LayoutObject->Block(
                Name => 'StatePending',
                Data => \%Param,
            );
            last STATE_ID;
        }
    }

    # types
    if ( $ConfigObject->Get('Ticket::Type') && $Config->{TicketType} ) {
        my %TypeList = $Self->_GetTypes(
            %Param,
            Action => $Self->{Action},
            UserID => $Self->{UserID},
        );
        $Param{TypeStrg} = $LayoutObject->BuildSelection(
            Data         => \%TypeList,
            PossibleNone => 1,
            Name         => 'TypeID',
            SelectedID   => $Param{TypeID},
            Sort         => 'AlphanumericValue',
            Translation  => 0,
            Class        => 'Modernize',
        );
        $LayoutObject->Block(
            Name => 'Type',
            Data => {%Param},
        );
    }

    # owner list
    if ( $Config->{Owner} ) {
        my %OwnerList = $Self->_GetOwners(
            %Param,
            Action => $Self->{Action},
            UserID => $Self->{UserID},
        );
        $Param{OwnerStrg} = $LayoutObject->BuildSelection(
            Data         => \%OwnerList,
            Name         => 'OwnerID',
            Translation  => 0,
            SelectedID   => $Param{OwnerID},
            PossibleNone => 1,
            Class        => 'Modernize',
        );
        $LayoutObject->Block(
            Name => 'Owner',
            Data => \%Param,
        );
    }

    # responsible list
    if ( $ConfigObject->Get('Ticket::Responsible') && $Config->{Responsible} ) {
        my %ResponsibleList = $Self->_GetResponsibles(
            %Param,
            Action => $Self->{Action},
            UserID => $Self->{UserID},
        );
        $Param{ResponsibleStrg} = $LayoutObject->BuildSelection(
            Data         => \%ResponsibleList,
            PossibleNone => 1,
            Name         => 'ResponsibleID',
            Translation  => 0,
            SelectedID   => $Param{ResponsibleID},
            Class        => 'Modernize',
        );
        $LayoutObject->Block(
            Name => 'Responsible',
            Data => \%Param,
        );
    }

    # build move queue string
    my %QueueList = $Self->_GetQueues(
        %Param,
        Type   => 'move_into',
        UserID => $Self->{UserID},
        Action => $Self->{Action},
    );
    $Param{MoveQueuesStrg} = $LayoutObject->AgentQueueListOption(
        Data           => { %QueueList, '' => '-' },
        Multiple       => 0,
        Size           => 0,
        Name           => 'QueueID',
        OnChangeSubmit => 0,
        Class          => 'Modernize',
    );

    # get priority
    if ( $Config->{Priority} ) {
        my %Priority;
        my %PriorityList = $Self->_GetPriorities(
            %Param,
            UserID => $Self->{UserID},
            Action => $Self->{Action},
        );
        if ( !$Config->{PriorityDefault} ) {
            $PriorityList{''} = '-';
        }
        if ( !$Param{PriorityID} ) {
            if ( $Config->{PriorityDefault} ) {
                $Priority{SelectedValue} = $Config->{PriorityDefault};
            }
        }
        else {
            $Priority{SelectedID} = $Param{PriorityID};
        }
        $Param{PriorityStrg} = $LayoutObject->BuildSelection(
            Data => \%PriorityList,
            Name => 'PriorityID',
            %Priority,
            Class => 'Modernize',

        );
        $LayoutObject->Block(
            Name => 'Priority',
            Data => \%Param,
        );
    }

    # show time accounting box
    if ( $ConfigObject->Get('Ticket::Frontend::AccountTime') ) {
        $Param{TimeUnitsRequired} = (
            $ConfigObject->Get('Ticket::Frontend::NeedAccountedTime')
            ? 'Validate_DependingRequiredAND Validate_Depending_Subject'
            : ''
        );
        $Param{TimeUnitsRequiredEmail} = (
            $ConfigObject->Get('Ticket::Frontend::NeedAccountedTime')
            ? 'Validate_DependingRequiredAND Validate_Depending_EmailSubject'
            : ''
        );

        if ( $ConfigObject->Get('Ticket::Frontend::NeedAccountedTime') ) {
            $LayoutObject->Block(
                Name => 'TimeUnitsLabelMandatory',
                Data => { TimeUnitsRequired => $Param{TimeUnitsRequired} },
            );
            $LayoutObject->Block(
                Name => 'TimeUnitsLabelMandatoryEmail',
                Data => { TimeUnitsRequired => $Param{TimeUnitsRequiredEmail} },
            );
        }
        else {
            $LayoutObject->Block(
                Name => 'TimeUnitsLabel',
                Data => \%Param,
            );
            $LayoutObject->Block(
                Name => 'TimeUnitsLabelEmail',
                Data => \%Param,
            );
        }
        $LayoutObject->Block(
            Name => 'TimeUnits',
            Data => \%Param,
        );
        $LayoutObject->Block(
            Name => 'TimeUnitsEmail',
            Data => \%Param,
        );
    }

    $Param{LinkTogetherYesNoOption} = $LayoutObject->BuildSelection(
        Data       => $ConfigObject->Get('YesNoOptions'),
        Name       => 'LinkTogether',
        SelectedID => $Param{LinkTogether} // 0,
        Class      => 'Modernize',
    );

    $Param{UnlockYesNoOption} = $LayoutObject->BuildSelection(
        Data       => $ConfigObject->Get('YesNoOptions'),
        Name       => 'Unlock',
        SelectedID => $Param{Unlock} // 1,
        Class      => 'Modernize',
    );

    # add rich text editor for note & email
    if ( $LayoutObject->{BrowserRichText} ) {

        # use height/width defined for this screen
        $Param{RichTextHeight} = $Config->{RichTextHeight} || 0;
        $Param{RichTextWidth}  = $Config->{RichTextWidth}  || 0;

        # set up rich text editor
        $LayoutObject->SetRichTextParameters(
            Data => \%Param,
        );
    }

    # reload parent window
    if ( $Param{TicketsWereLocked} ) {

        my $URL = $Self->{LastScreenOverview};

        # add session if no cookies are enabled
        if ( $Self->{SessionID} && !$Self->{SessionIDCookie} ) {
            $URL .= ';' . $Self->{SessionName} . '=' . $Self->{SessionID};
        }

        $LayoutObject->AddJSData(
            Key   => 'TicketBulkURL',
            Value => $LayoutObject->{Baselink} . $URL,
        );

        # show undo&close link
        $LayoutObject->Block(
            Name => 'UndoClosePopup',
            Data => {%Param},
        );
    }
    else {

        # show cancel&close link
        $LayoutObject->Block(
            Name => 'CancelClosePopup',
            Data => {%Param},
        );
    }

    my @BulkModules = @{ $Param{BulkModules} };

    # call Display() in all ticket bulk modules
    if (@BulkModules) {

        my @BulkModuleContent;

        MODULEOBJECT:
        for my $ModuleObject (@BulkModules) {
            next MODULEOBJECT if !$ModuleObject->can('Display');

            my $ModuleContent = $ModuleObject->Display(
                Errors => $Param{Errors},
                UserID => $Self->{UserID},
            );

            push @BulkModuleContent, $ModuleContent;
        }

        $Param{BulkModuleContent} = \@BulkModuleContent;
    }

    # get output back
    return $LayoutObject->Output(
        TemplateFile => 'AgentTicketBulk',
        Data         => \%Param,
    );
}

sub _GetStates {
    my ( $Self, %Param ) = @_;

    # TicketStateList() can not be used here as it might not be a queue selected
    my %StateList = $Kernel::OM->Get('Kernel::System::State')->StateGetStatesByType(
        StateType => $Param{StateType},
        Result    => 'HASH',
        Action    => $Self->{Action},
        UserID    => $Self->{UserID},
    );

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    # Execute ACLs.
    my $ACL = $TicketObject->TicketAcl(
        %Param,
        ReturnType    => 'Ticket',
        ReturnSubType => 'State',
        Data          => \%StateList,
    );

    return $TicketObject->TicketAclData() if $ACL;
    return %StateList;
}

sub _GetTypes {
    my ( $Self, %Param ) = @_;

    my %TypeList = $Kernel::OM->Get('Kernel::System::Ticket')->TicketTypeList(
        %Param,
        Action => $Self->{Action},
        UserID => $Self->{UserID},
    );

    return %TypeList;
}

sub _GetOwners {
    my ( $Self, %Param ) = @_;

    # Get all users.
    my %AllGroupsMembers = $Kernel::OM->Get('Kernel::System::User')->UserList(
        Type  => 'Long',
        Valid => 1
    );

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    # Put only possible 'owner' and 'rw' agents to owner list.
    my %OwnerList;
    if ( !$Kernel::OM->Get('Kernel::Config')->Get('Ticket::ChangeOwnerToEveryone') ) {
        my %AllGroupsMembersNew;
        my @QueueIDs;

        if ( $Param{QueueID} ) {
            push @QueueIDs, $Param{QueueID};
        }
        else {
            my @TicketIDs = grep {$_} $Kernel::OM->Get('Kernel::System::Web::Request')->GetArray( Param => 'TicketID' );
            for my $TicketID (@TicketIDs) {
                my %Ticket = $TicketObject->TicketGet(
                    TicketID      => $TicketID,
                    DynamicFields => 0,
                );
                push @QueueIDs, $Ticket{QueueID};
            }
        }

        my $QueueObject = $Kernel::OM->Get('Kernel::System::Queue');
        my $GroupObject = $Kernel::OM->Get('Kernel::System::Group');

        for my $QueueID (@QueueIDs) {
            my $GroupID     = $QueueObject->GetQueueGroupID( QueueID => $QueueID );
            my %GroupMember = $GroupObject->PermissionGroupGet(
                GroupID => $GroupID,
                Type    => 'owner',
            );
            USER_ID:
            for my $UserID ( sort keys %GroupMember ) {
                next USER_ID if !$AllGroupsMembers{$UserID};
                $AllGroupsMembersNew{$UserID} = $AllGroupsMembers{$UserID};
            }
            %OwnerList = %AllGroupsMembersNew;
        }
    }
    else {
        %OwnerList = %AllGroupsMembers;
    }

    # Execute ACLs.
    my $ACL = $TicketObject->TicketAcl(
        %Param,
        Action        => $Self->{Action},
        ReturnType    => 'Ticket',
        ReturnSubType => 'Owner',
        Data          => \%OwnerList,
        UserID        => $Self->{UserID},
    );

    return $TicketObject->TicketAclData() if $ACL;
    return %OwnerList;
}

sub _GetResponsibles {
    my ( $Self, %Param ) = @_;

    # Get all users.
    my %AllGroupsMembers = $Kernel::OM->Get('Kernel::System::User')->UserList(
        Type  => 'Long',
        Valid => 1
    );

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    # Put only possible 'responsible' and 'rw' agents to responsible list.
    my %ResponsibleList;
    if ( !$Kernel::OM->Get('Kernel::Config')->Get('Ticket::ChangeOwnerToEveryone') ) {
        my %AllGroupsMembersNew;
        my @QueueIDs;

        if ( $Param{QueueID} ) {
            push @QueueIDs, $Param{QueueID};
        }
        else {
            my @TicketIDs = grep {$_} $Kernel::OM->Get('Kernel::System::Web::Request')->GetArray( Param => 'TicketID' );
            for my $TicketID (@TicketIDs) {
                my %Ticket = $TicketObject->TicketGet(
                    TicketID      => $TicketID,
                    DynamicFields => 0,
                );
                push @QueueIDs, $Ticket{QueueID};
            }
        }

        my $QueueObject = $Kernel::OM->Get('Kernel::System::Queue');
        my $GroupObject = $Kernel::OM->Get('Kernel::System::Group');

        for my $QueueID (@QueueIDs) {
            my $GroupID     = $QueueObject->GetQueueGroupID( QueueID => $QueueID );
            my %GroupMember = $GroupObject->PermissionGroupGet(
                GroupID => $GroupID,
                Type    => 'responsible',
            );
            USER_ID:
            for my $UserID ( sort keys %GroupMember ) {
                next USER_ID if !$AllGroupsMembers{$UserID};
                $AllGroupsMembersNew{$UserID} = $AllGroupsMembers{$UserID};
            }
            %ResponsibleList = %AllGroupsMembersNew;
        }
    }
    else {
        %ResponsibleList = %AllGroupsMembers;
    }

    # Execute ACLs.
    my $ACL = $TicketObject->TicketAcl(
        %Param,
        Action        => $Self->{Action},
        ReturnType    => 'Ticket',
        ReturnSubType => 'Responsible',
        Data          => \%ResponsibleList,
        UserID        => $Self->{UserID},
    );

    return $TicketObject->TicketAclData() if $ACL;
    return %ResponsibleList;
}

sub _GetQueues {
    my ( $Self, %Param ) = @_;

    my %QueueList = $Kernel::OM->Get('Kernel::System::Ticket')->MoveList(
        %Param,
        UserID => $Self->{UserID},
        Action => $Self->{Action},
        Type   => 'move_into',
    );

    return %QueueList;
}

sub _GetPriorities {
    my ( $Self, %Param ) = @_;

    my %PriorityList = $Kernel::OM->Get('Kernel::System::Ticket')->TicketPriorityList(
        %Param,
        Action => $Self->{Action},
        UserID => $Self->{UserID},
    );
    return %PriorityList;
}

1;
