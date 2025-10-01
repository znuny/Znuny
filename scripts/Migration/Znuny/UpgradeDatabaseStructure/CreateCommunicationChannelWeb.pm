# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package scripts::Migration::Znuny::UpgradeDatabaseStructure::CreateCommunicationChannelWeb;    ## no critic

use strict;
use warnings;

use parent qw(scripts::Migration::Base);

our @ObjectDependencies;

=head1 SYNOPSIS

Inserts DB record for communication channel Web.

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    return if !$Self->_InsertCommunicationChannelWeb(%Param);

    return 1;
}

sub _InsertCommunicationChannelWeb {
    my ( $Self, %Param ) = @_;

    my @XMLStrings = (
        '<Insert Table="communication_channel">
        <Data Key="id" Type="AutoIncrement">5</Data>
        <Data Key="name" Type="Quote">Web</Data>
        <Data Key="module" Type="Quote">Kernel::System::CommunicationChannel::Web</Data>
        <Data Key="package_name" Type="Quote">Framework</Data>
        <Data Key="channel_data" Type="Quote">---
ArticleDataArticleIDField: article_id
ArticleDataTables:
- article_data_mime
- article_data_mime_plain
- article_data_mime_attachment
- article_data_mime_send_error
</Data>
        <Data Key="valid_id">1</Data>
        <Data Key="create_by">1</Data>
        <Data Key="create_time">current_timestamp</Data>
        <Data Key="change_by">1</Data>
        <Data Key="change_time">current_timestamp</Data>
    </Insert>',
    );

    return if !$Self->ExecuteXMLDBArray(
        XMLArray => \@XMLStrings,
    );

    return 1;
}

1;
