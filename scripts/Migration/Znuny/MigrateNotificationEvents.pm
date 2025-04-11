# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
## nofilter(TidyAll::Plugin::Znuny::Perl::Pod::NamePod)

package scripts::Migration::Znuny::MigrateNotificationEvents;    ## no critic

use strict;
use warnings;

use utf8;

use parent qw(scripts::Migration::Base);

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::System::NotificationEvent',
);

=head1 SYNOPSIS

Migrates existing notification events.

=head1 PUBLIC INTERFACE

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    return if !$Self->_MigrateEmailDeliveryFailureNotification(%Param);

    return 1;
}

sub _MigrateEmailDeliveryFailureNotification {
    my ( $Self, %Param ) = @_;

    my $NotificationEventObject = $Kernel::OM->Get('Kernel::System::NotificationEvent');

    my %NotificationEvents = $NotificationEventObject->NotificationList(

        # Type    => 'Ticket', # type of notifications; default: 'Ticket'
        Details => 1,    # include notification detailed data. possible (0|1) # ; default: 0
        All => 1,    # optional: if given all notification types will be returned, even if type is given (possible: 0|1)
    );

    my %NotificationEventsToUpdateByName = (
        'Ticket email delivery failure notification' => 1,
    );

    NOTIFICATIONEVENTID:
    for my $NotificationEventID ( sort keys %NotificationEvents ) {
        my $NotificationEvent = $NotificationEvents{$NotificationEventID};
        next NOTIFICATIONEVENTID if !$NotificationEventsToUpdateByName{ $NotificationEvent->{Name} };

        next NOTIFICATIONEVENTID if IsHashRefWithData( $NotificationEvent->{Message}->{de} );

        $NotificationEvent->{Message}->{de}->{ContentType} = 'text/plain';
        $NotificationEvent->{Message}->{de}->{Subject}     = 'Fehler beim Versand einer E-Mail';
        $NotificationEvent->{Message}->{de}->{Body}        = 'Hallo <OTRS_NOTIFICATION_RECIPIENT_UserFirstname>,

bitte beachten Sie, dass der Versand eines E-Mail-Artikels für [<OTRS_CONFIG_Ticket::Hook><OTRS_CONFIG_Ticket::HookDivider><OTRS_TICKET_TicketNumber>] fehlgeschlagen ist. Bitte überprüfen Sie die E-Mail-Adresse des Empfängers auf Fehler und versuchen Sie es erneut. Sie können den Artikel bei Bedarf manuell aus dem Ticket erneut senden.

Fehlermeldung:
<OTRS_AGENT_TransmissionStatusMessage>

<OTRS_CONFIG_HttpType>://<OTRS_CONFIG_FQDN>/<OTRS_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<OTRS_TICKET_TicketID>;ArticleID=<OTRS_TICKET_LAST_ARTICLE_ID>

-- <OTRS_CONFIG_NotificationSenderName>';

        my $NotificationEventUpdated = $NotificationEventObject->NotificationUpdate(
            %{$NotificationEvent},
            UserID => 1,
        );
        next NOTIFICATIONEVENTID if $NotificationEventUpdated;

        print "    Error updating notification event with ID $NotificationEventID.\n";
        return;
    }

    return 1;
}

1;
