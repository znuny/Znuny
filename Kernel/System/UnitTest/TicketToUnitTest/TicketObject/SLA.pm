# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::UnitTest::TicketToUnitTest::TicketObject::SLA;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::System::SLA',
);

use Kernel::System::VariableCheck qw(:all);
use parent qw( Kernel::System::UnitTest::TicketToUnitTest::Base );

sub Run {
    my ( $Self, %Param ) = @_;

    my $SLAObject = $Kernel::OM->Get('Kernel::System::SLA');

    return '' if !IsArrayRefWithData( $Param{SLA} );

    my $Output = <<OUTPUT;

# SLA setup

OUTPUT

    SLA:
    for my $SLA ( @{ $Param{SLA} } ) {

        my $SLAID = $SLAObject->SLALookup(
            Name => $SLA,
        );

        next SLA if !$SLAID;

        my %SLAData = $SLAObject->SLAGet(
            SLAID  => $SLAID,
            UserID => 1,
        );

        next SLA if !%SLAData;

        $Output .= <<OUTPUT;
## SLA '$SLAData{Name}'

\$ZnunyHelperObject->_SLACreateIfNotExists(
    Name                => '$SLAData{Name}',
    ServiceIDs          => [],                    # should not be necessary for UnitTest
    FirstResponseTime   => '$SLAData{FirstResponseTime}',
    FirstResponseNotify => '$SLAData{FirstResponseNotify}',
    UpdateTime          => '$SLAData{UpdateTime}',
    UpdateNotify        => '$SLAData{UpdateNotify}',
    SolutionTime        => '$SLAData{SolutionTime}',
    SolutionNotify      => '$SLAData{SolutionNotify}',
);

OUTPUT

    }

    return $Output;

}

1;
