# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
## nofilter(TidyAll::Plugin::Znuny::Perl::Pod::NamePod)

package scripts::Migration::Znuny::RemoveMentionFlagFromArchivedTickets;    ## no critic

use strict;
use warnings;
use utf8;

use IO::Interactive qw(is_interactive);

use parent qw(scripts::Migration::Base);

our @ObjectDependencies = (
);

=head1 SYNOPSIS

Add a hint/warning, that this command bin/znuny.Console.pl Maint::Ticket::ArchiveCleanup needs to be executed manually if archive is enabled.

=cut

=head2 FollowUp()

Adds FollowUp step to remove mention flag from archived tickets.

Returns 1 on success:

    my $Result = $MigrateToZnunyObject->FollowUp();

=cut

sub FollowUp {
    my ( $Self, %Param ) = @_;

    if ( $Param{CommandlineOptions}->{Verbose} ) {
        print "\n        Warning: It is possible that already archived tickets still have the MentionSeen flag set.\n";
    }

    print
        "\n         bin/znuny.Console.pl Maint::Ticket::ArchiveCleanup needs to be executed manually if archive is enabled.\n";

    return 1;
}

1;
