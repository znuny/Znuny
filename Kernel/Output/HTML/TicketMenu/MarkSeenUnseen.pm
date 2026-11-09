# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::TicketMenu::MarkSeenUnseen;

use strict;
use warnings;
use utf8;

use parent 'Kernel::Output::HTML::TicketMenu::Generic';

our @ObjectDependencies = (
    'Kernel::Output::HTML::Layout',
    'Kernel::System::Ticket::Article',
);

sub Run {
    my ( $Self, %Param ) = @_;

    my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');
    my $LayoutObject  = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    my $Item = $Self->SUPER::Run(%Param);
    return if !$Item;

    my $Link = $Param{Config}->{Link} // '';
    my ($Subaction) = $Link =~ m{Subaction=(Seen|Unseen)};
    return $Item if !$Subaction;

    my @ArticleIDs = $ArticleObject->ArticleIndex(
        TicketID => $Param{Ticket}->{TicketID},
    );
    return if !@ArticleIDs;

    my %ArticleFlags = $ArticleObject->ArticleFlagsOfTicketGet(
        TicketID => $Param{Ticket}->{TicketID},
        UserID   => $Self->{UserID},
    );

    my $SeenCount   = grep { $ArticleFlags{$_} && $ArticleFlags{$_}->{Seen} } @ArticleIDs;
    my $UnseenCount = scalar @ArticleIDs - $SeenCount;

    # Both actions stay in the DOM. TicketZoom JS toggles Hidden when an article is marked seen.
    $LayoutObject->AddJSData(
        Key   => 'MarkSeenUnseen',
        Value => {
            Seen   => $SeenCount,
            Unseen => $UnseenCount,
        },
    );

    $Item->{ListClass} = 'MarkTicket' . $Subaction;

    # Mark as seen only while an unread article remains.
    # Mark as unseen only while a read article remains.
    if ( $Subaction eq 'Seen' && !$UnseenCount ) {
        $Item->{ListClass} .= ' Hidden';
    }
    elsif ( $Subaction eq 'Unseen' && !$SeenCount ) {
        $Item->{ListClass} .= ' Hidden';
    }

    return $Item;
}

1;
