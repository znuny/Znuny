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

TODO: Done

Creates or alters the database table C<article_color> and alters color column to 25 characters.
This table is used to store the article color.

Adds 'FF' to the end of the color if length and structure of color is like #83bfc8

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    my $ArticleTableExists = $Self->TableExists(
        Table => 'article_color',
    );

    if ($ArticleTableExists) {
        return if !$Self->_AlterArticleColorTable(%Param);
        return if !$Self->_UpdateArticleColor(%Param);
    }
    else {
        return if !$Self->_CreateArticleColorTable(%Param);
        return if !$Self->_UpdateArticleColor(%Param);
    }

    return 1;
}

sub _CreateArticleColorTable {
    my ( $Self, %Param ) = @_;

    my @XMLStrings = (
        '<Table Name="article_color">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="SMALLINT"/>
            <Column Name="name" Required="true" Size="200" Type="VARCHAR"/>
            <Column Name="color" Required="true" Size="25" Type="VARCHAR" />
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

sub _AlterArticleColorTable {
    my ( $Self, %Param ) = @_;

    my @XMLStrings = (
        '<TableAlter Name="article_color">
            <ColumnChange NameOld="color" NameNew="color" Size="25" Type="VARCHAR"/>
        </TableAlter>',
    );

    return if !$Self->ExecuteXMLDBArray(
        XMLArray => \@XMLStrings,
    );

    return 1;
}

sub _UpdateArticleColor {
    my ( $Self, %Param ) = @_;

    my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');

    # Initialize article colors
    $ArticleObject->ArticleColorInit();

    # Get all article colors
    my @ArticleColorList = $ArticleObject->ArticleColorList();

    ARTICLECOLOR:
    for my $ArticleColor ( sort @ArticleColorList ) {

        # Get article color
        my %ArticleColor = $ArticleObject->ArticleColorGet(
            Name => $ArticleColor->{Name},
        );
        next ARTICLECOLOR if !%ArticleColor;

        my $Color = $ArticleColor{Color};

        # next if no '#' at the beginning
        next ARTICLECOLOR if $Color !~ /^#/;

        # Next ARTICLECOLOR if length and structure of color is like #83bfc8ff
        # '#' and 8 characters after it
        next ARTICLECOLOR if $Color =~ /^#([0-9a-fA-F]{8})$/;

        # Add 'FF' to the end of the color if length and structure of color is like #83bfc8
        if ( $Color =~ /^#([0-9a-fA-F]{6})$/ ) {
            $Color = '#' . $1 . 'FF';
        }

        my $ArticleColorID = $ArticleObject->ArticleColorSet(
            %{$ArticleColor},
            Color  => $Color,
            UserID => 1,
        );
    }

    return 1;
}

1;
