# --
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package scripts::Migration::Znuny6_3::AddHistoryTypes;    ## no critic

use strict;
use warnings;

use parent qw(scripts::Migration::Base);

our @ObjectDependencies = (
    'Kernel::System::DB',
);

sub Run {
    my ( $Self, %Param ) = @_;

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    my @HistoryTypes = (
        'Bulk',
    );

    HISTORYTYPE:
    for my $HistoryType (@HistoryTypes) {

        # Check if history type is already present.
        my $SQL  = 'SELECT id FROM ticket_history_type WHERE name = ?';
        my @Bind = (
            \$HistoryType,
        );

        return if !$DBObject->Prepare(
            SQL   => $SQL,
            Bind  => \@Bind,
            Limit => 1,
        );

        my $HistoryTypeFound;
        while ( $DBObject->FetchrowArray() ) {
            $HistoryTypeFound = 1;
        }

        next HISTORYTYPE if $HistoryTypeFound;

        my @XML = (
            '<Insert Table="ticket_history_type">
                <Data Key="name" Type="Quote">' . $HistoryType . '</Data>
                <Data Key="valid_id">1</Data>
                <Data Key="create_by">1</Data>
                <Data Key="create_time">current_timestamp</Data>
                <Data Key="change_by">1</Data>
                <Data Key="change_time">current_timestamp</Data>
            </Insert>',
        );

        return if !$Self->ExecuteXMLDBArray(
            XMLArray => \@XML,
        );
    }

    return 1;
}

1;
