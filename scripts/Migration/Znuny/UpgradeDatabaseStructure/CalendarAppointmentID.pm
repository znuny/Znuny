# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package scripts::Migration::Znuny::UpgradeDatabaseStructure::CalendarAppointmentID;    ## no critic

use strict;
use warnings;

use parent qw(scripts::Migration::Base);

our @ObjectDependencies = (
    'Kernel::System::DB',
);

=head1 SYNOPSIS

Sets the Datatype of AppointmentID from SmallInt -> BigInt

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    return if !$Self->_IncreaseColumnsSize(%Param);

    return 1;
}

sub _IncreaseColumnsSize {
    my ( $Self, %Param ) = @_;

    my @XMLStrings = (
        '<TableAlter Name="calendar_appointment_plugin">
            <ColumnChange NameOld="appointment_id" NameNew="appointment_id" Required="true" Type="BIGINT"/>
        </TableAlter>'
    );

    return if !$Self->ExecuteXMLDBArray(
        XMLArray => \@XMLStrings,
    );

    return 1;
}
1;
