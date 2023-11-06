# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Output::HTML::ToolBar::TicketSearchProfile;

use parent 'Kernel::Output::HTML::Base';

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::Output::HTML::Layout',
    'Kernel::System::SearchProfile',
    'Kernel::System::User',
);

sub Run {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    my %User = $Kernel::OM->Get('Kernel::System::User')->GetUserData(
        UserID => $Self->{UserID},
    );

    my %SearchProfiles = $Kernel::OM->Get('Kernel::System::SearchProfile')->SearchProfileList(
        Base      => 'TicketSearch',
        UserLogin => $User{UserLogin},
    );

    my $Priority = $Param{Config}->{'Priority'};
    my %Return   = ();

    my $HTMLSearchProfiles = '<ul>';
    for my $SearchProfile ( sort keys %SearchProfiles ) {
        $HTMLSearchProfiles .= '<li>';
        $HTMLSearchProfiles
            .= '<a href="'
            . $LayoutObject->{Baselink}
            . 'Action=AgentTicketSearch;Subaction=Search;TakeLastSearch=1;SaveProfile=1;Profile='
            . $SearchProfile . '" class="ToolBarSearchProfile dropdown-item">'
            . '<i class="fa fa-search"></i>'
            . '<span>' . $SearchProfile . '</span>'
            . '</a>';
        $HTMLSearchProfiles .= '</li>';
    }
    $HTMLSearchProfiles .= '</ul>';

    $Return{ $Priority++ } = {
        Block       => $Param{Config}->{Block},
        Description => $Param{Config}->{Description},
        Name        => $Param{Config}->{Name},
        Image       => '',
        Link        => $HTMLSearchProfiles,
        AccessKey   => '',
    };

    return %Return;
}

1;
