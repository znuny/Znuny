# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::Ticket;

use strict;
use warnings;

use File::Path;
use utf8;
use Encode ();
use MIME::Base64;

use parent qw(
    Kernel::System::EventHandler
    Kernel::System::Ticket::TicketSearch
    Kernel::System::Ticket::TicketACL
);

use Kernel::Language qw(Translatable);
use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::Language',
    'Kernel::System::Cache',
    'Kernel::System::Calendar',
    'Kernel::System::CustomerCompany',
    'Kernel::System::CustomerUser',
    'Kernel::System::DB',
    'Kernel::System::DateTime',
    'Kernel::System::DynamicField',
    'Kernel::System::DynamicField::Backend',
    'Kernel::System::DynamicFieldValue',
    'Kernel::System::Group',
    'Kernel::System::LinkObject',
    'Kernel::System::Lock',
    'Kernel::System::Log',
    'Kernel::System::Main',
    'Kernel::System::Priority',
    'Kernel::System::Queue',
    'Kernel::System::SLA',
    'Kernel::System::Service',
    'Kernel::System::State',
    'Kernel::System::Ticket::Article',
    'Kernel::System::Type',
    'Kernel::System::User',
);

=head1 NAME

Kernel::System::Ticket - Functions to create, modify and delete tickets as well as related helper functions

=head1 SYNOPSIS

Create ticket object

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

Create a new ticket

    my $TicketID = $TicketObject->TicketCreate(
        Title        => 'Some Ticket Title',
        Queue        => 'Raw',
        Lock         => 'unlock',
        Priority     => '3 normal',
        State        => 'new',
        CustomerID   => '12345',
        CustomerUser => 'customer@example.com',
        OwnerID      => 1,
        UserID       => 1,
    );

Lock the ticket

    my $Success = $TicketObject->TicketLockSet(
        Lock     => 'lock',
        TicketID => $TicketID,
        UserID   => 1,
    );


Update the title

    my $Success = $TicketObject->TicketTitleUpdate(
        Title    => 'Some Title',
        TicketID => $TicketID,
        UserID   => 1,
    );

Move ticket to another queue

    my $Success = $TicketObject->TicketQueueSet(
        Queue    => 'Some Queue Name',
        TicketID => $TicketID,
        UserID   => 1,
    );

Set a ticket type

    my $Success = $TicketObject->TicketTypeSet(
        Type     => 'Incident',
        TicketID => $TicketID,
        UserID   => 1,
    );

Assign another customer

    my $Success = $TicketObject->TicketCustomerSet(
        No       => '12345',
        User     => 'customer@company.org',
        TicketID => $TicketID,
        UserID   => 1,
    );

Update the state

    my $Success = $TicketObject->TicketStateSet(
        State     => 'pending reminder',
        TicketID => $TicketID,
        UserID   => 1,
    );

Update pending time (only for pending states)

    my $Success = $TicketObject->TicketPendingTimeSet(
        String   => '2019-08-14 22:05:00',
        TicketID => $TicketID,
        UserID   => 1,
    );

Set a new priority

    my $Success = $TicketObject->TicketPrioritySet(
        TicketID => $TicketID,
        Priority => 'low',
        UserID   => 1,
    );

Assign to another agent

    my $Success = $TicketObject->TicketOwnerSet(
        TicketID  => $TicketID,
        NewUserID => 2,
        UserID    => 1,
    );

Set a responsible

    my $Success = $TicketObject->TicketResponsibleSet(
        TicketID  => $TicketID,
        NewUserID => 3,
        UserID    => 1,
    );

Add something to the history

    my $Success = $TicketObject->HistoryAdd(
        Name         => 'Some Comment',
        HistoryType  => 'Move',
        TicketID     => $TicketID,
        CreateUserID => 1,
    );

Get the complete ticket history

    my @HistoryLines = $TicketObject->HistoryGet(
        TicketID => $TicketID,
        UserID   => 1,
    );

Get current ticket attributes

    my %Ticket = $TicketObject->TicketGet(
        TicketID      => $TicketID,
        UserID        => 1,
    );

Delete the ticket

    my $Success = $TicketObject->TicketDelete(
        TicketID => $TicketID,
        UserID   => 1,
    );

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # 0=off; 1=on;
    $Self->{Debug} = $Param{Debug} || 0;

    $Self->{CacheType} = 'Ticket';
    $Self->{CacheTTL}  = 60 * 60 * 24 * 20;

    # init of event handler
    $Self->EventHandlerInit(
        Config => 'Ticket::EventModulePost',
    );

    # get needed objects
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $MainObject   = $Kernel::OM->Get('Kernel::System::Main');

    # load ticket extension modules
    my $CustomModule = $ConfigObject->Get('Ticket::CustomModule');
    if ($CustomModule) {

        my %ModuleList;
        if ( ref $CustomModule eq 'HASH' ) {
            %ModuleList = %{$CustomModule};
        }
        else {
            $ModuleList{Init} = $CustomModule;
        }

        MODULEKEY:
        for my $ModuleKey ( sort keys %ModuleList ) {

            my $Module = $ModuleList{$ModuleKey};

            next MODULEKEY if !$Module;
            next MODULEKEY if !$MainObject->RequireBaseClass($Module);
        }
    }

    return $Self;
}

=head2 TicketCreateNumber()

creates a new ticket number

    my $TicketNumber = $TicketObject->TicketCreateNumber();

=cut

sub TicketCreateNumber {
    my ( $Self, %Param ) = @_;

    my $GeneratorModule = $Kernel::OM->Get('Kernel::Config')->Get('Ticket::NumberGenerator')
        || 'Kernel::System::Ticket::Number::AutoIncrement';

    return $Kernel::OM->Get($GeneratorModule)->TicketCreateNumber(%Param);
}

=head2 GetTNByString()

creates a new ticket number

    my $TicketNumber = $TicketObject->GetTNByString($Subject);

=cut

sub GetTNByString {
    my ( $Self, $String ) = @_;

    my $GeneratorModule = $Kernel::OM->Get('Kernel::Config')->Get('Ticket::NumberGenerator')
        || 'Kernel::System::Ticket::Number::AutoIncrement';

    return $Kernel::OM->Get($GeneratorModule)->GetTNByString($String);
}

=head2 TicketCheckNumber()

checks if ticket number exists, returns ticket id if number exists.

returns the merged ticket id if ticket was merged.
only into a depth of maximum 10 merges

    my $TicketID = $TicketObject->TicketCheckNumber(
        Tn => '200404051004575',
    );

=cut

sub TicketCheckNumber {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{Tn} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need TN!'
        );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # db query
    return if !$DBObject->Prepare(
        SQL   => 'SELECT id FROM ticket WHERE tn = ?',
        Bind  => [ \$Param{Tn} ],
        Limit => 1,
    );

    my $TicketID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $TicketID = $Row[0];
    }

    # get main ticket id if ticket has been merged
    return if !$TicketID;

    # do not check deeper than 10 merges
    my $Limit = 10;
    my $Count = 1;
    MERGE:
    for my $Current ( 1 .. $Limit ) {
        my %Ticket = $Self->TicketGet(
            TicketID      => $TicketID,
            DynamicFields => 0,
        );

        return $TicketID if $Ticket{StateType} ne 'merged';

        # get ticket history
        my @Lines = $Self->HistoryGet(
            TicketID => $TicketID,
            UserID   => 1,
        );

        HISTORYLINE:
        for my $Data ( reverse @Lines ) {
            next HISTORYLINE if $Data->{HistoryType} ne 'Merged';
            if ( $Data->{Name} =~ /^.*%%\d+?%%(\d+?)$/ ) {
                $TicketID = $1;
                $Count++;
                next MERGE if ( $Count <= $Limit );

                # returns no found Ticket after 10 deep-merges, so it should create a new one
                return;
            }
        }

        return $TicketID;
    }
    return;
}

=head2 TicketCreate()

creates a new ticket

    my $TicketID = $TicketObject->TicketCreate(
        Title        => 'Some Ticket Title',
        Queue        => 'Raw',            # or QueueID => 123,
        Lock         => 'unlock',
        Priority     => '3 normal',       # or PriorityID => 2,
        State        => 'new',            # or StateID => 5,
        CustomerID   => '123465',
        CustomerUser => 'customer@example.com',
        OwnerID      => 123,
        UserID       => 123,
    );

or

    my $TicketID = $TicketObject->TicketCreate(
        TN            => $TicketObject->TicketCreateNumber(), # optional
        Title         => 'Some Ticket Title',
        Queue         => 'Raw',              # or QueueID => 123,
        Lock          => 'unlock',
        Priority      => '3 normal',         # or PriorityID => 2,
        State         => 'new',              # or StateID => 5,
        Type          => 'Incident',         # or TypeID = 1 or Ticket type default (Ticket::Type::Default), not required
        Service       => 'Service A',        # or ServiceID => 1, not required
        SLA           => 'SLA A',            # or SLAID => 1, not required
        CustomerID    => '123465',
        CustomerUser  => 'customer@example.com',
        OwnerID       => 123,
        ResponsibleID => 123,                # not required
        ArchiveFlag   => 'y',                # (y|n) not required
        UserID        => 123,
    );

Events:
    TicketCreate

=cut

sub TicketCreate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(OwnerID UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    my $ArchiveFlag = 0;
    if ( $Param{ArchiveFlag} && $Param{ArchiveFlag} eq 'y' ) {
        $ArchiveFlag = 1;
    }

    $Param{ResponsibleID} ||= 1;

    # get type object
    my $TypeObject = $Kernel::OM->Get('Kernel::System::Type');

    if ( !$Param{TypeID} && !$Param{Type} ) {

        # get default ticket type
        my $DefaultTicketType = $Kernel::OM->Get('Kernel::Config')->Get('Ticket::Type::Default');

        # check if default ticket type exists
        my %AllTicketTypes = reverse $TypeObject->TypeList();

        if ( $AllTicketTypes{$DefaultTicketType} ) {
            $Param{Type} = $DefaultTicketType;
        }
        else {
            $Param{TypeID} = 1;
        }
    }

    # TypeID/Type lookup!
    if ( !$Param{TypeID} && $Param{Type} ) {
        $Param{TypeID} = $TypeObject->TypeLookup( Type => $Param{Type} );
    }
    elsif ( $Param{TypeID} && !$Param{Type} ) {
        $Param{Type} = $TypeObject->TypeLookup( TypeID => $Param{TypeID} );
    }
    if ( !$Param{TypeID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "No TypeID for '$Param{Type}'!",
        );
        return;
    }

    # get queue object
    my $QueueObject = $Kernel::OM->Get('Kernel::System::Queue');

    # QueueID/Queue lookup!
    if ( !$Param{QueueID} && $Param{Queue} ) {
        $Param{QueueID} = $QueueObject->QueueLookup( Queue => $Param{Queue} );
    }
    elsif ( !$Param{Queue} ) {
        $Param{Queue} = $QueueObject->QueueLookup( QueueID => $Param{QueueID} );
    }
    if ( !$Param{QueueID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "No QueueID for '$Param{Queue}'!",
        );
        return;
    }

    # get state object
    my $StateObject = $Kernel::OM->Get('Kernel::System::State');

    # StateID/State lookup!
    if ( !$Param{StateID} ) {
        my %State = $StateObject->StateGet( Name => $Param{State} );
        $Param{StateID} = $State{ID};
    }
    elsif ( !$Param{State} ) {
        my %State = $StateObject->StateGet( ID => $Param{StateID} );
        $Param{State} = $State{Name};
    }
    if ( !$Param{StateID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "No StateID for '$Param{State}'!",
        );
        return;
    }

    # LockID lookup!
    if ( !$Param{LockID} && $Param{Lock} ) {

        $Param{LockID} = $Kernel::OM->Get('Kernel::System::Lock')->LockLookup(
            Lock => $Param{Lock},
        );
    }
    if ( !$Param{LockID} && !$Param{Lock} ) {

        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'No LockID and no LockType!',
        );
        return;
    }

    # get priority object
    my $PriorityObject = $Kernel::OM->Get('Kernel::System::Priority');

    # PriorityID/Priority lookup!
    if ( !$Param{PriorityID} && $Param{Priority} ) {
        $Param{PriorityID} = $PriorityObject->PriorityLookup(
            Priority => $Param{Priority},
        );
    }
    elsif ( $Param{PriorityID} && !$Param{Priority} ) {
        $Param{Priority} = $PriorityObject->PriorityLookup(
            PriorityID => $Param{PriorityID},
        );
    }
    if ( !$Param{PriorityID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'No PriorityID (invalid Priority Name?)!',
        );
        return;
    }

    # get service object
    my $ServiceObject = $Kernel::OM->Get('Kernel::System::Service');

    # ServiceID/Service lookup!
    if ( !$Param{ServiceID} && $Param{Service} ) {
        $Param{ServiceID} = $ServiceObject->ServiceLookup(
            Name => $Param{Service},
        );
    }
    elsif ( $Param{ServiceID} && !$Param{Service} ) {
        $Param{Service} = $ServiceObject->ServiceLookup(
            ServiceID => $Param{ServiceID},
        );
    }

    # get sla object
    my $SLAObject = $Kernel::OM->Get('Kernel::System::SLA');

    # SLAID/SLA lookup!
    if ( !$Param{SLAID} && $Param{SLA} ) {
        $Param{SLAID} = $SLAObject->SLALookup( Name => $Param{SLA} );
    }
    elsif ( $Param{SLAID} && !$Param{SLA} ) {
        $Param{SLA} = $SLAObject->SLALookup( SLAID => $Param{SLAID} );
    }

    # create ticket number if none is given
    if ( !$Param{TN} ) {
        $Param{TN} = $Self->TicketCreateNumber();
    }

    # check ticket title
    if ( !defined $Param{Title} ) {
        $Param{Title} = '';
    }

    # substitute title if needed
    else {
        $Param{Title} = substr( $Param{Title}, 0, 255 );
    }

    # check database undef/NULL (set value to undef/NULL to prevent database errors)
    $Param{ServiceID} ||= undef;
    $Param{SLAID}     ||= undef;

    # create db record
    return if !$Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL => '
            INSERT INTO ticket (tn, title, type_id, queue_id, ticket_lock_id,
                user_id, responsible_user_id, ticket_priority_id, ticket_state_id,
                escalation_time, escalation_update_time, escalation_response_time,
                escalation_solution_time, timeout, service_id, sla_id, until_time,
                archive_flag, create_time, create_by, change_time, change_by)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 0, 0, 0, 0, 0, ?, ?, 0, ?,
                current_timestamp, ?, current_timestamp, ?)',
        Bind => [
            \$Param{TN}, \$Param{Title}, \$Param{TypeID}, \$Param{QueueID},
            \$Param{LockID},     \$Param{OwnerID}, \$Param{ResponsibleID},
            \$Param{PriorityID}, \$Param{StateID}, \$Param{ServiceID},
            \$Param{SLAID}, \$ArchiveFlag, \$Param{UserID}, \$Param{UserID},
        ],
    );

    # get ticket id
    my $TicketID = $Self->TicketIDLookup(
        TicketNumber => $Param{TN},
        UserID       => $Param{UserID},
    );

    # add history entry
    $Self->HistoryAdd(
        TicketID     => $TicketID,
        QueueID      => $Param{QueueID},
        HistoryType  => 'NewTicket',
        Name         => "\%\%$Param{TN}\%\%$Param{Queue}\%\%$Param{Priority}\%\%$Param{State}\%\%$TicketID",
        CreateUserID => $Param{UserID},
    );

    if ( $Kernel::OM->Get('Kernel::Config')->Get('Ticket::Service') ) {

        # history insert for service so that initial values can be seen
        my $HistoryService   = $Param{Service}   || 'NULL';
        my $HistoryServiceID = $Param{ServiceID} || '';
        $Self->HistoryAdd(
            TicketID     => $TicketID,
            HistoryType  => 'ServiceUpdate',
            Name         => "\%\%$HistoryService\%\%$HistoryServiceID\%\%NULL\%\%",
            CreateUserID => $Param{UserID},
        );

        # history insert for SLA
        my $HistorySLA   = $Param{SLA}   || 'NULL';
        my $HistorySLAID = $Param{SLAID} || '';
        $Self->HistoryAdd(
            TicketID     => $TicketID,
            HistoryType  => 'SLAUpdate',
            Name         => "\%\%$HistorySLA\%\%$HistorySLAID\%\%NULL\%\%",
            CreateUserID => $Param{UserID},
        );
    }

    if ( $Kernel::OM->Get('Kernel::Config')->Get('Ticket::Type') ) {

        # Insert history record for ticket type, so that initial value can be seen.
        #   Please see bug#12702 for more information.
        $Self->HistoryAdd(
            TicketID     => $TicketID,
            HistoryType  => 'TypeUpdate',
            Name         => "\%\%$Param{Type}\%\%$Param{TypeID}",
            CreateUserID => $Param{UserID},
        );
    }

    # set customer data if given
    if ( $Param{CustomerNo} || $Param{CustomerID} || $Param{CustomerUser} ) {
        $Self->TicketCustomerSet(
            TicketID => $TicketID,
            No       => $Param{CustomerNo} || $Param{CustomerID} || '',
            User     => $Param{CustomerUser} || '',
            UserID   => $Param{UserID},
        );
    }

    # update ticket view index
    $Self->TicketAcceleratorAdd( TicketID => $TicketID );

    # log ticket creation
    $Kernel::OM->Get('Kernel::System::Log')->Log(
        Priority => 'info',
        Message  => "New Ticket [$Param{TN}/" . substr( $Param{Title}, 0, 15 ) . "] created "
            . "(TicketID=$TicketID,Queue=$Param{Queue},Priority=$Param{Priority},State=$Param{State})",
    );

    # trigger event
    $Self->EventHandler(
        Event => 'TicketCreate',
        Data  => {
            TicketID => $TicketID,
        },
        UserID => $Param{UserID},
    );

    return $TicketID;
}

=head2 TicketDelete()

deletes a ticket with articles from storage

    my $Success = $TicketObject->TicketDelete(
        TicketID => 123,
        UserID   => 123,
    );

Events:
    TicketDelete

=cut

sub TicketDelete {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(TicketID UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    # Delete dynamic field values for this ticket.
    $Kernel::OM->Get('Kernel::System::DynamicFieldValue')->ObjectValuesDelete(
        ObjectType => 'Ticket',
        ObjectID   => $Param{TicketID},
        UserID     => $Param{UserID},
    );

    # clear ticket cache
    $Self->_TicketCacheClear( TicketID => $Param{TicketID} );

    # delete ticket links
    $Kernel::OM->Get('Kernel::System::LinkObject')->LinkDeleteAll(
        Object => 'Ticket',
        Key    => $Param{TicketID},
        UserID => $Param{UserID},
    );

    # update ticket index
    return if !$Self->TicketAcceleratorDelete(%Param);

    my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');

    # delete ticket entries from article search index.
    return if !$ArticleObject->ArticleSearchIndexDelete(
        TicketID => $Param{TicketID},
        UserID   => $Param{UserID},
    );

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # remove ticket watcher
    return if !$DBObject->Do(
        SQL  => 'DELETE FROM ticket_watcher WHERE ticket_id = ?',
        Bind => [ \$Param{TicketID} ],
    );

    # delete ticket flags
    return if !$DBObject->Do(
        SQL  => 'DELETE FROM ticket_flag WHERE ticket_id = ?',
        Bind => [ \$Param{TicketID} ],
    );

    # delete ticket flag cache
    $Kernel::OM->Get('Kernel::System::Cache')->Delete(
        Type => $Self->{CacheType},
        Key  => 'TicketFlag::' . $Param{TicketID},
    );

    # Delete calendar appointments linked to this ticket.
    #   Please see bug#13642 for more information.
    return if !$Kernel::OM->Get('Kernel::System::Calendar')->TicketAppointmentDelete(
        TicketID => $Param{TicketID},
    );

    # delete ticket_history
    return if !$Self->HistoryDelete(
        TicketID => $Param{TicketID},
        UserID   => $Param{UserID},
    );

    # Delete all articles and associated data.
    my @Articles = $ArticleObject->ArticleList( TicketID => $Param{TicketID} );
    for my $MetaArticle (@Articles) {
        return if !$ArticleObject->BackendForArticle( %{$MetaArticle} )->ArticleDelete(
            ArticleID => $MetaArticle->{ArticleID},
            %Param,
        );
    }

    # delete ticket
    return if !$DBObject->Do(
        SQL  => 'DELETE FROM ticket WHERE id = ?',
        Bind => [ \$Param{TicketID} ],
    );

    # trigger event
    $Self->EventHandler(
        Event => 'TicketDelete',
        Data  => {
            TicketID => $Param{TicketID},
        },
        UserID => $Param{UserID},
    );

    # Clear ticket cache again, in case it was rebuilt in the meantime.
    $Self->_TicketCacheClear( TicketID => $Param{TicketID} );

    return 1;
}

=head2 TicketIDLookup()

ticket id lookup by ticket number

    my $TicketID = $TicketObject->TicketIDLookup(
        TicketNumber => '2004040510440485',
    );

=cut

sub TicketIDLookup {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{TicketNumber} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need TicketNumber!'
        );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # db query
    return if !$DBObject->Prepare(
        SQL   => 'SELECT id FROM ticket WHERE tn = ?',
        Bind  => [ \$Param{TicketNumber} ],
        Limit => 1,
    );

    my $ID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ID = $Row[0];
    }

    return $ID;
}

=head2 TicketNumberLookup()

ticket number lookup by ticket id

    my $TicketNumber = $TicketObject->TicketNumberLookup(
        TicketID => 123,
    );

=cut

sub TicketNumberLookup {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{TicketID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need TicketID!',
        );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # db query
    return if !$DBObject->Prepare(
        SQL   => 'SELECT tn FROM ticket WHERE id = ?',
        Bind  => [ \$Param{TicketID} ],
        Limit => 1,
    );

    my $Number;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Number = $Row[0];
    }

    return $Number;
}

=head2 TicketSubjectBuild()

rebuild a new ticket subject

This will generate a subject like C<RE: [Ticket# 2004040510440485] Some subject>

    my $NewSubject = $TicketObject->TicketSubjectBuild(
        TicketNumber => '2004040510440485',
        Subject      => $OldSubject,
        Action       => 'Reply',
    );

This will generate a subject like C<[Ticket# 2004040510440485] Some subject>
(so without RE: )

    my $NewSubject = $TicketObject->TicketSubjectBuild(
        TicketNumber => '2004040510440485',
        Subject      => $OldSubject,
        Type         => 'New',
        Action       => 'Reply',
    );

This will generate a subject like C<FWD: [Ticket# 2004040510440485] Some subject>

    my $NewSubject = $TicketObject->TicketSubjectBuild(
        TicketNumber => '2004040510440485',
        Subject      => $OldSubject,
        Action       => 'Forward', # Possible values are Reply and Forward, Reply is default.
    );

This will generate a subject like C<[Ticket# 2004040510440485] Re: Some subject>
(so without clean-up of subject)

    my $NewSubject = $TicketObject->TicketSubjectBuild(
        TicketNumber => '2004040510440485',
        Subject      => $OldSubject,
        Type         => 'New',
        NoCleanup    => 1,
    );

=cut

sub TicketSubjectBuild {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !defined $Param{TicketNumber} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Need TicketNumber!"
        );
        return;
    }
    my $Subject = $Param{Subject} || '';
    my $Action  = $Param{Action}  || 'Reply';

    # cleanup of subject, remove existing ticket numbers and reply indentifier
    if ( !$Param{NoCleanup} ) {
        $Subject = $Self->TicketSubjectClean(%Param);
    }

    # get config object
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # get config options
    my $TicketHook          = $ConfigObject->Get('Ticket::Hook');
    my $TicketHookDivider   = $ConfigObject->Get('Ticket::HookDivider');
    my $TicketSubjectRe     = $ConfigObject->Get('Ticket::SubjectRe');
    my $TicketSubjectFwd    = $ConfigObject->Get('Ticket::SubjectFwd');
    my $TicketSubjectFormat = $ConfigObject->Get('Ticket::SubjectFormat') || 'Left';

    # return subject for new tickets
    if ( $Param{Type} && $Param{Type} eq 'New' ) {
        if ( lc $TicketSubjectFormat eq 'right' ) {
            return $Subject . " [$TicketHook$TicketHookDivider$Param{TicketNumber}]";
        }
        if ( lc $TicketSubjectFormat eq 'none' ) {
            return $Subject;
        }
        return "[$TicketHook$TicketHookDivider$Param{TicketNumber}] " . $Subject;
    }

    # return subject for existing tickets
    if ( $Action eq 'Forward' ) {
        if ($TicketSubjectFwd) {
            $TicketSubjectFwd .= ': ';
        }
        if ( lc $TicketSubjectFormat eq 'right' ) {
            return $TicketSubjectFwd . $Subject
                . " [$TicketHook$TicketHookDivider$Param{TicketNumber}]";
        }
        if ( lc $TicketSubjectFormat eq 'none' ) {
            return $TicketSubjectFwd . $Subject;
        }
        return
            $TicketSubjectFwd
            . "[$TicketHook$TicketHookDivider$Param{TicketNumber}] "
            . $Subject;
    }
    else {
        if ($TicketSubjectRe) {
            $TicketSubjectRe .= ': ';
        }
        if ( lc $TicketSubjectFormat eq 'right' ) {
            return $TicketSubjectRe . $Subject
                . " [$TicketHook$TicketHookDivider$Param{TicketNumber}]";
        }
        if ( lc $TicketSubjectFormat eq 'none' ) {
            return $TicketSubjectRe . $Subject;
        }
        return $TicketSubjectRe . "[$TicketHook$TicketHookDivider$Param{TicketNumber}] " . $Subject;
    }
}

=head2 TicketSubjectClean()

strip/clean up a ticket subject

    my $NewSubject = $TicketObject->TicketSubjectClean(
        TicketNumber => '2004040510440485',
        Subject      => $OldSubject,
        Size         => $SubjectSizeToBeDisplayed   # optional, if 0 do not cut subject
    );

=cut

sub TicketSubjectClean {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !defined $Param{TicketNumber} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Need TicketNumber!"
        );
        return;
    }

    my $Subject = $Param{Subject} || '';

    # get config object
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # get config options
    my $TicketHook        = $ConfigObject->Get('Ticket::Hook');
    my $TicketHookDivider = $ConfigObject->Get('Ticket::HookDivider');
    my $TicketSubjectSize = $Param{Size};
    if ( !defined $TicketSubjectSize ) {
        $TicketSubjectSize = $ConfigObject->Get('Ticket::SubjectSize')
            || 120;
    }
    my $TicketSubjectRe  = $ConfigObject->Get('Ticket::SubjectRe');
    my $TicketSubjectFwd = $ConfigObject->Get('Ticket::SubjectFwd');

    # remove all possible ticket hook formats with []
    $Subject =~ s/\[\s*\Q$TicketHook: $Param{TicketNumber}\E\s*\]\s*//g;
    $Subject =~ s/\[\s*\Q$TicketHook:$Param{TicketNumber}\E\s*\]\s*//g;
    $Subject =~ s/\[\s*\Q$TicketHook$TicketHookDivider$Param{TicketNumber}\E\s*\]\s*//g;

    # remove all ticket numbers with []
    if ( $ConfigObject->Get('Ticket::SubjectCleanAllNumbers') ) {
        $Subject =~ s/\[\s*\Q$TicketHook$TicketHookDivider\E\d+?\s*\]\s*//g;
    }

    # remove all possible ticket hook formats without []
    $Subject =~ s/\Q$TicketHook: $Param{TicketNumber}\E\s*//g;
    $Subject =~ s/\Q$TicketHook:$Param{TicketNumber}\E\s*//g;
    $Subject =~ s/\Q$TicketHook$TicketHookDivider$Param{TicketNumber}\E\s*//g;

    # remove all ticket numbers without []
    if ( $ConfigObject->Get('Ticket::SubjectCleanAllNumbers') ) {
        $Subject =~ s/\Q$TicketHook$TicketHookDivider\E\d+?\s*//g;
    }

    # remove leading number with configured "RE:\s" or "RE[\d+]:\s" e. g. "RE: " or "RE[4]: "
    $Subject =~ s/^($TicketSubjectRe(\[\d+\])?:\s)+//i;

    # remove leading number with configured "Fwd:\s" or "Fwd[\d+]:\s" e. g. "Fwd: " or "Fwd[4]: "
    $Subject =~ s/^($TicketSubjectFwd(\[\d+\])?:\s)+//i;

    # trim white space at the beginning or end
    $Subject =~ s/(^\s+|\s+$)//;

    # resize subject based on config
    # do not cut subject, if size parameter was 0
    if ($TicketSubjectSize) {
        $Subject =~ s/^(.{$TicketSubjectSize}).*$/$1 [...]/;
    }

    return $Subject;
}

