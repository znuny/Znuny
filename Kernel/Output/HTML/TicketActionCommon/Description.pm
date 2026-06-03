# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::TicketActionCommon::Description;

use parent 'Kernel::Output::HTML::Base';

use strict;
use warnings;
use utf8;

our @ObjectDependencies = (
    'Kernel::Output::HTML::Layout',
);

sub Run {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    if ( !$Param{Config}->{Description} ) {
        return {};
    }

    # Show description
    my $HTMLDescription = $LayoutObject->Output(
        Template => $Param{Config}->{Description} || '',
        Data     => $Param{Ticket}                || {},
    );

    my $Output = $LayoutObject->Output(
        TemplateFile => 'AgentTicketActionCommon/Description',
        Data         => {
            %Param,
            Description => $HTMLDescription,
        }
    );

    return {
        Output => $Output,
    };
}

1;
