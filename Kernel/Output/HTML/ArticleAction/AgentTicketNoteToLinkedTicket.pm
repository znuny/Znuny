# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Output::HTML::ArticleAction::AgentTicketNoteToLinkedTicket;

use strict;
use warnings;
use utf8;

use Kernel::Language qw(Translatable);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::Output::HTML::Layout',
    'Kernel::System::LinkObject',
    'Kernel::System::Log',
    'Kernel::System::Ticket',
);

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

# optional AclActionLookup
sub CheckAccess {
    my ( $Self, %Param ) = @_;

    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $LinkObject   = $Kernel::OM->Get('Kernel::System::LinkObject');
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    for my $Needed (qw(Ticket Article ChannelName UserID)) {
        if ( !$Param{$Needed} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    # Only add article action to agent ticket zoom view.
    my $Action = $LayoutObject->{Action} // '';
    return if $Action ne 'AgentTicketZoom';

    return if !$ConfigObject->Get('Frontend::Module')->{AgentTicketNoteToLinkedTicket};
    return if !$Param{AclActionLookup}->{AgentTicketNoteToLinkedTicket};

    my $Config = $ConfigObject->Get('Ticket::Frontend::AgentTicketNoteToLinkedTicket');
    if ( $Config->{Permission} ) {
        my $Ok = $TicketObject->TicketPermission(
            Type     => $Config->{Permission},
            TicketID => $Param{Ticket}->{TicketID},
            UserID   => $Param{UserID},
            LogNo    => 1,
        );
        return if !$Ok;
    }

    # Expanded ticket zoom renders every shown article in this same request and
    # calls CheckAccess for each one. This is why the result will be
    # stored in $Self->{LinkedTicketAccess}.
    my $TicketID = $Param{Ticket}->{TicketID};
    if ( exists $Self->{LinkedTicketAccess}->{$TicketID} ) {
        return $Self->{LinkedTicketAccess}->{$TicketID};
    }

    # Offer the action only when a linked ticket can be read and used.
    my %LinkKeyList = $LinkObject->LinkKeyList(
        Object1 => 'Ticket',
        Key1    => $TicketID,
        Object2 => 'Ticket',
        State   => 'Valid',
        UserID  => $Param{UserID},
    );

    if ( !%LinkKeyList ) {
        $Self->{LinkedTicketAccess}->{$TicketID} = 0;
        return;
    }

    my $Permission = $Config->{Permission} || '';

    LINKEDTICKETID:
    for my $LinkedTicketID ( sort keys %LinkKeyList ) {
        my $CanRead = $TicketObject->TicketPermission(
            Type     => 'ro',
            TicketID => $LinkedTicketID,
            UserID   => $Param{UserID},
            LogNo    => 1,
        );
        next LINKEDTICKETID if !$CanRead;

        if ($Permission) {
            my $CanUse = $TicketObject->TicketPermission(
                Type     => $Permission,
                TicketID => $LinkedTicketID,
                UserID   => $Param{UserID},
                LogNo    => 1,
            );
            next LINKEDTICKETID if !$CanUse;
        }

        $Self->{LinkedTicketAccess}->{$TicketID} = 1;
        return 1;
    }

    $Self->{LinkedTicketAccess}->{$TicketID} = 0;
    return;
}

sub GetConfig {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');

    for my $Needed (qw(Ticket Article UserID)) {
        if ( !$Param{$Needed} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    my $Link
        = "Action=AgentTicketNoteToLinkedTicket;TicketID=$Param{Ticket}->{TicketID};ArticleID=$Param{Article}->{ArticleID}";
    my $Description = Translatable('Create notice for linked ticket');
    my $Name        = Translatable('Transfer notice');

    # Execute additional JavaScript if link object view mode is set to "complex".
    # This is necessary to remove the article action menu item after all linked tickets have been removed
    # from within agent ticket zoom because the page will not be reloaded.
    my $LinkObjectViewMode = $ConfigObject->Get('LinkObject::ViewMode') // '';
    if ( $LayoutObject->{Action} eq 'AgentTicketZoom' && $LinkObjectViewMode eq 'Complex' ) {
        $LayoutObject->AddJSOnDocumentCompleteIfNotExists(
            Key  => 'Core.Agent.TicketNoteToLinkedTicket',
            Code => 'Core.Agent.TicketNoteToLinkedTicket.Init();',
        );
    }

    my %MenuItem = (
        ItemType    => 'Link',
        Description => $Description,
        Name        => $Name,

        # Icon        => 'fa fa-link',
        Class => 'AsPopup PopupType_TicketAction',
        Link  => $Link,
    );

    return ( \%MenuItem );
}

1;
