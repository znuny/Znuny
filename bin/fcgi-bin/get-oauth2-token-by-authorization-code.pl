#!/usr/bin/env perl
# --
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# --
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

## nofilter(TidyAll::Plugin::OTRS::Perl::ParamObject)

use strict;
use warnings;

# use ../../ as lib location
use FindBin qw($Bin);
use lib "$Bin/../..";
use lib "$Bin/../../Kernel/cpan-lib";
use lib "$Bin/../../Custom";

use CGI::Fast;
use Module::Refresh;

# load agent web interface
use Kernel::System::Web::InterfaceAgent();
use Kernel::System::ObjectManager;

# 0=off;1=on;
my $Debug = 0;

#my $Cnt = 0;

# Response loop
while ( my $WebRequest = CGI::Fast->new() ) {

    # Reload files in @INC that have changed since the last request.
    eval {
        Module::Refresh->refresh();
    };

    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $Interface = Kernel::System::Web::InterfaceAgent->new(
        Debug      => $Debug,
        WebRequest => $WebRequest,
    );

    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');
    $ParamObject->{Query}->param(
        -name  => 'Action',
        -value => 'AdminOAuth2TokenManagement',
    );
    $ParamObject->{Query}->param(
        -name  => 'Subaction',
        -value => 'RequestTokenByAuthorizationCode',
    );

    $Interface->Run();

    #    $Cnt++;
    #    print STDERR "This is connection number $Cnt\n";
}
