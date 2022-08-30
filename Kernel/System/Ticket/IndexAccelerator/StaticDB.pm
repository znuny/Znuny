# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::Ticket::IndexAccelerator::StaticDB;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::DB',
    'Kernel::System::Group',
    'Kernel::System::Lock',
    'Kernel::System::Log',
    'Kernel::System::State',
    'Kernel::System::Ticket',
    'Kernel::System::DateTime',
    'Kernel::System::Queue',
);

sub new {
    my ($Type) = @_;

    my $Self = {};
    return bless( $Self, $Type );
}

sub TicketAcceleratorUpdate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(TicketID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    # check if ticket is shown or not
    my $IndexUpdateNeeded = 0;
    my $IndexSelected     = 0;
    my %TicketData        = $Kernel::OM->Get('Kernel::System::Ticket')->TicketGet(
        %Param,
        DynamicFields => 0,
    );

    my %IndexTicketData = $Self->GetIndexTicket(%Param);

    if ( !%IndexTicketData ) {
        $IndexUpdateNeeded = 1;
    }
    else {

        # check if we need to update
        if ( $TicketData{Lock} ne $IndexTicketData{Lock} ) {
            $IndexUpdateNeeded = 1;
        }
        elsif ( $TicketData{State} ne $IndexTicketData{State} ) {
            $IndexUpdateNeeded = 1;
        }
        elsif ( $TicketData{QueueID} ne $IndexTicketData{QueueID} ) {
            $IndexUpdateNeeded = 1;
        }
    }

    # check if this ticket is still viewable
    my @ViewableStates = $Kernel::OM->Get('Kernel::System::State')->StateGetStatesByType(
        Type   => 'Viewable',
        Result => 'Name',
    );

    my $ViewableStatesHit = 0;

    for my $State (@ViewableStates) {

        if ( $State =~ /^$TicketData{State}$/i ) {
            $ViewableStatesHit = 1;
        }
    }

    my @ViewableLocks = $Kernel::OM->Get('Kernel::System::Lock')->LockViewableLock(
        Type => 'Name',
    );

    my $ViewableLocksHit = 0;

    for my $Lock (@ViewableLocks) {

        if ( $Lock =~ /^$TicketData{Lock}$/i ) {
            $ViewableLocksHit = 1;
        }
    }

    if ($ViewableStatesHit) {
        $IndexSelected = 1;
    }

    if ( $TicketData{ArchiveFlag} eq 'y' ) {
        $IndexSelected = 0;
    }

    # write index back
    if ($IndexUpdateNeeded) {

        if ($IndexSelected) {

            if ( $IndexTicketData{TicketID} ) {

                $Kernel::OM->Get('Kernel::System::DB')->Do(
                    SQL => '
                        UPDATE ticket_index
                        SET queue_id = ?, queue = ?, group_id = ?, s_lock = ?, s_state = ?
                        WHERE ticket_id = ?',
                    Bind => [
                        \$TicketData{QueueID}, \$TicketData{Queue}, \$TicketData{GroupID},
                        \$TicketData{Lock},    \$TicketData{State}, \$Param{TicketID},
                    ],
                );
            }
            else {
                $Self->TicketAcceleratorAdd(%TicketData);
            }
        }
        else {
            $Self->TicketAcceleratorDelete(%Param);
        }
    }

    # write lock index
    if ( !$ViewableLocksHit ) {

        # check if there is already an lock index entry
        if ( !$Self->_GetIndexTicketLock(%Param) ) {

            # add lock index entry
            $Self->TicketLockAcceleratorAdd(%TicketData);
        }
    }
    else {

        # delete lock index entry if ticket is unlocked
        $Self->TicketLockAcceleratorDelete(%Param);
    }

    return 1;
}

