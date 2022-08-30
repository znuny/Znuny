# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package scripts::Migration::Znuny::UpgradeDatabaseStructure::RecreateForeignKeysToArticleTable;    ## no critic

use strict;
use warnings;

use parent qw(scripts::Migration::Base);

our @ObjectDependencies = (
    'Kernel::System::DB',
    'Kernel::System::Log',
);

=head1 SYNOPSIS

Re-creates missing foreign keys that point to database table "article".

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    return if !$Self->_RecreateForeignKeysPointingToArticleTable();

    return 1;
}

=head2 _RecreateForeignKeysPointingToArticleTable()

re-create foreign keys pointing to the current article table,
due in some cases these are automatically redirected to the renamed table.

Returns 1 on success

    my $Result = $DBUpdateTo6Object->_RecreateForeignKeysPointingToArticleTable();

=cut

sub _RecreateForeignKeysPointingToArticleTable {
    my ( $Self, %Param ) = @_;

    # Re-create foreign keys pointing to the current article table.
    my @XMLStrings = (
        '<TableAlter Name="ticket_history">
            <ForeignKeyCreate ForeignTable="article">
                <Reference Local="article_id" Foreign="id"/>
            </ForeignKeyCreate>
        </TableAlter>',
        '<TableAlter Name="article_flag">
            <ForeignKeyCreate ForeignTable="article">
                <Reference Local="article_id" Foreign="id"/>
            </ForeignKeyCreate>
        </TableAlter>',
        '<TableAlter Name="time_accounting">
            <ForeignKeyCreate ForeignTable="article">
                <Reference Local="article_id" Foreign="id"/>
            </ForeignKeyCreate>
        </TableAlter>',
    );

    return if !$Self->ExecuteXMLDBArray(
        XMLArray => \@XMLStrings,
    );

    return 1;
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
