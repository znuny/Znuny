# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package scripts::test::ObjectManager::Dummy;    ## no critic

use strict;
use warnings;

## nofilter(TidyAll::Plugin::OTRS::Perl::ObjectDependencies)
## nofilter(TidyAll::Plugin::Znuny::Perl::ObjectDependencies)
our @ObjectDependencies = ();                   # we want to use an undeclared dependency for testing

sub new {
    my ( $Class, %Param ) = @_;
    bless \%Param, $Class;
    return \%Param;
}

sub Data {
    my ($Self) = @_;
    return $Self->{Data};
}

sub DESTROY {

    # Request this object (undeclared dependency) in the desctructor.
    #   This will create it again in the OM to test that ObjectsDiscard will still work.
    $Kernel::OM->Get('scripts::test::ObjectManager::Dummy2');

    return;
}

1;
