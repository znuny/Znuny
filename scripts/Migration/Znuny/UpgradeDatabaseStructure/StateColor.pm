# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package scripts::Migration::Znuny::UpgradeDatabaseStructure::StateColor;    ## no critic

use strict;
use warnings;
use utf8;

use parent qw(scripts::Migration::Base);

our @ObjectDependencies = (
    'Kernel::System::State',
);

=head1 SYNOPSIS

TODO: Done

Column size of color column in database table C<ticket_state> is already 25 characters. (3 years ago)
Adds 'FF' to the end of the color if length and structure of color is like #83bfc8

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    my $StateTableExists = $Self->TableExists(
        Table => 'ticket_state',
    );
    return 1 if !$StateTableExists;

    return if !$Self->_UpdateStateColor(%Param);

    return 1;
}

sub _UpdateStateColor {
    my ( $Self, %Param ) = @_;

    my $StateObject = $Kernel::OM->Get('Kernel::System::State');
    my %StateList   = $StateObject->StateList(
        UserID => 1,
        Valid  => 0,
    );

    STATEID:
    for my $StateID ( sort keys %StateList ) {

        my %State = $StateObject->StateGet(
            ID => $StateID,
        );
        next STATEID if !%State;

        my $Color = $State{Color};

        # next if no '#' at the beginning
        next STATEID if $Color !~ /^#/;

        # Next STATEID if length and structure of color is like #83bfc8ff
        # '#' and 8 characters after it
        next STATEID if $Color =~ /^#([0-9a-fA-F]{8})$/;

        # Add 'FF' to the end of the color if length and structure of color is like #83bfc8
        if ( $Color =~ /^#([0-9a-fA-F]{6})$/ ) {
            $Color = '#' . $1 . 'FF';
        }

        $StateObject->StateUpdate(
            ID => $StateID,
            %State,
            Color  => $Color,
            UserID => 1,
        );
    }

    return 1;
}

1;
