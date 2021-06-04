# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::CustomerUser::Event::SearchProfileUpdate;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::System::Log',
    'Kernel::System::SearchProfile',
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw( Data Event Config UserID )) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }
    for my $Needed (qw( UserLogin NewData OldData )) {
        if ( !$Param{Data}->{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed in Data!"
            );
            return;
        }
    }

    # only update CustomerUser search profiles if fields have really changed
    if ( lc $Param{Data}->{OldData}->{UserLogin} ne lc $Param{Data}->{NewData}->{UserLogin} ) {

        # update searchprofiles
        $Kernel::OM->Get('Kernel::System::SearchProfile')->SearchProfileUpdateUserLogin(
            Base         => 'CustomerTicketSearch',
            UserLogin    => $Param{Data}->{OldData}->{UserLogin},
            NewUserLogin => $Param{Data}->{NewData}->{UserLogin},
        );
    }

    return 1;
}

1;