=head2 TicketGet()

Get ticket info

    my %Ticket = $TicketObject->TicketGet(
        TicketID      => 123,
        DynamicFields => 0,         # Optional, default 0. To include the dynamic field values for this ticket on the return structure.
        UserID        => 123,
        Silent        => 0,         # Optional, default 0. To suppress the warning if the ticket does not exist.
    );

Returns:

    %Ticket = (
        TicketNumber       => '20101027000001',
        Title              => 'some title',
        TicketID           => 123,
        State              => 'some state',
        StateID            => 123,
        StateType          => 'some state type',
        Priority           => 'some priority',
        PriorityID         => 123,
        Lock               => 'lock',
        LockID             => 123,
        Queue              => 'some queue',
        QueueID            => 123,
        CustomerID         => 'customer_id_123',
        CustomerUserID     => 'customer_user_id_123',
        Owner              => 'some_owner_login',
        OwnerID            => 123,
        Type               => 'some ticket type',
        TypeID             => 123,
        SLA                => 'some sla',
        SLAID              => 123,
        Service            => 'some service',
        ServiceID          => 123,
        Responsible        => 'some_responsible_login',
        ResponsibleID      => 123,
        Age                => 3456,
        Created            => '2010-10-27 20:15:00'
        CreateBy           => 123,
        Changed            => '2010-10-27 20:15:15',
        ChangeBy           => 123,
        ArchiveFlag        => 'y',

        # If DynamicFields => 1 was passed, you'll get an entry like this for each dynamic field:
        DynamicField_X     => 'value_x',

        # (time stamps of expected escalations)
        EscalationResponseTime           (unix time stamp of response time escalation)
        EscalationUpdateTime             (unix time stamp of update time escalation)
        EscalationSolutionTime           (unix time stamp of solution time escalation)

        # (general escalation info of nearest escalation type)
        EscalationDestinationIn          (escalation in e. g. 1h 4m)
        EscalationDestinationTime        (date of escalation in unix time, e. g. 72193292)
        EscalationDestinationDate        (date of escalation, e. g. "2009-02-14 18:00:00")
        EscalationTimeWorkingTime        (seconds of working/service time till escalation, e. g. "1800")
        EscalationTime                   (seconds total till escalation of nearest escalation time type - response, update or solution time, e. g. "3600")

        # (detailed escalation info about first response, update and solution time)
        FirstResponseTimeEscalation      (if true, ticket is escalated)
        FirstResponseTimeNotification    (if true, notify - x% of escalation has reached)
        FirstResponseTimeDestinationTime (date of escalation in unix time, e. g. 72193292)
        FirstResponseTimeDestinationDate (date of escalation, e. g. "2009-02-14 18:00:00")
        FirstResponseTimeWorkingTime     (seconds of working/service time till escalation, e. g. "1800")
        FirstResponseTime                (seconds total till escalation, e. g. "3600")

        UpdateTimeEscalation             (if true, ticket is escalated)
        UpdateTimeNotification           (if true, notify - x% of escalation has reached)
        UpdateTimeDestinationTime        (date of escalation in unix time, e. g. 72193292)
        UpdateTimeDestinationDate        (date of escalation, e. g. "2009-02-14 18:00:00")
        UpdateTimeWorkingTime            (seconds of working/service time till escalation, e. g. "1800")
        UpdateTime                       (seconds total till escalation, e. g. "3600")

        SolutionTimeEscalation           (if true, ticket is escalated)
        SolutionTimeNotification         (if true, notify - x% of escalation has reached)
        SolutionTimeDestinationTime      (date of escalation in unix time, e. g. 72193292)
        SolutionTimeDestinationDate      (date of escalation, e. g. "2009-02-14 18:00:00")
        SolutionTimeWorkingTime          (seconds of working/service time till escalation, e. g. "1800")
        SolutionTime                     (seconds total till escalation, e. g. "3600")
    );

To get extended ticket attributes, use C<Extended>

    my %Ticket = $TicketObject->TicketGet(
        TicketID => 123,
        UserID   => 123,
        Extended => 1,
    );

Additional parameters are:

    %Ticket = (
        FirstResponse                   (timestamp of first response, first contact with customer)
        FirstResponseInMin              (minutes till first response)
        FirstResponseDiffInMin          (minutes till or over first response)

        SolutionInMin                   (minutes till solution time)
        SolutionDiffInMin               (minutes till or over solution time)

        FirstLock                       (timestamp of first lock)
    );

=cut

sub TicketGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{TicketID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need TicketID!'
        );
        return;
    }
    $Param{Extended} = $Param{Extended} ? 1 : 0;

    # Caching TicketGet() is a bit more complex than usual.
    #   The full function result will be cached in an in-memory cache to
    #       speed up subsequent operations in one request, but not on disk,
    #       because there are dependencies to other objects such as queue which cannot
    #       easily be tracked.
    #   The SQL for fetching ticket data will be cached on disk as well because this cache
    #       can easily be invalidated on ticket changes.

    # check cache
    my $FetchDynamicFields = $Param{DynamicFields} ? 1 : 0;

    my $CacheKey = 'Cache::GetTicket' . $Param{TicketID};
    my $CacheKeyDynamicFields
        = 'Cache::GetTicket' . $Param{TicketID} . '::' . $Param{Extended} . '::' . $FetchDynamicFields;

    my $CachedDynamicFields = $Kernel::OM->Get('Kernel::System::Cache')->Get(
        Type           => $Self->{CacheType},
        Key            => $CacheKeyDynamicFields,
        CacheInMemory  => 1,
        CacheInBackend => 0,
    );

    # check if result is cached
    if ( ref $CachedDynamicFields eq 'HASH' ) {
        return %{$CachedDynamicFields};
    }

    my %Ticket;

    my $Cached = $Kernel::OM->Get('Kernel::System::Cache')->Get(
        Type => $Self->{CacheType},
        Key  => $CacheKey,
    );

    if ( ref $Cached eq 'HASH' ) {
        %Ticket = %{$Cached};
    }
    else {

        # get database object
        my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

        return if !$DBObject->Prepare(
            SQL => '
                SELECT st.id, st.queue_id, st.ticket_state_id, st.ticket_lock_id, st.ticket_priority_id,
                    st.create_time, st.create_time, st.tn, st.customer_id, st.customer_user_id,
                    st.user_id, st.responsible_user_id, st.until_time, st.change_time, st.title,
                    st.escalation_update_time, st.timeout, st.type_id, st.service_id, st.sla_id,
                    st.escalation_response_time, st.escalation_solution_time, st.escalation_time, st.archive_flag,
                    st.create_by, st.change_by
                FROM ticket st
                WHERE st.id = ?',
            Bind  => [ \$Param{TicketID} ],
            Limit => 1,
        );

        while ( my @Row = $DBObject->FetchrowArray() ) {
            $Ticket{TicketID}   = $Row[0];
            $Ticket{QueueID}    = $Row[1];
            $Ticket{StateID}    = $Row[2];
            $Ticket{LockID}     = $Row[3];
            $Ticket{PriorityID} = $Row[4];

            $Ticket{Created}        = $Row[5];
            $Ticket{TicketNumber}   = $Row[7];
            $Ticket{CustomerID}     = $Row[8];
            $Ticket{CustomerUserID} = $Row[9];

            $Ticket{OwnerID}             = $Row[10];
            $Ticket{ResponsibleID}       = $Row[11] || 1;
            $Ticket{RealTillTimeNotUsed} = $Row[12];
            $Ticket{Changed}             = $Row[13];
            $Ticket{Title}               = $Row[14];

            $Ticket{EscalationUpdateTime} = $Row[15];
            $Ticket{UnlockTimeout}        = $Row[16];
            $Ticket{TypeID}               = $Row[17] || 1;
            $Ticket{ServiceID}            = $Row[18] || '';
            $Ticket{SLAID}                = $Row[19] || '';

            $Ticket{EscalationResponseTime} = $Row[20];
            $Ticket{EscalationSolutionTime} = $Row[21];
            $Ticket{EscalationTime}         = $Row[22];
            $Ticket{ArchiveFlag}            = $Row[23] ? 'y' : 'n';

            $Ticket{CreateBy} = $Row[24];
            $Ticket{ChangeBy} = $Row[25];
        }

        # use cache only when a ticket number is found otherwise a non-existant ticket
        # is cached. That can cause errors when the cache isn't expired and postmaster
        # creates that ticket
        if ( $Ticket{TicketID} ) {
            $Kernel::OM->Get('Kernel::System::Cache')->Set(
                Type => $Self->{CacheType},
                TTL  => $Self->{CacheTTL},
                Key  => $CacheKey,

                # make a local copy of the ticket data to avoid it being altered in-memory later
                Value => {%Ticket},
            );
        }
    }

    # check ticket
    if ( !$Ticket{TicketID} ) {
        if ( !$Param{Silent} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "No such TicketID ($Param{TicketID})!",
            );
        }
        return;
    }

    # check if need to return DynamicFields
    if ($FetchDynamicFields) {

        # get dynamic field objects
        my $DynamicFieldObject        = $Kernel::OM->Get('Kernel::System::DynamicField');
        my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

        # get all dynamic fields for the object type Ticket
        my $DynamicFieldList = $DynamicFieldObject->DynamicFieldListGet(
            ObjectType => 'Ticket'
        );

        DYNAMICFIELD:
        for my $DynamicFieldConfig ( @{$DynamicFieldList} ) {

            # validate each dynamic field
            next DYNAMICFIELD if !$DynamicFieldConfig;
            next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);
            next DYNAMICFIELD if !$DynamicFieldConfig->{Name};

            # get the current value for each dynamic field
            my $Value = $DynamicFieldBackendObject->ValueGet(
                DynamicFieldConfig => $DynamicFieldConfig,
                ObjectID           => $Ticket{TicketID},
            );

            # set the dynamic field name and value into the ticket hash
            $Ticket{ 'DynamicField_' . $DynamicFieldConfig->{Name} } = $Value;
        }
    }

    my %Queue = $Kernel::OM->Get('Kernel::System::Queue')->QueueGet(
        ID => $Ticket{QueueID},
    );

    $Ticket{Queue}   = $Queue{Name};
    $Ticket{GroupID} = $Queue{GroupID};

    # fillup runtime values
    my $TicketCreatedDTObj = $Kernel::OM->Create(
        'Kernel::System::DateTime',
        ObjectParams => {
            String => $Ticket{Created}
        },
    );

    my $Delta = $TicketCreatedDTObj->Delta( DateTimeObject => $Kernel::OM->Create('Kernel::System::DateTime') );
    $Ticket{Age} = $Delta->{AbsoluteSeconds};

    $Ticket{Priority} = $Kernel::OM->Get('Kernel::System::Priority')->PriorityLookup(
        PriorityID => $Ticket{PriorityID},
    );

    # get user object
    my $UserObject = $Kernel::OM->Get('Kernel::System::User');

    # get owner
    $Ticket{Owner} = $UserObject->UserLookup(
        UserID => $Ticket{OwnerID},
    );

    # get responsible
    $Ticket{Responsible} = $UserObject->UserLookup(
        UserID => $Ticket{ResponsibleID},
    );

    # get lock
    $Ticket{Lock} = $Kernel::OM->Get('Kernel::System::Lock')->LockLookup(
        LockID => $Ticket{LockID},
    );

    # get type
    $Ticket{Type} = $Kernel::OM->Get('Kernel::System::Type')->TypeLookup( TypeID => $Ticket{TypeID} );

    # get service
    if ( $Ticket{ServiceID} ) {

        $Ticket{Service} = $Kernel::OM->Get('Kernel::System::Service')->ServiceLookup(
            ServiceID => $Ticket{ServiceID},
        );
    }

    # get sla
    if ( $Ticket{SLAID} ) {
        $Ticket{SLA} = $Kernel::OM->Get('Kernel::System::SLA')->SLALookup(
            SLAID => $Ticket{SLAID},
        );
    }

    # get state info
    my %StateData = $Kernel::OM->Get('Kernel::System::State')->StateGet(
        ID => $Ticket{StateID}
    );

    $Ticket{StateType} = $StateData{TypeName};
    $Ticket{State}     = $StateData{Name};

    if ( !$Ticket{RealTillTimeNotUsed} || lc $StateData{TypeName} eq 'pending' ) {
        $Ticket{UntilTime} = 0;
    }
    else {
        $Ticket{UntilTime} = $Ticket{RealTillTimeNotUsed} - $Kernel::OM->Create('Kernel::System::DateTime')->ToEpoch();
    }

    # get escalation attributes
    my %Escalation = $Self->TicketEscalationDateCalculation(
        Ticket => \%Ticket,
        UserID => $Param{UserID} || 1,
    );

    for my $Key ( sort keys %Escalation ) {
        $Ticket{$Key} = $Escalation{$Key};
    }

    # do extended lookups
    if ( $Param{Extended} ) {
        my %TicketExtended = $Self->_TicketGetExtended(
            TicketID => $Param{TicketID},
            Ticket   => \%Ticket,
        );
        for my $Key ( sort keys %TicketExtended ) {
            $Ticket{$Key} = $TicketExtended{$Key};
        }
    }

    # cache user result
    $Kernel::OM->Get('Kernel::System::Cache')->Set(
        Type => $Self->{CacheType},
        TTL  => $Self->{CacheTTL},
        Key  => $CacheKeyDynamicFields,

        # make a local copy of the ticket data to avoid it being altered in-memory later
        Value          => {%Ticket},
        CacheInMemory  => 1,
        CacheInBackend => 0,
    );

    return %Ticket;
}

=head2 TicketDeepGet()

Returns ticket data with all resolved dependent data like (customer) user data, etc.
It also contains all articles and a separate hash of the requested article by parameter.

    my %Ticket = $TicketObject->TicketDeepGet(
        TicketID  => 123,
        ArticleID => 123, # optional
        UserID    => 53,

        # Also fetch all attachments for all articles of the given ticket.
        GetAllArticleAttachments => 1, # defaults to 0
    );

Returns:

    my %Ticket = (
        # ticket attributes

        %Ticket,
        Articles        => [
            # ...
        ],
        CustomerUser    => {
            # ...
        },
        CustomerCompany => {
            # ...
        },
        QueueData       => {
            # ...
        },
        TypeData        => {
            # ...
        },
        PriorityData    => {
            # ...
        },
        ServiceData     => {
            # ...
        },
        SLAData         => {
            # ...
        },
        OwnerData       => {
            # ...
        },
        ResponsibleData => {
            # ...
        },
        CreateByData    => {
            # ...
        },
        Article         => {
            # ...
        },
    );

=cut

sub TicketDeepGet {
    my ( $Self, %Param ) = @_;

    my $ArticleObject         = $Kernel::OM->Get('Kernel::System::Ticket::Article');
    my $CustomerCompanyObject = $Kernel::OM->Get('Kernel::System::CustomerCompany');
    my $CustomerUserObject    = $Kernel::OM->Get('Kernel::System::CustomerUser');
    my $QueueObject           = $Kernel::OM->Get('Kernel::System::Queue');
    my $ServiceObject         = $Kernel::OM->Get('Kernel::System::Service');
    my $SLAObject             = $Kernel::OM->Get('Kernel::System::SLA');
    my $TypeObject            = $Kernel::OM->Get('Kernel::System::Type');
    my $UserObject            = $Kernel::OM->Get('Kernel::System::User');
    my $PriorityObject        = $Kernel::OM->Get('Kernel::System::Priority');
    my $LogObject             = $Kernel::OM->Get('Kernel::System::Log');

    NEEDED:
    for my $Needed (qw(TicketID UserID)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter $Needed is needed.",
        );
        return;
    }

    my %Ticket = $Self->TicketGet(
        TicketID      => $Param{TicketID},
        DynamicFields => 1,
        Extended      => 1,
        UserID        => $Param{UserID},
    );
    return if !%Ticket;

    my %Data = %Ticket;

    my @Articles = $ArticleObject->ArticleList(
        TicketID => $Param{TicketID},
    );

    $Data{Articles} = [];
    for my $ArticleMeta (@Articles) {
        my %Article = $ArticleObject->ArticleGet(
            %{$ArticleMeta},
            DynamicFields => 1,
            RealNames     => 1,
        );

        if ( $Param{GetAllArticleAttachments} ) {
            my $ArticleAttachments = $Self->_GetBase64EncodedArticleAttachments(
                TicketID  => $Param{TicketID},
                ArticleID => $ArticleMeta->{ArticleID},
            );

            if ( IsArrayRefWithData($ArticleAttachments) ) {
                $Article{Attachment} = $ArticleAttachments;
            }
        }

        push @{ $Data{Articles} }, $Self->_TicketDeepGetDataCleanUp(
            Data => \%Article,
        );
    }

    $Data{CustomerUser} = {};
    if ( $Ticket{CustomerUserID} ) {
        my %CustomerUser = $CustomerUserObject->CustomerUserDataGet(
            User => $Ticket{CustomerUserID},
        );

        $Data{CustomerUser} = $Self->_TicketDeepGetDataCleanUp(
            Data => \%CustomerUser,
        );
    }

    $Data{CustomerCompany} = {};
    if ( $Ticket{CustomerID} ) {
        my %CustomerCompany = $CustomerCompanyObject->CustomerCompanyGet(
            CustomerID => $Ticket{CustomerID},
        );

        $Data{CustomerCompany} = $Self->_TicketDeepGetDataCleanUp(
            Data => \%CustomerCompany,
        );
    }

    $Data{QueueData} = {};
    if ( $Ticket{QueueID} ) {
        my %Queue = $QueueObject->QueueGet(
            ID => $Ticket{QueueID},
        );

        $Data{QueueData} = $Self->_TicketDeepGetDataCleanUp(
            Data => \%Queue,
        );
    }

    $Data{TypeData} = {};
    if ( $Ticket{TypeID} ) {
        my %TypeData = $TypeObject->TypeGet(
            ID => $Ticket{TypeID},
        );

        $Data{TypeData} = $Self->_TicketDeepGetDataCleanUp(
            Data => \%TypeData,
        );
    }

    $Data{PriorityData} = {};
    if ( $Ticket{PriorityID} ) {
        my %PriorityData = $PriorityObject->PriorityGet(
            PriorityID => $Ticket{PriorityID},
            UserID     => 1,
        );

        $Data{PriorityData} = $Self->_TicketDeepGetDataCleanUp(
            Data => \%PriorityData,
        );
    }

    $Data{ServiceData} = {};
    if ( $Ticket{ServiceID} ) {
        my %ServiceData = $ServiceObject->ServiceGet(
            ServiceID => $Ticket{ServiceID},
            UserID    => 1,
        );

        $Data{ServiceData} = $Self->_TicketDeepGetDataCleanUp(
            Data => \%ServiceData,
        );
    }

    $Data{SLAData} = {};
    if ( $Ticket{SLAID} ) {
        my %SLAData = $SLAObject->SLAGet(
            SLAID  => $Ticket{SLAID},
            UserID => 1,
        );

        $Data{SLAData} = $Self->_TicketDeepGetDataCleanUp(
            Data => \%SLAData,
        );
    }

    $Data{OwnerData} = {};
    if ( $Ticket{OwnerID} ) {
        my %Owner = $UserObject->GetUserData(
            UserID => $Ticket{OwnerID},
        );

        $Data{OwnerData} = $Self->_TicketDeepGetDataCleanUp(
            Data => \%Owner,
        );
    }

    $Data{ResponsibleData} = {};
    if ( $Ticket{ResponsibleID} ) {
        my %Responsible = $UserObject->GetUserData(
            UserID => $Ticket{ResponsibleID},
        );

        $Data{ResponsibleData} = $Self->_TicketDeepGetDataCleanUp(
            Data => \%Responsible,
        );
    }

    $Data{CreateByData} = {};
    if ( $Ticket{CreateBy} ) {
        my %CreateBy = $UserObject->GetUserData(
            UserID => $Ticket{CreateBy},
        );

        $Data{CreateByData} = $Self->_TicketDeepGetDataCleanUp(
            Data => \%CreateBy,
        );
    }

    $Data{Article} = {};
    return %Data if !IsArrayRefWithData( $Data{Articles} );

    # If there is only one article, return its data, regardless
    # if an article ID has been given or if the given ID is valid.
    if ( @{ $Data{Articles} } == 1 ) {
        $Param{ArticleID} = $Data{Articles}->[0]->{ArticleID};
    }

    return %Data if !$Param{ArticleID};

    @Articles = grep { $_->{ArticleID} == $Param{ArticleID} } @{ $Data{Articles} };
    return %Data if @Articles != 1;

    # %{} to prevent showing perl references in web service debug log.
    %{ $Data{Article} } = %{ $Articles[0] };

    my $ArticleAttachments = $Self->_GetBase64EncodedArticleAttachments(
        TicketID  => $Param{TicketID},
        ArticleID => $Param{ArticleID},
    );
    return %Data if !IsArrayRefWithData($ArticleAttachments);

    $Data{Article}->{Attachment} = $ArticleAttachments;

    return %Data;
}

=head2 _GetBase64EncodedArticleAttachments()

Returns all attachments of the the article with the given ID (base-64 encoded).

    my $Attachments = $Znuny4OTRSAdvancedGIObject->_GetBase64EncodedArticleAttachments(
        TicketID  => 123,
        ArticleID => 123,
    );

Returns:

    my $Attachments = [
        {
            Content            => '...', # base-64 encoded
            ContentAlternative => '',
            ContentID          => '',
            ContentType        => 'application/pdf',
            Filename           => 'StdAttachment-Test1.pdf',
            FilesizeRaw        => 4722,
            Disposition        => 'attachment',
            FileID             => 2,
        },

        # ...
    ];

=cut

sub _GetBase64EncodedArticleAttachments {
    my ( $Self, %Param ) = @_;

    my $LogObject     = $Kernel::OM->Get('Kernel::System::Log');
    my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');

    NEEDED:
    for my $Needed (qw( TicketID ArticleID )) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my %AttachmentIndex = $ArticleObject->ArticleAttachmentIndex(
        TicketID         => $Param{TicketID},
        ArticleID        => $Param{ArticleID},
        ExcludePlainText => 0,                   # (optional) Exclude plain text attachment
        ExcludeHTMLBody  => 0,                   # (optional) Exclude HTML body attachment
        ExcludeInline    => 0,                   # (optional) Exclude inline attachments
    );
    return [] if !%AttachmentIndex;

    my @Attachments;
    ATTACHMENT:
    for my $FileID ( sort keys %AttachmentIndex ) {
        next ATTACHMENT if !$FileID;

        my %Attachment = $ArticleObject->ArticleAttachment(
            TicketID  => $Param{TicketID},
            ArticleID => $Param{ArticleID},
            FileID    => $FileID,
        );
        next ATTACHMENT if !%Attachment;

        $Attachment{FileID}  = $FileID;
        $Attachment{Content} = encode_base64( $Attachment{Content}, '' );

        push @Attachments, \%Attachment;
    }

    return \@Attachments;
}

=head2 _TicketDeepGetDataCleanUp()

Cleans up the given hash by removing possible given passwords, tokens, etc.

    my $CleanedUpData = $TicketObject->_TicketDeepGetDataCleanUp(
        Data => {
            Test   => 'ok',
            config => 'removed',
            secret => 'removed',
            passw  => 'removed',
            userpw => 'removed',
            auth   => 'removed',
            token  => 'removed',
            Field  => 'ok',
        }
    );

Returns:

    my $CleanedUpData = {
        Test  => 'ok',
        Field => 'ok',
    };

=cut

sub _TicketDeepGetDataCleanUp {
    my ( $Self, %Param ) = @_;

    return $Param{Data} if !IsHashRefWithData( $Param{Data} );

    KEY:
    for my $Key ( sort keys %{ $Param{Data} } ) {
        next KEY if $Key !~ m{\:\:|config|secret|passw|userpw|auth|token}i;

        delete $Param{Data}->{$Key};
    }

    return $Param{Data};
}

=head2 TicketTitleUpdate()

update ticket title

    my $Success = $TicketObject->TicketTitleUpdate(
        Title    => 'Some Title',
        TicketID => 123,
        UserID   => 1,
    );

Events:
    TicketTitleUpdate

=cut

