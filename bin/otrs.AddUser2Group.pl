#!/usr/bin/perl -w
# --
# Copyright (C) 2001-2019 OTRS AG, https://otrs.com/
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

use File::Basename;
use FindBin qw($RealBin);
use lib dirname($RealBin);

use Kernel::Config;
use Kernel::System::Encode;
use Kernel::System::Log;
use Kernel::System::Time;
use Kernel::System::DB;
use Kernel::System::Main;
use Kernel::System::User;
use Kernel::System::Group;

my %Param;
my %CommonObject;
my %Opts;

use Getopt::Std;
getopt( 'guph', \%Opts );

if ( $Opts{h} || !$Opts{g} || !$Opts{u} || !$Opts{p} ) {
    print STDERR
        "Usage: bin/otrs.AddUser2Group -g groupname -u username -p ro|rw\n";
    exit;
}

# create common objects
$CommonObject{ConfigObject} = Kernel::Config->new(%CommonObject);
$CommonObject{EncodeObject} = Kernel::System::Encode->new(%CommonObject);
$CommonObject{LogObject}    = Kernel::System::Log->new(
    LogPrefix => 'OTRS-otrs.AddUser2Group',
    %CommonObject,
);
$CommonObject{TimeObject}  = Kernel::System::Time->new(%CommonObject);
$CommonObject{MainObject}  = Kernel::System::Main->new(%CommonObject);
$CommonObject{DBObject}    = Kernel::System::DB->new(%CommonObject);
$CommonObject{UserObject}  = Kernel::System::User->new(%CommonObject);
$CommonObject{GroupObject} = Kernel::System::Group->new(%CommonObject);

# user id
$Param{UserID} = '1';

# valid id
$Param{ValidID} = '1';

$Param{Permission}->{ $Opts{p} } = 1;
$Param{UserLogin}                = $Opts{u};
$Param{Group}                    = $Opts{g};

unless (
    $Param{UID} =
    $CommonObject{UserObject}->UserLookup( UserLogin => $Param{UserLogin} )
    )
{
    print STDERR "ERROR: Failed to get User ID. Perhaps non-existent user..\n";
    exit 1;
}

unless ( $Param{GID} = $CommonObject{GroupObject}->GroupLookup(%Param) ) {
    print STDERR
        "ERROR: Failed to get Group ID. Perhaps non-existent group..\n";
    exit;
}

print "GID: $Param{Group}/$Param{GID} \n";
print "UID: $Param{UserLogin}/$Param{UID} \n";
print "Permission: $Opts{p} \n";

if ( !$CommonObject{GroupObject}->GroupMemberAdd(%Param) ) {
    print STDERR "ERROR: Can't add user to group\n";
    exit 1;
}
else {
    exit(0);
}