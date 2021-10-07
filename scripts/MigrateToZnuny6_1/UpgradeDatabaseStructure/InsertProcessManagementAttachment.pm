# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
## nofilter(TidyAll::Plugin::OTRS::Perl::Pod::NamePod)

package scripts::MigrateToZnuny6_1::UpgradeDatabaseStructure::InsertProcessManagementAttachment;    ## no critic

use strict;
use warnings;

use parent qw(scripts::MigrateToZnuny6_1::Base);

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies;

=head1 NAME

insert DynamicField ProcessManagementAttachment.

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    my @XML = (
        '<Insert Table="dynamic_field">
        <Data Key="internal_field">1</Data>
        <Data Key="name" Type="Quote">ProcessManagementAttachment</Data>
        <Data Key="label" Type="Quote">Attachment</Data>
        <Data Key="field_order">1</Data>
        <Data Key="field_type" Type="Quote">TextArea</Data>
        <Data Key="object_type" Type="Quote">Ticket</Data>
        <Data Key="config" Type="Quote">---
DefaultValue: \'\'
</Data>
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

    return 1;
}

1;