sub TicketTitleUpdate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Title TicketID UserID)) {
        if ( !defined $Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    # check if update is needed
    my %Ticket = $Self->TicketGet(
        TicketID      => $Param{TicketID},
        UserID        => $Param{UserID},
        DynamicFields => 0,
    );

    return 1 if defined $Ticket{Title} && $Ticket{Title} eq $Param{Title};

    # db access
    return if !$Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL => 'UPDATE ticket SET title = ?, change_time = current_timestamp, '
            . ' change_by = ? WHERE id = ?',
        Bind => [ \$Param{Title}, \$Param{UserID}, \$Param{TicketID} ],
    );

    # clear ticket cache
    $Self->_TicketCacheClear( TicketID => $Param{TicketID} );

    # truncate title
    my $Title = substr( $Param{Title}, 0, 50 );
    $Title .= '...' if length($Title) == 50;

    # history insert
    $Self->HistoryAdd(
        TicketID     => $Param{TicketID},
        HistoryType  => 'TitleUpdate',
        Name         => "\%\%$Ticket{Title}\%\%$Title",
        CreateUserID => $Param{UserID},
    );

    # trigger event
    $Self->EventHandler(
        Event => 'TicketTitleUpdate',
        Data  => {
            TicketID => $Param{TicketID},
        },
        UserID => $Param{UserID},
    );

    return 1;
}

=head2 TicketUnlockTimeoutUpdate()

set the ticket unlock time to the passed time

    my $Success = $TicketObject->TicketUnlockTimeoutUpdate(
        UnlockTimeout => $Epoch,
        TicketID      => 123,
        UserID        => 143,
    );

Events:
    TicketUnlockTimeoutUpdate

=cut

sub TicketUnlockTimeoutUpdate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(UnlockTimeout TicketID UserID)) {
        if ( !defined $Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    # check if update is needed
    my %Ticket = $Self->TicketGet(
        %Param,
        DynamicFields => 0,
    );

    return 1 if $Ticket{UnlockTimeout} eq $Param{UnlockTimeout};

    # reset unlock time
    return if !$Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL => 'UPDATE ticket SET timeout = ?, change_time = current_timestamp, '
            . ' change_by = ? WHERE id = ?',
        Bind => [ \$Param{UnlockTimeout}, \$Param{UserID}, \$Param{TicketID} ],
    );

    # clear ticket cache
    $Self->_TicketCacheClear( TicketID => $Param{TicketID} );

    # add history
    $Self->HistoryAdd(
        TicketID     => $Param{TicketID},
        CreateUserID => $Param{UserID},
        HistoryType  => 'Misc',
        Name         => Translatable('Reset of unlock time.'),
    );

    # trigger event
    $Self->EventHandler(
        Event => 'TicketUnlockTimeoutUpdate',
        Data  => {
            TicketID => $Param{TicketID},
        },
        UserID => $Param{UserID},
    );

    return 1;
}

=head2 TicketQueueID()

get ticket queue id

    my $QueueID = $TicketObject->TicketQueueID(
        TicketID => 123,
    );

=cut

sub TicketQueueID {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{TicketID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need TicketID!'
        );
        return;
    }

    # get ticket data
    my %Ticket = $Self->TicketGet(
        TicketID      => $Param{TicketID},
        DynamicFields => 0,
        UserID        => 1,
        Silent        => 1,
    );

    return if !%Ticket;

    return $Ticket{QueueID};
}

=head2 TicketMoveList()

to get the move queue list for a ticket (depends on workflow, if configured)

    my %Queues = $TicketObject->TicketMoveList(
        Type   => 'create',
        UserID => 123,
    );

    my %Queues = $TicketObject->TicketMoveList(
        Type           => 'create',
        CustomerUserID => 'customer_user_id_123',
    );


    my %Queues = $TicketObject->TicketMoveList(
        QueueID => 123,
        UserID  => 123,
    );

    my %Queues = $TicketObject->TicketMoveList(
        TicketID => 123,
        UserID   => 123,
    );

=cut

sub TicketMoveList {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{UserID} && !$Param{CustomerUserID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need UserID or CustomerUserID!',
        );
        return;
    }

    # check needed stuff
    if ( !$Param{QueueID} && !$Param{TicketID} && !$Param{Type} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need QueueID, TicketID or Type!',
        );
        return;
    }

    # get queue object
    my $QueueObject = $Kernel::OM->Get('Kernel::System::Queue');

    my %Queues;
    if ( $Param{UserID} && $Param{UserID} eq 1 ) {
        %Queues = $QueueObject->GetAllQueues();
    }
    else {
        %Queues = $QueueObject->GetAllQueues(%Param);
    }

    # workflow
    my $ACL = $Self->TicketAcl(
        %Param,
        ReturnType    => 'Ticket',
        ReturnSubType => 'Queue',
        Data          => \%Queues,
    );
    return $Self->TicketAclData() if $ACL;
    return %Queues;
}

=head2 TicketQueueSet()

to move a ticket (sends notification to agents of selected my queues, if ticket is not closed)

    my $Success = $TicketObject->TicketQueueSet(
        QueueID  => 123,
        TicketID => 123,
        UserID   => 123,
    );

    my $Success = $TicketObject->TicketQueueSet(
        Queue    => 'Some Queue Name',
        TicketID => 123,
        UserID   => 123,
    );

    my $Success = $TicketObject->TicketQueueSet(
        Queue    => 'Some Queue Name',
        TicketID => 123,
        Comment  => 'some comment', # optional
        ForceNotificationToUserID => [1,43,56], # if you want to force somebody
        UserID   => 123,
    );

Optional attribute:
SendNoNotification disables or enables agent and customer notification for this
action.

For example:

        SendNoNotification => 0, # optional 1|0 (send no agent and customer notification)

Events:
    TicketQueueUpdate

=cut

sub TicketQueueSet {
    my ( $Self, %Param ) = @_;

    # get queue object
    my $QueueObject = $Kernel::OM->Get('Kernel::System::Queue');

    # queue lookup
    if ( $Param{Queue} && !$Param{QueueID} ) {
        $Param{QueueID} = $QueueObject->QueueLookup( Queue => $Param{Queue} );
    }

    # check needed stuff
    for my $Needed (qw(TicketID QueueID UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    # get current ticket
    my %Ticket = $Self->TicketGet(
        %Param,
        DynamicFields => 0,
    );

    # move needed?
    if ( $Param{QueueID} == $Ticket{QueueID} && !$Param{Comment} ) {

        # update not needed
        return 1;
    }

    # permission check
    my %MoveList = $Self->MoveList( %Param, Type => 'move_into' );
    if ( !$MoveList{ $Param{QueueID} } ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'notice',
            Message  => "Permission denied on TicketID: $Param{TicketID}!",
        );
        return;
    }

    return if !$Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL => 'UPDATE ticket SET queue_id = ?, change_time = current_timestamp, '
            . ' change_by = ? WHERE id = ?',
        Bind => [ \$Param{QueueID}, \$Param{UserID}, \$Param{TicketID} ],
    );

    # queue lookup
    my $Queue = $QueueObject->QueueLookup( QueueID => $Param{QueueID} );

    # clear ticket cache
    $Self->_TicketCacheClear( TicketID => $Param{TicketID} );

    # history insert
    $Self->HistoryAdd(
        TicketID     => $Param{TicketID},
        QueueID      => $Param{QueueID},
        HistoryType  => 'Move',
        Name         => "\%\%$Queue\%\%$Param{QueueID}\%\%$Ticket{Queue}\%\%$Ticket{QueueID}",
        CreateUserID => $Param{UserID},
    );

    # send move notify to queue subscriber
    if ( !$Param{SendNoNotification} && $Ticket{StateType} ne 'closed' ) {

        my @UserIDs;

        if ( $Param{ForceNotificationToUserID} ) {
            push @UserIDs, @{ $Param{ForceNotificationToUserID} };
        }

        # trigger notification event
        $Self->EventHandler(
            Event => 'NotificationMove',
            Data  => {
                TicketID              => $Param{TicketID},
                CustomerMessageParams => {
                    Queue => $Queue,
                },
                Recipients => \@UserIDs,
            },
            UserID => $Param{UserID},
        );
    }

    # trigger event, OldTicketData is needed for escalation events
    $Self->EventHandler(
        Event => 'TicketQueueUpdate',
        Data  => {
            TicketID      => $Param{TicketID},
            OldTicketData => \%Ticket,
        },
        UserID => $Param{UserID},
    );

    return 1;
}

=head2 TicketMoveQueueList()

returns a list of used queue ids / names

    my @QueueIDList = $TicketObject->TicketMoveQueueList(
        TicketID => 123,
        Type     => 'ID',
    );

Returns:

    @QueueIDList = ( 1, 2, 3 );

    my @QueueList = $TicketObject->TicketMoveQueueList(
        TicketID => 123,
        Type     => 'Name',
    );

Returns:

    @QueueList = ( 'QueueA', 'QueueB', 'QueueC' );

=cut

sub TicketMoveQueueList {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{TicketID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Need TicketID!"
        );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # db query
    return if !$DBObject->Prepare(
        SQL => 'SELECT sh.name, ht.name, sh.create_by, sh.queue_id FROM '
            . 'ticket_history sh, ticket_history_type ht WHERE '
            . 'sh.ticket_id = ? AND ht.name IN (\'Move\', \'NewTicket\') AND '
            . 'ht.id = sh.history_type_id ORDER BY sh.id',
        Bind => [ \$Param{TicketID} ],
    );

    my @QueueID;
    while ( my @Row = $DBObject->FetchrowArray() ) {

        # store result
        if ( $Row[1] eq 'NewTicket' ) {
            if ( $Row[3] ) {
                push @QueueID, $Row[3];
            }
        }
        elsif ( $Row[1] eq 'Move' ) {
            if ( $Row[0] =~ /^\%\%(.+?)\%\%(.+?)\%\%(.+?)\%\%(.+?)/ ) {
                push @QueueID, $2;
            }
            elsif ( $Row[0] =~ /^Ticket moved to Queue '.+?' \(ID=(.+?)\)/ ) {
                push @QueueID, $1;
            }
        }
    }

    # get queue object
    my $QueueObject = $Kernel::OM->Get('Kernel::System::Queue');

    # queue lookup
    my @QueueName;
    for my $QueueID (@QueueID) {

        my $Queue = $QueueObject->QueueLookup( QueueID => $QueueID );

        push @QueueName, $Queue;
    }

    if ( $Param{Type} && $Param{Type} eq 'Name' ) {
        return @QueueName;
    }
    else {
        return @QueueID;
    }
}

=head2 TicketTypeList()

to get all possible types for a ticket (depends on workflow, if configured)

    my %Types = $TicketObject->TicketTypeList(
        UserID => 123,
    );

    my %Types = $TicketObject->TicketTypeList(
        CustomerUserID => 'customer_user_id_123',
    );

    my %Types = $TicketObject->TicketTypeList(
        QueueID => 123,
        UserID  => 123,
    );

    my %Types = $TicketObject->TicketTypeList(
        TicketID => 123,
        UserID   => 123,
    );

Returns:

    %Types = (
        1 => 'default',
        2 => 'request',
        3 => 'offer',
    );

=cut

sub TicketTypeList {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{UserID} && !$Param{CustomerUserID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need UserID or CustomerUserID!'
        );
        return;
    }

    my %Types = $Kernel::OM->Get('Kernel::System::Type')->TypeList( Valid => 1 );

    # workflow
    my $ACL = $Self->TicketAcl(
        %Param,
        ReturnType    => 'Ticket',
        ReturnSubType => 'Type',
        Data          => \%Types,
    );

    return $Self->TicketAclData() if $ACL;
    return %Types;
}

=head2 TicketTypeSet()

to set a ticket type

    my $Success = $TicketObject->TicketTypeSet(
        TypeID   => 123,
        TicketID => 123,
        UserID   => 123,
    );

    my $Success = $TicketObject->TicketTypeSet(
        Type     => 'normal',
        TicketID => 123,
        UserID   => 123,
    );

Events:
    TicketTypeUpdate

=cut

sub TicketTypeSet {
    my ( $Self, %Param ) = @_;

    # type lookup
    if ( $Param{Type} && !$Param{TypeID} ) {
        $Param{TypeID} = $Kernel::OM->Get('Kernel::System::Type')->TypeLookup( Type => $Param{Type} );
    }

    # check needed stuff
    for my $Needed (qw(TicketID TypeID UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    # get current ticket
    my %Ticket = $Self->TicketGet(
        %Param,
        DynamicFields => 0,
    );

    # update needed?
    return 1 if $Param{TypeID} == $Ticket{TypeID};

    # permission check
    my %TypeList = $Self->TicketTypeList(%Param);
    if ( !$TypeList{ $Param{TypeID} } ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'notice',
            Message  => "Permission denied on TicketID: $Param{TicketID}!",
        );
        return;
    }

    return if !$Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL => 'UPDATE ticket SET type_id = ?, change_time = current_timestamp, '
            . ' change_by = ? WHERE id = ?',
        Bind => [ \$Param{TypeID}, \$Param{UserID}, \$Param{TicketID} ],
    );

    # clear ticket cache
    $Self->_TicketCacheClear( TicketID => $Param{TicketID} );

    # get new ticket data
    my %TicketNew = $Self->TicketGet(
        %Param,
        DynamicFields => 0,
    );
    $TicketNew{Type} = $TicketNew{Type} || 'NULL';
    $Param{TypeID}   = $Param{TypeID}   || '';
    $Ticket{Type}    = $Ticket{Type}    || 'NULL';
    $Ticket{TypeID}  = $Ticket{TypeID}  || '';

    # history insert
    $Self->HistoryAdd(
        TicketID     => $Param{TicketID},
        HistoryType  => 'TypeUpdate',
        Name         => "\%\%$TicketNew{Type}\%\%$Param{TypeID}\%\%$Ticket{Type}\%\%$Ticket{TypeID}",
        CreateUserID => $Param{UserID},
    );

    # trigger event
    $Self->EventHandler(
        Event => 'TicketTypeUpdate',
        Data  => {
            TicketID => $Param{TicketID},
        },
        UserID => $Param{UserID},
    );

    return 1;
}

=head2 TicketServiceList()

to get all possible services for a ticket (depends on workflow, if configured)

    my %Services = $TicketObject->TicketServiceList(
        QueueID        => 123,
        UserID         => 123,
    );

    my %Services = $TicketObject->TicketServiceList(
        CustomerUserID => 123,
        QueueID        => 123,
    );

    my %Services = $TicketObject->TicketServiceList(
        CustomerUserID => 123,
        TicketID       => 123,
        UserID         => 123,
    );

Returns:

    %Services = (
        1 => 'ServiceA',
        2 => 'ServiceB',
        3 => 'ServiceC',
    );

=cut

sub TicketServiceList {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{UserID} && !$Param{CustomerUserID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'UserID or CustomerUserID is needed!',
        );
        return;
    }

    # check needed stuff
    if ( !$Param{QueueID} && !$Param{TicketID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'QueueID or TicketID is needed!',
        );
        return;
    }

    my $ServiceObject = $Kernel::OM->Get('Kernel::System::Service');

    # Return all Services, filtering by KeepChildren config.
    my %AllServices = $ServiceObject->ServiceList(
        UserID => 1,
        KeepChildren =>
            $Kernel::OM->Get('Kernel::Config')->Get('Ticket::Service::KeepChildren'),
    );

    my %Services;
    if ( $Param{CustomerUserID} ) {

        # Return all Services in relation with CustomerUser.
        my %CustomerServices = $ServiceObject->CustomerUserServiceMemberList(
            Result            => 'HASH',
            CustomerUserLogin => $Param{CustomerUserID},
            UserID            => 1,
        );

        # Filter Services based on relation with CustomerUser and KeepChildren config.
        %Services = map { $_ => $CustomerServices{$_} } grep { defined $CustomerServices{$_} } sort keys %AllServices;
    }
    else {
        %Services = %AllServices;
    }

    # workflow
    my $ACL = $Self->TicketAcl(
        %Param,
        ReturnType    => 'Ticket',
        ReturnSubType => 'Service',
        Data          => \%Services,
    );

    return $Self->TicketAclData() if $ACL;
    return %Services;
}

=head2 TicketServiceSet()

to set a ticket service

    my $Success = $TicketObject->TicketServiceSet(
        ServiceID => 123,
        TicketID  => 123,
        UserID    => 123,
    );

    my $Success = $TicketObject->TicketServiceSet(
        Service  => 'Service A',
        TicketID => 123,
        UserID   => 123,
    );

Events:
    TicketServiceUpdate

=cut

sub TicketServiceSet {
    my ( $Self, %Param ) = @_;

    # service lookup
    if ( $Param{Service} && !$Param{ServiceID} ) {
        $Param{ServiceID} = $Kernel::OM->Get('Kernel::System::Service')->ServiceLookup(
            Name => $Param{Service},
        );
    }

    # check needed stuff
    for my $Needed (qw(TicketID ServiceID UserID)) {
        if ( !defined $Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    # get current ticket
    my %Ticket = $Self->TicketGet(
        %Param,
        DynamicFields => 0,
    );

    # update needed?
    return 1 if $Param{ServiceID} eq $Ticket{ServiceID};

    # permission check
    my %ServiceList = $Self->TicketServiceList(%Param);
    if ( $Param{ServiceID} ne '' && !$ServiceList{ $Param{ServiceID} } ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'notice',
            Message  => "Permission denied on TicketID: $Param{TicketID}!",
        );
        return;
    }

    # check database undef/NULL (set value to undef/NULL to prevent database errors)
    for my $Parameter (qw(ServiceID SLAID)) {
        if ( !$Param{$Parameter} ) {
            $Param{$Parameter} = undef;
        }
    }

    return if !$Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL => 'UPDATE ticket SET service_id = ?, change_time = current_timestamp, '
            . ' change_by = ? WHERE id = ?',
        Bind => [ \$Param{ServiceID}, \$Param{UserID}, \$Param{TicketID} ],
    );

    # clear ticket cache
    $Self->_TicketCacheClear( TicketID => $Param{TicketID} );

    # get new ticket data
    my %TicketNew = $Self->TicketGet(
        %Param,
        DynamicFields => 0,
    );
    $TicketNew{Service} = $TicketNew{Service} || 'NULL';
    $Param{ServiceID}   = $Param{ServiceID}   || '';
    $Ticket{Service}    = $Ticket{Service}    || 'NULL';
    $Ticket{ServiceID}  = $Ticket{ServiceID}  || '';

    # history insert
    $Self->HistoryAdd(
        TicketID    => $Param{TicketID},
        HistoryType => 'ServiceUpdate',
        Name =>
            "\%\%$TicketNew{Service}\%\%$Param{ServiceID}\%\%$Ticket{Service}\%\%$Ticket{ServiceID}",
        CreateUserID => $Param{UserID},
    );

    # trigger notification event
    $Self->EventHandler(
        Event => 'NotificationServiceUpdate',
        Data  => {
            TicketID              => $Param{TicketID},
            CustomerMessageParams => {},
        },
        UserID => $Param{UserID},
    );

    # trigger event
    $Self->EventHandler(
        Event => 'TicketServiceUpdate',
        Data  => {
            TicketID => $Param{TicketID},
        },
        UserID => $Param{UserID},
    );

    return 1;
}

=head2 TicketEscalationPreferences()

get escalation preferences of a ticket (e. g. from SLA or from Queue based settings)

    my %Escalation = $TicketObject->TicketEscalationPreferences(
        Ticket => $Param{Ticket},
        UserID => $Param{UserID},
    );

=cut

