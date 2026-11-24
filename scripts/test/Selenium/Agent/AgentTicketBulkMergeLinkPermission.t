# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));

my $Selenium = $Kernel::OM->Get('Kernel::System::UnitTest::Selenium');

$Selenium->RunTest(
    sub {

        my $HelperObject   = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
        my $GroupObject    = $Kernel::OM->Get('Kernel::System::Group');
        my $QueueObject    = $Kernel::OM->Get('Kernel::System::Queue');
        my $TicketObject   = $Kernel::OM->Get('Kernel::System::Ticket');
        my $ArticleObject  = $Kernel::OM->Get('Kernel::System::Ticket::Article');
        my $LinkObject     = $Kernel::OM->Get('Kernel::System::LinkObject');
        my $PriorityObject = $Kernel::OM->Get('Kernel::System::Priority');
        my $ConfigObject   = $Kernel::OM->Get('Kernel::Config');
        my $CacheObject    = $Kernel::OM->Get('Kernel::System::Cache');
        my $DBObject       = $Kernel::OM->Get('Kernel::System::DB');

        my $RandomID = $HelperObject->GetRandomID();

        $ConfigObject->Set(
            Key   => 'CheckEmailAddresses',
            Value => 0,
        );

        $HelperObject->ConfigSettingChange(
            Valid => 1,
            Key   => 'Ticket::Frontend::BulkFeature',
            Value => 1,
        );

        # Keep the permission result separate from the bulk lock behavior.
        $HelperObject->ConfigSettingChange(
            Valid => 1,
            Key   => 'Ticket::Frontend::AgentTicketBulk###RequiredLock',
            Value => 0,
        );

        $HelperObject->ConfigSettingChange(
            Valid => 1,
            Key   => 'Frontend::RichText',
            Value => 0,
        );

        my $NormalPriorityID = $PriorityObject->PriorityLookup(
            Priority => '3 normal',
        );
        my $HighPriorityID = $PriorityObject->PriorityLookup(
            Priority => '4 high',
        );
        $Self->True(
            $NormalPriorityID && $HighPriorityID,
            'Normal and high priorities exist',
        );

        my @GroupIDs;
        my $OwnGroupName     = "BulkPermission-Own-$RandomID";
        my $ForeignGroupName = "BulkPermission-Foreign-$RandomID";

        for my $GroupName ( $OwnGroupName, $ForeignGroupName ) {
            my $GroupID = $GroupObject->GroupAdd(
                Name    => $GroupName,
                ValidID => 1,
                UserID  => 1,
            );
            $Self->True(
                $GroupID,
                "Group $GroupName is created",
            );
            push @GroupIDs, $GroupID;
        }

        my @QueueIDs;
        my $OwnQueueID = $QueueObject->QueueAdd(
            Name            => "BulkPermission-Own-$RandomID",
            ValidID         => 1,
            GroupID         => $GroupIDs[0],
            SystemAddressID => 1,
            SalutationID    => 1,
            SignatureID     => 1,
            Comment         => 'Bulk permission test',
            UserID          => 1,
        );
        my $ForeignQueueID = $QueueObject->QueueAdd(
            Name            => "BulkPermission-Foreign-$RandomID",
            ValidID         => 1,
            GroupID         => $GroupIDs[1],
            SystemAddressID => 1,
            SalutationID    => 1,
            SignatureID     => 1,
            Comment         => 'Bulk permission test',
            UserID          => 1,
        );
        $Self->True(
            $OwnQueueID && $ForeignQueueID,
            'Queues are created',
        );
        push @QueueIDs, $OwnQueueID, $ForeignQueueID;

        # rw on the own queue only. The users group is required for the agent interface.
        my ( $TestUserLogin, $TestUserID ) = $HelperObject->TestUserCreate(
            Groups => [ 'users', $OwnGroupName ],
        );
        if ( !$TestUserLogin || !$TestUserID ) {
            die "Did not get test user";
        }

        my $CreateTicket = sub {
            my (%Param) = @_;

            my $TicketNumber = $TicketObject->TicketCreateNumber();
            my $TicketID     = $TicketObject->TicketCreate(
                TN           => $TicketNumber,
                Title        => $Param{Title},
                QueueID      => $Param{QueueID},
                Lock         => 'unlock',
                Priority     => '3 normal',
                State        => 'open',
                CustomerID   => 'Customer-' . $RandomID,
                CustomerUser => 'customer-' . $RandomID . '@example.com',
                OwnerID      => 1,
                UserID       => 1,
            );
            $Self->True(
                $TicketID,
                "Ticket is created - $Param{Title}",
            );

            return {
                TicketID     => $TicketID,
                TicketNumber => $TicketNumber,
            };
        };

        # Source is created before the newer tickets so merge-to-oldest can tell them apart.
        my $ForeignTicket = $CreateTicket->(
            Title   => 'Foreign',
            QueueID => $ForeignQueueID,
        );
        my $SourceTicket = $CreateTicket->(
            Title   => 'Source',
            QueueID => $OwnQueueID,
        );

        sleep 2;

        my $SiblingTicket = $CreateTicket->(
            Title   => 'Sibling',
            QueueID => $OwnQueueID,
        );
        my $MergeTicket = $CreateTicket->(
            Title   => 'MergeSource',
            QueueID => $OwnQueueID,
        );

        my $ArticleBackendObject = $ArticleObject->BackendForChannel(
            ChannelName => 'Internal',
        );
        my $ArticleID = $ArticleBackendObject->ArticleCreate(
            TicketID             => $MergeTicket->{TicketID},
            SenderType           => 'agent',
            IsVisibleForCustomer => 0,
            From                 => 'UnitTest',
            Subject              => 'Bulk permission article',
            Body                 => 'Bulk permission article',
            ContentType          => 'text/plain; charset=utf-8',
            HistoryType          => 'AddNote',
            HistoryComment       => 'Bulk permission test',
            UserID               => 1,
        );
        $Self->True(
            $ArticleID,
            'Article is created on the merge source ticket',
        );

        my @Tickets = ( $ForeignTicket, $SourceTicket, $SiblingTicket, $MergeTicket );

        $Selenium->Login(
            Type     => 'Agent',
            User     => $TestUserLogin,
            Password => $TestUserLogin,
        );

        my $ScriptAlias = $ConfigObject->Get('ScriptAlias');

        my $ReloadObjects = sub {
            $CacheObject->CleanUp( Type => 'Ticket' );
            $CacheObject->CleanUp( Type => 'Article' );

            # LinkList caches an empty list, and the cache key does not include the link type.
            $CacheObject->CleanUp( Type => 'LinkObject' );
            $Kernel::OM->ObjectsDiscard(
                Objects => [
                    'Kernel::System::Ticket',
                    'Kernel::System::Ticket::Article',
                    'Kernel::System::LinkObject',
                ],
            );
            $TicketObject  = $Kernel::OM->Get('Kernel::System::Ticket');
            $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');
            $LinkObject    = $Kernel::OM->Get('Kernel::System::LinkObject');
            return;
        };

        my $GetTicket = sub {
            my ($TicketID) = @_;

            $ReloadObjects->();
            my %Ticket = $TicketObject->TicketGet(
                TicketID      => $TicketID,
                DynamicFields => 0,
                UserID        => 1,
            );
            return %Ticket;
        };

        my $LinkedTicketIDs = sub {
            my ( $TicketID, $Type ) = @_;

            $ReloadObjects->();
            my $LinkList = $LinkObject->LinkList(
                Object => 'Ticket',
                Key    => $TicketID,
                State  => 'Valid',
                Type   => $Type,
                UserID => 1,
            ) || {};

            my %LinkedTicketIDs;
            my $TypeLinks = $LinkList->{Ticket}->{$Type} || {};
            DIRECTION:
            for my $Direction ( sort keys %{$TypeLinks} ) {
                my $DirectionLinks = $TypeLinks->{$Direction} || {};
                for my $LinkedTicketID ( sort keys %{$DirectionLinks} ) {
                    $LinkedTicketIDs{$LinkedTicketID} = 1;
                }
            }
            return \%LinkedTicketIDs;
        };

        my $ArticleIsOnTicket = sub {
            my ( $TicketID, $WantedArticleID ) = @_;

            $ReloadObjects->();
            my @Articles = $ArticleObject->ArticleList(
                TicketID => $TicketID,
            );
            ARTICLE:
            for my $Article (@Articles) {
                next ARTICLE if $Article->{ArticleID} != $WantedArticleID;
                return 1;
            }
            return 0;
        };

        my $OpenBulk = sub {
            my (@TicketIDs) = @_;

            my @TicketIDParams;
            for my $TicketID (@TicketIDs) {
                push @TicketIDParams, 'TicketID=' . $TicketID;
            }
            my $TicketIDQuery = join q{;}, @TicketIDParams;
            $Selenium->VerifiedGet(
                "${ScriptAlias}index.pl?Action=AgentTicketBulk;$TicketIDQuery"
            );
            $Selenium->WaitFor(
                JavaScript => 'return typeof($) === "function" && $("#submitRichText").length;'
            );
            return;
        };

        my $SubmitBulk = sub {
            $Selenium->execute_script(
                "document.getElementById('submitRichText').scrollIntoView({block:'center', inline:'nearest'});"
            );
            $Selenium->find_element( '#submitRichText', 'css' )->VerifiedClick();
            return;
        };

        my $SetMergeTarget = sub {
            my ($TicketNumber) = @_;

            $Selenium->execute_script(
                "\$('#OptionMergeTo').prop('checked', true); \$('#MergeTo').val('$TicketNumber');"
            );
            return;
        };

        my $SetParentTarget = sub {
            my ($TicketNumber) = @_;

            $Selenium->execute_script(
                "\$('#LinkTogetherParent').val('$TicketNumber');"
            );
            return;
        };

        my $SetLinkTogether = sub {
            $Selenium->InputFieldValueSet(
                Element => '#LinkTogether',
                Value   => 1,
            );
            return;
        };

        my $SetHighPriority = sub {
            $Selenium->InputFieldValueSet(
                Element => '#PriorityID',
                Value   => $HighPriorityID,
            );
            $Selenium->WaitFor(
                JavaScript => 'return typeof($) === "function" && !$(".AJAXLoader:visible").length;'
            );
            return;
        };

        my $FieldHasServerError = sub {
            my ($FieldID) = @_;

            $Selenium->WaitFor(
                JavaScript => "return typeof(\$) === 'function' && \$('#$FieldID.ServerError').length;"
            );
            $Self->True(
                $Selenium->execute_script("return \$('#$FieldID').hasClass('ServerError');"),
                "#$FieldID shows an invalid ticket identifier",
            );
            return;
        };

        # Merge into a ticket the agent cannot write. Other bulk changes must not be stored.
        $OpenBulk->( $SourceTicket->{TicketID} );
        $SetHighPriority->();
        $SetMergeTarget->( $ForeignTicket->{TicketNumber} );
        $SubmitBulk->();
        $FieldHasServerError->('MergeTo');

        my %SourceData = $GetTicket->( $SourceTicket->{TicketID} );
        $Self->Is(
            $SourceData{StateType},
            'open',
            'Merge into a ticket without write permission does not merge the source ticket',
        );
        $Self->Is(
            $SourceData{PriorityID},
            $NormalPriorityID,
            'Merge into a ticket without write permission does not apply other bulk changes',
        );
        my %ForeignData = $GetTicket->( $ForeignTicket->{TicketID} );
        $Self->Is(
            $ForeignData{StateType},
            'open',
            'Merge into a ticket without write permission leaves the target unchanged',
        );

        # Link to a parent the agent cannot write.
        $OpenBulk->( $SourceTicket->{TicketID} );
        $SetParentTarget->( $ForeignTicket->{TicketNumber} );
        $SubmitBulk->();
        $FieldHasServerError->('LinkTogetherParent');

        my $ParentLinks = $LinkedTicketIDs->( $SourceTicket->{TicketID}, 'ParentChild' );
        $Self->False(
            $ParentLinks->{ $ForeignTicket->{TicketID} },
            'Link to a parent without write permission creates no ParentChild link',
        );
        %SourceData = $GetTicket->( $SourceTicket->{TicketID} );
        $Self->Is(
            $SourceData{StateType},
            'open',
            'Link to a parent without write permission leaves the source ticket open',
        );

        # An unknown ticket number uses the same field error.
        $OpenBulk->( $SourceTicket->{TicketID} );
        $SetMergeTarget->('9999999999999999');
        $SetParentTarget->('9999999999999999');
        $SubmitBulk->();
        $FieldHasServerError->('MergeTo');
        $FieldHasServerError->('LinkTogetherParent');

        # Merge to oldest skips a ticket the agent cannot write, and still updates the writable ticket.
        $OpenBulk->( $SourceTicket->{TicketID}, $ForeignTicket->{TicketID} );
        $Selenium->find_element( '#OptionMergeToOldest', 'css' )->click();
        $SetHighPriority->();
        $SubmitBulk->();

        %SourceData = $GetTicket->( $SourceTicket->{TicketID} );
        $Self->Is(
            $SourceData{StateType},
            'open',
            'Merge to oldest does not merge the writable ticket into a ticket without write permission',
        );
        $Self->Is(
            $SourceData{PriorityID},
            $HighPriorityID,
            'Merge to oldest still applies other bulk changes to the writable ticket',
        );
        %ForeignData = $GetTicket->( $ForeignTicket->{TicketID} );
        $Self->Is(
            $ForeignData{StateType},
            'open',
            'Merge to oldest leaves the ticket without write permission unchanged',
        );
        $Self->Is(
            $ForeignData{PriorityID},
            $NormalPriorityID,
            'Merge to oldest does not change the ticket without write permission',
        );

        # Link together skips a ticket the agent cannot write.
        $OpenBulk->( $SourceTicket->{TicketID}, $ForeignTicket->{TicketID} );
        $SetLinkTogether->();
        $SubmitBulk->();

        my $NormalLinks = $LinkedTicketIDs->( $SourceTicket->{TicketID}, 'Normal' );
        $Self->False(
            $NormalLinks->{ $ForeignTicket->{TicketID} },
            'Link together does not link a ticket without write permission',
        );

        # The same actions succeed for tickets the agent can write.
        # Normal and ParentChild belong to one link type group, so they need different pairs.
        $OpenBulk->( $SourceTicket->{TicketID}, $SiblingTicket->{TicketID} );
        $SetLinkTogether->();
        $SubmitBulk->();

        $NormalLinks = $LinkedTicketIDs->( $SourceTicket->{TicketID}, 'Normal' );
        $Self->True(
            $NormalLinks->{ $SiblingTicket->{TicketID} },
            'Link together links tickets the agent can write',
        );

        $OpenBulk->( $MergeTicket->{TicketID} );
        $SetParentTarget->( $SiblingTicket->{TicketNumber} );
        $SubmitBulk->();

        $ParentLinks = $LinkedTicketIDs->( $MergeTicket->{TicketID}, 'ParentChild' );
        $Self->True(
            $ParentLinks->{ $SiblingTicket->{TicketID} },
            'Link to parent links a ticket the agent can write',
        );

        $OpenBulk->( $MergeTicket->{TicketID} );
        $SetMergeTarget->( $SiblingTicket->{TicketNumber} );
        $SubmitBulk->();

        my %MergeData = $GetTicket->( $MergeTicket->{TicketID} );
        $Self->Is(
            $MergeData{StateType},
            'merged',
            'Merge to a ticket with write permission merges the source ticket',
        );
        $Self->True(
            $ArticleIsOnTicket->( $SiblingTicket->{TicketID}, $ArticleID ),
            'Merge to a ticket with write permission moves the article to the target',
        );
        $Self->False(
            $ArticleIsOnTicket->( $MergeTicket->{TicketID}, $ArticleID ),
            'Merge to a ticket with write permission removes the article from the source',
        );

        $OpenBulk->( $SourceTicket->{TicketID}, $SiblingTicket->{TicketID} );
        $Selenium->find_element( '#OptionMergeToOldest', 'css' )->click();
        $SubmitBulk->();

        %SourceData = $GetTicket->( $SourceTicket->{TicketID} );
        $Self->Is(
            $SourceData{StateType},
            'open',
            'Merge to oldest keeps the oldest writable ticket open',
        );
        my %SiblingData = $GetTicket->( $SiblingTicket->{TicketID} );
        $Self->Is(
            $SiblingData{StateType},
            'merged',
            'Merge to oldest merges the newer writable ticket into the oldest one',
        );

        for my $Ticket (@Tickets) {
            my $Success = $TicketObject->TicketDelete(
                TicketID => $Ticket->{TicketID},
                UserID   => 1,
            );
            if ( !$Success ) {
                sleep 3;
                $Success = $TicketObject->TicketDelete(
                    TicketID => $Ticket->{TicketID},
                    UserID   => 1,
                );
            }
            $Self->True(
                $Success,
                "Ticket is deleted - $Ticket->{TicketNumber}",
            );
        }

        for my $QueueID (@QueueIDs) {
            my $Success = $DBObject->Do(
                SQL  => 'DELETE FROM queue WHERE id = ?',
                Bind => [ \$QueueID ],
            );
            $Self->True(
                $Success,
                "QueueID $QueueID is deleted",
            );
        }

        for my $GroupID (@GroupIDs) {
            my $Success = $DBObject->Do(
                SQL  => 'DELETE FROM group_user WHERE group_id = ?',
                Bind => [ \$GroupID ],
            );
            $Self->True(
                $Success,
                "Relation for group ID $GroupID is deleted",
            );
        }

        for my $GroupID (@GroupIDs) {
            my $Success = $DBObject->Do(
                SQL  => 'DELETE FROM permission_groups WHERE id = ?',
                Bind => [ \$GroupID ],
            );
            $Self->True(
                $Success,
                "GroupID $GroupID is deleted",
            );
        }

        $CacheObject->CleanUp( Type => 'Ticket' );
    }
);

1;