sub TicketAcceleratorUpdateOnQueueUpdate {
    my ( $Self, %Param ) = @_;

    for my $Needed (qw(NewQueueName OldQueueName)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # Update ticket_index for changed queue name.
    return if !$DBObject->Do(
        SQL => '
            UPDATE ticket_index
            SET queue = ?
            WHERE queue = ?',
        Bind => [
            \$Param{NewQueueName},
            \$Param{OldQueueName},
        ],
    );

    # Updated ticket_index for all sub queue names when parent name is changed.
    #   See bug#13570 for more information.
    my %AllQueue    = $Kernel::OM->Get('Kernel::System::Queue')->QueueList( Valid => 0 );
    my @ParentQueue = split( /::/, $Param{OldQueueName} );

    for my $QueueID ( sort keys %AllQueue ) {

        my @SubQueue = split( /::/, $AllQueue{$QueueID} );

        if ( $#SubQueue > $#ParentQueue ) {

            if ( $AllQueue{$QueueID} =~ /^\Q$Param{OldQueueName}::\E/i ) {

                my $NewQueueName = $AllQueue{$QueueID};
                $NewQueueName =~ s/\Q$Param{OldQueueName}\E/$Param{NewQueueName}/;

                return if !$DBObject->Do(
                    SQL => '
                        UPDATE ticket_index
                        SET queue = ?
                        WHERE queue = ?',
                    Bind => [
                        \$NewQueueName,
                        \$AllQueue{$QueueID},
                    ],
                );
            }
        }
    }

    return 1;
}

sub TicketAcceleratorDelete {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(TicketID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    return if !$Self->TicketLockAcceleratorDelete(%Param);

    return if !$Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL  => 'DELETE FROM ticket_index WHERE ticket_id = ?',
        Bind => [ \$Param{TicketID} ],
    );

    return 1;
}

sub TicketAcceleratorAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(TicketID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    # get ticket data
    my %TicketData = $Kernel::OM->Get('Kernel::System::Ticket')->TicketGet(
        %Param,
        DynamicFields => 0,
    );

    # check if this ticket is still viewable
    my @ViewableStates = $Kernel::OM->Get('Kernel::System::State')->StateGetStatesByType(
        Type   => 'Viewable',
        Result => 'Name',
    );

    my $ViewableStatesHit = 0;

    for my $State (@ViewableStates) {
        if ( $State =~ /^$TicketData{State}$/i ) {
            $ViewableStatesHit = 1;
        }
    }

    # do nothing if state is not viewable
    if ( !$ViewableStatesHit ) {
        return 1;
    }

    # do nothing if ticket is archived
    if ( $TicketData{ArchiveFlag} eq 'y' ) {
        return 1;
    }

    return if !$Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL => '
            INSERT INTO ticket_index
                (ticket_id, queue_id, queue, group_id, s_lock, s_state, create_time)
                VALUES (?, ?, ?, ?, ?, ?, ?)',
        Bind => [
            \$Param{TicketID},     \$TicketData{QueueID}, \$TicketData{Queue},
            \$TicketData{GroupID}, \$TicketData{Lock},    \$TicketData{State},
            \$TicketData{Created},
        ],
    );

    return 1;
}

sub TicketLockAcceleratorDelete {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(TicketID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    # db query
    return if !$Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL  => 'DELETE FROM ticket_lock_index WHERE ticket_id = ?',
        Bind => [ \$Param{TicketID} ],
    );

    return 1;
}

sub TicketLockAcceleratorAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(TicketID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    # get ticket data
    my %TicketData = $Kernel::OM->Get('Kernel::System::Ticket')->TicketGet(
        %Param,
        DynamicFields => 0,
    );

    return if !$Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL  => 'INSERT INTO ticket_lock_index (ticket_id) VALUES (?)',
        Bind => [ \$Param{TicketID} ],
    );

    return 1;
}