sub TicketEscalationPreferences {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Ticket UserID)) {
        if ( !defined $Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    # get ticket attributes
    my %Ticket = %{ $Param{Ticket} };

    # get escalation properties
    my %Escalation;
    if ( $Kernel::OM->Get('Kernel::Config')->Get('Ticket::Service') && $Ticket{SLAID} ) {

        %Escalation = $Kernel::OM->Get('Kernel::System::SLA')->SLAGet(
            SLAID  => $Ticket{SLAID},
            UserID => $Param{UserID},
            Cache  => 1,
        );
    }
    else {
        %Escalation = $Kernel::OM->Get('Kernel::System::Queue')->QueueGet(
            ID     => $Ticket{QueueID},
            UserID => $Param{UserID},
            Cache  => 1,
        );
    }

    return %Escalation;
}

=head2 TicketEscalationDateCalculation()

get escalation properties of a ticket

    my %Escalation = $TicketObject->TicketEscalationDateCalculation(
        Ticket => $Param{Ticket},
        UserID => $Param{UserID},
    );

returns

    (general escalation info)
    EscalationDestinationIn          (escalation in e. g. 1h 4m)
    EscalationDestinationTime        (date of escalation in unix time, e. g. 72193292)
    EscalationDestinationDate        (date of escalation, e. g. "2009-02-14 18:00:00")
    EscalationTimeWorkingTime        (seconds of working/service time till escalation, e. g. "1800")
    EscalationTime                   (seconds total till escalation, e. g. "3600")

    (detail escalation info about first response, update and solution time)
    FirstResponseTimeEscalation      (if true, ticket is escalated)
    FirstResponseTimeNotification    (if true, notify - x% of escalation has reached)
    FirstResponseTimeDestinationTime (date of escalation in unix time, e. g. 72193292)
    FirstResponseTimeDestinationDate (date of escalation, e. g. "2009-02-14 18:00:00")
    FirstResponseTimeWorkingTime     (seconds of working/service time till escalation, e. g. "1800")
    FirstResponseTime                (seconds total till escalation, e. g. "3600")

    UpdateTimeEscalation             (if true, ticket is escalated)
    UpdateTimeNotification           (if true, notify - x% of escalation has reached)
    UpdateTimeDestinationTime        (date of escalation in unix time, e. g. 72193292)
    UpdateTimeDestinationDate        (date of escalation, e. g. "2009-02-14 18:00:00")
    UpdateTimeWorkingTime            (seconds of working/service time till escalation, e. g. "1800")
    UpdateTime                       (seconds total till escalation, e. g. "3600")

    SolutionTimeEscalation           (if true, ticket is escalated)
    SolutionTimeNotification         (if true, notify - x% of escalation has reached)
    SolutionTimeDestinationTime      (date of escalation in unix time, e. g. 72193292)
    SolutionTimeDestinationDate      (date of escalation, e. g. "2009-02-14 18:00:00")
    SolutionTimeWorkingTime          (seconds of working/service time till escalation, e. g. "1800")
    SolutionTime                     (seconds total till escalation, e. g. "3600")

=cut

sub TicketEscalationDateCalculation {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Ticket UserID)) {
        if ( !defined $Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    # get ticket attributes
    my %Ticket = %{ $Param{Ticket} };

    # do no escalations on (merge|close|remove) tickets
    return if $Ticket{StateType} eq 'merged';
    return if $Ticket{StateType} eq 'closed';
    return if $Ticket{StateType} eq 'removed';

    # get escalation properties
    my %Escalation = $Self->TicketEscalationPreferences(
        Ticket => $Param{Ticket},
        UserID => $Param{UserID} || 1,
    );

    # return if we do not have any escalation attributes
    my %Map = (
        EscalationResponseTime => 'FirstResponse',
        EscalationUpdateTime   => 'Update',
        EscalationSolutionTime => 'Solution',
    );
    my $EscalationAttribute;
    KEY:
    for my $Key ( sort keys %Map ) {
        if ( $Escalation{ $Map{$Key} . 'Time' } ) {
            $EscalationAttribute = 1;
            last KEY;
        }
    }

    return if !$EscalationAttribute;

    # create datetime object
    my $DateTimeObject = $Kernel::OM->Create('Kernel::System::DateTime');

    # calculate escalation times based on escalation properties
    my %Data;

    TIME:
    for my $Key ( sort keys %Map ) {

        next TIME if !$Ticket{$Key};

        # get time before or over escalation (escalation_destination_unixtime - now)
        my $TimeTillEscalation = $Ticket{$Key} - $DateTimeObject->ToEpoch();

        # ticket is not escalated till now ($TimeTillEscalation > 0)
        my $WorkingTime = 0;
        if ( $TimeTillEscalation > 0 ) {

            my $StopTimeObj = $Kernel::OM->Create(
                'Kernel::System::DateTime',
                ObjectParams => {
                    Epoch => $Ticket{$Key}
                }
            );

            my $DeltaObj = $DateTimeObject->Delta(
                DateTimeObject => $StopTimeObj,
                ForWorkingTime => 1,
                Calendar       => $Escalation{Calendar},
            );

            $WorkingTime = $DeltaObj ? $DeltaObj->{AbsoluteSeconds} : 0;

            # extract needed data
            my $Notify = $Escalation{ $Map{$Key} . 'Notify' };
            my $Time   = $Escalation{ $Map{$Key} . 'Time' };

            # set notification if notify % is reached
            if ( $Notify && $Time ) {

                my $Reached = 100 - ( $WorkingTime / ( $Time * 60 / 100 ) );

                if ( $Reached >= $Notify ) {
                    $Data{ $Map{$Key} . 'TimeNotification' } = 1;
                }
            }
        }

        # ticket is overtime ($TimeTillEscalation < 0)
        else {
            my $StartTimeObj = $Kernel::OM->Create(
                'Kernel::System::DateTime',
                ObjectParams => {
                    Epoch => $Ticket{$Key}
                }
            );

            my $DeltaObj = $StartTimeObj->Delta(
                DateTimeObject => $DateTimeObject,
                ForWorkingTime => 1,
                Calendar       => $Escalation{Calendar},
            );

            $WorkingTime = 0;
            if ( $DeltaObj && $DeltaObj->{AbsoluteSeconds} ) {
                $WorkingTime = '-' . $DeltaObj->{AbsoluteSeconds};
            }

            # set escalation
            $Data{ $Map{$Key} . 'TimeEscalation' } = 1;
        }

        my $DestinationDate = $Kernel::OM->Create(
            'Kernel::System::DateTime',
            ObjectParams => {
                Epoch => $Ticket{$Key}
            }
        );

        $Data{ $Map{$Key} . 'TimeDestinationTime' } = $Ticket{$Key};
        $Data{ $Map{$Key} . 'TimeDestinationDate' } = $DestinationDate->ToString();
        $Data{ $Map{$Key} . 'TimeWorkingTime' }     = $WorkingTime;
        $Data{ $Map{$Key} . 'Time' }                = $TimeTillEscalation;

        # set global escalation attributes (set the escalation which is the first in time)
        if (
            !$Data{EscalationDestinationTime}
            || $Data{EscalationDestinationTime} > $Ticket{$Key}
            )
        {
            $Data{EscalationDestinationTime} = $Ticket{$Key};
            $Data{EscalationDestinationDate} = $DestinationDate->ToString();
            $Data{EscalationTimeWorkingTime} = $WorkingTime;
            $Data{EscalationTime}            = $TimeTillEscalation;

            # escalation time in readable way
            $Data{EscalationDestinationIn} = '';
            $WorkingTime = abs($WorkingTime);
            if ( $WorkingTime >= 3600 ) {
                $Data{EscalationDestinationIn} .= int( $WorkingTime / 3600 ) . 'h ';
                $WorkingTime = $WorkingTime
                    - ( int( $WorkingTime / 3600 ) * 3600 );    # remove already shown hours
            }
            if ( $WorkingTime <= 3600 || int( $WorkingTime / 60 ) ) {
                $Data{EscalationDestinationIn} .= int( $WorkingTime / 60 ) . 'm';
            }
        }
    }

    return %Data;
}

=head2 TicketEscalationIndexBuild()

build escalation index of one ticket with current settings (SLA, Queue, Calendar...)

    my $Success = $TicketObject->TicketEscalationIndexBuild(
        TicketID => $Param{TicketID},
        UserID   => $Param{UserID},
    );

=cut

sub TicketEscalationIndexBuild {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(TicketID UserID)) {
        if ( !defined $Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    my %Ticket = $Self->TicketGet(
        TicketID      => $Param{TicketID},
        UserID        => $Param{UserID},
        DynamicFields => 0,
        Silent        => 1,                  # Suppress warning if the ticket was deleted in the meantime.
    );

    return if !%Ticket;

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # do no escalations on (merge|close|remove) tickets
    if ( $Ticket{StateType} && $Ticket{StateType} =~ /^(merge|close|remove)/i ) {

        # update escalation times with 0
        my %EscalationTimes = (
            EscalationTime         => 'escalation_time',
            EscalationResponseTime => 'escalation_response_time',
            EscalationUpdateTime   => 'escalation_update_time',
            EscalationSolutionTime => 'escalation_solution_time',
        );

        TIME:
        for my $Key ( sort keys %EscalationTimes ) {

            # check if table update is needed
            next TIME if !$Ticket{$Key};

            # update ticket table
            $DBObject->Do(
                SQL =>
                    "UPDATE ticket SET $EscalationTimes{$Key} = 0, change_time = current_timestamp, "
                    . " change_by = ? WHERE id = ?",
                Bind => [ \$Param{UserID}, \$Ticket{TicketID}, ],
            );
        }

        # clear ticket cache
        $Self->_TicketCacheClear( TicketID => $Param{TicketID} );

        return 1;
    }

    # get escalation properties
    my %Escalation;
    if (%Ticket) {
        %Escalation = $Self->TicketEscalationPreferences(
            Ticket => \%Ticket,
            UserID => $Param{UserID},
        );
    }

    # find escalation times
    my $EscalationTime = 0;

    # update first response (if not responded till now)
    if ( !$Escalation{FirstResponseTime} ) {
        $DBObject->Do(
            SQL =>
                'UPDATE ticket SET escalation_response_time = 0, change_time = current_timestamp, '
                . ' change_by = ? WHERE id = ?',
            Bind => [ \$Param{UserID}, \$Ticket{TicketID}, ]
        );
    }
    else {

        # check if first response is already done
        my %FirstResponseDone = $Self->_TicketGetFirstResponse(
            TicketID => $Ticket{TicketID},
            Ticket   => \%Ticket,
        );

        # update first response time to 0
        if (%FirstResponseDone) {
            $DBObject->Do(
                SQL =>
                    'UPDATE ticket SET escalation_response_time = 0, change_time = current_timestamp, '
                    . ' change_by = ? WHERE id = ?',
                Bind => [ \$Param{UserID}, \$Ticket{TicketID}, ]
            );
        }

        # update first response time to expected escalation destination time
        else {

            my $DateTimeObject = $Kernel::OM->Create(
                'Kernel::System::DateTime',
                ObjectParams => {
                    String => $Ticket{Created},
                }
            );

            $DateTimeObject->Add(
                AsWorkingTime => 1,
                Calendar      => $Escalation{Calendar},
                Seconds       => $Escalation{FirstResponseTime} * 60,
            );

            my $DestinationTime = $DateTimeObject->ToEpoch();

            # update first response time to $DestinationTime
            $DBObject->Do(
                SQL =>
                    'UPDATE ticket SET escalation_response_time = ?, change_time = current_timestamp, '
                    . ' change_by = ? WHERE id = ?',
                Bind => [ \$DestinationTime, \$Param{UserID}, \$Ticket{TicketID}, ]
            );

            # remember escalation time
            $EscalationTime = $DestinationTime;
        }
    }

    # update update && do not escalate in "pending auto" for escalation update time
    if ( !$Escalation{UpdateTime} || $Ticket{StateType} =~ /^(pending)/i ) {
        $DBObject->Do(
            SQL => 'UPDATE ticket SET escalation_update_time = 0, change_time = current_timestamp, '
                . ' change_by = ? WHERE id = ?',
            Bind => [ \$Param{UserID}, \$Ticket{TicketID}, ]
        );
    }
    else {

        # check if update escalation should be set
        my @SenderHistory;
        return if !$DBObject->Prepare(
            SQL => 'SELECT article_sender_type_id, is_visible_for_customer, create_time FROM '
                . 'article WHERE ticket_id = ? ORDER BY create_time ASC',
            Bind => [ \$Param{TicketID} ],
        );
        while ( my @Row = $DBObject->FetchrowArray() ) {
            push @SenderHistory, {
                SenderTypeID         => $Row[0],
                IsVisibleForCustomer => $Row[1],
                Created              => $Row[2],
            };
        }

        my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');

        # fill up lookups
        for my $Row (@SenderHistory) {
            $Row->{SenderType} = $ArticleObject->ArticleSenderTypeLookup(
                SenderTypeID => $Row->{SenderTypeID},
            );
        }

        # get latest customer contact time
        my $LastSenderTime;
        my $LastSenderType = '';
        ROW:
        for my $Row ( reverse @SenderHistory ) {

            # fill up latest sender time (as initial value)
            if ( !$LastSenderTime ) {
                $LastSenderTime = $Row->{Created};
            }

            # do not use locked tickets for calculation
            #last ROW if $Ticket{Lock} eq 'lock';

            # do not use internal articles for calculation
            next ROW if !$Row->{IsVisibleForCustomer};

            # only use 'agent' and 'customer' sender types for calculation
            next ROW if $Row->{SenderType} !~ /^(agent|customer)$/;

            # last ROW if latest was customer and the next was not customer
            # otherwise use also next, older customer article as latest
            # customer followup for starting escalation
            if ( $Row->{SenderType} eq 'agent' && $LastSenderType eq 'customer' ) {
                last ROW;
            }

            # start escalation on latest customer article
            if ( $Row->{SenderType} eq 'customer' ) {
                $LastSenderType = 'customer';
                $LastSenderTime = $Row->{Created};
            }

            # start escalation on latest agent article
            if ( $Row->{SenderType} eq 'agent' ) {
                $LastSenderTime = $Row->{Created};
                last ROW;
            }
        }
        if ($LastSenderTime) {

            # create datetime object
            my $DateTimeObject = $Kernel::OM->Create(
                'Kernel::System::DateTime',
                ObjectParams => {
                    String => $LastSenderTime,
                }
            );

            $DateTimeObject->Add(
                Seconds       => $Escalation{UpdateTime} * 60,
                AsWorkingTime => 1,
                Calendar      => $Escalation{Calendar},
            );

            my $DestinationTime = $DateTimeObject->ToEpoch();

            # update update time to $DestinationTime
            $DBObject->Do(
                SQL =>
                    'UPDATE ticket SET escalation_update_time = ?, change_time = current_timestamp, '
                    . ' change_by = ? WHERE id = ?',
                Bind => [ \$DestinationTime, \$Param{UserID}, \$Ticket{TicketID}, ]
            );

            # remember escalation time
            if ( $EscalationTime == 0 || $DestinationTime < $EscalationTime ) {
                $EscalationTime = $DestinationTime;
            }
        }

        # else, no not escalate, because latest sender was agent
        else {
            $DBObject->Do(
                SQL =>
                    'UPDATE ticket SET escalation_update_time = 0, change_time = current_timestamp, '
                    . ' change_by = ? WHERE id = ?',
                Bind => [ \$Param{UserID}, \$Ticket{TicketID}, ]
            );
        }
    }

    # update solution
    if ( !$Escalation{SolutionTime} ) {
        $DBObject->Do(
            SQL =>
                'UPDATE ticket SET escalation_solution_time = 0, change_time = current_timestamp, '
                . ' change_by = ? WHERE id = ?',
            Bind => [ \$Param{UserID}, \$Ticket{TicketID}, ],
        );
    }
    else {

        # find solution time / first close time
        my %SolutionDone = $Self->_TicketGetClosed(
            TicketID => $Ticket{TicketID},
            Ticket   => \%Ticket,
        );

        # update solution time to 0
        if (%SolutionDone) {
            $DBObject->Do(
                SQL =>
                    'UPDATE ticket SET escalation_solution_time = 0, change_time = current_timestamp, '
                    . ' change_by = ? WHERE id = ?',
                Bind => [ \$Param{UserID}, \$Ticket{TicketID}, ],
            );
        }
        else {

            # get datetime object
            my $DateTimeObject = $Kernel::OM->Create(
                'Kernel::System::DateTime',
                ObjectParams => {
                    String => $Ticket{Created},
                }
            );

            $DateTimeObject->Add(
                Seconds       => $Escalation{SolutionTime} * 60,
                AsWorkingTime => 1,
                Calendar      => $Escalation{Calendar},
            );

            my $DestinationTime = $DateTimeObject->ToEpoch();

            # update solution time to $DestinationTime
            $DBObject->Do(
                SQL =>
                    'UPDATE ticket SET escalation_solution_time = ?, change_time = current_timestamp, '
                    . ' change_by = ? WHERE id = ?',
                Bind => [ \$DestinationTime, \$Param{UserID}, \$Ticket{TicketID}, ],
            );

            # remember escalation time
            if ( $EscalationTime == 0 || $DestinationTime < $EscalationTime ) {
                $EscalationTime = $DestinationTime;
            }
        }
    }

    # update escalation time (< escalation time)
    if ( defined $EscalationTime ) {
        $DBObject->Do(
            SQL => 'UPDATE ticket SET escalation_time = ?, change_time = current_timestamp, '
                . ' change_by = ? WHERE id = ?',
            Bind => [ \$EscalationTime, \$Param{UserID}, \$Ticket{TicketID}, ],
        );
    }

    # clear ticket cache
    $Self->_TicketCacheClear( TicketID => $Param{TicketID} );

    return 1;
}

=head2 TicketSLAList()

to get all possible SLAs for a ticket (depends on workflow, if configured)

    my %SLAs = $TicketObject->TicketSLAList(
        ServiceID => 1,
        UserID    => 123,
    );

    my %SLAs = $TicketObject->TicketSLAList(
        ServiceID      => 1,
        CustomerUserID => 'customer_user_id_123',
    );


    my %SLAs = $TicketObject->TicketSLAList(
        QueueID   => 123,
        ServiceID => 1,
        UserID    => 123,
    );

    my %SLAs = $TicketObject->TicketSLAList(
        TicketID  => 123,
        ServiceID => 1,
        UserID    => 123,
    );

Returns:

    %SLAs = (
        1 => 'SLA A',
        2 => 'SLA B',
        3 => 'SLA C',
    );

=cut

sub TicketSLAList {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{UserID} && !$Param{CustomerUserID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need UserID or CustomerUserID!'
        );
        return;
    }

    # check needed stuff
    if ( !$Param{QueueID} && !$Param{TicketID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need QueueID or TicketID!'
        );
        return;
    }

    # return emty hash, if no service id is given
    if ( !$Param{ServiceID} ) {
        return ();
    }

    # get sla list
    my %SLAs = $Kernel::OM->Get('Kernel::System::SLA')->SLAList(
        ServiceID => $Param{ServiceID},
        UserID    => 1,
    );

    # workflow
    my $ACL = $Self->TicketAcl(
        %Param,
        ReturnType    => 'Ticket',
        ReturnSubType => 'SLA',
        Data          => \%SLAs,
    );

    return $Self->TicketAclData() if $ACL;
    return %SLAs;
}

=head2 TicketSLASet()

to set a ticket service level agreement

    my $Success = $TicketObject->TicketSLASet(
        SLAID    => 123,
        TicketID => 123,
        UserID   => 123,
    );

    my $Success = $TicketObject->TicketSLASet(
        SLA      => 'SLA A',
        TicketID => 123,
        UserID   => 123,
    );

Events:
    TicketSLAUpdate

=cut

sub TicketSLASet {
    my ( $Self, %Param ) = @_;

    # sla lookup
    if ( $Param{SLA} && !$Param{SLAID} ) {
        $Param{SLAID} = $Kernel::OM->Get('Kernel::System::SLA')->SLALookup( Name => $Param{SLA} );
    }

    # check needed stuff
    for my $Needed (qw(TicketID SLAID UserID)) {
        if ( !defined $Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    # get current ticket
    my %Ticket = $Self->TicketGet(
        %Param,
        DynamicFields => 0,
    );

    # update needed?
    return 1 if ( $Param{SLAID} eq $Ticket{SLAID} );

    # permission check
    my %SLAList = $Self->TicketSLAList(
        %Param,
        ServiceID => $Ticket{ServiceID},
    );

    if ( $Param{UserID} != 1 && $Param{SLAID} ne '' && !$SLAList{ $Param{SLAID} } ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'notice',
            Message  => "Permission denied on TicketID: $Param{TicketID}!",
        );
        return;
    }

    # check database undef/NULL (set value to undef/NULL to prevent database errors)
    for my $Parameter (qw(ServiceID SLAID)) {
        if ( !$Param{$Parameter} ) {
            $Param{$Parameter} = undef;
        }
    }

    return if !$Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL => 'UPDATE ticket SET sla_id = ?, change_time = current_timestamp, '
            . ' change_by = ? WHERE id = ?',
        Bind => [ \$Param{SLAID}, \$Param{UserID}, \$Param{TicketID} ],
    );

    # clear ticket cache
    $Self->_TicketCacheClear( TicketID => $Param{TicketID} );

    # get new ticket data
    my %TicketNew = $Self->TicketGet(
        %Param,
        DynamicFields => 0,
    );
    $TicketNew{SLA} = $TicketNew{SLA} || 'NULL';
    $Param{SLAID}   = $Param{SLAID}   || '';
    $Ticket{SLA}    = $Ticket{SLA}    || 'NULL';
    $Ticket{SLAID}  = $Ticket{SLAID}  || '';

    # history insert
    $Self->HistoryAdd(
        TicketID     => $Param{TicketID},
        HistoryType  => 'SLAUpdate',
        Name         => "\%\%$TicketNew{SLA}\%\%$Param{SLAID}\%\%$Ticket{SLA}\%\%$Ticket{SLAID}",
        CreateUserID => $Param{UserID},
    );

    # trigger event, OldTicketData is needed for escalation events
    $Self->EventHandler(
        Event => 'TicketSLAUpdate',
        Data  => {
            TicketID      => $Param{TicketID},
            OldTicketData => \%Ticket,
        },
        UserID => $Param{UserID},
    );

    return 1;
}

=head2 TicketCustomerSet()

Set customer data of ticket. Can set 'No' (CustomerID),
'User' (CustomerUserID), or both.

    my $Success = $TicketObject->TicketCustomerSet(
        No       => 'client123',
        User     => 'client-user-123',
        TicketID => 123,
        UserID   => 23,
    );

Events:
    TicketCustomerUpdate

=cut

sub TicketCustomerSet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(TicketID UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }
    if ( !defined $Param{No} && !defined $Param{User} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need User or No for update!'
        );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # db customer id update
    if ( defined $Param{No} ) {

        my $Ok = $DBObject->Do(
            SQL => 'UPDATE ticket SET customer_id = ?, '
                . ' change_time = current_timestamp, change_by = ? WHERE id = ?',
            Bind => [ \$Param{No}, \$Param{UserID}, \$Param{TicketID} ]
        );

        if ($Ok) {
            $Param{History} = "CustomerID=$Param{No};";
        }
    }

    # db customer user update
    if ( defined $Param{User} ) {

        my $Ok = $DBObject->Do(
            SQL => 'UPDATE ticket SET customer_user_id = ?, '
                . 'change_time = current_timestamp, change_by = ? WHERE id = ?',
            Bind => [ \$Param{User}, \$Param{UserID}, \$Param{TicketID} ],
        );

        if ($Ok) {
            $Param{History} .= "CustomerUser=$Param{User};";
        }
    }

    # clear ticket cache
    $Self->_TicketCacheClear( TicketID => $Param{TicketID} );

    # if no change
    if ( !$Param{History} ) {
        return;
    }

    # history insert
    $Self->HistoryAdd(
        TicketID     => $Param{TicketID},
        HistoryType  => 'CustomerUpdate',
        Name         => "\%\%" . $Param{History},
        CreateUserID => $Param{UserID},
    );

    # trigger event
    $Self->EventHandler(
        Event => 'TicketCustomerUpdate',
        Data  => {
            TicketID => $Param{TicketID},
        },
        UserID => $Param{UserID},
    );

    return 1;
}

=head2 TicketPermission()

returns whether or not the agent has permission on a ticket

    my $Access = $TicketObject->TicketPermission(
        Type     => 'ro',
        TicketID => 123,
        UserID   => 123,
    );

or without logging, for example for to check if a link/action should be shown

    my $Access = $TicketObject->TicketPermission(
        Type     => 'ro',
        TicketID => 123,
        LogNo    => 1,
        UserID   => 123,
    );

=cut

sub TicketPermission {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Type TicketID UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    # get needed objects
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $MainObject   = $Kernel::OM->Get('Kernel::System::Main');

    # run all TicketPermission modules
    if ( ref $ConfigObject->Get('Ticket::Permission') eq 'HASH' ) {
        my %Modules = %{ $ConfigObject->Get('Ticket::Permission') };

        MODULE:
        for my $Module ( sort keys %Modules ) {

            # log try of load module
            if ( $Self->{Debug} > 1 ) {
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'debug',
                    Message  => "Try to load module: $Modules{$Module}->{Module}!",
                );
            }

            # load module
            next MODULE if !$MainObject->Require( $Modules{$Module}->{Module} );

            # create object
            my $ModuleObject = $Modules{$Module}->{Module}->new();

            # execute Run()
            my $AccessOk = $ModuleObject->Run(%Param);

            # check granted option (should I say ok)
            if ( $AccessOk && $Modules{$Module}->{Granted} ) {
                if ( $Self->{Debug} > 0 ) {
                    $Kernel::OM->Get('Kernel::System::Log')->Log(
                        Priority => 'debug',
                        Message  => "Granted access '$Param{Type}' true for "
                            . "TicketID '$Param{TicketID}' "
                            . "through $Modules{$Module}->{Module} (no more checks)!",
                    );
                }

                # access ok
                return 1;
            }

            # return because access is false but it's required
            if ( !$AccessOk && $Modules{$Module}->{Required} ) {
                if ( !$Param{LogNo} ) {
                    $Kernel::OM->Get('Kernel::System::Log')->Log(
                        Priority => 'notice',
                        Message  => "Permission denied because module "
                            . "($Modules{$Module}->{Module}) is required "
                            . "(UserID: $Param{UserID} '$Param{Type}' on "
                            . "TicketID: $Param{TicketID})!",
                    );
                }

                # access not ok
                return;
            }
        }
    }

    # don't grant access to the ticket
    if ( !$Param{LogNo} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'notice',
            Message  => "Permission denied (UserID: $Param{UserID} '$Param{Type}' "
                . "on TicketID: $Param{TicketID})!",
        );
    }

    return;
}

=head2 TicketCustomerPermission()

returns whether or not a customer has permission to a ticket

    my $Access = $TicketObject->TicketCustomerPermission(
        Type     => 'ro',
        TicketID => 123,
        UserID   => 123,
    );

or without logging, for example for to check if a link/action should be displayed

    my $Access = $TicketObject->TicketCustomerPermission(
        Type     => 'ro',
        TicketID => 123,
        LogNo    => 1,
        UserID   => 123,
    );

=cut

sub TicketCustomerPermission {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Type TicketID UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    # get main object
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $MainObject   = $Kernel::OM->Get('Kernel::System::Main');

    # run all CustomerTicketPermission modules
    if ( ref $ConfigObject->Get('CustomerTicket::Permission') eq 'HASH' ) {
        my %Modules = %{ $ConfigObject->Get('CustomerTicket::Permission') };

        MODULE:
        for my $Module ( sort keys %Modules ) {

            # log try of load module
            if ( $Self->{Debug} > 1 ) {
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'debug',
                    Message  => "Try to load module: $Modules{$Module}->{Module}!",
                );
            }

            # load module
            next MODULE if !$MainObject->Require( $Modules{$Module}->{Module} );

            # create object
            my $ModuleObject = $Modules{$Module}->{Module}->new();

            # execute Run()
            my $AccessOk = $ModuleObject->Run(%Param);

            # check granted option (should I say ok)
            if ( $AccessOk && $Modules{$Module}->{Granted} ) {
                if ( $Self->{Debug} > 0 ) {
                    $Kernel::OM->Get('Kernel::System::Log')->Log(
                        Priority => 'debug',
                        Message  => "Granted access '$Param{Type}' true for "
                            . "TicketID '$Param{TicketID}' "
                            . "through $Modules{$Module}->{Module} (no more checks)!",
                    );
                }

                # access ok
                return 1;
            }

            # return because access is false but it's required
            if ( !$AccessOk && $Modules{$Module}->{Required} ) {
                if ( !$Param{LogNo} ) {
                    $Kernel::OM->Get('Kernel::System::Log')->Log(
                        Priority => 'notice',
                        Message  => "Permission denied because module "
                            . "($Modules{$Module}->{Module}) is required "
                            . "(UserID: $Param{UserID} '$Param{Type}' on "
                            . "TicketID: $Param{TicketID})!",
                    );
                }

                # access not ok
                return;
            }
        }
    }

    # don't grant access to the ticket
    if ( !$Param{LogNo} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'notice',
            Message  => "Permission denied (UserID: $Param{UserID} '$Param{Type}' on "
                . "TicketID: $Param{TicketID})!",
        );
    }
    return;
}

=head2 GetSubscribedUserIDsByQueueID()

returns an array of user ids which selected the given queue id as
custom queue.

    my @UserIDs = $TicketObject->GetSubscribedUserIDsByQueueID(
        QueueID => 123,
    );

Returns:

    @UserIDs = ( 1, 2, 3 );

=cut

sub GetSubscribedUserIDsByQueueID {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{QueueID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need QueueID!'
        );
        return;
    }

    # get group of queue
    my %Queue = $Kernel::OM->Get('Kernel::System::Queue')->QueueGet( ID => $Param{QueueID} );

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # fetch all queues
    my @UserIDs;
    return if !$DBObject->Prepare(
        SQL  => 'SELECT user_id FROM personal_queues WHERE queue_id = ?',
        Bind => [ \$Param{QueueID} ],
    );
    while ( my @Row = $DBObject->FetchrowArray() ) {
        push @UserIDs, $Row[0];
    }

    # get needed objects
    my $GroupObject = $Kernel::OM->Get('Kernel::System::Group');
    my $UserObject  = $Kernel::OM->Get('Kernel::System::User');

    # check if user is valid and check permissions
    my @CleanUserIDs;

    USER:
    for my $UserID (@UserIDs) {

        my %User = $UserObject->GetUserData(
            UserID => $UserID,
            Valid  => 1
        );

        next USER if !%User;

        # just send emails to permitted agents
        my %GroupMember = $GroupObject->PermissionUserGet(
            UserID => $UserID,
            Type   => 'ro',
        );

        if ( $GroupMember{ $Queue{GroupID} } ) {
            push @CleanUserIDs, $UserID;
        }
    }

    return @CleanUserIDs;
}

=head2 GetSubscribedUserIDsByServiceID()

returns an array of user ids which selected the given service id as
custom service.

    my @UserIDs = $TicketObject->GetSubscribedUserIDsByServiceID(
        ServiceID => 123,
    );

Returns:

    @UserIDs = ( 1, 2, 3 );

=cut

sub GetSubscribedUserIDsByServiceID {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{ServiceID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need ServiceID!'
        );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # fetch all users
    my @UserIDs;
    return if !$DBObject->Prepare(
        SQL => '
            SELECT user_id
            FROM personal_services
            WHERE service_id = ?',
        Bind => [ \$Param{ServiceID} ],
    );

    while ( my @Row = $DBObject->FetchrowArray() ) {
        push @UserIDs, $Row[0];
    }

    # get user object
    my $UserObject = $Kernel::OM->Get('Kernel::System::User');

    # check if user is valid
    my @CleanUserIDs;
    USER:
    for my $UserID (@UserIDs) {

        my %User = $UserObject->GetUserData(
            UserID => $UserID,
            Valid  => 1,
        );

        next USER if !%User;

        push @CleanUserIDs, $UserID;
    }

    return @CleanUserIDs;
}

=head2 TicketPendingTimeSet()

set ticket pending time:

    my $Success = $TicketObject->TicketPendingTimeSet(
        Year     => 2003,
        Month    => 08,
        Day      => 14,
        Hour     => 22,
        Minute   => 05,
        TicketID => 123,
        UserID   => 23,
    );

or use a time stamp:

    my $Success = $TicketObject->TicketPendingTimeSet(
        String   => '2003-08-14 22:05:00',
        TicketID => 123,
        UserID   => 23,
    );

or use a diff (set pending time to "now" + diff minutes)

    my $Success = $TicketObject->TicketPendingTimeSet(
        Diff     => ( 7 * 24 * 60 ),  # minutes (here: 10080 minutes - 7 days)
        TicketID => 123,
        UserID   => 23,
    );

If you want to set the pending time to null, just supply zeros:

    my $Success = $TicketObject->TicketPendingTimeSet(
        Year     => 0000,
        Month    => 00,
        Day      => 00,
        Hour     => 00,
        Minute   => 00,
        TicketID => 123,
        UserID   => 23,
    );

or use a time stamp:

    my $Success = $TicketObject->TicketPendingTimeSet(
        String   => '0000-00-00 00:00:00',
        TicketID => 123,
        UserID   => 23,
    );

Events:
    TicketPendingTimeUpdate

=cut

