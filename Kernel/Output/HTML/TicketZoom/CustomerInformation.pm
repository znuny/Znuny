# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Output::HTML::TicketZoom::CustomerInformation;

use parent 'Kernel::Output::HTML::Base';

use strict;
use warnings;

our $ObjectManagerDisabled = 1;

sub Run {
    my ( $Self, %Param ) = @_;

    my %CustomerData;
    if ( $Param{Ticket}->{CustomerUserID} ) {
        %CustomerData = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerUserDataGet(
            User => $Param{Ticket}->{CustomerUserID},
        );
    }

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    if ( $CustomerData{UserTitle} ) {
        $CustomerData{UserTitle} = $LayoutObject->{LanguageObject}->Translate( $CustomerData{UserTitle} );
    }

    my $CustomerTable = $LayoutObject->AgentCustomerViewTable(
        Data   => \%CustomerData,
        Ticket => $Param{Ticket},
        Max    => $Kernel::OM->Get('Kernel::Config')->Get('Ticket::Frontend::CustomerInfoZoomMaxSize'),
    );
    my $Output = $LayoutObject->Output(
        TemplateFile => 'AgentTicketZoom/CustomerInformation',
        Data         => {
            CustomerTable => $CustomerTable,
        },
    );

    my $Config = $Param{Config};
    my %Rank;
    %Rank = ( Rank => $Config->{Rank} ) if exists $Config->{Rank} && defined $Config->{Rank};

    return {
        Output => $Output,
        %Rank,
    };
}

1;
