# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package scripts::Migration::Znuny::UpgradeDatabaseStructure::CalendarColor;    ## no critic

use strict;
use warnings;
use utf8;

use parent qw(scripts::Migration::Base);

our @ObjectDependencies = (
    'Kernel::System::Calendar',
);

=head1 SYNOPSIS

TODO: Done

Alters color column in database table C<calendar> to 25 characters.

Adds 'FF' to the end of the color if length and structure of color is like #83bfc8

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    my $CalendarTableExists = $Self->TableExists(
        Table => 'calendar',
    );
    return 1 if !$CalendarTableExists;

    return if !$Self->_AlterCalendarColorTable(%Param);
    return if !$Self->_UpdateCalendarColor(%Param);

    return 1;
}

sub _AlterCalendarColorTable {
    my ( $Self, %Param ) = @_;

    my @XMLStrings = (
        '<TableAlter Name="calendar">
            <ColumnChange NameOld="color" NameNew="color" Required="true" Size="25" Type="VARCHAR"/>
        </TableAlter>',
    );

    return if !$Self->ExecuteXMLDBArray(
        XMLArray => \@XMLStrings,
    );

    return 1;
}

sub _UpdateCalendarColor {
    my ( $Self, %Param ) = @_;

    my $CalendarObject = $Kernel::OM->Get('Kernel::System::Calendar');
    my @CalendarList   = $CalendarObject->CalendarList(
        UserID => 1,
        Valid  => 0,
    );

    CALENDARID:
    for my $Calendar (@CalendarList) {

        my %Calendar = $CalendarObject->CalendarGet(
            CalendarID => $Calendar->{CalendarID},
            UserID     => 1,
        );

        my $Color = $Calendar{Color};

        # next if no '#' at the beginning
        next CALENDARID if $Color !~ /^#/;

        # Next CALENDARID if length and structure of color is like #83bfc8ff
        # '#' and 8 characters after it
        next CALENDARID if $Color =~ /^#([0-9a-fA-F]{8})$/;

        # Add 'FF' to the end of the color if length and structure of color is like #83bfc8
        if ( $Color =~ /^#([0-9a-fA-F]{6})$/ ) {
            $Color = '#' . $1 . 'FF';
        }

        $CalendarObject->CalendarUpdate(
            CalendarID => $Calendar->{CalendarID},
            %Calendar,
            Color  => $Color,
            UserID => 1,
        );
    }

    return 1;
}

1;