sub TicketPendingTimeSet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{String} && !$Param{Diff} ) {
        for my $Needed (qw(Year Month Day Hour Minute TicketID UserID)) {
            if ( !defined $Param{$Needed} ) {
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'error',
                    Message  => "Need $Needed!"
                );
                return;
            }
        }
    }
    elsif (
        !$Param{String} &&
        !( $Param{Year} && $Param{Month} && $Param{Day} && $Param{Hour} && $Param{Minute} )
        )
    {
        for my $Needed (qw(Diff TicketID UserID)) {
            if ( !defined $Param{$Needed} ) {
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'error',
                    Message  => "Need $Needed!"
                );
                return;
            }
        }
    }
    else {
        for my $Needed (qw(String TicketID UserID)) {
            if ( !defined $Param{$Needed} ) {
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'error',
                    Message  => "Need $Needed!"
                );
                return;
            }
        }
    }

    # check if we need to null the PendingTime
    my $PendingTimeNull;
    if ( $Param{String} && $Param{String} eq '0000-00-00 00:00:00' ) {
        $PendingTimeNull = 1;
        $Param{Sec}      = 0;
        $Param{Minute}   = 0;
        $Param{Hour}     = 0;
        $Param{Day}      = 0;
        $Param{Month}    = 0;
        $Param{Year}     = 0;
    }
    elsif (
        !$Param{String}
        && !$Param{Diff}
        && $Param{Minute} == 0
        && $Param{Hour} == 0 && $Param{Day} == 0
        && $Param{Month} == 0
        && $Param{Year} == 0
        )
    {
        $PendingTimeNull = 1;
    }

    # get system time from string/params
    my $Time = 0;
    if ( !$PendingTimeNull ) {

        if ( $Param{String} ) {

            my $DateTimeObject = $Kernel::OM->Create(
                'Kernel::System::DateTime',
                ObjectParams => {
                    String => $Param{String}
                }
            );
            return if ( !$DateTimeObject );

            $Time = $DateTimeObject->ToEpoch();

            my $DateTimeValues = $DateTimeObject->Get();
            $Param{Sec}    = $DateTimeValues->{Second};
            $Param{Minute} = $DateTimeValues->{Minute};
            $Param{Hour}   = $DateTimeValues->{Hour};
            $Param{Day}    = $DateTimeValues->{Day};
            $Param{Month}  = $DateTimeValues->{Month};
            $Param{Year}   = $DateTimeValues->{Year};
        }
        elsif ( $Param{Diff} ) {

            my $DateTimeObject = $Kernel::OM->Create('Kernel::System::DateTime');
            $DateTimeObject->Add( Minutes => $Param{Diff} );

            $Time = $DateTimeObject->ToEpoch();

            my $DateTimeValues = $DateTimeObject->Get();
            $Param{Sec}    = $DateTimeValues->{Second};
            $Param{Minute} = $DateTimeValues->{Minute};
            $Param{Hour}   = $DateTimeValues->{Hour};
            $Param{Day}    = $DateTimeValues->{Day};
            $Param{Month}  = $DateTimeValues->{Month};
            $Param{Year}   = $DateTimeValues->{Year};
        }
        else {
            # create datetime object
            my $DateTimeObject = $Kernel::OM->Create(
                'Kernel::System::DateTime',
                ObjectParams => {
                    String => "$Param{Year}-$Param{Month}-$Param{Day} $Param{Hour}:$Param{Minute}:00",
                }
            );
            return if !$DateTimeObject;
            $Time = $DateTimeObject->ToEpoch();
        }

        # return if no convert is possible
        return if !$Time;
    }

    # db update
    return if !$Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL => 'UPDATE ticket SET until_time = ?, change_time = current_timestamp, change_by = ?'
            . ' WHERE id = ?',
        Bind => [ \$Time, \$Param{UserID}, \$Param{TicketID} ],
    );

    # clear ticket cache
    $Self->_TicketCacheClear( TicketID => $Param{TicketID} );

    # history insert
    $Self->HistoryAdd(
        TicketID    => $Param{TicketID},
        HistoryType => 'SetPendingTime',
        Name        => '%%'
            . sprintf( "%02d", $Param{Year} ) . '-'
            . sprintf( "%02d", $Param{Month} ) . '-'
            . sprintf( "%02d", $Param{Day} ) . ' '
            . sprintf( "%02d", $Param{Hour} ) . ':'
            . sprintf( "%02d", $Param{Minute} ) . '',
        CreateUserID => $Param{UserID},
    );

    # trigger event
    $Self->EventHandler(
        Event => 'TicketPendingTimeUpdate',
        Data  => {
            TicketID => $Param{TicketID},
        },
        UserID => $Param{UserID},
    );

    return 1;
}

=head2 TicketLockGet()

check if a ticket is locked or not

    if ($TicketObject->TicketLockGet(TicketID => 123)) {
        print "Ticket is locked!\n";
    }
    else {
        print "Ticket is not locked!\n";
    }

=cut

sub TicketLockGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{TicketID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need TicketID!'
        );
        return;
    }

    my %Ticket = $Self->TicketGet(
        %Param,
        DynamicFields => 0,
    );

    # check lock state
    return 1 if lc $Ticket{Lock} eq 'lock';

    return;
}

=head2 TicketLockSet()

to lock or unlock a ticket

    my $Success = $TicketObject->TicketLockSet(
        Lock     => 'lock',
        TicketID => 123,
        UserID   => 123,
    );

    my $Success = $TicketObject->TicketLockSet(
        LockID   => 1,
        TicketID => 123,
        UserID   => 123,
    );

Optional attribute:
SendNoNotification, disable or enable agent and customer notification for this
action. Otherwise a notification will be sent to agent and customer.

For example:

        SendNoNotification => 0, # optional 1|0 (send no agent and customer notification)

Events:
    TicketLockUpdate

=cut

sub TicketLockSet {
    my ( $Self, %Param ) = @_;

    # lookup!
    if ( !$Param{LockID} && $Param{Lock} ) {

        $Param{LockID} = $Kernel::OM->Get('Kernel::System::Lock')->LockLookup(
            Lock => $Param{Lock},
        );
    }
    if ( $Param{LockID} && !$Param{Lock} ) {

        $Param{Lock} = $Kernel::OM->Get('Kernel::System::Lock')->LockLookup(
            LockID => $Param{LockID},
        );
    }

    # check needed stuff
    for my $Needed (qw(TicketID UserID LockID Lock)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }
    if ( !$Param{Lock} && !$Param{LockID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need LockID or Lock!'
        );
        return;
    }

    # check if update is needed
    my %Ticket = $Self->TicketGet(
        %Param,
        DynamicFields => 0,
    );
    return 1 if $Ticket{Lock} eq $Param{Lock};

    # db update
    return if !$Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL => 'UPDATE ticket SET ticket_lock_id = ?, '
            . ' change_time = current_timestamp, change_by = ? WHERE id = ?',
        Bind => [ \$Param{LockID}, \$Param{UserID}, \$Param{TicketID} ],
    );

    # clear ticket cache
    $Self->_TicketCacheClear( TicketID => $Param{TicketID} );

    # add history
    my $HistoryType = '';
    if ( lc $Param{Lock} eq 'unlock' ) {
        $HistoryType = 'Unlock';
    }
    elsif ( lc $Param{Lock} eq 'lock' ) {
        $HistoryType = 'Lock';
    }
    else {
        $HistoryType = 'Misc';
    }
    if ($HistoryType) {
        $Self->HistoryAdd(
            TicketID     => $Param{TicketID},
            CreateUserID => $Param{UserID},
            HistoryType  => $HistoryType,
            Name         => "\%\%$Param{Lock}",
        );
    }

    # set unlock time it event is 'lock'
    if ( $Param{Lock} eq 'lock' ) {

        # create datetime object
        my $DateTimeObject = $Kernel::OM->Create('Kernel::System::DateTime');

        $Self->TicketUnlockTimeoutUpdate(
            UnlockTimeout => $DateTimeObject->ToEpoch(),
            TicketID      => $Param{TicketID},
            UserID        => $Param{UserID},
        );
    }

    # send unlock notify
    if ( lc $Param{Lock} eq 'unlock' ) {

        my $Notification = defined $Param{Notification} ? $Param{Notification} : 1;
        if ( !$Param{SendNoNotification} && $Notification )
        {
            my @SkipRecipients;
            if ( $Ticket{OwnerID} eq $Param{UserID} ) {
                @SkipRecipients = [ $Param{UserID} ];
            }

            # trigger notification event
            $Self->EventHandler(
                Event          => 'NotificationLockTimeout',
                SkipRecipients => \@SkipRecipients,
                Data           => {
                    TicketID              => $Param{TicketID},
                    CustomerMessageParams => {},
                },
                UserID => $Param{UserID},
            );
        }
    }

    # trigger event
    $Self->EventHandler(
        Event => 'TicketLockUpdate',
        Data  => {
            TicketID => $Param{TicketID},
        },
        UserID => $Param{UserID},
    );

    return 1;
}

=head2 TicketArchiveFlagSet()

to set the ticket archive flag

    my $Success = $TicketObject->TicketArchiveFlagSet(
        ArchiveFlag => 'y',  # (y|n)
        TicketID    => 123,
        UserID      => 123,
    );

Events:
    TicketArchiveFlagUpdate

=cut

sub TicketArchiveFlagSet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(TicketID UserID ArchiveFlag)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    # get config object
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # return if feature is not enabled
    return if !$ConfigObject->Get('Ticket::ArchiveSystem');

    # check given archive flag
    if ( $Param{ArchiveFlag} ne 'y' && $Param{ArchiveFlag} ne 'n' ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "ArchiveFlag is invalid '$Param{ArchiveFlag}'!",
        );
        return;
    }

    # check if update is needed
    my %Ticket = $Self->TicketGet(
        %Param,
        DynamicFields => 0,
    );

    # return if no update is needed
    return 1 if $Ticket{ArchiveFlag} && $Ticket{ArchiveFlag} eq $Param{ArchiveFlag};

    # translate archive flag
    my $ArchiveFlag = $Param{ArchiveFlag} eq 'y' ? 1 : 0;

    # set new archive flag
    return if !$Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL => '
            UPDATE ticket
            SET archive_flag = ?, change_time = current_timestamp, change_by = ?
            WHERE id = ?',
        Bind => [ \$ArchiveFlag, \$Param{UserID}, \$Param{TicketID} ],
    );

    # clear ticket cache
    $Self->_TicketCacheClear( TicketID => $Param{TicketID} );

    # Remove seen flags from ticket and article and ticket watcher data if configured
    #   and if the ticket flag was just set.
    if ($ArchiveFlag) {

        if ( $ConfigObject->Get('Ticket::ArchiveSystem::RemoveSeenFlags') ) {
            $Self->TicketFlagDelete(
                TicketID => $Param{TicketID},
                Key      => 'Seen',
                AllUsers => 1,
            );

            my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');

            my @Articles = $ArticleObject->ArticleList( TicketID => $Param{TicketID} );
            for my $Article (@Articles) {
                $ArticleObject->ArticleFlagDelete(
                    TicketID  => $Param{TicketID},
                    ArticleID => $Article->{ArticleID},
                    Key       => 'Seen',
                    AllUsers  => 1,
                );
            }
        }

        if (
            $ConfigObject->Get('Ticket::ArchiveSystem::RemoveTicketWatchers')
            && $ConfigObject->Get('Ticket::Watcher')
            )
        {
            $Self->TicketWatchUnsubscribe(
                TicketID => $Param{TicketID},
                AllUsers => 1,
                UserID   => $Param{UserID},
            );
        }
    }

    # add history
    $Self->HistoryAdd(
        TicketID     => $Param{TicketID},
        CreateUserID => $Param{UserID},
        HistoryType  => 'ArchiveFlagUpdate',
        Name         => "\%\%$Param{ArchiveFlag}",
    );

    # trigger event
    $Self->EventHandler(
        Event => 'TicketArchiveFlagUpdate',
        Data  => {
            TicketID => $Param{TicketID},
        },
        UserID => $Param{UserID},
    );

    return 1;
}

=head2 TicketArchiveFlagGet()

check if a ticket is archived or not

    if ( $TicketObject->TicketArchiveFlagGet( TicketID => 123 ) ) {
        print "Ticket is archived!\n";
    }
    else {
        print "Ticket is not archived!\n";
    }

=cut

sub TicketArchiveFlagGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{TicketID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need TicketID!'
        );
        return;
    }

    my %Ticket = $Self->TicketGet(
        %Param,
        DynamicFields => 0,
    );

    # check archive state
    return 1 if lc $Ticket{ArchiveFlag} eq 'y';

    return;
}

=head2 TicketStateSet()

to set a ticket state

    my $Success = $TicketObject->TicketStateSet(
        State     => 'open',
        TicketID  => 123,
        ArticleID => 123, #optional, for history
        UserID    => 123,
    );

    my $Success = $TicketObject->TicketStateSet(
        StateID  => 3,
        TicketID => 123,
        UserID   => 123,
    );

Optional attribute:
SendNoNotification, disable or enable agent and customer notification for this
action. Otherwise a notification will be sent to agent and customer.

For example:

        SendNoNotification => 0, # optional 1|0 (send no agent and customer notification)

Events:
    TicketStateUpdate

=cut

sub TicketStateSet {
    my ( $Self, %Param ) = @_;

    my %State;
    my $ArticleID = $Param{ArticleID} || '';

    # check needed stuff
    for my $Needed (qw(TicketID UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }
    if ( !$Param{State} && !$Param{StateID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need StateID or State!'
        );
        return;
    }

    # get state object
    my $StateObject = $Kernel::OM->Get('Kernel::System::State');

    # state id lookup
    if ( !$Param{StateID} ) {
        %State = $StateObject->StateGet( Name => $Param{State} );
    }

    # state lookup
    if ( !$Param{State} ) {
        %State = $StateObject->StateGet( ID => $Param{StateID} );
    }
    if ( !%State ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need StateID or State!'
        );
        return;
    }

    # check if update is needed
    my %Ticket = $Self->TicketGet(
        TicketID      => $Param{TicketID},
        DynamicFields => 0,
    );
    if ( $State{Name} eq $Ticket{State} ) {

        # update is not needed
        return 1;
    }

    # permission check
    my %StateList = $Self->StateList(%Param);
    if ( !$StateList{ $State{ID} } ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'notice',
            Message  => "Permission denied on TicketID: $Param{TicketID} / StateID: $State{ID}!",
        );
        return;
    }

    # db update
    return if !$Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL => 'UPDATE ticket SET ticket_state_id = ?, '
            . ' change_time = current_timestamp, change_by = ? WHERE id = ?',
        Bind => [ \$State{ID}, \$Param{UserID}, \$Param{TicketID} ],
    );

    # clear ticket cache
    $Self->_TicketCacheClear( TicketID => $Param{TicketID} );

    # add history
    $Self->HistoryAdd(
        TicketID     => $Param{TicketID},
        StateID      => $State{ID},
        ArticleID    => $ArticleID,
        QueueID      => $Ticket{QueueID},
        Name         => "\%\%$Ticket{State}\%\%$State{Name}\%\%",
        HistoryType  => 'StateUpdate',
        CreateUserID => $Param{UserID},
    );

    # trigger event, OldTicketData is needed for escalation events
    $Self->EventHandler(
        Event => 'TicketStateUpdate',
        Data  => {
            TicketID      => $Param{TicketID},
            OldTicketData => \%Ticket,
        },
        UserID => $Param{UserID},
    );

    return 1;
}

=head2 TicketStateList()

to get the state list for a ticket (depends on workflow, if configured)

    my %States = $TicketObject->TicketStateList(
        TicketID => 123,
        UserID   => 123,
    );

    my %States = $TicketObject->TicketStateList(
        TicketID       => 123,
        CustomerUserID => 'customer_user_id_123',
    );

    my %States = $TicketObject->TicketStateList(
        QueueID => 123,
        UserID  => 123,
    );

    my %States = $TicketObject->TicketStateList(
        TicketID => 123,
        Type     => 'open',
        UserID   => 123,
    );

Returns:

    %States = (
        1 => 'State A',
        2 => 'State B',
        3 => 'State C',
    );

=cut

sub TicketStateList {
    my ( $Self, %Param ) = @_;

    my %States;

    # check needed stuff
    if ( !$Param{UserID} && !$Param{CustomerUserID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need UserID or CustomerUserID!'
        );
        return;
    }

    # check needed stuff
    if ( !$Param{QueueID} && !$Param{TicketID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need QueueID, TicketID!'
        );
        return;
    }

    # get config object
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # get state object
    my $StateObject = $Kernel::OM->Get('Kernel::System::State');

    # get states by type
    if ( $Param{Type} ) {
        %States = $StateObject->StateGetStatesByType(
            Type   => $Param{Type},
            Result => 'HASH',
        );
    }
    elsif ( $Param{Action} ) {

        if (
            ref $ConfigObject->Get("Ticket::Frontend::$Param{Action}")->{StateType} ne
            'ARRAY'
            )
        {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need config for Ticket::Frontend::$Param{Action}->StateType!"
            );
            return;
        }

        my @StateType = @{ $ConfigObject->Get("Ticket::Frontend::$Param{Action}")->{StateType} };
        %States = $StateObject->StateGetStatesByType(
            StateType => \@StateType,
            Result    => 'HASH',
        );
    }

    # get whole states list
    else {
        %States = $StateObject->StateList(
            UserID => $Param{UserID},
        );
    }

    # workflow
    my $ACL = $Self->TicketAcl(
        %Param,
        ReturnType    => 'Ticket',
        ReturnSubType => 'State',
        Data          => \%States,
    );

    return $Self->TicketAclData() if $ACL;
    return %States;
}

=head2 OwnerCheck()

to get the ticket owner

    my ($OwnerID, $Owner) = $TicketObject->OwnerCheck(
        TicketID => 123,
    );

or for access control

    my $AccessOk = $TicketObject->OwnerCheck(
        TicketID => 123,
        OwnerID  => 321,
    );

=cut

sub OwnerCheck {
    my ( $Self, %Param ) = @_;

    my $SQL = '';

    # check needed stuff
    if ( !$Param{TicketID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need TicketID!'
        );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # db query
    if ( $Param{OwnerID} ) {

        # create cache key
        my $CacheKey = $Param{TicketID} . '::' . $Param{OwnerID};

        # check cache
        if ( defined $Self->{OwnerCheck}->{$CacheKey} ) {
            return   if !$Self->{OwnerCheck}->{$CacheKey};
            return 1 if $Self->{OwnerCheck}->{$CacheKey};
        }

        # check if user has access
        return if !$DBObject->Prepare(
            SQL => 'SELECT user_id FROM ticket WHERE '
                . ' id = ? AND (user_id = ? OR responsible_user_id = ?)',
            Bind => [ \$Param{TicketID}, \$Param{OwnerID}, \$Param{OwnerID}, ],
        );
        my $Access = 0;
        while ( my @Row = $DBObject->FetchrowArray() ) {
            $Access = 1;
        }

        # fill cache
        $Self->{OwnerCheck}->{$CacheKey} = $Access;
        return   if !$Access;
        return 1 if $Access;
    }

    # get config object
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # search for owner_id and owner
    return if !$DBObject->Prepare(
        SQL => "SELECT st.user_id, su.$ConfigObject->{DatabaseUserTableUser} "
            . " FROM ticket st, $ConfigObject->{DatabaseUserTable} su "
            . " WHERE st.id = ? AND "
            . " st.user_id = su.$ConfigObject->{DatabaseUserTableUserID}",
        Bind => [ \$Param{TicketID}, ],
    );

    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Param{SearchUserID} = $Row[0];
        $Param{SearchUser}   = $Row[1];
    }

    # return if no owner as been found
    return if !$Param{SearchUserID};

    # return owner id and owner
    return $Param{SearchUserID}, $Param{SearchUser};
}

=head2 TicketOwnerSet()

to set the ticket owner (notification to the new owner will be sent)

by using user id

    my $Success = $TicketObject->TicketOwnerSet(
        TicketID  => 123,
        NewUserID => 555,
        UserID    => 123,
    );

by using user login

    my $Success = $TicketObject->TicketOwnerSet(
        TicketID => 123,
        NewUser  => 'some-user-login',
        UserID   => 123,
    );

Return:
    1 = owner has been set
    2 = this owner is already set, no update needed

Optional attribute:
SendNoNotification, disable or enable agent and customer notification for this
action. Otherwise a notification will be sent to agent and customer.

For example:

        SendNoNotification => 0, # optional 1|0 (send no agent and customer notification)

Events:
    TicketOwnerUpdate

=cut

sub TicketOwnerSet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(TicketID UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }
    if ( !$Param{NewUserID} && !$Param{NewUser} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need NewUserID or NewUser!'
        );
        return;
    }

    # get user object
    my $UserObject = $Kernel::OM->Get('Kernel::System::User');

    # lookup if no NewUserID is given
    if ( !$Param{NewUserID} ) {
        $Param{NewUserID} = $UserObject->UserLookup(
            UserLogin => $Param{NewUser},
        );
    }

    # lookup if no NewUser is given
    if ( !$Param{NewUser} ) {
        $Param{NewUser} = $UserObject->UserLookup(
            UserID => $Param{NewUserID},
        );
    }

    # make sure the user exists
    if ( !$UserObject->UserLookup( UserID => $Param{NewUserID} ) ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "User does not exist.",
        );
        return;
    }

    # check if update is needed!
    my ( $OwnerID, $Owner ) = $Self->OwnerCheck( TicketID => $Param{TicketID} );
    if ( $OwnerID eq $Param{NewUserID} ) {

        # update is "not" needed!
        return 2;
    }

    # db update
    return if !$Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL => 'UPDATE ticket SET '
            . ' user_id = ?, change_time = current_timestamp, change_by = ? WHERE id = ?',
        Bind => [ \$Param{NewUserID}, \$Param{UserID}, \$Param{TicketID} ],
    );

    # clear ticket cache
    $Self->_TicketCacheClear( TicketID => $Param{TicketID} );

    # add history
    $Self->HistoryAdd(
        TicketID     => $Param{TicketID},
        CreateUserID => $Param{UserID},
        HistoryType  => 'OwnerUpdate',
        Name         => "\%\%$Param{NewUser}\%\%$Param{NewUserID}",
    );

    # send agent notify
    if ( !$Param{SendNoNotification} ) {

        my @SkipRecipients;
        if ( $Param{UserID} eq $Param{NewUserID} ) {
            @SkipRecipients = [ $Param{UserID} ];
        }

        # trigger notification event
        $Self->EventHandler(
            Event => 'NotificationOwnerUpdate',
            Data  => {
                TicketID              => $Param{TicketID},
                SkipRecipients        => \@SkipRecipients,
                CustomerMessageParams => {
                    %Param,
                    Body => $Param{Comment} || '',
                },
            },
            UserID => $Param{UserID},
        );
    }

    # trigger event
    $Self->EventHandler(
        Event => 'TicketOwnerUpdate',
        Data  => {
            TicketID => $Param{TicketID},
        },
        UserID => $Param{UserID},
    );

    return 1;
}

=head2 TicketOwnerList()

returns the owner in the past as array with hash ref of the owner data
(name, email, ...)

    my @Owner = $TicketObject->TicketOwnerList(
        TicketID => 123,
    );

Returns:

    @Owner = (
        {
            UserFirstname => 'SomeName',
            UserLastname  => 'SomeName',
            UserEmail     => 'some@example.com',
            # custom attributes
        },
        {
            UserFirstname => 'SomeName',
            UserLastname  => 'SomeName',
            UserEmail     => 'some@example.com',
            # custom attributes
        },
    );

=cut

sub TicketOwnerList {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{TicketID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Need TicketID!"
        );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # db query
    return if !$DBObject->Prepare(
        SQL => 'SELECT sh.owner_id FROM ticket_history sh, ticket_history_type ht WHERE '
            . ' sh.ticket_id = ? AND ht.name IN (\'OwnerUpdate\', \'NewTicket\') AND '
            . ' ht.id = sh.history_type_id ORDER BY sh.id',
        Bind => [ \$Param{TicketID} ],
    );
    my @UserID;

    USER:
    while ( my @Row = $DBObject->FetchrowArray() ) {
        next USER if !$Row[0];
        next USER if $Row[0] eq 1;
        push @UserID, $Row[0];
    }

    # get user object
    my $UserObject = $Kernel::OM->Get('Kernel::System::User');

    my @UserInfo;
    USER:
    for my $UserID (@UserID) {

        my %User = $UserObject->GetUserData(
            UserID => $UserID,
            Cache  => 1,
            Valid  => 1,
        );

        next USER if !%User;

        push @UserInfo, \%User;
    }

    return @UserInfo;
}

=head2 TicketResponsibleSet()

to set the ticket responsible (notification to the new responsible will be sent)

by using user id

    my $Success = $TicketObject->TicketResponsibleSet(
        TicketID  => 123,
        NewUserID => 555,
        UserID    => 213,
    );

by using user login

    my $Success = $TicketObject->TicketResponsibleSet(
        TicketID  => 123,
        NewUser   => 'some-user-login',
        UserID    => 213,
    );

Return:
    1 = responsible has been set
    2 = this responsible is already set, no update needed

Optional attribute:
SendNoNotification, disable or enable agent and customer notification for this
action. Otherwise a notification will be sent to agent and customer.

For example:

        SendNoNotification => 0, # optional 1|0 (send no agent and customer notification)

Events:
    TicketResponsibleUpdate

=cut

sub TicketResponsibleSet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(TicketID UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }
    if ( !$Param{NewUserID} && !$Param{NewUser} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need NewUserID or NewUser!'
        );
        return;
    }

    # get user object
    my $UserObject = $Kernel::OM->Get('Kernel::System::User');

    # lookup if no NewUserID is given
    if ( !$Param{NewUserID} ) {
        $Param{NewUserID} = $UserObject->UserLookup( UserLogin => $Param{NewUser} );
    }

    # lookup if no NewUser is given
    if ( !$Param{NewUser} ) {
        $Param{NewUser} = $UserObject->UserLookup( UserID => $Param{NewUserID} );
    }

    # make sure the user exists
    if ( !$UserObject->UserLookup( UserID => $Param{NewUserID} ) ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "User does not exist.",
        );
        return;
    }

    # check if update is needed!
    my %Ticket = $Self->TicketGet(
        TicketID      => $Param{TicketID},
        UserID        => $Param{NewUserID},
        DynamicFields => 0,
    );
    if ( $Ticket{ResponsibleID} eq $Param{NewUserID} ) {

        # update is "not" needed!
        return 2;
    }

    # db update
    return if !$Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL => 'UPDATE ticket SET responsible_user_id = ?, '
            . ' change_time = current_timestamp, change_by = ? '
            . ' WHERE id = ?',
        Bind => [ \$Param{NewUserID}, \$Param{UserID}, \$Param{TicketID} ],
    );

    # clear ticket cache
    $Self->_TicketCacheClear( TicketID => $Param{TicketID} );

    # add history
    $Self->HistoryAdd(
        TicketID     => $Param{TicketID},
        CreateUserID => $Param{UserID},
        HistoryType  => 'ResponsibleUpdate',
        Name         => "\%\%$Param{NewUser}\%\%$Param{NewUserID}",
    );

    # send agent notify
    if ( !$Param{SendNoNotification} ) {

        my @SkipRecipients;
        if ( $Param{UserID} eq $Param{NewUserID} ) {
            @SkipRecipients = [ $Param{UserID} ];
        }

        # trigger notification event
        $Self->EventHandler(
            Event => 'NotificationResponsibleUpdate',
            Data  => {
                TicketID              => $Param{TicketID},
                SkipRecipients        => \@SkipRecipients,
                CustomerMessageParams => \%Param,
            },
            UserID => $Param{UserID},
        );
    }

    # trigger event
    $Self->EventHandler(
        Event => 'TicketResponsibleUpdate',
        Data  => {
            TicketID => $Param{TicketID},
        },
        UserID => $Param{UserID},
    );

    return 1;
}