sub TicketAcceleratorIndex {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(UserID QueueID ShownQueueIDs)) {
        if ( !exists( $Param{$Needed} ) ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    my %Queues;
    $Queues{MaxAge}       = 0;
    $Queues{TicketsShown} = 0;
    $Queues{TicketsAvail} = 0;

    my @QueueIDs = @{ $Param{ShownQueueIDs} };

    # prepare "All tickets: ??" in Queue
    my @ViewableLocks = $Kernel::OM->Get('Kernel::System::Lock')->LockViewableLock(
        Type => 'Name',
    );

    my %ViewableLocks = ( map { $_ => 1 } @ViewableLocks );

    my @ViewableStateIDs = $Kernel::OM->Get('Kernel::System::State')->StateGetStatesByType(
        Type   => 'Viewable',
        Result => 'ID',
    );

    if (@QueueIDs) {

        # get database object
        my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

        my $SQL = "
            SELECT count(*)
            FROM ticket st
            WHERE st.ticket_state_id IN ( ${\(join ', ', @ViewableStateIDs)} )
                AND st.queue_id IN (";

        for my $Index ( 0 .. $#QueueIDs ) {

            if ( $Index > 0 ) {
                $SQL .= ",";
            }

            $SQL .= $DBObject->Quote( $QueueIDs[$Index], 'Integer' );
        }

        $SQL .= " )";

        $DBObject->Prepare( SQL => $SQL );

        while ( my @Row = $DBObject->FetchrowArray() ) {
            $Queues{AllTickets} = $Row[0];
        }
    }

    # get user groups
    my $Type             = 'rw';
    my $AgentTicketQueue = $Kernel::OM->Get('Kernel::Config')->Get('Ticket::Frontend::AgentTicketQueue');

    if (
        $AgentTicketQueue
        && ref $AgentTicketQueue eq 'HASH'
        && $AgentTicketQueue->{ViewAllPossibleTickets}
        )
    {
        $Type = 'ro';
    }

    my %GroupList = $Kernel::OM->Get('Kernel::System::Group')->PermissionUserGet(
        UserID => $Param{UserID},
        Type   => $Type,
    );

    my @GroupIDs = sort keys %GroupList;

    # get index
    $Queues{MaxAge} = 0;

    # check if user is in min. one group! if not, return here
    if ( !@GroupIDs ) {

        my %Hashes;
        $Hashes{QueueID} = 0;
        $Hashes{Queue}   = 'CustomQueue';
        $Hashes{MaxAge}  = 0;
        $Hashes{Count}   = 0;

        push @{ $Queues{Queues} }, \%Hashes;

        return %Queues;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # CustomQueue add on
    return if !$DBObject->Prepare(
        SQL => "
            SELECT count(*), ti.s_lock
            FROM ticket_index ti
                JOIN personal_queues suq ON suq.queue_id = ti.queue_id
            WHERE ti.group_id IN ( ${\(join ', ', @GroupIDs)} )
                AND suq.user_id = $Param{UserID}
            GROUP BY ti.s_lock",
    );

    my %CustomQueueHashes = (
        QueueID => 0,
        Queue   => 'CustomQueue',
        MaxAge  => 0,
        Count   => 0,
        Total   => 0,
    );

    while ( my @Row = $DBObject->FetchrowArray() ) {
        $CustomQueueHashes{Total} += $Row[0];
        if ( $ViewableLocks{ $Row[1] } ) {
            $CustomQueueHashes{Count} += $Row[0];
        }
    }

    push @{ $Queues{Queues} }, \%CustomQueueHashes;

    # prepare the tickets in Queue bar (all data only with my/your Permission)
    return if !$DBObject->Prepare(
        SQL => "
            SELECT queue_id, queue, min(create_time), s_lock, count(*)
            FROM ticket_index
            WHERE group_id IN ( ${\(join ', ', @GroupIDs)} )
            GROUP BY queue_id, queue, s_lock
            ORDER BY queue",
    );

    my $CurrentDateTimeObject = $Kernel::OM->Create('Kernel::System::DateTime');

    my %QueuesSeen;
    while ( my @Row = $DBObject->FetchrowArray() ) {

        my $Queue     = $Row[1];
        my $QueueData = $QueuesSeen{$Queue};    # ref to HASH

        if ( !$QueueData ) {

            $QueueData = $QueuesSeen{$Queue} = {
                QueueID => $Row[0],
                Queue   => $Queue,
                Total   => 0,
                Count   => 0,
                MaxAge  => 0,
            };

            push @{ $Queues{Queues} }, $QueueData;
        }

        my $Count = $Row[4];
        $QueueData->{Total} += $Count;

        if ( $ViewableLocks{ $Row[3] } ) {

            $QueueData->{Count} += $Count;

            my $TicketCreatedDTObj = $Kernel::OM->Create(
                'Kernel::System::DateTime',
                ObjectParams => {
                    String => $Row[2],
                },
            );

            my $Delta  = $TicketCreatedDTObj->Delta( DateTimeObject => $CurrentDateTimeObject );
            my $MaxAge = $Delta->{AbsoluteSeconds};
            $QueueData->{MaxAge} = $MaxAge if $MaxAge > $QueueData->{MaxAge};

            # get the oldest queue id
            if ( $QueueData->{MaxAge} > $Queues{MaxAge} ) {
                $Queues{MaxAge}          = $QueueData->{MaxAge};
                $Queues{QueueIDOfMaxAge} = $QueueData->{QueueID};
            }
        }

        # set some things
        if ( $Param{QueueID} eq $Queue ) {
            $Queues{TicketsShown} = $QueueData->{Total};
            $Queues{TicketsAvail} = $QueueData->{Count};
        }
    }

    return %Queues;
}

sub TicketAcceleratorRebuild {
    my ( $Self, %Param ) = @_;

    my @ViewableStateIDs = $Kernel::OM->Get('Kernel::System::State')->StateGetStatesByType(
        Type   => 'Viewable',
        Result => 'ID',
    );

    my @ViewableLockIDs = $Kernel::OM->Get('Kernel::System::Lock')->LockViewableLock( Type => 'ID' );

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # get all viewable tickets
    my $SQL = "
        SELECT st.id, st.queue_id, sq.name, sq.group_id, slt.name, tsd.name, st.create_time
        FROM ticket st
            JOIN queue sq             ON st.queue_id = sq.id
            JOIN ticket_state tsd     ON st.ticket_state_id = tsd.id
            JOIN ticket_lock_type slt ON st.ticket_lock_id = slt.id
        WHERE st.ticket_state_id IN ( ${\(join ', ', @ViewableStateIDs)} )
            AND st.archive_flag = 0";

    return if !$DBObject->Prepare( SQL => $SQL );

    my @RowBuffer;
    while ( my @Row = $DBObject->FetchrowArray() ) {

        my %Data;
        $Data{TicketID}   = $Row[0];
        $Data{QueueID}    = $Row[1];
        $Data{Queue}      = $Row[2];
        $Data{GroupID}    = $Row[3];
        $Data{Lock}       = $Row[4];
        $Data{State}      = $Row[5];
        $Data{CreateTime} = $Row[6];

        push @RowBuffer, \%Data;
    }

    # write index
    return if !$DBObject->Do( SQL => 'DELETE FROM ticket_index' );

    for my $Row (@RowBuffer) {

        my %Data = %{$Row};

        $DBObject->Do(
            SQL => '
                INSERT INTO ticket_index
                    (ticket_id, queue_id, queue, group_id, s_lock, s_state, create_time)
                    VALUES (?, ?, ?, ?, ?, ?, ?)',
            Bind => [
                \$Data{TicketID}, \$Data{QueueID}, \$Data{Queue}, \$Data{GroupID},
                \$Data{Lock}, \$Data{State}, \$Data{CreateTime},
            ],
        );
    }

    # write lock index
    return if !$DBObject->Prepare(
        SQL => "
            SELECT ti.id
            FROM ticket ti
            WHERE ti.ticket_lock_id not IN ( ${\(join ', ', @ViewableLockIDs)} ) ",
    );

    my @LockRowBuffer;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        push @LockRowBuffer, $Row[0];
    }

    # add lock index entry
    return if !$DBObject->Do( SQL => 'DELETE FROM ticket_lock_index' );

    for my $TicketID (@LockRowBuffer) {
        $Self->TicketLockAcceleratorAdd( TicketID => $TicketID );
    }

    return 1;
}

sub GetIndexTicket {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(TicketID)) {
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

    # sql query
    return if !$DBObject->Prepare(
        SQL => '
            SELECT ticket_id, queue_id, queue, group_id, s_lock, s_state, create_time
            FROM ticket_index
            WHERE ticket_id = ?',
        Bind => [ \$Param{TicketID} ]
    );

    my %Data;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Data{TicketID}   = $Row[0];
        $Data{QueueID}    = $Row[1];
        $Data{Queue}      = $Row[2];
        $Data{GroupID}    = $Row[3];
        $Data{Lock}       = $Row[4];
        $Data{State}      = $Row[5];
        $Data{CreateTime} = $Row[6];
    }

    return %Data;
}

sub _GetIndexTicketLock {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(TicketID)) {
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

    # sql query
    return if !$DBObject->Prepare(
        SQL  => 'SELECT ticket_id FROM ticket_lock_index WHERE ticket_id = ?',
        Bind => [ \$Param{TicketID} ],
    );

    my $Hit = 0;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Hit = 1;
    }

    return $Hit;
}

1;
