# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Output::HTML::Dashboard::CustomerIDStatus;

use strict;
use warnings;

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    # get needed parameters
    for my $Needed (qw(Config Name UserID)) {
        die "Got no $Needed!" if ( !$Self->{$Needed} );
    }

    $Self->{PrefKey} = 'UserDashboardPref' . $Self->{Name} . '-Shown';

    $Self->{CacheKey} = $Self->{Name};

    return $Self;
}

sub Preferences {
    my ( $Self, %Param ) = @_;

    return;
}

sub Config {
    my ( $Self, %Param ) = @_;

    return (
        %{ $Self->{Config} },

        # caching not needed
        CacheKey => undef,
        CacheTTL => undef,
    );
}

sub Run {
    my ( $Self, %Param ) = @_;

    return if !$Param{CustomerID};

    my $CustomerIDRaw = $Param{CustomerID};

    # get ticket object
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    # escalated tickets
    my $Count = $TicketObject->TicketSearch(
        TicketEscalationTimeOlderMinutes => 1,
        CustomerIDRaw                    => $CustomerIDRaw,
        Result                           => 'COUNT',
        Permission                       => $Self->{Config}->{Permission},
        UserID                           => $Self->{UserID},
        CacheTTL                         => $Self->{Config}->{CacheTTLLocal} * 60,
    ) || 0;

    # get layout object
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    $LayoutObject->Block(
        Name => 'ContentSmallCustomerIDStatusEscalatedTickets',
        Data => {
            %Param,
            Count => $Count
        },
    );

    # open tickets
    $Count = $TicketObject->TicketSearch(
        StateType     => 'Open',
        CustomerIDRaw => $CustomerIDRaw,
        Result        => 'COUNT',
        Permission    => $Self->{Config}->{Permission},
        UserID        => $Self->{UserID},
        CacheTTL      => $Self->{Config}->{CacheTTLLocal} * 60,
    ) || 0;

    $LayoutObject->Block(
        Name => 'ContentSmallCustomerIDStatusOpenTickets',
        Data => {
            %Param,
            Count => $Count
        },
    );

    # closed tickets
    $Count = $TicketObject->TicketSearch(
        StateType     => 'Closed',
        CustomerIDRaw => $CustomerIDRaw,
        Result        => 'COUNT',
        Permission    => $Self->{Config}->{Permission},
        UserID        => $Self->{UserID},
        CacheTTL      => $Self->{Config}->{CacheTTLLocal} * 60,
    ) || 0;

    $LayoutObject->Block(
        Name => 'ContentSmallCustomerIDStatusClosedTickets',
        Data => {
            %Param,
            Count => $Count
        },
    );

    # all tickets
    $Count = $TicketObject->TicketSearch(
        CustomerIDRaw => $CustomerIDRaw,
        Result        => 'COUNT',
        Permission    => $Self->{Config}->{Permission},
        UserID        => $Self->{UserID},
        CacheTTL      => $Self->{Config}->{CacheTTLLocal} * 60,
    ) || 0;

    $LayoutObject->Block(
        Name => 'ContentSmallCustomerIDStatusAllTickets',
        Data => {
            %Param,
            Count => $Count
        },
    );

    # archived tickets
    if ( $Kernel::OM->Get('Kernel::Config')->Get('Ticket::ArchiveSystem') ) {
        $Count = $TicketObject->TicketSearch(
            CustomerIDRaw => $CustomerIDRaw,
            ArchiveFlags  => ['y'],
            Result        => 'COUNT',
            Permission    => $Self->{Config}->{Permission},
            UserID        => $Self->{UserID},
            CacheTTL      => $Self->{Config}->{CacheTTLLocal} * 60,
        ) || 0;

        $LayoutObject->Block(
            Name => 'ContentSmallCustomerIDStatusArchivedTickets',
            Data => {
                %Param,
                Count => $Count
            },
        );
    }

    my $Content = $LayoutObject->Output(
        TemplateFile => 'AgentDashboardCustomerIDStatus',
        Data         => {
            %{ $Self->{Config} },
            Name => $Self->{Name},
        },
        AJAX => $Param{AJAX},
    );

    return $Content;
}

1;
