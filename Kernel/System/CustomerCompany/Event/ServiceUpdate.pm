# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::CustomerCompany::Event::ServiceUpdate;

use strict;
use warnings;
use utf8;

our @ObjectDependencies = (
    'Kernel::System::Cache',
    'Kernel::System::DB',
    'Kernel::System::Log',
);

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    for my $Needed (qw( Data Event Config UserID )) {
        if ( !$Param{$Needed} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }
    for my $Needed (qw( CustomerID OldCustomerID )) {
        if ( !$Param{Data}->{$Needed} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $Needed in Data!"
            );
            return;
        }
    }

    return 1 if $Param{Data}->{CustomerID} eq $Param{Data}->{OldCustomerID};

    return if !$Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL  => 'UPDATE service_customer_company SET customer_id = ? WHERE customer_id = ?',
        Bind => [ \$Param{Data}->{CustomerID}, \$Param{Data}->{OldCustomerID} ],
    );

    $Kernel::OM->Get('Kernel::System::Cache')->CleanUp(
        Type => 'Service',
    );

    return 1;
}

1;
