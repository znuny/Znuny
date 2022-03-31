# --
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package scripts::DBUpdateTo6::RemoveGenericAgentSystemCommandCalls;    ## no critic

use strict;
use warnings;

use IO::Interactive qw(is_interactive);

use parent qw(scripts::DBUpdateTo6::Base);

use version;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::System::GenericAgent',
);

sub Run {
    my ( $Self, %Param ) = @_;

    my $GenericAgentObject = $Kernel::OM->Get('Kernel::System::GenericAgent');

    my $UserID = 1;

    my $JobsToMigrate = $Self->_GetJobsToMigrate();
    return 1 if !IsHashRefWithData($JobsToMigrate);

    # Remove system commands from generic agents and mark them via job name as '[NEEDS ATTENTION]'
    for my $OldJobName ( sort keys %{$JobsToMigrate} ) {
        my $NewJobName = "[NEEDS ATTENTION] $OldJobName";

        my $Job = $JobsToMigrate->{$OldJobName};
        delete $Job->{NewCMD};

        $Job->{Valid} = 0;

        $GenericAgentObject->JobDelete(
            Name   => $OldJobName,
            UserID => $UserID,
        );

        $GenericAgentObject->JobAdd(
            Name   => $NewJobName,
            Data   => $Job,
            UserID => $UserID,
        );
    }

    return 1;
}

sub CheckPreviousRequirement {
    my ( $Self, %Param ) = @_;

    my $JobsToMigrate = $Self->_GetJobsToMigrate();
    return 1 if !IsHashRefWithData($JobsToMigrate);

    print "\n        The following generic agent jobs have configured system command calls.\n";
    print
        "        System command calls are not allowed anymore and will be removed. The job will also be renamed and set invalid.\n";

    for my $JobName ( sort keys %{$JobsToMigrate} ) {
        print "            $JobName: $JobsToMigrate->{$JobName}->{NewCMD}\n";
    }

    if ( is_interactive() ) {
        print '        Do you want to continue? [Y]es/[N]o: ';

        my $Answer = <>;
        $Answer =~ s{\s}{}g;

        return if $Answer !~ m{\Ay(es)?\z}i;
    }

    return 1;
}

sub _GetJobsToMigrate {
    my ( $Self, %Param ) = @_;

    my $GenericAgentObject = $Kernel::OM->Get('Kernel::System::GenericAgent');

    my %Jobs = $GenericAgentObject->JobList();

    my %JobsToMigrate;

    JOBNAME:
    for my $JobName ( sort keys %Jobs ) {
        my %Job = $GenericAgentObject->JobGet( Name => $JobName );
        next JOBNAME if !%Job;
        next JOBNAME if !IsStringWithData( $Job{'NewCMD'} );

        $JobsToMigrate{$JobName} = {%Job};
    }

    return \%JobsToMigrate;
}

1;
