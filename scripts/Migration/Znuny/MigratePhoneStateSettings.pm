# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package scripts::Migration::Znuny::MigratePhoneStateSettings;    ## no critic

use strict;
use warnings;
use utf8;

use IO::Interactive qw(is_interactive);

use parent qw(scripts::Migration::Base);

our @ObjectDependencies = (
);

=head1 SYNOPSIS

Check previous requirement task to inform administrator about manual phone state settings migration.

=cut

sub CheckPreviousRequirement {
    my ( $Self, %Param ) = @_;

    # This check will occur only if we are in interactive mode.
    if ( $Param{CommandlineOptions}->{NonInteractive} || !is_interactive() ) {
        return 1;
    }

    print <<'EOF';

    ============================================================================
    IMPORTANT: Manual Phone State Settings Migration Required
    ============================================================================

    The following SysConfig settings have changed from Znuny 7.2 to 7.3:

    OLD FORMAT (Znuny 7.2):
    - Ticket::Frontend::AgentTicketPhoneInbound###State  (contained state value like "open")
    - Ticket::Frontend::AgentTicketPhoneOutbound###State (contained state value like "open")

    NEW FORMAT (Znuny 7.3):
    - Ticket::Frontend::AgentTicketPhoneInbound###State  (now 1/0 for enabled/disabled)
    - Ticket::Frontend::AgentTicketPhoneInbound###StateDefault  (contains the state value)
    - Ticket::Frontend::AgentTicketPhoneOutbound###State  (now 1/0 for enabled/disabled)
    - Ticket::Frontend::AgentTicketPhoneOutbound###StateDefault  (contains the state value)

    MANUAL ACTION REQUIRED:
    ======================

    You need to manually migrate the state values from the old settings to the new StateDefault settings:

    1. Check current values:
       - Go to Admin -> System Configuration
       - Search for "Ticket::Frontend::AgentTicketPhoneInbound###State"
       - Search for "Ticket::Frontend::AgentTicketPhoneOutbound###State"

    2. If these settings contain state values (like "open", "closed", etc.):
       - Copy the state value to the corresponding StateDefault setting after migration is completed

    3. Examples:
       - If "Ticket::Frontend::AgentTicketPhoneInbound###State" = "open"
         -> Set "Ticket::Frontend::AgentTicketPhoneInbound###StateDefault" = "open"
         -> Set "Ticket::Frontend::AgentTicketPhoneInbound###State" = "1"

       - If "Ticket::Frontend::AgentTicketPhoneOutbound###State" = "pending reminder"
         -> Set "Ticket::Frontend::AgentTicketPhoneOutbound###StateDefault" = "pending reminder"
         -> Set "Ticket::Frontend::AgentTicketPhoneOutbound###State" = "1"

    4. Deploy the configuration after making changes.

    This migration cannot be automated because it requires administrator verification
    of the correct state values for each phone ticket type.

    ============================================================================

EOF

    print "\n        Do you want to continue with the migration? [Y]es/[N]o: ";

    my $Answer = <>;

    # Remove white space from input.
    $Answer =~ s{\s}{}g;

    # Continue only if user answers affirmatively.
    if ( $Answer =~ m{\Ay(?:es)?\z}i ) {
        print "\n";
        return 1;
    }

    return;
}

1;
