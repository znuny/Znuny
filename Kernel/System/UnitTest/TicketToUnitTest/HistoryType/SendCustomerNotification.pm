# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::UnitTest::TicketToUnitTest::HistoryType::SendCustomerNotification;

use strict;
use warnings;
use utf8;

our @ObjectDependencies = (
    'Kernel::System::Log',
    'Kernel::System::Ticket::Event::NotificationEvent',
);

use parent qw( Kernel::System::UnitTest::TicketToUnitTest::Base );

sub Run {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    NEEDED:
    for my $Needed (qw(Name)) {

        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    $Param{Name} =~ /^\%\%($Param{Recipient}->{UserEmail})/;

    $Param{RecipientUserEmail} ||= $1;
    $Param{Event}              ||= 'SendCustomerNotification';

    my $Output = <<OUTPUT;
# This is not fully implemented yet.
# Please check the implementation in the Kernel::System::Ticket::Event::NotificationEvent module.
# In most cases, it makes no sense to test this history type.
#
# my \$NotificationEventObject = \$Kernel::OM->Get('Kernel::System::Ticket::Event::NotificationEvent');
#
# \$Success = \$NotificationEventObject->_SendRecipientNotification(
#     TicketID        => \$TicketID,
#     Notification    => '$Param{NotificationName}',
#     Recipient       => '$Param{RecipientUserEmail}',
#     Event           => '$Param{Event}',
#     Transport       => '$Param{Transport}',
#     TransportObject => \$TransportObject,   # please check this object
#     UserID          => \$UserID,
# );
#
# \$Self->True(
#     \$Success,
#     '_SendRecipientNotification "$Param{NotificationName}" to "$Param{RecipientUserLogin}" was successful.',
# );
#
OUTPUT

    return $Output;
}

1;
