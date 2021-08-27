# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::UnitTest::TicketToUnitTest::TicketObject::Service;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::System::Service',
);

use Kernel::System::VariableCheck qw(:all);
use parent qw( Kernel::System::UnitTest::TicketToUnitTest::Base );

sub Run {
    my ( $Self, %Param ) = @_;

    my $ServiceObject = $Kernel::OM->Get('Kernel::System::Service');

    return '' if !IsArrayRefWithData( $Param{Service} );

    my $Output = <<OUTPUT;

# Service setup

OUTPUT

    for my $Service ( @{ $Param{Service} } ) {

        $Output .= <<OUTPUT;
## Service '$Service'

\$ZnunyHelperObject->_ServiceCreateIfNotExists(
    Name => '$Service',
);

OUTPUT

    }

    return $Output;

}

1;
