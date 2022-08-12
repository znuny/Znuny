# --
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package scripts::Migration::Znuny::UpgradeDatabaseStructure::StateColor;    ## no critic

use strict;
use warnings;

use parent qw(scripts::Migration::Base);

our @ObjectDependencies = (
    'Kernel::System::State',
);

=head1 SYNOPSIS

Adds new column color to ticket_state table and also add a default value for initial states.

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    return if !$Self->_AddColorColumnToStateTable(%Param);
    return if !$Self->_UpdateStateEntries(%Param);

    return 1;
}

sub _AddColorColumnToStateTable {
    my ( $Self, %Param ) = @_;

    my $ColorColumnExists = $Self->ColumnExists(
        Table  => 'ticket_state',
        Column => 'color',
    );
    return 1 if $ColorColumnExists;

    my @XMLStrings = (
        '<TableAlter Name="ticket_state">
            <ColumnAdd Name="color" Required="true" Size="25" Type="VARCHAR" />
        </TableAlter>',
    );

    return if !$Self->ExecuteXMLDBArray(
        XMLArray => \@XMLStrings,
    );

    return 1;
}

sub _UpdateStateEntries {
    my ( $Self, %Param ) = @_;

    my $StateObject = $Kernel::OM->Get('Kernel::System::State');

    my %ColorByState = (
        'new'                 => '#50B5FF',
        'closed successful'   => '#3DD598',
        'closed unsuccessful' => '#FC5A5A',
        'open'                => '#FFC542',
        'removed'             => '#8D8D9B',
        'pending reminder'    => '#FF8A25',
        'pending auto close+' => '#3DD598',
        'pending auto close-' => '#FC5A5A',
        'merged'              => '#8D8D9B',
    );

    my %StateList = $StateObject->StateList(
        UserID => 1,
    );
    return 1 if !%StateList;

    STATEID:
    for my $StateID ( sort keys %StateList ) {
        my %State = $StateObject->StateGet(
            ID => $StateID,
        );
        next STATEID if !%State;

        $StateObject->StateUpdate(
            %State,
            Color  => $ColorByState{ $State{Name} } // '#FFFFFF',
            UserID => 1,
        );
    }

    return 1;
}

1;
