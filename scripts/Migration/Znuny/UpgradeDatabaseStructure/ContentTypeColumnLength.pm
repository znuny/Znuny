# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package scripts::Migration::Znuny::UpgradeDatabaseStructure::ContentTypeColumnLength;    ## no critic

use strict;
use warnings;
use utf8;

use parent qw(scripts::Migration::Base);

our @ObjectDependencies = (
    'Kernel::System::DB',
);

=head1 SYNOPSIS

Increases the size of column content_type in database tables article_data_mime_attachment and web_upload_cache.

The column contains the complete Content-Type header of an attachment, including the encoded file name.
For long non-ASCII file names this exceeds the former sizes of 450/250 characters, so the attachment was not stored.

Columns which already are big enough (e.g. TEXT on MySQL or a column which has been changed manually) are skipped,
so that they won't be altered needlessly or even shrunk.

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    my $Size = 4000;

    my @XMLStrings;

    TABLE:
    for my $Table (qw(article_data_mime_attachment web_upload_cache)) {
        my %Column = $Self->_ColumnSizeGet(
            Table  => $Table,
            Column => 'content_type',
        );
        next TABLE if !%Column;

        # Undefined size means that the column has no length limit (e.g. TEXT on PostgreSQL).
        next TABLE if !defined $Column{Size};
        next TABLE if $Column{Size} >= $Size;

        push @XMLStrings, qq{<TableAlter Name="$Table">
            <ColumnChange NameOld="content_type" NameNew="content_type" Required="false" Size="$Size" Type="VARCHAR"/>
        </TableAlter>};
    }

    return 1 if !@XMLStrings;

    return if !$Self->ExecuteXMLDBArray(
        XMLArray => \@XMLStrings,
    );

    return 1;
}

sub _ColumnSizeGet {
    my ( $Self, %Param ) = @_;

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');
    my $DBType   = $DBObject->GetDatabaseFunction('Type');

    my $SQL;
    if ( $DBType eq 'mysql' ) {
        $SQL = '
            SELECT character_maximum_length
            FROM information_schema.columns
            WHERE table_schema = DATABASE() AND table_name = ? AND column_name = ?
        ';
    }
    elsif ( $DBType eq 'postgresql' ) {
        $SQL = '
            SELECT character_maximum_length
            FROM information_schema.columns
            WHERE table_schema = current_schema() AND table_name = ? AND column_name = ?
        ';
    }
    elsif ( $DBType eq 'oracle' ) {
        $SQL = '
            SELECT data_length
            FROM user_tab_columns
            WHERE table_name = UPPER(?) AND column_name = UPPER(?)
        ';
    }
    else {
        return;
    }

    return if !$DBObject->Prepare(
        SQL   => $SQL,
        Bind  => [ \$Param{Table}, \$Param{Column} ],
        Limit => 1,
    );

    my %Column;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        %Column = (
            Size => $Row[0],
        );
    }

    return %Column;
}

1;
