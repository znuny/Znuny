# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package scripts::Migration::Znuny::UpgradeDatabaseStructure::ArticleColor;    ## no critic

use strict;
use warnings;

use utf8;

use parent qw(scripts::Migration::Base);

our @ObjectDependencies = (
    'Kernel::System::Ticket::Article',
);

=head1 SYNOPSIS

Creates the database table C<article_color>.
This table is used to store the article color.

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    return 1 if $Self->TableExists(
        Table => 'article_color',
    );

    return if !$Self->_CreateArticleColorTable(%Param);
    $Self->_InsertArticleColor(%Param);

    return 1;
}

sub _CreateArticleColorTable {
    my ( $Self, %Param ) = @_;

    my @XMLStrings = (
        '<Table Name="article_color">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="SMALLINT"/>
            <Column Name="name" Required="true" Size="200" Type="VARCHAR"/>
            <Column Name="color" Required="true" Size="10" Type="VARCHAR" />
            <Column Name="create_time" Required="true" Type="DATE"/>
            <Column Name="create_by" Required="true" Type="INTEGER"/>
            <Column Name="change_time" Required="true" Type="DATE"/>
            <Column Name="change_by" Required="true" Type="INTEGER"/>
            <Unique Name="article_color_name">
                <UniqueColumn Name="name"/>
            </Unique>
            <ForeignKey ForeignTable="users">
                <Reference Local="create_by" Foreign="id"/>
                <Reference Local="change_by" Foreign="id"/>
            </ForeignKey>
        </Table>',
    );

    return if !$Self->ExecuteXMLDBArray(
        XMLArray => \@XMLStrings,
    );

    return 1;
}

sub _InsertArticleColor {
    my ( $Self, %Param ) = @_;

    my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');

    $ArticleObject->ArticleColorInit();

    return 1;
}

1;
