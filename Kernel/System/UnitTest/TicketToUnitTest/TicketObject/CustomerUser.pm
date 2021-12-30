# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::UnitTest::TicketToUnitTest::TicketObject::CustomerUser;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::System::CustomerUser',
);

use Kernel::System::VariableCheck qw(:all);
use parent qw( Kernel::System::UnitTest::TicketToUnitTest::Base );

sub Run {
    my ( $Self, %Param ) = @_;

    my $CustomerUserObject = $Kernel::OM->Get('Kernel::System::CustomerUser');

    return '' if !IsArrayRefWithData( $Param{CustomerUser} );

    my $Output = <<OUTPUT;

# CustomerUser setup

OUTPUT

    CUSTOEMRUSER:
    for my $CustomerUser ( @{ $Param{CustomerUser} } ) {

        my %CustomerUser = $CustomerUserObject->CustomerUserDataGet(
            User => $CustomerUser,
        );

        next CUSTOEMRUSER if !%CustomerUser;

        $Output .= <<OUTPUT;
## CustomerUser '$CustomerUser{UserLogin}' - $CustomerUser{UserFirstname} $CustomerUser{UserLastname}

\$HelperObject->TestCustomerUserCreate(
    UserFirstname  => '$CustomerUser{UserFirstname}',
    UserLastname   => '$CustomerUser{UserLastname}',
    UserCustomerID => '$CustomerUser{UserCustomerID}',
    UserLogin      => '$CustomerUser{UserLogin}',
    UserEmail      => '$CustomerUser{UserEmail}',
    ValidID        => 1,
    UserID         => 1,
);

OUTPUT

    }

    return $Output;

}

1;
