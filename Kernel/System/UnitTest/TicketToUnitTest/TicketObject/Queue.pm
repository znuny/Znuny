# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::UnitTest::TicketToUnitTest::TicketObject::Queue;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::System::Queue',
);

use Kernel::System::VariableCheck qw(:all);
use parent qw( Kernel::System::UnitTest::TicketToUnitTest::Base );

sub Run {
    my ( $Self, %Param ) = @_;

    my $QueueObject = $Kernel::OM->Get('Kernel::System::Queue');

    return '' if !IsArrayRefWithData( $Param{Queue} );

    my $Output = <<OUTPUT;

# Queue setup

OUTPUT

    for my $Queue ( @{ $Param{Queue} } ) {

        my %QueueData = $QueueObject->QueueGet(
            Name => $Queue,
        );

        $Output .= <<OUTPUT;
## Queue '$QueueData{Name}'

\$ZnunyHelperObject->_QueueCreateIfNotExists(
OUTPUT

        for my $Attribute ( sort keys %QueueData ) {
            $QueueData{$Attribute} //= '';

            $Output .= <<OUTPUT;
    '$Attribute' => '$QueueData{$Attribute}',
OUTPUT

        }
        $Output .= ');';

    }

    return $Output;

}

1;
