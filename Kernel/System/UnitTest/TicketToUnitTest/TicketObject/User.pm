# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::UnitTest::TicketToUnitTest::TicketObject::User;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::System::User',
);

use Kernel::System::VariableCheck qw(:all);
use parent qw( Kernel::System::UnitTest::TicketToUnitTest::Base );

sub Run {
    my ( $Self, %Param ) = @_;

    my $UserObject = $Kernel::OM->Get('Kernel::System::User');

    return '' if !IsArrayRefWithData( $Param{User} );

    my $Output;
    my $Header = <<OUTPUT;

# User setup

OUTPUT

    USER:
    for my $User ( @{ $Param{User} } ) {

        my %User = $UserObject->GetUserData(
            User => $User,
        );

        next USER if !%User;

        $Output .= <<OUTPUT;
## User '$User{UserLogin}' - $User{UserFirstname} $User{UserLastname}

\$HelperObject->TestUserCreate(
    UserFirstname  => '$User{UserFirstname}',
    UserLastname   => '$User{UserLastname}',
    UserLogin      => '$User{UserLogin}',
    UserEmail      => '$User{UserEmail}',
    ValidID        => 1,
    UserID         => 1,
);

OUTPUT

    }

    return '' if !$Output;
    $Output = $Header . $Output;

    return $Output;

}

1;
