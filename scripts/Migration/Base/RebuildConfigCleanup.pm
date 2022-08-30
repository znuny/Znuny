# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --
## nofilter(TidyAll::Plugin::OTRS::Perl::Pod::NamePod)

package scripts::Migration::Base::RebuildConfigCleanup;    ## no critic

use strict;
use warnings;

use parent qw(scripts::Migration::Base);

our @ObjectDependencies = ();

=head1 SYNOPSIS

Rebuilds the system configuration trying to cleanup the database.

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    return $Self->RebuildConfig(
        %Param,
        CleanUpIfPossible => 1,
    );
}

1;
