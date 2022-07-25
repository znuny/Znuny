# --
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::TicketZoom::Mentions;

use parent 'Kernel::Output::HTML::Base';

use strict;
use warnings;
use Kernel::System::VariableCheck qw(:all);

our $ObjectManagerDisabled = 1;

sub Run {
    my ( $Self, %Param ) = @_;

    my $MentionObject = $Kernel::OM->Get('Kernel::System::Mention');
    my $LayoutObject  = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $UserObject    = $Kernel::OM->Get('Kernel::System::User');

    my $Mentions = $MentionObject->GetTicketMentions(
        TicketID => $Param{Ticket}->{TicketID},
    ) // [];

    my %Users;

    MENTION:
    for my $Mention ( @{$Mentions} ) {
        next MENTION if $Users{ $Mention->{UserID} };

        my %User = $UserObject->GetUserData(
            UserID => $Mention->{UserID}
        );
        next MENTION if !%User;

        my $Removable = 0;
        if (
            $Param{Ticket}->{OwnerID} == $Self->{UserID}
            || $Mention->{UserID} == $Self->{UserID}
            )
        {
            $Removable = 1;
        }

        $Users{ $User{UserID} } = 1;
        my $UserDescription = "$User{UserLogin} ($User{UserEmail})";
        $LayoutObject->Block(
            Name => "User",
            Data => {
                UserFullname => $UserDescription,
                UserID       => $User{UserID},
                Removable    => $Removable,
            }
        );
    }

    if ( !IsArrayRefWithData($Mentions) ) {
        $LayoutObject->Block(
            Name => "NoMentions",
            Data => {},
        );
    }

    my $Output = $LayoutObject->Output(
        TemplateFile => 'AgentTicketZoom/MentionsTable',
        Data         => {},
    );

    return {
        Output => $Output,
    };
}

1;
