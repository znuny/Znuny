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

TODO: Done

Column size of color column in database table C<ticket_priority> is already 25 characters. (3 years ago)
Adds 'FF' to the end of the color if length and structure of color is like #83bfc8

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    my $PriorityTableExists = $Self->TableExists(
        Table => 'ticket_priority',
    );
    return 1 if !$PriorityTableExists;

    return if !$Self->_UpdatePriorityColor(%Param);

    return 1;
}

sub _UpdatePriorityColor {
    my ( $Self, %Param ) = @_;

    my $PriorityObject = $Kernel::OM->Get('Kernel::System::Priority');
    my %PriorityList   = $PriorityObject->PriorityList(
        Valid => 0,
    );

    PRIORITYID:
    for my $PriorityID ( sort keys %PriorityList ) {

        my %Priority = $PriorityObject->PriorityGet(
            PriorityID => $PriorityID,
            UserID     => 1,
        );
        next PRIORITYID if !%Priority;

        my $Color = $Priority{Color};

        # next if no '#' at the beginning
        next PRIORITYID if $Color !~ /^#/;

        # Next PRIORITYID if length and structure of color is like #83bfc8ff
        # '#' and 8 characters after it
        next PRIORITYID if $Color =~ /^#([0-9a-fA-F]{8})$/;

        # Add 'FF' to the end of the color if length and structure of color is like #83bfc8
        if ( $Color =~ /^#([0-9a-fA-F]{6})$/ ) {
            $Color = '#' . $1 . 'FF';
        }

        $PriorityObject->PriorityUpdate(
            PriorityID => $PriorityID,
            %Priority,
            Color  => $Color,
            UserID => 1,
        );
    }

    return 1;
}

1;
