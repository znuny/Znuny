# --
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Mention;

use strict;
use warnings;

use Kernel::Language qw(Translatable);
use Kernel::System::VariableCheck qw(:all);

use parent qw(Kernel::System::EventHandler);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::DB',
    'Kernel::System::Log',
    'Kernel::System::Ticket',
    'Kernel::System::Ticket::Article',
);

=head1 NAME

Kernel::System::Mention

=head1 DESCRIPTION

Support for mentioning users.

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $MentionObject = $Kernel::OM->Get('Kernel::System::Mention');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    $Self->EventHandlerInit(
        Config => 'Ticket::EventModulePost',
    );

    return $Self;
}

=head2 SendNotification()

Adds a mention for every given recipient and triggers event 'UserMention'
of notification "Mention notification" to execute/send it.

    my $Success = $MentionObject->SendNotification(
        TicketID   => 3252,
        ArticleID  => 6538,
        Recipients => {
            'root@localhost' => {
                UserID    => 1,
                UserEmail => 'admin@mycompany.org',
            },
            # ...
        },
    );

    Returns true value if all mentions were added successfully.


=cut

sub SendNotification {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    NEEDED:
    for my $Needed (qw(TicketID ArticleID Recipients)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    if ( !IsHashRefWithData( $Param{Recipients} ) ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter 'Recipients' needs to be a hash with data!",
        );
        return;
    }

    my $AllMentionAddsOK = 1;

    RECIPIENT:
    for my $Recipient ( sort keys %{ $Param{Recipients} } ) {
        my $Success = $Self->AddMention(
            TicketID  => $Param{TicketID},
            ArticleID => $Param{ArticleID},
            Recipient => $Param{Recipients}->{$Recipient},
        );

        $AllMentionAddsOK = 0 if !$Success;
    }

    return $AllMentionAddsOK;
}

=head2 AddMention()

Adds a mention and triggers event "UserMention" to send a notification.

    my $Success = $MentionObject->AddMention(
        TicketID  => 3252,
        ArticleID => 6538,
        Recipient => {
            UserID    => 1,
            UserEmail => 'admin@mycompany.org',
        },
    );

    Returns true value on success.

=cut

sub AddMention {
    my ( $Self, %Param ) = @_;

    my $LogObject     = $Kernel::OM->Get('Kernel::System::Log');
    my $DBObject      = $Kernel::OM->Get('Kernel::System::DB');
    my $ConfigObject  = $Kernel::OM->Get('Kernel::Config');
    my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');
    my $TicketObject  = $Kernel::OM->Get('Kernel::System::Ticket');

    NEEDED:
    for my $Needed (qw(TicketID ArticleID Recipient)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    if ( !IsHashRefWithData( $Param{Recipient} ) ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter 'Recipient' needs to be a hash with data!",
        );
        return;
    }

    my $TicketID  = $Param{TicketID};
    my $ArticleID = $Param{ArticleID};
    my $UserID    = $Param{Recipient}->{UserID};

    my $Mentions = $Self->GetTicketMentions(
        TicketID => $TicketID,
    );
    return if ref $Mentions ne 'ARRAY';

    my $MentionExists = grep {
        $_->{UserID} == $UserID
            && $_->{TicketID} == $TicketID
            && $_->{ArticleID} == $ArticleID
    } @{$Mentions};
    return 1 if $MentionExists;

    my $TicketFlagSet = $TicketObject->TicketFlagSet(
        TicketID => $TicketID,
        Key      => 'MentionSeen',
        Value    => 0,
        UserID   => $UserID,
    );
    return if !$TicketFlagSet;

    return if !$DBObject->Do(
        SQL => '
            INSERT INTO
                mention (user_id, ticket_id, article_id, create_time)
                VALUES (?, ?, ?, current_timestamp)
        ',
        Bind => [
            \$UserID,
            \$TicketID,
            \$ArticleID,
        ],
    );

    my $NotificationsConfig = $ConfigObject->Get('Mentions')->{Notifications};
    if ( $NotificationsConfig && $NotificationsConfig eq 'Ticket' ) {
        my $IsUserMentionedTicket = grep {
            $_->{UserID} == $UserID
                && $_->{TicketID} == $TicketID
        } @{$Mentions};

        return if $IsUserMentionedTicket;
    }

    $Self->EventHandler(
        Event => 'UserMention',
        Data  => {
            TicketID   => $TicketID,
            ArticleID  => $ArticleID,
            Recipients => [ $UserID, ],
        },
        UserID => $UserID,
    );

    return 1;
}

=head2 RemoveMention()

Removes all mentions of a ticket for a specific user ID.

    my $Success = $MentionObject->RemoveMention(
        TicketID => 3252,
        UserID   => 5,
    );

    Returns true value on success.

=cut