=head2 TicketResponsibleList()

returns the responsible in the past as array with hash ref of the owner data
(name, email, ...)

    my @Responsible = $TicketObject->TicketResponsibleList(
        TicketID => 123,
    );

Returns:

    @Responsible = (
        {
            UserFirstname => 'SomeName',
            UserLastname  => 'SomeName',
            UserEmail     => 'some@example.com',
            # custom attributes
        },
        {
            UserFirstname => 'SomeName',
            UserLastname  => 'SomeName',
            UserEmail     => 'some@example.com',
            # custom attributes
        },
    );

=cut

sub TicketResponsibleList {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{TicketID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Need TicketID!"
        );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # db query
    my @User;
    my $LastResponsible = 1;
    return if !$DBObject->Prepare(
        SQL => 'SELECT sh.name, ht.name, sh.create_by FROM '
            . ' ticket_history sh, ticket_history_type ht WHERE '
            . ' sh.ticket_id = ? AND '
            . ' ht.name IN (\'ResponsibleUpdate\', \'NewTicket\') AND '
            . ' ht.id = sh.history_type_id ORDER BY sh.id',
        Bind => [ \$Param{TicketID} ],
    );

    while ( my @Row = $DBObject->FetchrowArray() ) {

        # store result
        if ( $Row[1] eq 'NewTicket' && $Row[2] ne '1' && $LastResponsible ne $Row[2] ) {
            $LastResponsible = $Row[2];
            push @User, $Row[2];
        }
        elsif ( $Row[1] eq 'ResponsibleUpdate' ) {
            if (
                $Row[0] =~ /^New Responsible is '(.+?)' \(ID=(.+?)\)/
                || $Row[0] =~ /^\%\%(.+?)\%\%(.+?)$/
                )
            {
                $LastResponsible = $2;
                push @User, $2;
            }
        }
    }

    # get user object
    my $UserObject = $Kernel::OM->Get('Kernel::System::User');

    my @UserInfo;
    for my $SingleUser (@User) {

        my %User = $UserObject->GetUserData(
            UserID => $SingleUser,
            Cache  => 1
        );
        push @UserInfo, \%User;
    }

    return @UserInfo;
}

=head2 TicketInvolvedAgentsList()

returns an array with hash ref of agents which have been involved with a ticket.
It is guaranteed that no agent is returned twice.

    my @InvolvedAgents = $TicketObject->TicketInvolvedAgentsList(
        TicketID => 123,
    );

Returns:

    @InvolvedAgents = (
        {
            UserFirstname => 'SomeName',
            UserLastname  => 'SomeName',
            UserEmail     => 'some@example.com',
            # custom attributes
        },
        {
            UserFirstname => 'AnotherName',
            UserLastname  => 'AnotherName',
            UserEmail     => 'another@example.com',
            # custom attributes
        },
    );

=cut

sub TicketInvolvedAgentsList {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{TicketID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need TicketID!'
        );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # db query, only entries with a known history_id are retrieved
    my @User;
    my %UsedOwner;
    return if !$DBObject->Prepare(
        SQL => ''
            . 'SELECT sh.create_by'
            . ' FROM ticket_history sh, ticket_history_type ht'
            . ' WHERE sh.ticket_id = ?'
            . ' AND ht.id = sh.history_type_id'
            . ' ORDER BY sh.id',
        Bind => [ \$Param{TicketID} ],
    );

    while ( my @Row = $DBObject->FetchrowArray() ) {

        # store result, skip the
        if ( $Row[0] ne 1 && !$UsedOwner{ $Row[0] } ) {
            $UsedOwner{ $Row[0] } = $Row[0];
            push @User, $Row[0];
        }
    }

    # get user object
    my $UserObject = $Kernel::OM->Get('Kernel::System::User');

    # collect agent information
    my @UserInfo;
    USER:
    for my $SingleUser (@User) {

        my %User = $UserObject->GetUserData(
            UserID => $SingleUser,
            Valid  => 1,
            Cache  => 1,
        );

        next USER if !%User;

        push @UserInfo, \%User;
    }

    return @UserInfo;
}

=head2 TicketPrioritySet()

to set the ticket priority

    my $Success = $TicketObject->TicketPrioritySet(
        TicketID => 123,
        Priority => 'low',
        UserID   => 213,
    );

    my $Success = $TicketObject->TicketPrioritySet(
        TicketID   => 123,
        PriorityID => 2,
        UserID     => 213,
    );

Events:
    TicketPriorityUpdate

=cut

sub TicketPrioritySet {
    my ( $Self, %Param ) = @_;

    # get priority object
    my $PriorityObject = $Kernel::OM->Get('Kernel::System::Priority');

    # lookup!
    if ( !$Param{PriorityID} && $Param{Priority} ) {
        $Param{PriorityID} = $PriorityObject->PriorityLookup(
            Priority => $Param{Priority},
        );
    }
    if ( $Param{PriorityID} && !$Param{Priority} ) {
        $Param{Priority} = $PriorityObject->PriorityLookup(
            PriorityID => $Param{PriorityID},
        );
    }

    # check needed stuff
    for my $Needed (qw(TicketID UserID PriorityID Priority)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }
    my %Ticket = $Self->TicketGet(
        %Param,
        DynamicFields => 0,
    );

    # check if update is needed
    if ( $Ticket{Priority} eq $Param{Priority} ) {

        # update not needed
        return 1;
    }

    # permission check
    my %PriorityList = $Self->PriorityList(%Param);
    if ( !$PriorityList{ $Param{PriorityID} } ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'notice',
            Message  => "Permission denied on TicketID: $Param{TicketID}!",
        );
        return;
    }

    # db update
    return if !$Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL => 'UPDATE ticket SET ticket_priority_id = ?, '
            . ' change_time = current_timestamp, change_by = ?'
            . ' WHERE id = ?',
        Bind => [ \$Param{PriorityID}, \$Param{UserID}, \$Param{TicketID} ],
    );

    # clear ticket cache
    $Self->_TicketCacheClear( TicketID => $Param{TicketID} );

    # add history
    $Self->HistoryAdd(
        TicketID     => $Param{TicketID},
        QueueID      => $Ticket{QueueID},
        CreateUserID => $Param{UserID},
        HistoryType  => 'PriorityUpdate',
        Name         => "\%\%$Ticket{Priority}\%\%$Ticket{PriorityID}"
            . "\%\%$Param{Priority}\%\%$Param{PriorityID}",
    );

    # trigger event
    $Self->EventHandler(
        Event => 'TicketPriorityUpdate',
        Data  => {
            TicketID => $Param{TicketID},
        },
        UserID => $Param{UserID},
    );

    return 1;
}

=head2 TicketPriorityList()

to get the priority list for a ticket (depends on workflow, if configured)

    my %Priorities = $TicketObject->TicketPriorityList(
        TicketID => 123,
        UserID   => 123,
    );

    my %Priorities = $TicketObject->TicketPriorityList(
        TicketID       => 123,
        CustomerUserID => 'customer_user_id_123',
    );

    my %Priorities = $TicketObject->TicketPriorityList(
        QueueID => 123,
        UserID  => 123,
    );

Returns:

    %Priorities = (
        1 => 'Priority A',
        2 => 'Priority B',
        3 => 'Priority C',
    );

=cut

sub TicketPriorityList {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{UserID} && !$Param{CustomerUserID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need UserID or CustomerUserID!'
        );
        return;
    }

    my %Data = $Kernel::OM->Get('Kernel::System::Priority')->PriorityList(%Param);

    # workflow
    my $ACL = $Self->TicketAcl(
        %Param,
        ReturnType    => 'Ticket',
        ReturnSubType => 'Priority',
        Data          => \%Data,
    );

    return $Self->TicketAclData() if $ACL;
    return %Data;
}

=head2 HistoryTicketStatusGet()

get a hash with ticket id as key and a hash ref (result of HistoryTicketGet)
of all affected tickets in this time area.

    my %Tickets = $TicketObject->HistoryTicketStatusGet(
        StartDay   => 12,
        StartMonth => 1,
        StartYear  => 2006,
        StopDay    => 18,
        StopMonth  => 1,
        StopYear   => 2006,
        Force      => 0,
    );

=cut

sub HistoryTicketStatusGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(StopYear StopMonth StopDay StartYear StartMonth StartDay)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    # format month and day params
    for my $DateParameter (qw(StopMonth StopDay StartMonth StartDay)) {
        $Param{$DateParameter} = sprintf( "%02d", $Param{$DateParameter} );
    }

    my $SQLExt = '';
    for my $HistoryTypeData (
        qw(NewTicket FollowUp OwnerUpdate PriorityUpdate CustomerUpdate StateUpdate
        PhoneCallCustomer Forward Bounce SendAnswer EmailCustomer
        PhoneCallAgent WebRequestCustomer TicketDynamicFieldUpdate)
        )
    {
        my $ID = $Self->HistoryTypeLookup( Type => $HistoryTypeData );
        if ( !$SQLExt ) {
            $SQLExt = "AND history_type_id IN ($ID";
        }
        else {
            $SQLExt .= ",$ID";
        }
    }

    if ($SQLExt) {
        $SQLExt .= ')';
    }

    # assemble stop date/time string for database comparison
    my $StopDateTimeObject = $Kernel::OM->Create(
        'Kernel::System::DateTime',
        ObjectParams => {
            String => "$Param{StopYear}-$Param{StopMonth}-$Param{StopDay} 00:00:00",
        }
    );
    $StopDateTimeObject->Add( Hours => 24 );
    my $StopDateTimeString = $StopDateTimeObject->Format( Format => '%Y-%m-%d 00:00:00' );

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Prepare(
        SQL => "
            SELECT DISTINCT(th.ticket_id), th.create_time
            FROM ticket_history th
            WHERE th.create_time <= '$StopDateTimeString'
                AND th.create_time >= '$Param{StartYear}-$Param{StartMonth}-$Param{StartDay} 00:00:01'
                $SQLExt
            ORDER BY th.create_time DESC",
        Limit => 150000,
    );

    my %Ticket;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Ticket{ $Row[0] } = 1;
    }

    for my $TicketID ( sort keys %Ticket ) {

        my %TicketData = $Self->HistoryTicketGet(
            TicketID  => $TicketID,
            StopYear  => $Param{StopYear},
            StopMonth => $Param{StopMonth},
            StopDay   => $Param{StopDay},
            Force     => $Param{Force} || 0,
        );

        if (%TicketData) {
            $Ticket{$TicketID} = \%TicketData;
        }
        else {
            $Ticket{$TicketID} = {};
        }
    }

    return %Ticket;
}

=head2 HistoryTicketGet()

returns a hash of some of the ticket data
calculated based on ticket history info at the given date.

    my %HistoryData = $TicketObject->HistoryTicketGet(
        StopYear   => 2003,
        StopMonth  => 12,
        StopDay    => 24,
        StopHour   => 10, (optional, default 23)
        StopMinute => 0,  (optional, default 59)
        StopSecond => 0,  (optional, default 59)
        TicketID   => 123,
        Force      => 0,     # 1: don't use cache
    );

returns

    TicketNumber
    TicketID
    Type
    TypeID
    Queue
    QueueID
    Priority
    PriorityID
    State
    StateID
    Owner
    OwnerID
    CreateUserID
    CreateTime (timestamp)
    CreateOwnerID
    CreatePriority
    CreatePriorityID
    CreateState
    CreateStateID
    CreateQueue
    CreateQueueID
    LockFirst (timestamp)
    LockLast (timestamp)
    UnlockFirst (timestamp)
    UnlockLast (timestamp)

=cut

sub HistoryTicketGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(TicketID StopYear StopMonth StopDay)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }
    $Param{StopHour}   = defined $Param{StopHour}   ? $Param{StopHour}   : '23';
    $Param{StopMinute} = defined $Param{StopMinute} ? $Param{StopMinute} : '59';
    $Param{StopSecond} = defined $Param{StopSecond} ? $Param{StopSecond} : '59';

    # format month and day params
    for my $DateParameter (qw(StopMonth StopDay)) {
        $Param{$DateParameter} = sprintf( "%02d", $Param{$DateParameter} );
    }

    my $CacheKey = 'HistoryTicketGet::'
        . join( '::', map { ( $_ || 0 ) . "::$Param{$_}" } sort keys %Param );

    my $Cached = $Kernel::OM->Get('Kernel::System::Cache')->Get(
        Type => $Self->{CacheType},
        Key  => $CacheKey,
    );
    if ( ref $Cached eq 'HASH' && !$Param{Force} ) {
        return %{$Cached};
    }

    my $Time
        = "$Param{StopYear}-$Param{StopMonth}-$Param{StopDay} $Param{StopHour}:$Param{StopMinute}:$Param{StopSecond}";

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Prepare(
        SQL => '
            SELECT th.name, tht.name, th.create_time, th.create_by, th.ticket_id,
                th.article_id, th.queue_id, th.state_id, th.priority_id, th.owner_id, th.type_id
            FROM ticket_history th, ticket_history_type tht
            WHERE th.history_type_id = tht.id
                AND th.ticket_id = ?
                AND th.create_time <= ?
            ORDER BY th.create_time, th.id ASC',
        Bind  => [ \$Param{TicketID}, \$Time ],
        Limit => 3000,
    );

    my %Ticket;
    while ( my @Row = $DBObject->FetchrowArray() ) {

        if ( $Row[1] eq 'NewTicket' ) {
            if (
                $Row[0] =~ /^\%\%(.+?)\%\%(.+?)\%\%(.+?)\%\%(.+?)\%\%(.+?)$/
                || $Row[0] =~ /Ticket=\[(.+?)\],.+?Q\=(.+?);P\=(.+?);S\=(.+?)/
                )
            {
                $Ticket{TicketNumber}   = $1;
                $Ticket{Queue}          = $2;
                $Ticket{CreateQueue}    = $2;
                $Ticket{Priority}       = $3;
                $Ticket{CreatePriority} = $3;
                $Ticket{State}          = $4;
                $Ticket{CreateState}    = $4;
                $Ticket{TicketID}       = $Row[4];
                $Ticket{Owner}          = 'root';
                $Ticket{CreateUserID}   = $Row[3];
                $Ticket{CreateTime}     = $Row[2];
            }
            else {

                # COMPAT: compat to 1.1
                # NewTicket
                $Ticket{TicketVersion} = '1.1';
                $Ticket{TicketID}      = $Row[4];
                $Ticket{CreateUserID}  = $Row[3];
                $Ticket{CreateTime}    = $Row[2];
            }
            $Ticket{CreateOwnerID}    = $Row[9] || '';
            $Ticket{CreatePriorityID} = $Row[8] || '';
            $Ticket{CreateStateID}    = $Row[7] || '';
            $Ticket{CreateQueueID}    = $Row[6] || '';
        }

        # COMPAT: compat to 1.1
        elsif ( $Row[1] eq 'PhoneCallCustomer' ) {
            $Ticket{TicketVersion} = '1.1';
            $Ticket{TicketID}      = $Row[4];
            $Ticket{CreateUserID}  = $Row[3];
            $Ticket{CreateTime}    = $Row[2];
        }
        elsif ( $Row[1] eq 'Move' ) {
            if (
                $Row[0] =~ /^\%\%(.+?)\%\%(.+?)\%\%(.+?)\%\%(.+?)/
                || $Row[0] =~ /^Ticket moved to Queue '(.+?)'/
                )
            {
                $Ticket{Queue} = $1;
            }
        }
        elsif (
            $Row[1] eq 'StateUpdate'
            || $Row[1] eq 'Close successful'
            || $Row[1] eq 'Close unsuccessful'
            || $Row[1] eq 'Open'
            || $Row[1] eq 'Misc'
            )
        {
            if (
                $Row[0]    =~ /^\%\%(.+?)\%\%(.+?)(\%\%|)$/
                || $Row[0] =~ /^Old: '(.+?)' New: '(.+?)'/
                || $Row[0] =~ /^Changed Ticket State from '(.+?)' to '(.+?)'/
                )
            {
                $Ticket{State}     = $2;
                $Ticket{StateTime} = $Row[2];
            }
        }
        elsif ( $Row[1] eq 'TicketFreeTextUpdate' ) {
            if ( $Row[0] =~ /^\%\%(.+?)\%\%(.+?)\%\%(.+?)\%\%(.+?)$/ ) {
                $Ticket{ 'Ticket' . $1 } = $2;
                $Ticket{ 'Ticket' . $3 } = $4;
                $Ticket{$1}              = $2;
                $Ticket{$3}              = $4;
            }
        }
        elsif ( $Row[1] eq 'TicketDynamicFieldUpdate' ) {

            # take care about different values between 3.3 and 4
            # 3.x: %%FieldName%%test%%Value%%TestValue1
            # 4.x: %%FieldName%%test%%Value%%TestValue1%%OldValue%%OldTestValue1
            if ( $Row[0] =~ /^\%\%FieldName\%\%(.+?)\%\%Value\%\%(.*?)(?:\%\%|$)/ ) {

                my $FieldName = $1;
                my $Value     = $2 || '';
                $Ticket{$FieldName} = $Value;

                # Backward compatibility for TicketFreeText and TicketFreeTime
                if ( $FieldName =~ /^Ticket(Free(?:Text|Key)(?:[?:1[0-6]|[1-9]))$/ ) {

                    # Remove the leading Ticket on field name
                    my $FreeFieldName = $1;
                    $Ticket{$FreeFieldName} = $Value;
                }
            }
        }
        elsif ( $Row[1] eq 'PriorityUpdate' ) {
            if ( $Row[0] =~ /^\%\%(.+?)\%\%(.+?)\%\%(.+?)\%\%(.+?)/ ) {
                $Ticket{Priority} = $3;
            }
        }
        elsif ( $Row[1] eq 'OwnerUpdate' ) {
            if ( $Row[0] =~ /^\%\%(.+?)\%\%(.+?)/ || $Row[0] =~ /^New Owner is '(.+?)'/ ) {
                $Ticket{Owner} = $1;
            }
        }
        elsif ( $Row[1] eq 'Lock' ) {
            if ( !$Ticket{LockFirst} ) {
                $Ticket{LockFirst} = $Row[2];
            }
            $Ticket{LockLast} = $Row[2];
        }
        elsif ( $Row[1] eq 'Unlock' ) {
            if ( !$Ticket{UnlockFirst} ) {
                $Ticket{UnlockFirst} = $Row[2];
            }
            $Ticket{UnlockLast} = $Row[2];
        }

        # get default options
        $Ticket{TypeID}     = $Row[10] || '';
        $Ticket{OwnerID}    = $Row[9]  || '';
        $Ticket{PriorityID} = $Row[8]  || '';
        $Ticket{StateID}    = $Row[7]  || '';
        $Ticket{QueueID}    = $Row[6]  || '';
    }
    if ( !%Ticket ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'notice',
            Message  => "No such TicketID in ticket history till "
                . "'$Param{StopYear}-$Param{StopMonth}-$Param{StopDay} $Param{StopHour}:$Param{StopMinute}:$Param{StopSecond}' ($Param{TicketID})!",
        );
        return;
    }

    # update old ticket info
    my %CurrentTicketData = $Self->TicketGet(
        TicketID      => $Ticket{TicketID},
        DynamicFields => 0,
    );
    for my $TicketAttribute (qw(State Priority Queue TicketNumber)) {
        if ( !$Ticket{$TicketAttribute} ) {
            $Ticket{$TicketAttribute} = $CurrentTicketData{$TicketAttribute};
        }
        if ( !$Ticket{"Create$TicketAttribute"} ) {
            $Ticket{"Create$TicketAttribute"} = $CurrentTicketData{$TicketAttribute};
        }
    }

    # create datetime object
    my $DateTimeObject = $Kernel::OM->Create('Kernel::System::DateTime');

    # check if we should cache this ticket data
    my $DateTimeValues = $DateTimeObject->Get();

    # if the request is for the last month or older, cache it
    if ( int $DateTimeValues->{Year} . int $DateTimeValues->{Month} > int $Param{StopYear} . int $Param{StopMonth} ) {
        $Kernel::OM->Get('Kernel::System::Cache')->Set(
            Type  => $Self->{CacheType},
            TTL   => $Self->{CacheTTL},
            Key   => $CacheKey,
            Value => \%Ticket,
        );
    }

    return %Ticket;
}

=head2 HistoryTypeLookup()

returns the id of the requested history type.

    my $ID = $TicketObject->HistoryTypeLookup( Type => 'Move' );

=cut

sub HistoryTypeLookup {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{Type} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need Type!'
        );
        return;
    }

    # check if we ask the same request?
    my $CacheKey = 'Ticket::History::HistoryTypeLookup::' . $Param{Type};
    my $Cached   = $Kernel::OM->Get('Kernel::System::Cache')->Get(
        Type => $Self->{CacheType},
        Key  => $CacheKey,
    );

    if ($Cached) {
        return $Cached;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # db query
    return if !$DBObject->Prepare(
        SQL  => 'SELECT id FROM ticket_history_type WHERE name = ?',
        Bind => [ \$Param{Type} ],
    );

    my $HistoryTypeID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $HistoryTypeID = $Row[0];
    }

    # check if data exists
    if ( !$HistoryTypeID ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "No TypeID for $Param{Type} found!",
        );
        return;
    }

    # set cache
    $Kernel::OM->Get('Kernel::System::Cache')->Set(
        Type           => $Self->{CacheType},
        TTL            => $Self->{CacheTTL},
        Key            => $CacheKey,
        Value          => $HistoryTypeID,
        CacheInMemory  => 1,
        CacheInBackend => 0,
    );

    return $HistoryTypeID;
}

=head2 HistoryAdd()

add a history entry to an ticket

    my $Success = $TicketObject->HistoryAdd(
        Name         => 'Some Comment',
        HistoryType  => 'Move', # see system tables
        TicketID     => 123,
        ArticleID    => 1234, # not required!
        QueueID      => 123, # not required!
        TypeID       => 123, # not required!
        CreateUserID => 123,
    );

Events:
    HistoryAdd

=cut

sub HistoryAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{Name} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need Name!'
        );
        return;
    }

    # lookup!
    if ( !$Param{HistoryTypeID} && $Param{HistoryType} ) {
        $Param{HistoryTypeID} = $Self->HistoryTypeLookup( Type => $Param{HistoryType} );
    }

    # check needed stuff
    for my $Needed (qw(TicketID CreateUserID HistoryTypeID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    my %Ticket;
    if ( !$Param{QueueID} || !$Param{TypeID} || !$Param{OwnerID} || !$Param{PriorityID} || !$Param{StateID} ) {
        %Ticket = $Self->TicketGet(
            %Param,
            DynamicFields => 0,
        );
    }

    if ( !$Param{QueueID} ) {
        $Param{QueueID} = $Ticket{QueueID};
    }
    if ( !$Param{TypeID} ) {
        $Param{TypeID} = $Ticket{TypeID};
    }
    if ( !$Param{OwnerID} ) {
        $Param{OwnerID} = $Ticket{OwnerID};
    }
    if ( !$Param{PriorityID} ) {
        $Param{PriorityID} = $Ticket{PriorityID};
    }
    if ( !$Param{StateID} ) {
        $Param{StateID} = $Ticket{StateID};
    }

    # limit name to 200 chars
    if ( $Param{Name} ) {
        $Param{Name} = substr( $Param{Name}, 0, 200 );
    }

    # db quote
    if ( !$Param{ArticleID} ) {
        $Param{ArticleID} = undef;
    }

    # db insert
    return if !$Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL => 'INSERT INTO ticket_history '
            . ' (name, history_type_id, ticket_id, article_id, queue_id, owner_id, '
            . ' priority_id, state_id, type_id, '
            . ' create_time, create_by, change_time, change_by) '
            . 'VALUES '
            . '(?, ?, ?, ?, ?, ?, ?, ?, ?, current_timestamp, ?, current_timestamp, ?)',
        Bind => [
            \$Param{Name},    \$Param{HistoryTypeID}, \$Param{TicketID},   \$Param{ArticleID},
            \$Param{QueueID}, \$Param{OwnerID},       \$Param{PriorityID}, \$Param{StateID},
            \$Param{TypeID},  \$Param{CreateUserID},  \$Param{CreateUserID},
        ],
    );

    # Prevent infinite loops for notifications base on 'HistoryAdd' event
    # see bug#13002
    if ( $Param{HistoryType} ne 'SendAgentNotification' ) {

        # trigger event
        $Self->EventHandler(
            Event => 'HistoryAdd',
            Data  => {
                TicketID => $Param{TicketID},
            },
            UserID => $Param{CreateUserID},
        );
    }

    return 1;
}

=head2 HistoryGet()

get ticket history as array with hashes
(TicketID, ArticleID, Name, CreateBy, CreateTime, HistoryType, QueueID,
OwnerID, PriorityID, StateID, HistoryTypeID and TypeID)

    my @HistoryLines = $TicketObject->HistoryGet(
        TicketID => 123,
        UserID   => 123,
    );

=cut

sub HistoryGet {
    my ( $Self, %Param ) = @_;

    my @Lines;

    # check needed stuff
    for my $Needed (qw(TicketID UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Prepare(
        SQL => 'SELECT sh.name, sh.article_id, sh.create_time, sh.create_by, ht.name, '
            . ' sh.queue_id, sh.owner_id, sh.priority_id, sh.state_id, sh.history_type_id, sh.type_id '
            . ' FROM ticket_history sh, ticket_history_type ht WHERE '
            . ' sh.ticket_id = ? AND ht.id = sh.history_type_id'
            . ' ORDER BY sh.create_time, sh.id',
        Bind => [ \$Param{TicketID} ],
    );

    while ( my @Row = $DBObject->FetchrowArray() ) {
        my %Data;
        $Data{TicketID}      = $Param{TicketID};
        $Data{ArticleID}     = $Row[1] || 0;
        $Data{Name}          = $Row[0];
        $Data{CreateBy}      = $Row[3];
        $Data{CreateTime}    = $Row[2];
        $Data{HistoryType}   = $Row[4];
        $Data{QueueID}       = $Row[5];
        $Data{OwnerID}       = $Row[6];
        $Data{PriorityID}    = $Row[7];
        $Data{StateID}       = $Row[8];
        $Data{HistoryTypeID} = $Row[9];
        $Data{TypeID}        = $Row[10];
        push @Lines, \%Data;
    }

    # get user object
    my $UserObject = $Kernel::OM->Get('Kernel::System::User');

    # get user data
    for my $Data (@Lines) {

        my %UserInfo = $UserObject->GetUserData(
            UserID => $Data->{CreateBy},
        );

        # merge result, put %Data last so that it "wins"
        %{$Data} = ( %UserInfo, %{$Data} );
    }

    return @Lines;
}

=head2 HistoryDelete()

delete a ticket history (from storage)

    my $Success = $TicketObject->HistoryDelete(
        TicketID => 123,
        UserID   => 123,
    );

Events:
    HistoryDelete

=cut

sub HistoryDelete {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(TicketID UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    # delete ticket history entries from db
    return if !$Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL =>
            'DELETE FROM ticket_history WHERE ticket_id = ? AND (article_id IS NULL OR article_id = 0)',
        Bind => [ \$Param{TicketID} ],
    );

    # trigger event
    $Self->EventHandler(
        Event => 'HistoryDelete',
        Data  => {
            TicketID => $Param{TicketID},
        },
        UserID => $Param{UserID},
    );

    return 1;
}

=head2 TicketAccountedTimeGet()

returns the accounted time of a ticket.

    my $AccountedTime = $TicketObject->TicketAccountedTimeGet(TicketID => 1234);

=cut

sub TicketAccountedTimeGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{TicketID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need TicketID!'
        );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # db query
    return if !$DBObject->Prepare(
        SQL  => 'SELECT time_unit FROM time_accounting WHERE ticket_id = ?',
        Bind => [ \$Param{TicketID} ],
    );

    my $AccountedTime = 0;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Row[0] =~ s/,/./g;
        $AccountedTime = $AccountedTime + $Row[0];
    }

    return $AccountedTime;
}

