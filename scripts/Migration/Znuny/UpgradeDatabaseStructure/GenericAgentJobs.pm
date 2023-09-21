# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package scripts::Migration::Znuny::UpgradeDatabaseStructure::GenericAgentJobs;    ## no critic

use strict;
use warnings;

use parent qw(scripts::Migration::Base);

our @ObjectDependencies = (
    'Kernel::System::DB',
);

=head1 SYNOPSIS

Increases the size if some columns of table generic_agent_jobs

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    return if !$Self->_IncreaseColumnsSize(%Param);

    return 1;
}

sub _IncreaseColumnsSize {
    my ( $Self, %Param ) = @_;

    my @XMLStrings = (
        '<TableAlter Name="generic_agent_jobs">
            <ColumnChange NameOld="job_key" NameNew="job_key" Required="true" Size="255" Type="VARCHAR"/>
            <ColumnChange NameOld="job_value" NameNew="job_value" Required="false" Size="3800" Type="VARCHAR"/>
        </TableAlter>'
    );

    return if !$Self->ExecuteXMLDBArray(
        XMLArray => \@XMLStrings,
    );

    return 1;
}
1;
