# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
## nofilter(TidyAll::Plugin::Znuny::Perl::Pod::NamePod)

package scripts::Migration::Znuny::MigrateDynamicFields;    ## no critic

use strict;
use warnings;

use parent qw(scripts::Migration::Base);

our @ObjectDependencies = (
    'Kernel::System::Cache',
    'Kernel::System::DB',
);

=head1 SYNOPSIS

Migrates existing dynamic fields.

=head1 PUBLIC INTERFACE

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');

    return if !$Self->_MigrateDynamicFieldWebserviceTextConfig(%Param);

    #     return if !$Self->_MigrateDynamicFieldExample(%Param);

    $CacheObject->CleanUp(
        Type => 'DynamicField',
    );
    $CacheObject->CleanUp(
        Type => 'DynamicFieldValue',
    );

    return 1;
}

# Migrates dynamic fields of type 'WebserviceText' to 'WebserviceDropdown'.
sub _MigrateDynamicFieldWebserviceTextConfig {
    my ( $Self, %Param ) = @_;

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # Since storage and config is identical for WebserviceText and WebserviceDropdown,
    # only the field type has to be updated.
    my $SQL = '
        UPDATE dynamic_field
        SET    field_type = ?
        WHERE  field_type = ?
    ';

    my @Bind = (
        \'WebserviceDropdown',
        \'WebserviceText',
    );

    return if !$DBObject->Do(
        SQL  => $SQL,
        Bind => \@Bind,
    );

    return 1;
}

# sub _MigrateDynamicFieldExample {
#     my ( $Self, %Param ) = @_;

#     my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

#     my $SQL = '
#         UPDATE dynamic_field
#         SET    field_type = ?
#         WHERE  field_type = ?
#     ';

#     my @Bind = (
#         \'ExampleNewType',
#         \'ExampleOldType',
#     );

#     return if !$DBObject->Do(
#         SQL  => $SQL,
#         Bind => \@Bind,
#     );

#     return 1;
# }

1;