=head2 TicketAccountTime()

account time to a ticket.

    my $Success = $TicketObject->TicketAccountTime(
        TicketID  => 1234,
        ArticleID => 23542,
        TimeUnit  => '4.5',
        UserID    => 1,
    );

Events:
    TicketAccountTime

=cut

sub TicketAccountTime {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(TicketID ArticleID TimeUnit UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    # check some wrong formats
    $Param{TimeUnit} =~ s/,/\./g;
    $Param{TimeUnit} =~ s/ //g;
    $Param{TimeUnit} =~ s/^(\d{1,10}\.\d\d).+?$/$1/g;
    chomp $Param{TimeUnit};

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # update change time
    return if !$DBObject->Do(
        SQL => 'UPDATE ticket SET change_time = current_timestamp, '
            . ' change_by = ? WHERE id = ?',
        Bind => [ \$Param{UserID}, \$Param{TicketID} ],
    );

    # db quote
    $Param{TimeUnit} = $DBObject->Quote( $Param{TimeUnit}, 'Number' );

    # db update
    return if !$DBObject->Do(
        SQL => "INSERT INTO time_accounting "
            . " (ticket_id, article_id, time_unit, create_time, create_by, change_time, change_by) "
            . " VALUES (?, ?, $Param{TimeUnit}, current_timestamp, ?, current_timestamp, ?)",
        Bind => [
            \$Param{TicketID}, \$Param{ArticleID}, \$Param{UserID}, \$Param{UserID},
        ],
    );

    # clear ticket cache
    $Self->_TicketCacheClear( TicketID => $Param{TicketID} );

    # add history
    my $AccountedTime = $Self->TicketAccountedTimeGet( TicketID => $Param{TicketID} );
    $Self->HistoryAdd(
        TicketID     => $Param{TicketID},
        ArticleID    => $Param{ArticleID},
        CreateUserID => $Param{UserID},
        HistoryType  => 'TimeAccounting',
        Name         => "\%\%$Param{TimeUnit}\%\%$AccountedTime",
    );

    # trigger event
    $Self->EventHandler(
        Event => 'TicketAccountTime',
        Data  => {
            TicketID  => $Param{TicketID},
            ArticleID => $Param{ArticleID},
        },
        UserID => $Param{UserID},
    );

    return 1;
}

=head2 TicketMerge()

merge two tickets

    my $Success = $TicketObject->TicketMerge(
        MainTicketID  => 412,
        MergeTicketID => 123,
        UserID        => 123,
    );

Events:
    TicketMerge

=cut

sub TicketMerge {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(MainTicketID MergeTicketID UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    # Get the list of all merged states.
    my @MergeStateList = $Kernel::OM->Get('Kernel::System::State')->StateGetStatesByType(
        StateType => ['merged'],
        Result    => 'Name',
    );

    # Error handling.
    if ( !@MergeStateList ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "No merge state found! Please add a valid merge state.",
        );
        return 'NoValidMergeStates';
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # change ticket id of merge ticket to main ticket
    return if !$DBObject->Do(
        SQL => 'UPDATE article SET ticket_id = ?, change_time = current_timestamp, '
            . ' change_by = ? WHERE ticket_id = ?',
        Bind => [ \$Param{MainTicketID}, \$Param{UserID}, \$Param{MergeTicketID} ],
    );

    # former bug 9635 (with table article_index)
    # do the same with article_search_index (harmless if not used)
    return if !$DBObject->Do(
        SQL  => 'UPDATE article_search_index SET ticket_id = ? WHERE ticket_id = ?',
        Bind => [ \$Param{MainTicketID}, \$Param{MergeTicketID} ],
    );

    # reassign article history
    return if !$DBObject->Do(
        SQL => 'UPDATE ticket_history SET ticket_id = ?, change_time = current_timestamp, '
            . ' change_by = ? WHERE ticket_id = ?
            AND (article_id IS NOT NULL OR article_id != 0)',
        Bind => [ \$Param{MainTicketID}, \$Param{UserID}, \$Param{MergeTicketID} ],
    );

    # update the accounted time of the main ticket
    return if !$DBObject->Do(
        SQL => 'UPDATE time_accounting SET ticket_id = ?, change_time = current_timestamp, '
            . ' change_by = ? WHERE ticket_id = ?',
        Bind => [ \$Param{MainTicketID}, \$Param{UserID}, \$Param{MergeTicketID} ],
    );

    my %MainTicket = $Self->TicketGet(
        TicketID      => $Param{MainTicketID},
        DynamicFields => 0,
    );
    my %MergeTicket = $Self->TicketGet(
        TicketID      => $Param{MergeTicketID},
        DynamicFields => 0,
    );

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # Set language for AutomaticMergeText, see more in bug #13967
    my %UserInfo = $Kernel::OM->Get('Kernel::System::User')->GetUserData(
        UserID => $Param{UserID},
    );
    my $Language = $UserInfo{UserLanguage} || $Kernel::OM->Get('Kernel::Config')->Get('DefaultLanguage') || 'en';

    $Kernel::OM->ObjectsDiscard(
        Objects => ['Kernel::Language'],
    );
    $Kernel::OM->ObjectParamAdd(
        'Kernel::Language' => {
            UserLanguage => $Language,
        },
    );
    my $LanguageObject = $Kernel::OM->Get('Kernel::Language');

    my $Body = $ConfigObject->Get('Ticket::Frontend::AutomaticMergeText');
    $Body = $LanguageObject->Translate($Body);
    $Body =~ s{<OTRS_TICKET>}{$MergeTicket{TicketNumber}}xms;
    $Body =~ s{<OTRS_MERGE_TO_TICKET>}{$MainTicket{TicketNumber}}xms;

    my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');

    # Add merge article to merge ticket using internal channel.
    $ArticleObject->BackendForChannel( ChannelName => 'Internal' )->ArticleCreate(
        TicketID             => $Param{MergeTicketID},
        SenderType           => 'agent',
        IsVisibleForCustomer => 1,
        ContentType          => "text/plain; charset=ascii",
        UserID               => $Param{UserID},
        HistoryType          => 'AddNote',
        HistoryComment       => '%%Note',
        Subject              => $ConfigObject->Get('Ticket::Frontend::AutomaticMergeSubject') || 'Ticket Merged',
        Body                 => $Body,
        NoAgentNotify        => 1,
    );

    # add merge history to merge ticket
    $Self->HistoryAdd(
        TicketID    => $Param{MergeTicketID},
        HistoryType => 'Merged',
        Name        => "\%\%$MergeTicket{TicketNumber}\%\%$Param{MergeTicketID}"
            . "\%\%$MainTicket{TicketNumber}\%\%$Param{MainTicketID}",
        CreateUserID => $Param{UserID},
    );

    # add merge history to main ticket
    $Self->HistoryAdd(
        TicketID    => $Param{MainTicketID},
        HistoryType => 'Merged',
        Name        => "\%\%$MergeTicket{TicketNumber}\%\%$Param{MergeTicketID}"
            . "\%\%$MainTicket{TicketNumber}\%\%$Param{MainTicketID}",
        CreateUserID => $Param{UserID},
    );

    # transfer watchers - only those that were not already watching the main ticket
    # delete all watchers from the merge ticket that are already watching the main ticket
    my %MainWatchers = $Self->TicketWatchGet(
        TicketID => $Param{MainTicketID},
    );

    my %MergeWatchers = $Self->TicketWatchGet(
        TicketID => $Param{MergeTicketID},
    );

    WATCHER:
    for my $WatcherID ( sort keys %MergeWatchers ) {

        next WATCHER if !$MainWatchers{$WatcherID};
        return if !$DBObject->Do(
            SQL => '
                DELETE FROM ticket_watcher
                    WHERE user_id = ?
                    AND ticket_id = ?
                ',
            Bind => [ \$WatcherID, \$Param{MergeTicketID} ],
        );
    }

    # transfer remaining watchers to new ticket
    return if !$DBObject->Do(
        SQL => '
            UPDATE ticket_watcher
                SET ticket_id = ?
                WHERE ticket_id = ?
            ',
        Bind => [ \$Param{MainTicketID}, \$Param{MergeTicketID} ],
    );

    # transfer all linked objects to new ticket
    $Self->TicketMergeLinkedObjects(
        MergeTicketID => $Param{MergeTicketID},
        MainTicketID  => $Param{MainTicketID},
        UserID        => $Param{UserID},
    );

    # link tickets
    $Kernel::OM->Get('Kernel::System::LinkObject')->LinkAdd(
        SourceObject => 'Ticket',
        SourceKey    => $Param{MainTicketID},
        TargetObject => 'Ticket',
        TargetKey    => $Param{MergeTicketID},
        Type         => 'ParentChild',
        State        => 'Valid',
        UserID       => $Param{UserID},
    );

    # Update change time and user ID for main ticket.
    #   See bug#13092 for more information.
    return if !$DBObject->Do(
        SQL  => 'UPDATE ticket SET change_time = current_timestamp, change_by = ? WHERE id = ?',
        Bind => [ \$Param{UserID}, \$Param{MainTicketID} ],
    );

    # set new state of merge ticket
    $Self->TicketStateSet(
        State    => $MergeStateList[0],
        TicketID => $Param{MergeTicketID},
        UserID   => $Param{UserID},
    );

    # unlock ticket
    $Self->LockSet(
        Lock     => 'unlock',
        TicketID => $Param{MergeTicketID},
        UserID   => $Param{UserID},
    );

    # remove seen flag for all users on the main ticket
    $Self->TicketFlagDelete(
        TicketID => $Param{MainTicketID},
        Key      => 'Seen',
        AllUsers => 1,
    );

    $Self->TicketMergeDynamicFields(
        MergeTicketID => $Param{MergeTicketID},
        MainTicketID  => $Param{MainTicketID},
        UserID        => $Param{UserID},
    );

    $Self->_TicketCacheClear( TicketID => $Param{MergeTicketID} );
    $Self->_TicketCacheClear( TicketID => $Param{MainTicketID} );

    # trigger event
    $Self->EventHandler(
        Event => 'TicketMerge',
        Data  => {
            TicketID     => $Param{MergeTicketID},
            MainTicketID => $Param{MainTicketID},
        },
        UserID => $Param{UserID},
    );

    return 1;
}

=head2 TicketMergeDynamicFields()

merge dynamic fields from one ticket into another, that is, copy
them from the merge ticket to the main ticket if the value is empty
in the main ticket.

    my $Success = $TicketObject->TicketMergeDynamicFields(
        MainTicketID  => 123,
        MergeTicketID => 42,
        UserID        => 1,
        DynamicFields => ['DynamicField_TicketFreeText1'], # optional
    );

If DynamicFields is not present, it is taken from the Ticket::MergeDynamicFields
configuration.

=cut

sub TicketMergeDynamicFields {
    my ( $Self, %Param ) = @_;

    for my $Needed (qw(MainTicketID MergeTicketID UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    my $DynamicFields = $Param{DynamicFields};

    if ( !$DynamicFields ) {
        $DynamicFields = $Kernel::OM->Get('Kernel::Config')->Get('Ticket::MergeDynamicFields');
    }

    return 1 if !IsArrayRefWithData($DynamicFields);

    my %MainTicket = $Self->TicketGet(
        TicketID      => $Param{MainTicketID},
        UserID        => $Param{UserID},
        DynamicFields => 1,
    );
    my %MergeTicket = $Self->TicketGet(
        TicketID      => $Param{MergeTicketID},
        UserID        => $Param{UserID},
        DynamicFields => 1,
    );

    # get dynamic field objects
    my $DynamicFieldObject        = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    FIELDS:
    for my $DynamicFieldName ( @{$DynamicFields} ) {

        my $Key = "DynamicField_$DynamicFieldName";

        if (
            defined $MergeTicket{$Key}
            && length $MergeTicket{$Key}
            && !( defined $MainTicket{$Key} && length $MainTicket{$Key} )
            )
        {

            my $DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
                Name => $DynamicFieldName,
            );

            if ( !$DynamicFieldConfig ) {
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'Error',
                    Message  => qq[No such dynamic field "$DynamicFieldName"],
                );
                return;
            }

            $DynamicFieldBackendObject->ValueSet(
                DynamicFieldConfig => $DynamicFieldConfig,
                ObjectID           => $Param{MainTicketID},
                UserID             => $Param{UserID},
                Value              => $MergeTicket{$Key},
            );
        }
    }

    return 1;
}

=head2 TicketMergeLinkedObjects()

merge linked objects from one ticket into another, that is, move
them from the merge ticket to the main ticket in the link_relation table.

    my $Success = $TicketObject->TicketMergeLinkedObjects(
        MainTicketID  => 123,
        MergeTicketID => 42,
        UserID        => 1,
    );

=cut

sub TicketMergeLinkedObjects {
    my ( $Self, %Param ) = @_;

    for my $Needed (qw(MainTicketID MergeTicketID UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    # Lookup the object id of a ticket.
    my $TicketObjectID = $Kernel::OM->Get('Kernel::System::LinkObject')->ObjectLookup(
        Name => 'Ticket',
    );

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # Delete all duplicate links relations between merged tickets.
    # See bug#12994 (https://bugs.otrs.org/show_bug.cgi?id=12994).
    $DBObject->Prepare(
        SQL => '
            SELECT target_key
            FROM link_relation
            WHERE target_object_id = ?
              AND source_object_id = ?
              AND source_key= ?
              AND target_key
              IN (SELECT target_key FROM link_relation WHERE source_key= ? )',
        Bind => [
            \$TicketObjectID,
            \$TicketObjectID,
            \$Param{MainTicketID},
            \$Param{MergeTicketID},
        ],
    );

    my @Relations;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        push @Relations, $Row[0];
    }
    if (@Relations) {

        my $SQL = "DELETE FROM link_relation
                 WHERE target_object_id = ?
                   AND source_object_id = ?
                   AND source_key = ?
                   AND target_key IN ( '${\(join '\',\'', @Relations)}' )";

        $DBObject->Prepare(
            SQL  => $SQL,
            Bind => [
                \$TicketObjectID,
                \$TicketObjectID,
                \$Param{MergeTicketID},
            ],
        );
    }

    # Update links from old ticket to new ticket where the old ticket is the source  MainTicketID.
    $DBObject->Do(
        SQL => '
            UPDATE link_relation
            SET source_key = ?
            WHERE source_object_id = ?
              AND source_key = ?',
        Bind => [

            \$Param{MainTicketID},
            \$TicketObjectID,
            \$Param{MergeTicketID},
        ],
    );

    # Update links from old ticket to new ticket where the old ticket is the target.
    $DBObject->Do(
        SQL => '
            UPDATE link_relation
            SET target_key = ?
            WHERE target_object_id = ?
              AND target_key = ?',
        Bind => [
            \$Param{MainTicketID},
            \$TicketObjectID,
            \$Param{MergeTicketID},
        ],
    );

    # Delete all links between tickets where source and target object are the same.
    $DBObject->Do(
        SQL => '
            DELETE FROM link_relation
            WHERE source_object_id = ?
                AND target_object_id = ?
                AND source_key = target_key
        ',
        Bind => [
            \$TicketObjectID,
            \$TicketObjectID,
        ],
    );

    return 1;
}

=head2 TicketWatchGet()

to get all user ids and additional attributes of an watched ticket

    my %Watch = $TicketObject->TicketWatchGet(
        TicketID => 123,
    );

get list of users to notify

    my %Watch = $TicketObject->TicketWatchGet(
        TicketID => 123,
        Notify   => 1,
    );

get list of users as array

    my @Watch = $TicketObject->TicketWatchGet(
        TicketID => 123,
        Result   => 'ARRAY',
    );

=cut

sub TicketWatchGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{TicketID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Need TicketID!"
        );
        return;
    }

    # check if feature is enabled
    return if !$Kernel::OM->Get('Kernel::Config')->Get('Ticket::Watcher');

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # get all attributes of an watched ticket
    return if !$DBObject->Prepare(
        SQL => '
            SELECT user_id, create_time, create_by, change_time, change_by
            FROM ticket_watcher
            WHERE ticket_id = ?',
        Bind => [ \$Param{TicketID} ],
    );

    # fetch the result
    my %Data;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Data{ $Row[0] } = {
            CreateTime => $Row[1],
            CreateBy   => $Row[2],
            ChangeTime => $Row[3],
            ChangeBy   => $Row[4],
        };
    }

    if ( $Param{Notify} ) {

        for my $UserID ( sort keys %Data ) {

            # get user object
            my $UserObject = $Kernel::OM->Get('Kernel::System::User');

            my %UserData = $UserObject->GetUserData(
                UserID => $UserID,
                Valid  => 1,
            );

            if ( !$UserData{UserSendWatcherNotification} ) {
                delete $Data{$UserID};
            }
        }
    }

    # check result
    if ( $Param{Result} && $Param{Result} eq 'ARRAY' ) {

        my @UserIDs;

        for my $UserID ( sort keys %Data ) {
            push @UserIDs, $UserID;
        }

        return @UserIDs;
    }

    return %Data;
}

=head2 TicketWatchSubscribe()

to subscribe a ticket to watch it

    my $Success = $TicketObject->TicketWatchSubscribe(
        TicketID    => 111,
        WatchUserID => 123,
        UserID      => 123,
    );

Events:
    TicketSubscribe

=cut

sub TicketWatchSubscribe {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(TicketID WatchUserID UserID)) {
        if ( !defined $Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # db access
    return if !$DBObject->Do(
        SQL => '
            DELETE FROM ticket_watcher
            WHERE ticket_id = ?
                AND user_id = ?',
        Bind => [ \$Param{TicketID}, \$Param{WatchUserID} ],
    );
    return if !$DBObject->Do(
        SQL => '
            INSERT INTO ticket_watcher (ticket_id, user_id, create_time, create_by, change_time, change_by)
            VALUES (?, ?, current_timestamp, ?, current_timestamp, ?)',
        Bind => [ \$Param{TicketID}, \$Param{WatchUserID}, \$Param{UserID}, \$Param{UserID} ],
    );

    # get user data
    my %User = $Kernel::OM->Get('Kernel::System::User')->GetUserData(
        UserID => $Param{WatchUserID},
    );

    # add history
    $Self->HistoryAdd(
        TicketID     => $Param{TicketID},
        CreateUserID => $Param{UserID},
        HistoryType  => 'Subscribe',
        Name         => "\%\%$User{UserFullname}",
    );

    # trigger event
    $Self->EventHandler(
        Event => 'TicketSubscribe',
        Data  => {
            TicketID => $Param{TicketID},
        },
        UserID => $Param{UserID},
    );

    return 1;
}

=head2 TicketWatchUnsubscribe()

to remove a subscription of a ticket

    my $Success = $TicketObject->TicketWatchUnsubscribe(
        TicketID    => 111,
        WatchUserID => 123,
        UserID      => 123,
    );

Events:
    TicketUnsubscribe

=cut

sub TicketWatchUnsubscribe {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(TicketID UserID)) {
        if ( !defined $Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    # only one of these parameters is needed
    if ( !$Param{WatchUserID} && !$Param{AllUsers} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Need WatchUserID or AllUsers param!"
        );
        return;
    }

    # get user object
    my $UserObject = $Kernel::OM->Get('Kernel::System::User');

    if ( $Param{AllUsers} ) {
        my @WatchUsers = $Self->TicketWatchGet(
            TicketID => $Param{TicketID},
            Result   => 'ARRAY',
        );

        return if !$Kernel::OM->Get('Kernel::System::DB')->Do(
            SQL  => 'DELETE FROM ticket_watcher WHERE ticket_id = ?',
            Bind => [ \$Param{TicketID} ],
        );

        for my $WatchUser (@WatchUsers) {

            my %User = $UserObject->GetUserData(
                UserID => $WatchUser,
            );

            $Self->HistoryAdd(
                TicketID     => $Param{TicketID},
                CreateUserID => $Param{UserID},
                HistoryType  => 'Unsubscribe',
                Name         => "\%\%$User{UserFullname}",
            );

            $Self->EventHandler(
                Event => 'TicketUnsubscribe',
                Data  => {
                    TicketID => $Param{TicketID},
                },
                UserID => $Param{UserID},
            );
        }

    }
    else {
        return if !$Kernel::OM->Get('Kernel::System::DB')->Do(
            SQL  => 'DELETE FROM ticket_watcher WHERE ticket_id = ? AND user_id = ?',
            Bind => [ \$Param{TicketID}, \$Param{WatchUserID} ],
        );

        my %User = $UserObject->GetUserData(
            UserID => $Param{WatchUserID},
        );

        $Self->HistoryAdd(
            TicketID     => $Param{TicketID},
            CreateUserID => $Param{UserID},
            HistoryType  => 'Unsubscribe',
            Name         => "\%\%$User{UserFullname}",
        );

        $Self->EventHandler(
            Event => 'TicketUnsubscribe',
            Data  => {
                TicketID => $Param{TicketID},
            },
            UserID => $Param{UserID},
        );
    }

    return 1;
}

=head2 TicketFlagSet()

set ticket flags

    my $Success = $TicketObject->TicketFlagSet(
        TicketID => 123,
        Key      => 'Seen',
        Value    => 1,
        UserID   => 123, # apply to this user
    );

Events:
    TicketFlagSet

=cut

sub TicketFlagSet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(TicketID Key Value UserID)) {
        if ( !defined $Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    # get flags
    my %Flag = $Self->TicketFlagGet(
        TicketID => $Param{TicketID},
        UserID   => $Param{UserID},
    );

    # check if set is needed
    return 1 if defined $Flag{ $Param{Key} } && $Flag{ $Param{Key} } eq $Param{Value};

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # set flag
    return if !$DBObject->Do(
        SQL => '
            DELETE FROM ticket_flag
            WHERE ticket_id = ?
                AND ticket_key = ?
                AND create_by = ?',
        Bind => [ \$Param{TicketID}, \$Param{Key}, \$Param{UserID} ],
    );
    return if !$DBObject->Do(
        SQL => '
            INSERT INTO ticket_flag
            (ticket_id, ticket_key, ticket_value, create_time, create_by)
            VALUES (?, ?, ?, current_timestamp, ?)',
        Bind => [ \$Param{TicketID}, \$Param{Key}, \$Param{Value}, \$Param{UserID} ],
    );

    # delete cache
    $Kernel::OM->Get('Kernel::System::Cache')->Delete(
        Type => $Self->{CacheType},
        Key  => 'TicketFlag::' . $Param{TicketID},
    );

    # event
    $Self->EventHandler(
        Event => 'TicketFlagSet',
        Data  => {
            TicketID => $Param{TicketID},
            Key      => $Param{Key},
            Value    => $Param{Value},
            UserID   => $Param{UserID},
        },
        UserID => $Param{UserID},
    );

    return 1;
}

=head2 TicketFlagDelete()

delete ticket flag

    my $Success = $TicketObject->TicketFlagDelete(
        TicketID => 123,
        Key      => 'Seen',
        UserID   => 123,
    );

    my $Success = $TicketObject->TicketFlagDelete(
        TicketID => 123,
        Key      => 'Seen',
        AllUsers => 1,
    );

Events:
    TicketFlagDelete

=cut

sub TicketFlagDelete {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(TicketID Key)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    # only one of these parameters is needed
    if ( !$Param{UserID} && !$Param{AllUsers} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Need UserID or AllUsers param!",
        );
        return;
    }

    # if all users parameter was given
    if ( $Param{AllUsers} ) {

        # get all affected users
        my @AllTicketFlags = $Self->TicketFlagGet(
            TicketID => $Param{TicketID},
            AllUsers => 1,
        );

        # delete flags from database
        return if !$Kernel::OM->Get('Kernel::System::DB')->Do(
            SQL => '
                DELETE FROM ticket_flag
                WHERE ticket_id = ?
                    AND ticket_key = ?',
            Bind => [ \$Param{TicketID}, \$Param{Key} ],
        );

        # delete cache
        $Kernel::OM->Get('Kernel::System::Cache')->Delete(
            Type => $Self->{CacheType},
            Key  => 'TicketFlag::' . $Param{TicketID},
        );

        for my $Record (@AllTicketFlags) {

            $Self->EventHandler(
                Event => 'TicketFlagDelete',
                Data  => {
                    TicketID => $Param{TicketID},
                    Key      => $Param{Key},
                    UserID   => $Record->{UserID},
                },
                UserID => $Record->{UserID},
            );
        }
    }
    else {

        # delete flags from database
        return if !$Kernel::OM->Get('Kernel::System::DB')->Do(
            SQL => '
                DELETE FROM ticket_flag
                WHERE ticket_id = ?
                    AND create_by = ?
                    AND ticket_key = ?',
            Bind => [ \$Param{TicketID}, \$Param{UserID}, \$Param{Key} ],
        );

        # delete cache
        $Kernel::OM->Get('Kernel::System::Cache')->Delete(
            Type => $Self->{CacheType},
            Key  => 'TicketFlag::' . $Param{TicketID},
        );

        $Self->EventHandler(
            Event => 'TicketFlagDelete',
            Data  => {
                TicketID => $Param{TicketID},
                Key      => $Param{Key},
                UserID   => $Param{UserID},
            },
            UserID => $Param{UserID},
        );
    }

    return 1;
}

=head2 TicketFlagGet()

