# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::CustomerCompany::Event::CustomerUserUpdate;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::System::CustomerUser',
    'Kernel::System::Log',
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
    for my $Needed (qw( CustomerID OldCustomerID )) {
        if ( !$Param{Data}->{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed in Data!"
            );
            return;
        }
    }

    return 1 if $Param{Data}->{CustomerID} eq $Param{Data}->{OldCustomerID};

    # get customer user object
    my $CustomerUserObject = $Kernel::OM->Get('Kernel::System::CustomerUser');

    my %CustomerUsers = $CustomerUserObject->CustomerSearch(
        CustomerIDRaw => $Param{Data}->{OldCustomerID},
        Valid         => 0,
    );

    for my $CustomerUserLogin ( sort keys %CustomerUsers ) {
        my %CustomerData = $CustomerUserObject->CustomerUserDataGet(
            User => $CustomerUserLogin,
        );

        # we do not need to 'change' the password (this would re-hash it!)
        delete $CustomerData{UserPassword};
        $CustomerUserObject->CustomerUserUpdate(
            %CustomerData,
            ID             => $CustomerUserLogin,
            UserCustomerID => $Param{Data}->{CustomerID},
            UserID         => $Param{UserID},
        );
    }

    return 1;
}

1;
