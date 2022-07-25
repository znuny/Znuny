# --
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package scripts::Migration::Znuny::UpgradeDatabaseStructure::Mentions;    ## no critic

use strict;
use warnings;

use parent qw(scripts::Migration::Base);

our @ObjectDependencies = (
    'Kernel::System::NotificationEvent',
);

=head1 SYNOPSIS

Adds new table and notification event for user mention support

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    return if !$Self->_CreateMentionTable(%Param);
    return if !$Self->_CreateNotificationEvent(%Param);

    return 1;
}

sub _CreateMentionTable {
    my ( $Self, %Param ) = @_;

    my $MentionsTableExists = $Self->TableExists(
        Table => 'mentions',
    );

    return 1 if $MentionsTableExists;

    my @XMLStrings = (
        '<TableCreate Name="mention">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER"/>
            <Column Name="user_id" Type="INTEGER"/>
            <Column Name="ticket_id" Type="INTEGER"/>
            <Column Name="article_id" Type="INTEGER"/>
            <Column Name="create_time" Type="DATE"/>
            <Index Name="mention_user_id">
                <IndexColumn Name="user_id"/>
            </Index>
            <Index Name="mention_ticket_id">
                <IndexColumn Name="ticket_id"/>
            </Index>
            <Index Name="mention_article_id">
                <IndexColumn Name="article_id"/>
            </Index>
        </TableCreate>',
    );

    return if !$Self->ExecuteXMLDBArray(
        XMLArray => \@XMLStrings,
    );

    return 1;
}

sub _CreateNotificationEvent {
    my ( $Self, %Param ) = @_;

    my $NotificationEventObject = $Kernel::OM->Get('Kernel::System::NotificationEvent');

    my %NotificationData = (
        Name => 'Mention notification',
        Data => {
            AgentEnabledByDefault    => ['Email'],
            ArticleAttachmentInclude => [0],
            Events                   => ['UserMention'],
            LanguageID               => ['en'],
            TransportEmailTemplate   => ['Default'],
            Transports               => ['Email'],
            VisibleForAgent          => [1],
        },
        Message => {
            en => {
                Subject => 'Mention in ticket: <OTRS_TICKET_Title>',
                Body    => 'You have been mentioned in ticket <OTRS_TICKET_NUMBER>
<OTRS_AGENT_BODY[5]',
                ContentType => 'text/plain',
            },
            de => {
                Subject => 'Erwähnung in Ticket: <OTRS_TICKET_Title>',
                Body    => 'Sie wurden erwähnt in Ticket <OTRS_TICKET_NUMBER>
<OTRS_AGENT_BODY[5]',
                ContentType => 'text/plain',
            },
        },

        #         Comment => '', # (optional)
        ValidID => 1,
        UserID  => 1,
    );

    my %Notification = $NotificationEventObject->NotificationGet(
        Name => $NotificationData{Name},
    );

    if (%Notification) {
        $NotificationData{ID} = $Notification{ID};

        return if !$NotificationEventObject->NotificationUpdate(%NotificationData);
        return 1;
    }

    return if !$NotificationEventObject->NotificationAdd(%NotificationData);

    return 1;
}

1;