get ticket flags

    my %Flags = $TicketObject->TicketFlagGet(
        TicketID => 123,
        UserID   => 123,  # to get flags of one user
    );

    my @Flags = $TicketObject->TicketFlagGet(
        TicketID => 123,
        AllUsers => 1,    # to get flags of all users
    );

=cut

sub TicketFlagGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{TicketID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Need TicketID!",
        );
        return;
    }

    # check optional
    if ( !$Param{UserID} && !$Param{AllUsers} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Need UserID or AllUsers param!",
        );
        return;
    }

    # get cache object
    my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');

    # check cache
    my $Flags = $CacheObject->Get(
        Type => $Self->{CacheType},
        Key  => 'TicketFlag::' . $Param{TicketID},
    );

    if ( !$Flags || ref $Flags ne 'HASH' ) {

        # get database object
        my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

        # get all ticket flags of the given ticket
        return if !$DBObject->Prepare(
            SQL => '
                SELECT create_by, ticket_key, ticket_value
                FROM ticket_flag
                WHERE ticket_id = ?',
            Bind => [ \$Param{TicketID} ],
        );

        # fetch the result
        $Flags = {};
        while ( my @Row = $DBObject->FetchrowArray() ) {
            $Flags->{ $Row[0] }->{ $Row[1] } = $Row[2];
        }

        # set cache
        $CacheObject->Set(
            Type  => $Self->{CacheType},
            TTL   => $Self->{CacheTTL},
            Key   => 'TicketFlag::' . $Param{TicketID},
            Value => $Flags,
        );
    }

    if ( $Param{AllUsers} ) {

        my @FlagAllUsers;
        for my $UserID ( sort keys %{$Flags} ) {

            for my $Key ( sort keys %{ $Flags->{$UserID} } ) {

                push @FlagAllUsers, {
                    Key    => $Key,
                    Value  => $Flags->{$UserID}->{$Key},
                    UserID => $UserID,
                };
            }
        }

        return @FlagAllUsers;
    }

    # extract user tags
    my $UserTags = $Flags->{ $Param{UserID} } || {};

    return %{$UserTags};
}

=head2 TicketArticleStorageSwitch()

move article storage from one backend to other backend

    my $Success = $TicketObject->TicketArticleStorageSwitch(
        TicketID    => 123,
        Source      => 'ArticleStorageDB',
        Destination => 'ArticleStorageFS',
        UserID      => 1,
    );

=cut

sub TicketArticleStorageSwitch {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(TicketID Source Destination UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    # check source vs. destination
    return 1 if $Param{Source} eq $Param{Destination};

    # get config object
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # reset events and remember
    my $EventConfig = $ConfigObject->Get('Ticket::EventModulePost');
    $ConfigObject->{'Ticket::EventModulePost'} = {};

    # make sure that CheckAllBackends is set for the duration of this method
    $Self->{CheckAllBackends} = 1;

    my $MainObject    = $Kernel::OM->Get('Kernel::System::Main');
    my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');

    # Get articles.
    my @Articles = $ArticleObject->ArticleList(
        TicketID => $Param{TicketID},
        UserID   => $Param{UserID},
    );

    ARTICLE:
    for my $Article (@Articles) {

        # Handle only MIME based articles.
        my $BackendName = $ArticleObject->BackendForArticle(
            TicketID  => $Param{TicketID},
            ArticleID => $Article->{ArticleID}
        )->ChannelNameGet();
        next ARTICLE if $BackendName !~ /^(Email|Phone|Internal)$/;

        my $ArticleObjectSource = Kernel::System::Ticket::Article::Backend::MIMEBase->new(
            ArticleStorageModule => 'Kernel::System::Ticket::Article::Backend::MIMEBase::' . $Param{Source},
        );
        if (
            !$ArticleObjectSource
            || $ArticleObjectSource->{ArticleStorageModule} ne
            "Kernel::System::Ticket::Article::Backend::MIMEBase::$Param{Source}"
            )
        {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Could not create Kernel::System::Ticket::Article::Backend::MIMEBase::" . $Param{Source},
            );
            die;
        }

        # read source attachments
        my %Index = $ArticleObjectSource->ArticleAttachmentIndex(
            ArticleID     => $Article->{ArticleID},
            OnlyMyBackend => 1,
        );

        # read source plain
        my $Plain = $ArticleObjectSource->ArticlePlain(
            ArticleID     => $Article->{ArticleID},
            OnlyMyBackend => 1,
        );
        my $PlainMD5Sum = '';
        if ($Plain) {
            my $PlainMD5 = $Plain;
            $PlainMD5Sum = $MainObject->MD5sum(
                String => \$PlainMD5,
            );
        }

        # read source attachments
        my @Attachments;
        my %MD5Sums;
        for my $FileID ( sort keys %Index ) {
            my %Attachment = $ArticleObjectSource->ArticleAttachment(
                ArticleID     => $Article->{ArticleID},
                FileID        => $FileID,
                OnlyMyBackend => 1,
                Force         => 1,
            );
            push @Attachments, \%Attachment;
            my $MD5Sum = $MainObject->MD5sum(
                String => $Attachment{Content},
            );
            $MD5Sums{$MD5Sum}++;
        }

        # nothing to transfer
        next ARTICLE if !@Attachments && !$Plain;

        my $ArticleObjectDestination = Kernel::System::Ticket::Article::Backend::MIMEBase->new(
            ArticleStorageModule => 'Kernel::System::Ticket::Article::Backend::MIMEBase::' . $Param{Destination},
        );
        if (
            !$ArticleObjectDestination
            || $ArticleObjectDestination->{ArticleStorageModule} ne
            "Kernel::System::Ticket::Article::Backend::MIMEBase::$Param{Destination}"
            )
        {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Could not create Kernel::System::Ticket::" . $Param{Destination},
            );
            die;
        }

        # read destination attachments
        %Index = $ArticleObjectDestination->ArticleAttachmentIndex(
            ArticleID     => $Article->{ArticleID},
            OnlyMyBackend => 1,
        );

        # read source attachments
        if (%Index) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message =>
                    "Attachments of TicketID:$Param{TicketID}/ArticleID:$Article->{ArticleID} already in $Param{Destination}!",
            );
        }
        else {

            # write attachments to destination
            for my $Attachment (@Attachments) {

                # Check UTF8 string for validity and replace any wrongly encoded characters with _
                if (
                    utf8::is_utf8( $Attachment->{Filename} )
                    && !eval { Encode::is_utf8( $Attachment->{Filename}, 1 ) }
                    )
                {

                    Encode::_utf8_off( $Attachment->{Filename} );

                    # replace invalid characters with � (U+FFFD, Unicode replacement character)
                    # If it runs on good UTF-8 input, output should be identical to input
                    $Attachment->{Filename} = eval {
                        Encode::decode( 'UTF-8', $Attachment->{Filename} );
                    };

                    # Replace wrong characters with "_".
                    $Attachment->{Filename} =~ s{[\x{FFFD}]}{_}xms;
                }

                $ArticleObjectDestination->ArticleWriteAttachment(
                    %{$Attachment},
                    ArticleID => $Article->{ArticleID},
                    UserID    => $Param{UserID},
                );
            }

            # write destination plain
            if ($Plain) {
                $ArticleObjectDestination->ArticleWritePlain(
                    Email     => $Plain,
                    ArticleID => $Article->{ArticleID},
                    UserID    => $Param{UserID},
                );
            }

            # verify destination attachments
            %Index = $ArticleObjectDestination->ArticleAttachmentIndex(
                ArticleID     => $Article->{ArticleID},
                OnlyMyBackend => 1,
            );
        }

        for my $FileID ( sort keys %Index ) {
            my %Attachment = $ArticleObjectDestination->ArticleAttachment(
                ArticleID     => $Article->{ArticleID},
                FileID        => $FileID,
                OnlyMyBackend => 1,
                Force         => 1,
            );
            my $MD5Sum = $MainObject->MD5sum(
                String => \$Attachment{Content},
            );
            if ( $MD5Sums{$MD5Sum} ) {
                $MD5Sums{$MD5Sum}--;
                if ( !$MD5Sums{$MD5Sum} ) {
                    delete $MD5Sums{$MD5Sum};
                }
            }
            else {
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'error',
                    Message =>
                        "Corrupt file: $Attachment{Filename} (TicketID:$Param{TicketID}/ArticleID:$Article->{ArticleID})!",
                );

                # delete corrupt attachments from destination
                $ArticleObjectDestination->ArticleDeleteAttachment(
                    ArticleID     => $Article->{ArticleID},
                    UserID        => 1,
                    OnlyMyBackend => 1,
                );

                # set events
                $ConfigObject->{'Ticket::EventModulePost'} = $EventConfig;
                return;
            }
        }

        # check if all files are moved
        if (%MD5Sums) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message =>
                    "Not all files are moved! (TicketID:$Param{TicketID}/ArticleID:$Article->{ArticleID})!",
            );

            # delete incomplete attachments from destination
            $ArticleObjectDestination->ArticleDeleteAttachment(
                ArticleID     => $Article->{ArticleID},
                UserID        => 1,
                OnlyMyBackend => 1,
            );

            # set events
            $ConfigObject->{'Ticket::EventModulePost'} = $EventConfig;
            return;
        }

        # verify destination plain if exists in source backend
        if ($Plain) {
            my $PlainVerify = $ArticleObjectDestination->ArticlePlain(
                ArticleID     => $Article->{ArticleID},
                OnlyMyBackend => 1,
            );
            my $PlainMD5SumVerify = '';
            if ($PlainVerify) {
                $PlainMD5SumVerify = $MainObject->MD5sum(
                    String => \$PlainVerify,
                );
            }
            if ( $PlainMD5Sum ne $PlainMD5SumVerify ) {
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'error',
                    Message =>
                        "Corrupt plain file: ArticleID: $Article->{ArticleID} ($PlainMD5Sum/$PlainMD5SumVerify)",
                );

                # delete corrupt plain file from destination
                $ArticleObjectDestination->ArticleDeletePlain(
                    ArticleID     => $Article->{ArticleID},
                    UserID        => 1,
                    OnlyMyBackend => 1,
                );

                # set events
                $ConfigObject->{'Ticket::EventModulePost'} = $EventConfig;
                return;
            }
        }

        $ArticleObjectSource->ArticleDeleteAttachment(
            ArticleID     => $Article->{ArticleID},
            UserID        => 1,
            OnlyMyBackend => 1,
        );

        # remove source plain
        $ArticleObjectSource->ArticleDeletePlain(
            ArticleID     => $Article->{ArticleID},
            UserID        => 1,
            OnlyMyBackend => 1,
        );

        # read source attachments
        %Index = $ArticleObjectSource->ArticleAttachmentIndex(
            ArticleID     => $Article->{ArticleID},
            OnlyMyBackend => 1,
        );

        # read source attachments
        if (%Index) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Attachments still in $Param{Source}!",
            );
            return;
        }
    }

    # set events
    $ConfigObject->{'Ticket::EventModulePost'} = $EventConfig;

    # Restore previous behavior.
    $Self->{CheckAllBackends} =
        $ConfigObject->Get('Ticket::Article::Backend::MIMEBase::CheckAllStorageBackends')
        // 0;

    return 1;
}

# ProcessManagement functions

=head2 TicketCheckForProcessType()

    checks whether or not the ticket is of a process type.

    $TicketObject->TicketCheckForProcessType(
        TicketID => 123,
    );

=cut

sub TicketCheckForProcessType {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{TicketID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need TicketID!',
        );
        return;
    }

    my $DynamicFieldName = $Kernel::OM->Get('Kernel::Config')->Get('Process::DynamicFieldProcessManagementProcessID');

    return if !$DynamicFieldName;
    $DynamicFieldName = 'DynamicField_' . $DynamicFieldName;

    # get ticket attributes
    my %Ticket = $Self->TicketGet(
        TicketID      => $Param{TicketID},
        DynamicFields => 1,
    );

    # return 1 if we got process ticket
    return 1 if $Ticket{$DynamicFieldName};

    return;
}

=head2 TicketCalendarGet()

checks calendar to be used for ticket based on sla and queue

    my $Calendar = $TicketObject->TicketCalendarGet(
        QueueID => 1,
        SLAID   => 1,   # optional
    );

returns calendar number or empty string for default calendar

=cut

sub TicketCalendarGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{QueueID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need QueueID!'
        );
        return;
    }

    # check if SLAID was passed and if sla has a specific calendar
    if ( $Param{SLAID} ) {

        my %SLAData = $Kernel::OM->Get('Kernel::System::SLA')->SLAGet(
            SLAID  => $Param{SLAID},
            UserID => 1,
        );

        # if SLA has a defined calendar, return it
        return $SLAData{Calendar} if $SLAData{Calendar};
    }

    # if no calendar was determined by SLA, check if queue has a specific calendar
    my %QueueData = $Kernel::OM->Get('Kernel::System::Queue')->QueueGet(
        ID => $Param{QueueID},
    );

    # if queue has a defined calendar, return it
    return $QueueData{Calendar} if $QueueData{Calendar};

    # use default calendar
    return '';
}

=head2 SearchUnknownTicketCustomers()

search customer users that are not saved in any backend

    my $UnknownTicketCustomerList = $TicketObject->SearchUnknownTicketCustomers(
        SearchTerm => 'SomeSearchTerm',
    );

Returns:

    %UnknownTicketCustomerList = (
        {
            CustomerID    => 'SomeCustomerID',
            CustomerUser  => 'SomeCustomerUser',
        },
        {
            CustomerID    => 'SomeCustomerID',
            CustomerUser  => 'SomeCustomerUser',
        },
    );

=cut

sub SearchUnknownTicketCustomers {
    my ( $Self, %Param ) = @_;

    my $SearchTerm = $Param{SearchTerm} || '';

    # get database object
    my $DBObject         = $Kernel::OM->Get('Kernel::System::DB');
    my $LikeEscapeString = $DBObject->GetDatabaseFunction('LikeEscapeString');
    my $QuotedSearch     = '%' . $DBObject->Quote( $SearchTerm, 'Like' ) . '%';

    # db query
    return if !$DBObject->Prepare(
        SQL =>
            "SELECT DISTINCT customer_user_id, customer_id FROM ticket WHERE customer_user_id LIKE ? $LikeEscapeString",
        Bind => [ \$QuotedSearch ],
    );
    my $UnknownTicketCustomerList;

    CUSTOMERUSER:
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $UnknownTicketCustomerList->{ $Row[0] } = $Row[1];
    }

    return $UnknownTicketCustomerList;
}

sub TicketAcceleratorUpdate {
    my ( $Self, %Param ) = @_;

    my $TicketIndexModule = $Kernel::OM->Get('Kernel::Config')->Get('Ticket::IndexModule')
        || 'Kernel::System::Ticket::IndexAccelerator::RuntimeDB';

    return $Kernel::OM->Get($TicketIndexModule)->TicketAcceleratorUpdate(%Param);
}

sub TicketAcceleratorDelete {
    my ( $Self, %Param ) = @_;

    my $TicketIndexModule = $Kernel::OM->Get('Kernel::Config')->Get('Ticket::IndexModule')
        || 'Kernel::System::Ticket::IndexAccelerator::RuntimeDB';

    return $Kernel::OM->Get($TicketIndexModule)->TicketAcceleratorDelete(%Param);
}

sub TicketAcceleratorAdd {
    my ( $Self, %Param ) = @_;

    my $TicketIndexModule = $Kernel::OM->Get('Kernel::Config')->Get('Ticket::IndexModule')
        || 'Kernel::System::Ticket::IndexAccelerator::RuntimeDB';

    return $Kernel::OM->Get($TicketIndexModule)->TicketAcceleratorAdd(%Param);
}

sub TicketAcceleratorIndex {
    my ( $Self, %Param ) = @_;

    my $TicketIndexModule = $Kernel::OM->Get('Kernel::Config')->Get('Ticket::IndexModule')
        || 'Kernel::System::Ticket::IndexAccelerator::RuntimeDB';

    return $Kernel::OM->Get($TicketIndexModule)->TicketAcceleratorIndex(%Param);
}

sub TicketAcceleratorRebuild {
    my ( $Self, %Param ) = @_;

    my $TicketIndexModule = $Kernel::OM->Get('Kernel::Config')->Get('Ticket::IndexModule')
        || 'Kernel::System::Ticket::IndexAccelerator::RuntimeDB';

    return $Kernel::OM->Get($TicketIndexModule)->TicketAcceleratorRebuild(%Param);
}

sub DESTROY {
    my $Self = shift;

    # execute all transaction events
    $Self->EventHandlerTransaction();

    return 1;
}

# COMPAT: to OTRS 1.x and 2.x (can be removed later)

sub CustomerPermission {
    my ( $Self, %Param ) = @_;

    return $Self->TicketCustomerPermission(%Param);
}

sub InvolvedAgents {
    my ( $Self, %Param ) = @_;

    return $Self->TicketInvolvedAgentsList(%Param);
}

sub LockIsTicketLocked {
    my ( $Self, %Param ) = @_;

    return $Self->TicketLockGet(%Param);
}

sub LockSet {
    my ( $Self, %Param ) = @_;

    return $Self->TicketLockSet(%Param);
}

sub MoveList {
    my ( $Self, %Param ) = @_;

    return $Self->TicketMoveList(%Param);
}

sub MoveTicket {
    my ( $Self, %Param ) = @_;

    return $Self->TicketQueueSet(%Param);
}

sub MoveQueueList {
    my ( $Self, %Param ) = @_;

    return $Self->TicketMoveQueueList(%Param);
}

sub OwnerList {
    my ( $Self, %Param ) = @_;

    return $Self->TicketOwnerList(%Param);
}

sub OwnerSet {
    my ( $Self, %Param ) = @_;

    return $Self->TicketOwnerSet(%Param);
}

sub Permission {
    my ( $Self, %Param ) = @_;

    return $Self->TicketPermission(%Param);
}

sub PriorityList {
    my ( $Self, %Param ) = @_;

    return $Self->TicketPriorityList(%Param);
}

sub PrioritySet {
    my ( $Self, %Param ) = @_;

    return $Self->TicketPrioritySet(%Param);
}

sub ResponsibleList {
    my ( $Self, %Param ) = @_;

    return $Self->TicketResponsibleList(%Param);
}

sub ResponsibleSet {
    my ( $Self, %Param ) = @_;

    return $Self->TicketResponsibleSet(%Param);
}

sub SetCustomerData {
    my ( $Self, %Param ) = @_;

    return $Self->TicketCustomerSet(%Param);
}

sub StateList {
    my ( $Self, %Param ) = @_;

    return $Self->TicketStateList(%Param);
}

sub StateSet {
    my ( $Self, %Param ) = @_;

    return $Self->TicketStateSet(%Param);
}

=head1 PRIVATE FUNCTIONS

=head2 _TicketCacheClear()

Remove all caches related to specified ticket.

    my $Success = $TicketObject->_TicketCacheClear(
        TicketID => 123,
    );

=cut

sub _TicketCacheClear {
    my ( $Self, %Param ) = @_;

    for my $Needed (qw(TicketID)) {
        if ( !defined $Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    # get cache object
    my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');

    # TicketGet()
    my $CacheKey = 'Cache::GetTicket' . $Param{TicketID};
    $CacheObject->Delete(
        Type => $Self->{CacheType},
        Key  => $CacheKey,
    );

    # delete extended cache for TicketGet()
    for my $Extended ( 0 .. 1 ) {
        for my $FetchDynamicFields ( 0 .. 1 ) {
            my $CacheKeyDynamicFields = $CacheKey . '::' . $Extended . '::' . $FetchDynamicFields;

            $CacheObject->Delete(
                Type => $Self->{CacheType},
                Key  => $CacheKeyDynamicFields,
            );
        }
    }

    $Kernel::OM->Get('Kernel::System::Ticket::Article')->_ArticleCacheClear(%Param);

    return 1;
}

=head2 _TicketGetExtended()

Collect extended attributes for given ticket,
namely first response, first lock and close data.

    my %TicketExtended = $TicketObject->_TicketGetExtended(
        TicketID => $Param{TicketID},
        Ticket   => \%Ticket,
    );

=cut

sub _TicketGetExtended {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(TicketID Ticket)) {
        if ( !defined $Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    # get extended attributes
    my %FirstResponse   = $Self->_TicketGetFirstResponse(%Param);
    my %FirstLock       = $Self->_TicketGetFirstLock(%Param);
    my %TicketGetClosed = $Self->_TicketGetClosed(%Param);

    # return all as hash
    return ( %TicketGetClosed, %FirstResponse, %FirstLock );
}

=head2 _TicketGetFirstResponse()

Collect attributes of first response for given ticket.

    my %FirstResponse = $TicketObject->_TicketGetFirstResponse(
        TicketID => $Param{TicketID},
        Ticket   => \%Ticket,
    );

=cut

sub _TicketGetFirstResponse {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(TicketID Ticket)) {
        if ( !defined $Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # check if first response is already done
    return if !$DBObject->Prepare(
        SQL => '
            SELECT a.create_time,a.id FROM article a, article_sender_type ast
            WHERE a.article_sender_type_id = ast.id
                AND a.ticket_id = ?
                AND ast.name = ?
                AND a.is_visible_for_customer = ?
            ORDER BY a.create_time',
        Bind  => [ \$Param{TicketID}, \'agent', \1 ],
        Limit => 1,
    );

    my %Data;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Data{FirstResponse} = $Row[0];

        # cleanup time stamps (some databases are using e. g. 2008-02-25 22:03:00.000000
        # and 0000-00-00 00:00:00 time stamps)
        $Data{FirstResponse} =~ s/^(\d\d\d\d-\d\d-\d\d\s\d\d:\d\d:\d\d)\..+?$/$1/;
    }

    return if !$Data{FirstResponse};

    # get escalation properties
    my %Escalation = $Self->TicketEscalationPreferences(
        Ticket => $Param{Ticket},
        UserID => $Param{UserID} || 1,
    );

    if ( $Escalation{FirstResponseTime} ) {

        # create datetime object
        my $DateTimeObject = $Kernel::OM->Create(
            'Kernel::System::DateTime',
            ObjectParams => {
                String => $Param{Ticket}->{Created},
            }
        );

        my $FirstResponseTimeObj = $DateTimeObject->Clone();
        $FirstResponseTimeObj->Set(
            String => $Data{FirstResponse}
        );

        my $DeltaObj = $DateTimeObject->Delta(
            DateTimeObject => $FirstResponseTimeObj,
            ForWorkingTime => 1,
            Calendar       => $Escalation{Calendar},
        );

        my $WorkingTime = $DeltaObj ? $DeltaObj->{AbsoluteSeconds} : 0;

        $Data{FirstResponseInMin} = int( $WorkingTime / 60 );
        my $EscalationFirstResponseTime = $Escalation{FirstResponseTime} * 60;
        $Data{FirstResponseDiffInMin} =
            int( ( $EscalationFirstResponseTime - $WorkingTime ) / 60 );
    }

    return %Data;
}

=head2 _TicketGetClosed()

Collect attributes of (last) closing for given ticket.

    my %TicketGetClosed = $TicketObject->_TicketGetClosed(
        TicketID => $Param{TicketID},
        Ticket   => \%Ticket,
    );

=cut

sub _TicketGetClosed {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(TicketID Ticket)) {
        if ( !defined $Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    # get close state types
    my @List = $Kernel::OM->Get('Kernel::System::State')->StateGetStatesByType(
        StateType => ['closed'],
        Result    => 'ID',
    );
    return if !@List;

    # Get id for history types
    my @HistoryTypeIDs;
    for my $HistoryType (qw(StateUpdate NewTicket)) {
        push @HistoryTypeIDs, $Self->HistoryTypeLookup( Type => $HistoryType );
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Prepare(
        SQL => "
            SELECT MAX(create_time)
            FROM ticket_history
            WHERE ticket_id = ?
               AND state_id IN (${\(join ', ', sort @List)})
               AND history_type_id IN  (${\(join ', ', sort @HistoryTypeIDs)})
            ",
        Bind => [ \$Param{TicketID} ],
    );

    my %Data;
    ROW:
    while ( my @Row = $DBObject->FetchrowArray() ) {
        next ROW if !defined $Row[0];
        $Data{Closed} = $Row[0];

        # cleanup time stamps (some databases are using e. g. 2008-02-25 22:03:00.000000
        # and 0000-00-00 00:00:00 time stamps)
        $Data{Closed} =~ s/^(\d\d\d\d-\d\d-\d\d\s\d\d:\d\d:\d\d)\..+?$/$1/;
    }

    return if !$Data{Closed};

    # get escalation properties
    my %Escalation = $Self->TicketEscalationPreferences(
        Ticket => $Param{Ticket},
        UserID => $Param{UserID} || 1,
    );

    # create datetime object
    my $DateTimeObject = $Kernel::OM->Create(
        'Kernel::System::DateTime',
        ObjectParams => {
            String => $Param{Ticket}->{Created},
        }
    );

    my $SolutionTimeObj = $Kernel::OM->Create(
        'Kernel::System::DateTime',
        ObjectParams => {
            String => $Data{Closed},
        }
    );

    my $DeltaObj = $DateTimeObject->Delta(
        DateTimeObject => $SolutionTimeObj,
        ForWorkingTime => 1,
        Calendar       => $Escalation{Calendar},
    );

    my $WorkingTime = $DeltaObj ? $DeltaObj->{AbsoluteSeconds} : 0;

    $Data{SolutionInMin} = int( $WorkingTime / 60 );

    if ( $Escalation{SolutionTime} ) {
        my $EscalationSolutionTime = $Escalation{SolutionTime} * 60;
        $Data{SolutionDiffInMin} =
            int( ( $EscalationSolutionTime - $WorkingTime ) / 60 );
    }

    return %Data;
}

=head2 _TicketGetFirstLock()

Collect first lock time for given ticket.

    my %FirstLock = $TicketObject->_TicketGetFirstLock(
        TicketID => $Param{TicketID},
        Ticket   => \%Ticket,
    );

=cut

sub _TicketGetFirstLock {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(TicketID Ticket)) {
        if ( !defined $Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    my $LockHistoryTypeID = $Self->HistoryTypeLookup( Type => 'Lock' );

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # get first lock
    return if !$DBObject->Prepare(
        SQL => 'SELECT create_time '
            . 'FROM ticket_history '
            . 'WHERE ticket_id = ? AND history_type_id = ? '
            . 'ORDER BY create_time ASC, id ASC',
        Bind  => [ \$Param{TicketID}, \$LockHistoryTypeID, ],
        Limit => 1,
    );

    my %Data;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Data{FirstLock} = $Row[0];

        # cleanup time stamp (some databases are using e. g. '2008-02-25 22:03:00.000000' time stamps)
        $Data{FirstLock} =~ s{ \A ( \d{4} - \d{2} - \d{2} [ ] \d{2} : \d{2} : \d{2} ) .* \z }{$1}xms;
    }

    return %Data;
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
