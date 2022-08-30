#!/usr/bin/env perl
# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
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

use strict;
use warnings;

# Make sure we are in a sane environment.
$ENV{MOD_PERL} =~ /mod_perl/ || die "MOD_PERL not used!";

BEGIN {

    # switch to unload_package_xs, the PP version is broken in Perl 5.10.1.
    # see http://rt.perl.org/rt3//Public/Bug/Display.html?id=72866
    $ModPerl::Util::DEFAULT_UNLOAD_METHOD = 'unload_package_xs';    ## no critic

    # set $0 to index.pl if it is not an existing file:
    # on Fedora, $0 is not a path which would break OTRS.
    # see bug # 8533
    if ( !-e $0 || -d $0 ) {
        $0 = '/opt/otrs/bin/cgi-bin/index.pl';    ## no critic
    }
}

use Apache2::RequestRec ();
use ModPerl::Util       ();

use lib "/opt/otrs/";
use lib "/opt/otrs/Kernel/cpan-lib";
use lib "/opt/otrs/Custom";

# Preload frequently used modules to speed up client spawning.
use CGI ();
CGI->compile(':cgi');
use CGI::Carp ();

use Apache::DBI ();

# enable this if you use mysql
#use DBD::mysql ();
#use Kernel::System::DB::mysql;

# enable this if you use postgresql
#use DBD::Pg ();
#use Kernel::System::DB::postgresql;

# enable this if you use oracle
#use DBD::Oracle ();
#use Kernel::System::DB::oracle;

# Preload Net::DNS if it is installed. It is important to preload Net::DNS because otherwise loading
#   could take more than 30 seconds.
eval { require Net::DNS };

# Preload DateTime, an expensive external dependency.
use DateTime ();

# Preload dependencies that are always used.
use Template ();
use Encode qw(:all);

1;
