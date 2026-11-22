# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
## nofilter(TidyAll::Plugin::Znuny::Perl::Pod::NamePod)

package scripts::Migration::Znuny::CleanupActivities;    ## no critic

use strict;
use warnings;
use utf8;

use parent qw(scripts::Migration::Base);

our @ObjectDependencies = (
    'Kernel::System::Activity',
);

=head1 SYNOPSIS

Schedules cleanup of excess activities accumulated before the per-user limit was introduced.

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    return 1 if !$Self->TableExists(
        Table => 'activity',
    );

    my $ActivityObject = $Kernel::OM->Get('Kernel::System::Activity');

    my $ScheduledTaskCount = $ActivityObject->CleanupExcessActivities();
    if ( !defined $ScheduledTaskCount ) {
        print "        Error while cleaning up activities.\n";
        return;
    }

    if ($ScheduledTaskCount) {
        print "        Scheduled $ScheduledTaskCount activity cleanup tasks.\n";
    }

    return 1;
}

1;
