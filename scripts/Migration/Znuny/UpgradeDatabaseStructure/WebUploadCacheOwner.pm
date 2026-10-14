# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package scripts::Migration::Znuny::UpgradeDatabaseStructure::WebUploadCacheOwner;    ## no critic

use strict;
use warnings;
use utf8;

use parent qw(scripts::Migration::Base);

our @ObjectDependencies = (
);

=head1 SYNOPSIS

Adds owner columns user_id and user_type to database table web_upload_cache.

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    my @XMLStrings = (
        '<TableAlter Name="web_upload_cache">
            <ColumnAdd Name="user_id" Required="false" Size="250" Type="VARCHAR"/>
        </TableAlter>',
        '<TableAlter Name="web_upload_cache">
            <ColumnAdd Name="user_type" Required="false" Size="20" Type="VARCHAR"/>
        </TableAlter>',
    );

    return if !$Self->ExecuteXMLDBArray(
        XMLArray => \@XMLStrings,
    );

    return 1;
}

1;
