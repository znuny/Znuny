# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package scripts::Migration::Znuny::UpgradeDatabaseStructure::PriorityColor;    ## no critic

use strict;
use warnings;
use utf8;

use parent qw(scripts::Migration::Base);

our @ObjectDependencies = (
    'Kernel::System::Priority',
);

=head1 SYNOPSIS

Adds new column color to ticket_priority table and also add a default value for initial priorities.

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    return if !$Self->_AddColorColumnToPriorityTable(%Param);
    return if !$Self->_UpdatePriorityEntries(%Param);

    return 1;
}

sub _AddColorColumnToPriorityTable {
    my ( $Self, %Param ) = @_;

    my $ColorColumnExists = $Self->ColumnExists(
        Table  => 'ticket_priority',
        Column => 'color',
    );
    return 1 if $ColorColumnExists;

    my @XMLStrings = (
        '<TableAlter Name="ticket_priority">
            <ColumnAdd Name="color" Required="true" Size="25" Type="VARCHAR" />
        </TableAlter>',
    );

    return if !$Self->ExecuteXMLDBArray(
        XMLArray => \@XMLStrings,
    );

    return 1;
}

sub _UpdatePriorityEntries {
    my ( $Self, %Param ) = @_;

    my $PriorityObject = $Kernel::OM->Get('Kernel::System::Priority');

    my %ColorByPriority = (
        '1 very low'  => '#03c4f0',
        '2 low'       => '#83bfc8',
        '3 normal'    => '#cdcdcd',
        '4 high'      => '#ffaaaa',
        '5 very high' => '#ff505e',
    );

    my %PriorityList = $PriorityObject->PriorityList(
        UserID => 1,
    );
    return 1 if !%PriorityList;

    PriorityID:
    for my $PriorityID ( sort keys %PriorityList ) {
        my %Priority = $PriorityObject->PriorityGet(
            PriorityID => $PriorityID,
            UserID     => 1,
        );
        next PriorityID if !%Priority;

        $PriorityObject->PriorityUpdate(
            %Priority,
            PriorityID => $Priority{ID},
            Color      => $ColorByPriority{ $Priority{Name} } // '#FFFFFF',
            UserID     => 1,
        );
    }

    return 1;
}

1;