sub RemoveMention {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');
    my $DBObject  = $Kernel::OM->Get('Kernel::System::DB');

    NEEDED:
    for my $Needed (qw(TicketID UserID)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my $TicketID = $Param{TicketID};
    my $UserID   = $Param{UserID};

    return if !$DBObject->Do(
        SQL => '
            DELETE FROM mention
            WHERE       ticket_id = ?
                        AND user_id = ?
        ',
        Bind => [
            \$Param{TicketID},
            \$Param{UserID},
        ],
    );

    return 1;
}

=head2 GetTicketMentions()

Retrieves all mentions of a ticket.

    my $Mentions = $MentionObject->GetTicketMentions(
        TicketID  => 3252,
        OrderBy   => 'create_time', # optional; default
        SortOrder => 'ASC', # or 'DESC', optional; default
    );

    Returns:

    my $Mentions = [
        {
            UserID     => 5,
            TicketID   => 76,
            ArticleID  => 89,
            CreateTime => '2022-07-20 12:34:23',
        },
        # ...
    ];

=cut

sub GetTicketMentions {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');
    my $DBObject  = $Kernel::OM->Get('Kernel::System::DB');

    NEEDED:
    for my $Needed (qw(TicketID)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my $OrderByQuery = $Self->_AssembleOrderByQuery(
        OrderBy   => $Param{OrderBy},
        SortOrder => $Param{SortOrder},
    );
    return if !$OrderByQuery;

    return if !$DBObject->Prepare(
        SQL => "
            SELECT   user_id, ticket_id, article_id, create_time
            FROM     mention
            WHERE    ticket_id = ?
            ORDER BY $OrderByQuery
        ",
        Bind => [
            \$Param{TicketID},
        ],
    );

    my @Mentions;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        my %Mention = (
            UserID     => $Row[0],
            TicketID   => $Row[1],
            ArticleID  => $Row[2],
            CreateTime => $Row[3],
        );

        push @Mentions, \%Mention;
    }

    return \@Mentions;
}

=head2 GetUserMentions()

Retrieves all mentions of a user.

    my $Mentions = $MentionObject->GetUserMentions(
        UserID     => 87,

        # optional, defaults to 0 and then means that all mentions of all articles per ticket are
        # counted as one combined mention;
        # if set to 1, all mentions of every article count separately
        PerArticle => 0,

        OrderBy    => 'create_time', # optional; default
        SortOrder  => 'ASC', # or 'DESC', optional; default
    );

    Returns:

    my $Mentions = [
        {
            UserID   => 5,
            TicketID => 76,

            # the following two entries will only be returned if parameter PerArticle is set
            ArticleID  => 89,
            CreateTime => '2022-07-20 12:34:23',
        },
        # ...
    ];

=cut

sub GetUserMentions {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');
    my $DBObject  = $Kernel::OM->Get('Kernel::System::DB');

    NEEDED:
    for my $Needed (qw(UserID)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my $OrderByQuery = $Self->_AssembleOrderByQuery(
        OrderBy   => $Param{OrderBy},
        SortOrder => $Param{SortOrder},
    );
    return if !$OrderByQuery;

    $DBObject->Prepare(
        SQL => "
            SELECT   user_id, ticket_id, article_id, create_time
            FROM     mention
            WHERE    user_id = ?
            ORDER BY $OrderByQuery
        ",
        Bind => [
            \$Param{UserID},
        ],
    );

    my $PerArticle = $Param{PerArticle} // 0;
    my %MentionedTicketIDs;

    my @Mentions;
    ROW:
    while ( my @Row = $DBObject->FetchrowArray() ) {
        my $TicketID = $Row[1];
        if ( !$PerArticle ) {
            next ROW if $MentionedTicketIDs{$TicketID};

            $MentionedTicketIDs{$TicketID} = 1;
        }

        my %Mention = (
            UserID   => $Row[0],
            TicketID => $TicketID,
        );

        if ($PerArticle) {
            $Mention{ArticleID}  = $Row[2];
            $Mention{CreateTime} = $Row[3];
        }

        push @Mentions, \%Mention;
    }

    return \@Mentions;
}

=head2 GetDashboardWidgetTicketData()

Returns data for dashboard widgets that output information about mentions.

    my $Data = $MentionObject->GetDashboardWidgetTicketData(
        UserID => 37,
    );

    Returns:

    my $Data = (
        TicketIDs     => [ 5, 27, 382, ],
        CustomColumns => {
            5 => {
                LastMention => '2022-07-03 10:32:42',
            },
            27 => {
                LastMention => '2022-07-08 14:56:20',
            },
            382 => {
                LastMention => '2022-07-25 16:09:12',
            },
        },
    );

=cut

sub GetDashboardWidgetTicketData {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    NEEDED:
    for my $Needed (qw(UserID)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my $Mentions = $Self->GetUserMentions(
        UserID     => $Param{UserID},
        PerArticle => 1,
        OrderBy    => 'create_time',
        SortOrder  => 'ASC',
    );
    return if !IsArrayRefWithData($Mentions);

    my %TicketIDs;
    my %CustomColumns;
    for my $Mention ( @{$Mentions} ) {
        $TicketIDs{ $Mention->{TicketID} } = 1;

        # Note: This will only use the creation time of the newest article
        # per ticket.
        $CustomColumns{ $Mention->{TicketID} }->{Translatable('LastMention')} = $Mention->{CreateTime};
    }

    my %Data = (
        TicketIDs     => [ sort keys %TicketIDs ],
        CustomColumns => \%CustomColumns,
    );

    return \%Data;
}

sub _AssembleOrderByQuery {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    my $OrderBy      = $Param{OrderBy} // 'create_time';
    my %ValidOrderBy = (
        user_id     => 1,
        ticket_id   => 1,
        article_id  => 1,
        create_time => 1,
    );
    if ( !$ValidOrderBy{$OrderBy} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter 'OrderBy' contains invalid column name!",
        );
        return;
    }

    my $SortOrder = $Param{SortOrder} // 'ASC';
    if ( $SortOrder !~ m{\A(?:ASC|DESC)\z}i ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter 'SortOrder' contains invalid value!",
        );
        return;
    }

    my $OrderByQuery = "$OrderBy $SortOrder";

    return $OrderByQuery;
}

1;
