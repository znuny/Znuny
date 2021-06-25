# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
## nofilter(TidyAll::Plugin::OTRS::Perl::Pod::NamePod)

package scripts::MigrateToZnuny6_1::MigrateGroups;    ## no critic

use strict;
use warnings;

use parent qw(scripts::MigrateToZnuny6_1::Base);

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::System::DB',
    'Kernel::System::Group',
    'Kernel::System::ZnunyHelper',
);

=head1 NAME

Migrate web service configuration.

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    $Self->_MigrateGroupNames(%Param);
    $Self->_CreateMissingGroups(%Param);

    return 1;
}

sub _MigrateGroupNames {
    my ( $Self, %Param ) = @_;

    my $DBObject    = $Kernel::OM->Get('Kernel::System::DB');
    my $GroupObject = $Kernel::OM->Get('Kernel::System::Group');

    my %Groups = $GroupObject->GroupList(
        Valid => 0,
    );
    return 1 if !%Groups;

    my %GroupIDsByName = reverse %Groups;

    my %GroupNameMapping = (
        'znuny4otrs_timeaccounting_webservice' => 'timeaccounting_webservice',
    );

    CURRENTGROUPNAME:
    for my $CurrentGroupName ( sort keys %GroupNameMapping ) {

        # No group with matching name found.
        next CURRENTGROUPNAME if !$GroupIDsByName{$CurrentGroupName};

        my $NewGroupName = $GroupNameMapping{$CurrentGroupName};

        # A group with the new name already exists.
        if ( $GroupIDsByName{$NewGroupName} ) {
            print
                "        Group $CurrentGroupName cannot be renamed to $NewGroupName because this name is already used by another group.\n";
            next CURRENTGROUPNAME;
        }

        # Rename group.
        my $RenamingOK = $DBObject->Do(
            SQL => '
                UPDATE groups SET name = ?
                WHERE id = ?
            ',
            Bind => [
                \$NewGroupName,
                \$GroupIDsByName{$CurrentGroupName},
            ],
        );

        next CURRENTGROUPNAME if $RenamingOK;

        print "        Error renaming group $CurrentGroupName to $NewGroupName.\n";
    }

    return 1;
}

sub _CreateMissingGroups {
    my ( $Self, %Param ) = @_;

    my $GroupObject       = $Kernel::OM->Get('Kernel::System::Group');
    my $ZnunyHelperObject = $Kernel::OM->Get('Kernel::System::ZnunyHelper');

    my %Groups = $GroupObject->GroupList(
        Valid => 0,
    );

    my %GroupIDsByName = reverse %Groups;

    my @GroupsToCreate = (
        'timeaccounting_webservice',
    );

    GROUPNAME:
    for my $GroupName ( sort @GroupsToCreate ) {
        next GROUPNAME if $GroupIDsByName{$GroupName};

        $ZnunyHelperObject->_GroupCreateIfNotExists(
            Name => $GroupName,
        );
    }

    return 1;
}

1;
