# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::TicketActionCommon::CustomerInformation;

use parent 'Kernel::Output::HTML::Base';

use strict;
use warnings;
use utf8;

our $ObjectManagerDisabled = 1;

sub Run {
    my ( $Self, %Param ) = @_;

    my $ConfigObject       = $Kernel::OM->Get('Kernel::Config');
    my $CustomerUserObject = $Kernel::OM->Get('Kernel::System::CustomerUser');
    my $LayoutObject       = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    my $Config = $Param{Config};

    my %CustomerData;
    if ( $Param{Ticket}->{CustomerUserID} ) {
        %CustomerData = $CustomerUserObject->CustomerUserDataGet(
            User => $Param{Ticket}->{CustomerUserID},
        );
    }

    if ( $CustomerData{UserTitle} ) {
        $CustomerData{UserTitle} = $LayoutObject->{LanguageObject}->Translate( $CustomerData{UserTitle} );
    }

    my $CustomerTable = $LayoutObject->AgentCustomerViewTable(
        Data   => \%CustomerData,
        Ticket => $Param{Ticket},
        Max    => $ConfigObject->Get('Ticket::Frontend::CustomerInfoZoomMaxSize'),
    );

    # Hide empty customer information widget when nothing is to show.
    my $None = $LayoutObject->{LanguageObject}->Translate('none');

    return if $CustomerTable eq $None;

    my $Output = $LayoutObject->Output(
        TemplateFile => 'AgentTicketActionCommon/CustomerInfo',
        Data         => {
            %Param,
            CustomerTable => $CustomerTable,
        },
    );

    return {
        Output => $Output,
    };
}

1;
