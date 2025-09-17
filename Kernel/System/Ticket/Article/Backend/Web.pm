# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Ticket::Article::Backend::Web;

use strict;
use warnings;

use parent 'Kernel::System::Ticket::Article::Backend::MIMEBase';

our @ObjectDependencies = ();

=head1 NAME

Kernel::System::Ticket::Article::Backend::Web - backend class for web articles

=head1 DESCRIPTION

This class provides functions to manipulate web articles in the database.

Inherits from L<Kernel::System::Ticket::Article::Backend::MIMEBase>, please have a look there for its API.

=cut

sub ChannelNameGet {
    return 'Web';
}

1;
