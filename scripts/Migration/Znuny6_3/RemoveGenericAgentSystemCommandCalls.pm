# --
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package scripts::Migration::Znuny6_3::RemoveGenericAgentSystemCommandCalls;    ## no critic

use strict;
use warnings;

use IO::Interactive qw(is_interactive);

use parent qw(scripts::Migration::Base);

use version;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::System::DB',
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

    my $JobsToMigrate = $Self->_GetJobsToMigrateForRequirementsCheck();
    return 1 if !IsHashRefWithData($JobsToMigrate);

    print "\n        The following generic agent jobs have configured system command calls.\n";
    print
        "        System command calls are not allowed anymore and will be removed. The job will also be renamed and set invalid.\n";

    for my $JobName ( sort keys %{$JobsToMigrate} ) {
        print "            $JobName: $JobsToMigrate->{$JobName}\n";
    }

    if ( is_interactive() ) {
        print '        Do you want to continue? [Y]es/[N]o: ';

        my $Answer = <>;
        $Answer =~ s{\s}{}g;

        return if $Answer !~ m{\Ay(es)?\z}i;
    }

    return 1;
}

sub _GetJobsToMigrateForRequirementsCheck {
    my ( $Self, %Param ) = @_;

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # Use direct DB query because at this point the ZZZ Perl config files
    # might not be present yet, resulting in Kernel::System::GenericAgent
    # to fail to initialize (see GitLab issue #244).
    return if !$DBObject->Prepare(
        SQL => '
            SELECT job_name, job_value
            FROM   generic_agent_jobs
            WHERE  job_key = ?
        ',
        Bind => [
            \'NewCMD',
        ],
    );

    my %JobsToMigrate;
    ROW:
    while ( my @Row = $DBObject->FetchrowArray() ) {
        my $JobName = $Row[0];
        my $Command = $Row[1];
        next ROW if !IsStringWithData($Command);

        $JobsToMigrate{$JobName} = $Command;
    }

    return \%JobsToMigrate;
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
