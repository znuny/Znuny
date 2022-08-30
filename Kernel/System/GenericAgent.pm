# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::GenericAgent;

use strict;
use warnings;

use Time::HiRes qw(usleep);

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Cache',
    'Kernel::System::DateTime',
    'Kernel::System::DB',
    'Kernel::System::DynamicField',
    'Kernel::System::DynamicField::Backend',
    'Kernel::System::Log',
    'Kernel::System::Main',
    'Kernel::System::Queue',
    'Kernel::System::State',
    'Kernel::System::Ticket',
    'Kernel::System::Ticket::Article',
    'Kernel::System::TemplateGenerator',
    'Kernel::System::CustomerUser',
);

=head1 NAME

Kernel::System::GenericAgent - to manage the generic agent jobs

=head1 DESCRIPTION

All functions to manage the generic agent and the generic agent jobs.

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $GenericAgentObject = $Kernel::OM->Get('Kernel::System::GenericAgent');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # get dynamic field objects
    my $DynamicFieldObject        = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    # get the dynamic fields for ticket object
    $Self->{DynamicField} = $DynamicFieldObject->DynamicFieldListGet(
        Valid      => 1,
        ObjectType => ['Ticket'],
    );

    # debug
    $Self->{Debug} = $Param{Debug} || 0;

    # notice on STDOUT
    $Self->{NoticeSTDOUT} = $Param{NoticeSTDOUT} || 0;

    my %Map = (
        TicketNumber            => 'SCALAR',
        Title                   => 'SCALAR',
        MIMEBase_From           => 'SCALAR',
        MIMEBase_To             => 'SCALAR',
        MIMEBase_Cc             => 'SCALAR',
        MIMEBase_Subject        => 'SCALAR',
        MIMEBase_Body           => 'SCALAR',
        TimeUnit                => 'SCALAR',
        CustomerID              => 'SCALAR',
        CustomerUserLogin       => 'SCALAR',
        Agent                   => 'SCALAR',
        StateIDs                => 'ARRAY',
        StateTypeIDs            => 'ARRAY',
        QueueIDs                => 'ARRAY',
        PriorityIDs             => 'ARRAY',
        OwnerIDs                => 'ARRAY',
        LockIDs                 => 'ARRAY',
        TypeIDs                 => 'ARRAY',
        ResponsibleIDs          => 'ARRAY',
        ServiceIDs              => 'ARRAY',
        SLAIDs                  => 'ARRAY',
        NewTitle                => 'SCALAR',
        NewCustomerID           => 'SCALAR',
        NewCustomerUserLogin    => 'SCALAR',
        NewStateID              => 'SCALAR',
        NewQueueID              => 'SCALAR',
        NewPriorityID           => 'SCALAR',
        NewOwnerID              => 'SCALAR',
        NewLockID               => 'SCALAR',
        NewTypeID               => 'SCALAR',
        NewResponsibleID        => 'SCALAR',
        NewServiceID            => 'SCALAR',
        NewSLAID                => 'SCALAR',
        ScheduleLastRun         => 'SCALAR',
        ScheduleLastRunUnixTime => 'SCALAR',
        Valid                   => 'SCALAR',
        ScheduleDays            => 'ARRAY',
        ScheduleMinutes         => 'ARRAY',
        ScheduleHours           => 'ARRAY',
        EventValues             => 'ARRAY',
    );

    # add time attributes
    for my $Type (
        qw(Time ChangeTime CloseTime TimePending EscalationTime EscalationResponseTime EscalationUpdateTime EscalationSolutionTime)
        )
    {
        my $Key = $Type . 'SearchType';
        $Map{$Key} = 'SCALAR';
    }
    for my $Type (
        qw(TicketCreate TicketChange TicketClose TicketLastChange TicketLastClose TicketPending TicketEscalation TicketEscalationResponse TicketEscalationUpdate TicketEscalationSolution)
        )
    {
        for my $Attribute (
            qw(PointFormat Point PointStart Start StartDay StartMonth StartYear Stop StopDay StopMonth StopYear)
            )
        {
            my $Key = $Type . 'Time' . $Attribute;
            $Map{$Key} = 'SCALAR';
        }
    }

    # Add Dynamic Fields attributes
    DYNAMICFIELD:
    for my $DynamicFieldConfig ( @{ $Self->{DynamicField} } ) {
        next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

        # get the field type of the dynamic fields for edit and search
        my $FieldValueType = $DynamicFieldBackendObject->TemplateValueTypeGet(
            DynamicFieldConfig => $DynamicFieldConfig,
            FieldType          => 'All',
        );

        # Add field type to Map
        if ( IsHashRefWithData($FieldValueType) ) {
            for my $FieldName ( sort keys %{$FieldValueType} ) {
                $Map{$FieldName} = $FieldValueType->{$FieldName};
            }
        }
    }

    $Self->{Map} = \%Map;

    return $Self;
}

=head2 JobRun()

run a generic agent job

    $GenericAgentObject->JobRun(
        Job          => 'JobName',
        OnlyTicketID => 123,     # (optional) for event based Job execution
        SleepTime    => 100_000  # (optional) sleeptime per ticket in microseconds
        UserID       => 1,
    );

=cut

sub JobRun {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Job UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }
    if ( $Self->{NoticeSTDOUT} ) {
        print "Job: '$Param{Job}'\n";
    }

    # get job from param
    my %Job;
    my %DynamicFieldSearchTemplate;
    if ( $Param{Config} ) {
        %Job = %{ $Param{Config} };

        # log event
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'notice',
            Message  => "Run GenericAgent Job '$Param{Job}' from config file.",
        );
    }

    # get db job
    else {

        # log event
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'notice',
            Message  => "Run GenericAgent Job '$Param{Job}' from db.",
        );

        # get job data
        my %DBJobRaw = $Self->JobGet( Name => $Param{Job} );

        # updated last run time
        $Self->_JobUpdateRunTime(
            Name   => $Param{Job},
            UserID => $Param{UserID}
        );

        # rework
        for my $Key ( sort keys %DBJobRaw ) {
            if ( $Key =~ /^New/ ) {
                my $NewKey = $Key;
                $NewKey =~ s/^New//;
                $Job{New}->{$NewKey} = $DBJobRaw{$Key};
            }
            else {

                # skip dynamic fields
                if ( $Key !~ m{ DynamicField_ }xms ) {
                    $Job{$Key} = $DBJobRaw{$Key};
                }
            }

            # convert dynamic fields
            if ( $Key =~ m{ \A DynamicField_ }xms ) {
                $Job{New}->{$Key} = $DBJobRaw{$Key};
            }
            elsif ( $Key =~ m{ \A Search_DynamicField_ }xms ) {
                $DynamicFieldSearchTemplate{$Key} = $DBJobRaw{$Key};
            }
        }

        # Pass module parameters directly to the module in %Param,
        #   but don't overwrite existing keys
        for my $Counter ( 1 .. 6 ) {
            if ( $Job{New}->{"ParamKey$Counter"} ) {
                $Job{New}->{ $Job{New}->{"ParamKey$Counter"} } //= $Job{New}->{"ParamValue$Counter"};
            }
        }

        if ( exists $Job{SearchInArchive} && $Job{SearchInArchive} eq 'ArchivedTickets' ) {
            $Job{ArchiveFlags} = ['y'];
        }
        if ( exists $Job{SearchInArchive} && $Job{SearchInArchive} eq 'AllTickets' ) {
            $Job{ArchiveFlags} = [ 'y', 'n' ];
        }
    }

    # get dynamic field backend objects
    my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    # set dynamic fields search parameters
    my %DynamicFieldSearchParameters;
    DYNAMICFIELD:
    for my $DynamicFieldConfig ( @{ $Self->{DynamicField} } ) {

        next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

        # get search field preferences
        my $SearchFieldPreferences = $DynamicFieldBackendObject->SearchFieldPreferences(
            DynamicFieldConfig => $DynamicFieldConfig,
        );

        next DYNAMICFIELD if !IsArrayRefWithData($SearchFieldPreferences);

        PREFERENCE:
        for my $Preference ( @{$SearchFieldPreferences} ) {

            my $DynamicFieldTemp = $DynamicFieldSearchTemplate{
                'Search_DynamicField_'
                    . $DynamicFieldConfig->{Name}
                    . $Preference->{Type}
            };

            next PREFERENCE if !defined $DynamicFieldTemp;

            # extract the dynamic field value from the profile
            my $SearchParameter = $DynamicFieldBackendObject->SearchFieldParameterBuild(
                DynamicFieldConfig => $DynamicFieldConfig,
                Profile            => \%DynamicFieldSearchTemplate,
                Type               => $Preference->{Type},
            );

            # set search parameter
            if ( defined $SearchParameter ) {
                $DynamicFieldSearchParameters{ 'DynamicField_' . $DynamicFieldConfig->{Name} }
                    = $SearchParameter->{Parameter};
            }
        }
    }

    if ( $Param{OnlyTicketID} ) {
        $Job{TicketID} = $Param{OnlyTicketID};
    }

    # get needed objects
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # escalation tickets
    my %Tickets;

    # get ticket limit on job run
    my $RunLimit = $ConfigObject->Get('Ticket::GenericAgentRunLimit');
    if ( $Job{Escalation} ) {

        # Find all tickets which will escalate within the next five days.
        #   The notification module will determine if a notification must be sent out or not.
        my @Tickets = $TicketObject->TicketSearch(
            %Job,
            Result                           => 'ARRAY',
            Limit                            => $Job{Limit} || $Param{Limit} || 100,
            TicketEscalationTimeOlderMinutes => $Job{TicketEscalationTimeOlderMinutes}
                || -( 5 * 24 * 60 ),
            Permission => 'rw',
            UserID     => $Param{UserID} || 1,
        );

        for my $TicketID (@Tickets) {
            if ( !$Job{Queue} ) {
                $Tickets{$TicketID} = $TicketObject->TicketNumberLookup( TicketID => $TicketID );
            }
            else {
                my %Ticket = $TicketObject->TicketGet(
                    TicketID      => $TicketID,
                    DynamicFields => 0,
                );
                if ( $Ticket{Queue} eq $Job{Queue} ) {
                    $Tickets{$TicketID} = $Ticket{TicketNumber};
                }
            }
        }
    }

    # pending tickets
    elsif ( $Job{PendingReminder} || $Job{PendingAuto} ) {
        my $Type = '';
        if ( $Job{PendingReminder} ) {
            $Type = 'PendingReminder';
        }
        else {
            $Type = 'PendingAuto';
        }
        if ( !$Job{Queue} ) {
            %Tickets = (
                $TicketObject->TicketSearch(
                    %Job,
                    %DynamicFieldSearchParameters,
                    ConditionInline => 1,
                    StateType       => $Type,
                    Limit           => $Param{Limit} || $RunLimit,
                    UserID          => $Param{UserID},
                ),
                %Tickets
            );
        }
        elsif ( ref $Job{Queue} eq 'ARRAY' ) {
            for my $Queue ( @{ $Job{Queue} } ) {
                if ( $Self->{NoticeSTDOUT} ) {
                    print " For Queue: $Queue\n";
                }
                %Tickets = (
                    $TicketObject->TicketSearch(
                        %Job,
                        %DynamicFieldSearchParameters,
                        ConditionInline => 1,
                        Queues          => [$Queue],
                        StateType       => $Type,
                        Limit           => $Param{Limit} || $RunLimit,
                        UserID          => $Param{UserID},
                    ),
                    %Tickets
                );
            }
        }
        else {
            %Tickets = (
                $TicketObject->TicketSearch(
                    %Job,
                    %DynamicFieldSearchParameters,
                    ConditionInline => 1,
                    StateType       => $Type,
                    Queues          => [ $Job{Queue} ],
                    Limit           => $Param{Limit} || $RunLimit,
                    UserID          => $Param{UserID},
                ),
                %Tickets
            );
        }
        for my $TicketID ( sort keys %Tickets ) {
            my %Ticket = $TicketObject->TicketGet(
                TicketID      => $TicketID,
                DynamicFields => 0,
            );
            if ( $Ticket{UntilTime} > 1 ) {
                delete $Tickets{$TicketID};
            }
        }
    }

    # get regular tickets
    else {
        if ( !$Job{Queue} ) {

            # check min. one search arg
            my $Count = 0;
            for my $Key ( sort keys %Job ) {
                if ( $Key !~ /^(New|Name|Valid|Schedule|Event)/ && $Job{$Key} ) {
                    $Count++;
                }
            }

            # also search in Dynamic fields search attributes
            for my $DynamicFieldName ( sort keys %DynamicFieldSearchParameters ) {
                $Count++;
            }

            # log no search attribute
            if ( !$Count ) {
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'error',
                    Message  => "Attention: Can't run GenericAgent Job '$Param{Job}' because no "
                        . "search attributes are used!.",
                );
                return;
            }

            # search tickets
            if ( $Self->{NoticeSTDOUT} ) {
                print " For all Queues: \n";
            }
            my $GenericAgentTicketSearch = $ConfigObject->Get("Ticket::GenericAgentTicketSearch") || {};
            %Tickets = $TicketObject->TicketSearch(
                %Job,
                %DynamicFieldSearchParameters,
                ConditionInline => $GenericAgentTicketSearch->{ExtendedSearchCondition},
                Limit           => $Param{Limit} || $RunLimit,
                UserID          => $Param{UserID},
            );
        }
        elsif ( ref $Job{Queue} eq 'ARRAY' ) {
            for my $Queue ( @{ $Job{Queue} } ) {
                if ( $Self->{NoticeSTDOUT} ) {
                    print " For Queue: $Queue\n";
                }
                %Tickets = (
                    $TicketObject->TicketSearch(
                        %Job,
                        %DynamicFieldSearchParameters,
                        ConditionInline => 1,
                        Queues          => [$Queue],
                        Limit           => $Param{Limit} || $RunLimit,
                        UserID          => $Param{UserID},
                    ),
                    %Tickets
                );
            }
        }
        else {
            %Tickets = $TicketObject->TicketSearch(
                %Job,
                %DynamicFieldSearchParameters,
                ConditionInline => 1,
                Queues          => [ $Job{Queue} ],
                Limit           => $Param{Limit} || $RunLimit,
                UserID          => $Param{UserID},
            );
        }
    }

    # process each ticket
    TICKETID:
    for my $TicketID ( sort keys %Tickets ) {

        $Self->_JobRunTicket(
            Config       => \%Job,
            Job          => $Param{Job},
            TicketID     => $TicketID,
            TicketNumber => $Tickets{$TicketID},
            UserID       => $Param{UserID},
        );

        next TICKETID if !$Param{SleepTime};

        Time::HiRes::usleep( $Param{SleepTime} );
    }

    return 1;
}

=head2 JobList()

returns a hash of jobs

    my %List = $GenericAgentObject->JobList();

=cut

sub JobList {
    my ( $Self, %Param ) = @_;

    # get cache object
    my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');

    # check cache
    my $CacheKey = "JobList";
    my $Cache    = $CacheObject->Get(
        Type => 'GenericAgent',
        Key  => $CacheKey,
    );
    return %{$Cache} if ref $Cache;

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Prepare(
        SQL => 'SELECT DISTINCT(job_name) FROM generic_agent_jobs',
    );

    my %Data;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Data{ $Row[0] } = $Row[0];
    }

    $CacheObject->Set(
        Type  => 'GenericAgent',
        Key   => $CacheKey,
        Value => \%Data,
        TTL   => 24 * 60 * 60,
    );

    return %Data;
}

=head2 JobGet()

returns a hash of the job data

    my %Job = $GenericAgentObject->JobGet(Name => 'JobName');

=cut

sub JobGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Name)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    # get cache object
    my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');

    # check cache
    my $CacheKey = 'JobGet::' . $Param{Name};
    my $Cache    = $CacheObject->Get(
        Type => 'GenericAgent',
        Key  => $CacheKey,
    );
    return %{$Cache} if ref $Cache;

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Prepare(
        SQL => '
            SELECT job_key, job_value
            FROM generic_agent_jobs
            WHERE job_name = ?',
        Bind => [ \$Param{Name} ],
    );

    my %Data;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        if ( $Self->{Map}->{ $Row[0] } && $Self->{Map}->{ $Row[0] } eq 'ARRAY' ) {
            push @{ $Data{ $Row[0] } }, $Row[1];
        }
        else {
            $Data{ $Row[0] } = $Row[1];
        }
    }

    # get time settings
    my %Map = (
        TicketCreate             => 'Time',
        TicketChange             => 'ChangeTime',
        TicketClose              => 'CloseTime',
        TicketLastChange         => 'LastChangeTime',
        TicketLastClose          => 'LastCloseTime',
        TicketPending            => 'TimePending',
        TicketEscalation         => 'EscalationTime',
        TicketEscalationResponse => 'EscalationResponseTime',
        TicketEscalationUpdate   => 'EscalationUpdateTime',
        TicketEscalationSolution => 'EscalationSolutionTime',
    );

    for my $Type (
        qw(TicketCreate TicketChange TicketClose TicketLastChange TicketLastClose TicketPending TicketEscalation TicketEscalationResponse TicketEscalationUpdate TicketEscalationSolution)
        )
    {
        my $SearchType = $Map{$Type} . 'SearchType';

        if ( !$Data{$SearchType} || $Data{$SearchType} eq 'None' ) {

            # do nothing on time stuff
            for my $Key (
                qw(TimeStartMonth TimeStopMonth TimeStopDay TimeStartDay TimeStopYear TimePoint TimeStartYear TimePointFormat TimePointStart)
                )
            {
                delete $Data{ $Type . $Key };
            }
        }
        elsif ( $Data{$SearchType} && $Data{$SearchType} eq 'TimeSlot' ) {
            for my $Key (qw(TimePoint TimePointFormat TimePointStart)) {
                delete $Data{ $Type . $Key };
            }
            for my $Key (qw(Month Day)) {
                $Data{ $Type . "TimeStart$Key" } = sprintf( '%02d', $Data{ $Type . "TimeStart$Key" } );
                $Data{ $Type . "TimeStop$Key" }  = sprintf( '%02d', $Data{ $Type . "TimeStop$Key" } );
            }
            if (
                $Data{ $Type . 'TimeStartDay' }
                && $Data{ $Type . 'TimeStartMonth' }
                && $Data{ $Type . 'TimeStartYear' }
                )
            {
                $Data{ $Type . 'TimeNewerDate' } = $Data{ $Type . 'TimeStartYear' } . '-'
                    . $Data{ $Type . 'TimeStartMonth' } . '-'
                    . $Data{ $Type . 'TimeStartDay' }
                    . ' 00:00:01';
            }
            if (
                $Data{ $Type . 'TimeStopDay' }
                && $Data{ $Type . 'TimeStopMonth' }
                && $Data{ $Type . 'TimeStopYear' }
                )
            {
                $Data{ $Type . 'TimeOlderDate' } = $Data{ $Type . 'TimeStopYear' } . '-'
                    . $Data{ $Type . 'TimeStopMonth' } . '-'
                    . $Data{ $Type . 'TimeStopDay' }
                    . ' 23:59:59';
            }
        }
        elsif ( $Data{$SearchType} && $Data{$SearchType} eq 'TimePoint' ) {
            for my $Key (qw(TimeStartMonth TimeStopMonth TimeStopDay TimeStartDay TimeStopYear TimeStartYear)) {
                delete $Data{ $Type . $Key };
            }
            if (
                $Data{ $Type . 'TimePoint' }
                && $Data{ $Type . 'TimePointStart' }
                && $Data{ $Type . 'TimePointFormat' }
                )
            {
                my $Time = 0;
                if ( $Data{ $Type . 'TimePointFormat' } eq 'minute' ) {
                    $Time = $Data{ $Type . 'TimePoint' };
                }
                elsif ( $Data{ $Type . 'TimePointFormat' } eq 'hour' ) {
                    $Time = $Data{ $Type . 'TimePoint' } * 60;
                }
                elsif ( $Data{ $Type . 'TimePointFormat' } eq 'day' ) {
                    $Time = $Data{ $Type . 'TimePoint' } * 60 * 24;
                }
                elsif ( $Data{ $Type . 'TimePointFormat' } eq 'week' ) {
                    $Time = $Data{ $Type . 'TimePoint' } * 60 * 24 * 7;
                }
                elsif ( $Data{ $Type . 'TimePointFormat' } eq 'month' ) {
                    $Time = $Data{ $Type . 'TimePoint' } * 60 * 24 * 30;
                }
                elsif ( $Data{ $Type . 'TimePointFormat' } eq 'year' ) {
                    $Time = $Data{ $Type . 'TimePoint' } * 60 * 24 * 365;
                }
                if ( $Data{ $Type . 'TimePointStart' } eq 'Before' ) {

                    # more than ... ago
                    $Data{ $Type . 'TimeOlderMinutes' } = $Time;
                }
                elsif ( $Data{ $Type . 'TimePointStart' } eq 'Next' ) {

                    # within the next ...
                    $Data{ $Type . 'TimeNewerMinutes' } = 0;
                    $Data{ $Type . 'TimeOlderMinutes' } = -$Time;
                }
                else {

                    # within the last ...
                    $Data{ $Type . 'TimeOlderMinutes' } = 0;
                    $Data{ $Type . 'TimeNewerMinutes' } = $Time;
                }
            }
        }
    }

    # check valid
    if ( %Data && !defined $Data{Valid} ) {
        $Data{Valid} = 1;
    }
    if (%Data) {
        $Data{Name} = $Param{Name};
    }

    $CacheObject->Set(
        Type  => 'GenericAgent',
        Key   => $CacheKey,
        Value => \%Data,
        TTL   => 24 * 60 * 60,
    );

    return %Data;
}

=head2 JobAdd()

adds a new job to the database

    $GenericAgentObject->JobAdd(
        Name => 'JobName',
        Data => {
            Queue => 'SomeQueue',
            ...
            Valid => 1,
        },
        UserID => 123,
    );

=cut

sub JobAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Name Data UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    # check if job name already exists
    my %Check = $Self->JobGet( Name => $Param{Name} );
    if (%Check) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "A job with the name '$Param{Name}' already exists.",
        );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # insert data into db
    for my $Key ( sort keys %{ $Param{Data} } ) {
        if ( ref $Param{Data}->{$Key} eq 'ARRAY' ) {
            for my $Item ( @{ $Param{Data}->{$Key} } ) {
                if ( defined $Item ) {
                    $DBObject->Do(
                        SQL => 'INSERT INTO generic_agent_jobs '
                            . '(job_name, job_key, job_value) VALUES (?, ?, ?)',
                        Bind => [ \$Param{Name}, \$Key, \$Item ],
                    );
                }
            }
        }
        else {
            if ( defined $Param{Data}->{$Key} ) {
                $DBObject->Do(
                    SQL => 'INSERT INTO generic_agent_jobs '
                        . '(job_name, job_key, job_value) VALUES (?, ?, ?)',
                    Bind => [ \$Param{Name}, \$Key, \$Param{Data}->{$Key} ],
                );
            }
        }
    }

    $Kernel::OM->Get('Kernel::System::Log')->Log(
        Priority => 'notice',
        Message  => "New GenericAgent job '$Param{Name}' added (UserID=$Param{UserID}).",
    );

    $Kernel::OM->Get('Kernel::System::Cache')->CleanUp(
        Type => 'GenericAgent',
    );

    return 1;
}

=head2 JobDelete()

deletes a job from the database

    my $Success = $GenericAgentObject->JobDelete(
        Name   => 'JobName',
        UserID => 123,
    );

returns:

    $Success = 1;       # or false in case of a failure

=cut

sub JobDelete {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Name UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    # delete job
    $Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL  => 'DELETE FROM generic_agent_jobs WHERE job_name = ?',
        Bind => [ \$Param{Name} ],
    );

    $Kernel::OM->Get('Kernel::System::Log')->Log(
        Priority => 'notice',
        Message  => "GenericAgent job '$Param{Name}' deleted (UserID=$Param{UserID}).",
    );

    $Kernel::OM->Get('Kernel::System::Cache')->CleanUp(
        Type => 'GenericAgent',
    );

    return 1;
}

=head2 JobEventList()

returns a hash of events for each job

    my %List = $GenericAgentObject->JobEventList();

=cut

sub JobEventList {
    my ( $Self, %Param ) = @_;

    # get cache object
    my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');

    # check cache
    my $CacheKey = "JobEventList";
    my $Cache    = $CacheObject->Get(
        Type => 'GenericAgent',
        Key  => $CacheKey,
    );
    return %{$Cache} if ref $Cache;

    my %JobList = $Self->JobList();
    my %Data;
    JOB_NAME:
    for my $JobName ( sort keys %JobList ) {
        my %Job = $Self->JobGet( Name => $JobName );
        next JOB_NAME if !$Job{Valid};
        $Data{$JobName} = $Job{EventValues};
    }

    $CacheObject->Set(
        Type  => 'GenericAgent',
        Key   => $CacheKey,
        Value => \%Data,
        TTL   => 24 * 60 * 60,
    );

    return %Data;
}

=begin Internal:

=cut

=head2 _JobRunTicket()

run a generic agent job on a ticket

    $GenericAgentObject->_JobRunTicket(
        TicketID => 123,
        TicketNumber => '2004081400001',
        Config => {
            %Job,
        },
        UserID => 1,
    );

=cut

sub _JobRunTicket {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(TicketID TicketNumber Config UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    # get ticket object
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    my $Ticket = "($Param{TicketNumber}/$Param{TicketID})";

    # disable sending emails
    $TicketObject->{SendNoNotification} = $Param{Config}->{New}->{SendNoNotification} ? 1 : 0;

    # move ticket
    if ( $Param{Config}->{New}->{Queue} ) {
        if ( $Self->{NoticeSTDOUT} ) {
            print "  - Move Ticket $Ticket to Queue '$Param{Config}->{New}->{Queue}'\n";
        }
        $TicketObject->TicketQueueSet(
            QueueID => $Kernel::OM->Get('Kernel::System::Queue')->QueueLookup(
                Queue => $Param{Config}->{New}->{Queue},
                Cache => 1,
            ),
            UserID   => $Param{UserID},
            TicketID => $Param{TicketID},
        );
    }
    if ( $Param{Config}->{New}->{QueueID} ) {
        if ( $Self->{NoticeSTDOUT} ) {
            print "  - Move Ticket $Ticket to QueueID '$Param{Config}->{New}->{QueueID}'\n";
        }
        $TicketObject->TicketQueueSet(
            QueueID  => $Param{Config}->{New}->{QueueID},
            UserID   => $Param{UserID},
            TicketID => $Param{TicketID},
        );
    }

    my $ContentType = 'text/plain';

    # add note if wanted
    if ( $Param{Config}->{New}->{Note}->{Body} || $Param{Config}->{New}->{NoteBody} ) {
        if ( $Self->{NoticeSTDOUT} ) {
            print "  - Add note to Ticket $Ticket\n";
        }

        my %Ticket = $TicketObject->TicketGet(
            TicketID      => $Param{TicketID},
            DynamicFields => 0,
        );

        if ( IsHashRefWithData( \%Ticket ) ) {
            my %CustomerUserData;
            if ( IsStringWithData( $Ticket{CustomerUserID} ) ) {
                %CustomerUserData = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerUserDataGet(
                    User => $Ticket{CustomerUserID},
                );
            }

            my %Notification = (
                Subject     => $Param{Config}->{New}->{NoteSubject},
                Body        => $Param{Config}->{New}->{NoteBody},
                ContentType => 'text/plain',
            );

            my %GenericAgentArticle = $Kernel::OM->Get('Kernel::System::TemplateGenerator')->GenericAgentArticle(
                TicketID     => $Param{TicketID},
                Recipient    => \%CustomerUserData,
                Notification => \%Notification,
                UserID       => $Param{UserID},
            );

            if (
                IsStringWithData( $GenericAgentArticle{Body} )
                || IsHashRefWithData( $GenericAgentArticle{Subject} )
                )
            {
                $Param{Config}->{New}->{Note}->{Subject} = $GenericAgentArticle{Subject} || '';
                $Param{Config}->{New}->{Note}->{Body}    = $GenericAgentArticle{Body}    || '';
                $ContentType                             = $GenericAgentArticle{ContentType};
            }
        }

        my $ArticleBackendObject = $Kernel::OM->Get('Kernel::System::Ticket::Article')->BackendForChannel(
            ChannelName => 'Internal',
        );

        my $ArticleID = $ArticleBackendObject->ArticleCreate(
            TicketID             => $Param{TicketID},
            SenderType           => 'agent',
            IsVisibleForCustomer => $Param{Config}->{New}->{Note}->{IsVisibleForCustomer}
                // $Param{Config}->{New}->{NoteIsVisibleForCustomer}
                // 0,
            From => $Param{Config}->{New}->{Note}->{From}
                || $Param{Config}->{New}->{NoteFrom}
                || 'GenericAgent',
            Subject => $Param{Config}->{New}->{Note}->{Subject}
                || $Param{Config}->{New}->{NoteSubject}
                || 'Note',
            Body           => $Param{Config}->{New}->{Note}->{Body} || $Param{Config}->{New}->{NoteBody},
            MimeType       => $ContentType,
            Charset        => 'utf-8',
            UserID         => $Param{UserID},
            HistoryType    => 'AddNote',
            HistoryComment => 'Generic Agent note added.',
            NoAgentNotify  => $Param{Config}->{New}->{SendNoNotification} || 0,
        );
        my $TimeUnits = $Param{Config}->{New}->{Note}->{TimeUnits}
            || $Param{Config}->{New}->{NoteTimeUnits};
        if ( $ArticleID && $TimeUnits ) {
            $TicketObject->TicketAccountTime(
                TicketID  => $Param{TicketID},
                ArticleID => $ArticleID,
                TimeUnit  => $TimeUnits,
                UserID    => $Param{UserID},
            );
        }
    }

    my %PendingStates = $Kernel::OM->Get('Kernel::System::State')->StateGetStatesByType(
        StateType => [ 'pending auto', 'pending reminder' ],
        Result    => 'HASH',
    );

    $Self->{PendingStateList} = \%PendingStates || {};

    # set new state
    my $IsPendingState;
    if ( $Param{Config}->{New}->{State} ) {
        if ( $Self->{NoticeSTDOUT} ) {
            print "  - changed state of Ticket $Ticket to '$Param{Config}->{New}->{State}'\n";
        }
        $TicketObject->TicketStateSet(
            TicketID => $Param{TicketID},
            UserID   => $Param{UserID},
            State    => $Param{Config}->{New}->{State},
        );

        $IsPendingState = grep { $_ eq $Param{Config}->{New}->{State} } values %{ $Self->{PendingStateList} };
    }
    if ( $Param{Config}->{New}->{StateID} ) {
        if ( $Self->{NoticeSTDOUT} ) {
            print "  - changed state id of ticket $Ticket to '$Param{Config}->{New}->{StateID}'\n";
        }
        $TicketObject->TicketStateSet(
            TicketID => $Param{TicketID},
            UserID   => $Param{UserID},
            StateID  => $Param{Config}->{New}->{StateID},
        );

        $IsPendingState = grep { $_ == $Param{Config}->{New}->{StateID} } keys %{ $Self->{PendingStateList} };
    }

    if (
        $Param{Config}->{New}->{PendingTime}
        && !$Param{Config}->{New}->{State}
        && !$Param{Config}->{New}->{StateID}
        )
    {
        # if pending time is provided, but there is no new ticket state provided,
        # check if ticket is already in pending state
        my %Ticket = $TicketObject->TicketGet(
            TicketID      => $Param{TicketID},
            DynamicFields => 0,
        );

        $IsPendingState = grep { $_ eq $Ticket{State} } values %{ $Self->{PendingStateList} };
    }

    # set pending time, if new state is pending state
    if ( $IsPendingState && $Param{Config}->{New}->{PendingTime} ) {

        # pending time
        my $PendingTime = $Param{Config}->{New}->{PendingTime};

        # calculate pending time based on hours, minutes, years...
        if ( $Param{Config}->{New}->{PendingTimeType} ) {
            $PendingTime *= $Param{Config}->{New}->{PendingTimeType};
        }

        # add systemtime
        my $DateTimeObject = $Kernel::OM->Create('Kernel::System::DateTime');
        $DateTimeObject->Add( Seconds => $PendingTime );

        # set pending time
        $TicketObject->TicketPendingTimeSet(
            Year     => $DateTimeObject->Format( Format => '%Y' ),
            Month    => $DateTimeObject->Format( Format => '%m' ),
            Day      => $DateTimeObject->Format( Format => '%d' ),
            Hour     => $DateTimeObject->Format( Format => '%H' ),
            Minute   => $DateTimeObject->Format( Format => '%M' ),
            TicketID => $Param{TicketID},
            UserID   => $Param{UserID},
        );
    }

    # set customer id and customer user
    if ( $Param{Config}->{New}->{CustomerID} || $Param{Config}->{New}->{CustomerUserLogin} ) {

        # If CustomerID or CustomerUserID is updated but not both in same call,
        # keep original values for non updated ones. See bug#14864 (https://bugs.otrs.org/show_bug.cgi?id=14864).
        my %Ticket = $TicketObject->TicketGet(
            TicketID      => $Param{TicketID},
            DynamicFields => 0,
        );

        if ( $Param{Config}->{New}->{CustomerID} ) {
            if ( $Self->{NoticeSTDOUT} ) {
                print
                    "  - set customer id of Ticket $Ticket to '$Param{Config}->{New}->{CustomerID}'\n";
            }
        }
        if ( $Param{Config}->{New}->{CustomerUserLogin} ) {
            if ( $Self->{NoticeSTDOUT} ) {
                print
                    "  - set customer user id of Ticket $Ticket to '$Param{Config}->{New}->{CustomerUserLogin}'\n";
            }
        }
        $TicketObject->TicketCustomerSet(
            TicketID => $Param{TicketID},
            No       => $Param{Config}->{New}->{CustomerID} || $Ticket{CustomerID} || '',
            User     => $Param{Config}->{New}->{CustomerUserLogin} || $Ticket{CustomerUserID} || '',
            UserID   => $Param{UserID},
        );
    }

    # set new title
    if ( $Param{Config}->{New}->{Title} ) {
        if ( $Self->{NoticeSTDOUT} ) {
            print "  - set title of Ticket $Ticket to '$Param{Config}->{New}->{Title}'\n";
        }
        $TicketObject->TicketTitleUpdate(
            Title    => $Param{Config}->{New}->{Title},
            TicketID => $Param{TicketID},
            UserID   => $Param{UserID},
        );
    }

    # set new type
    if ( $Param{Config}->{New}->{Type} ) {
        if ( $Self->{NoticeSTDOUT} ) {
            print "  - set type of Ticket $Ticket to '$Param{Config}->{New}->{Type}'\n";
        }
        $TicketObject->TicketTypeSet(
            TicketID => $Param{TicketID},
            UserID   => $Param{UserID},
            Type     => $Param{Config}->{New}->{Type},
        );
    }
    if ( $Param{Config}->{New}->{TypeID} ) {
        if ( $Self->{NoticeSTDOUT} ) {
            print "  - set type id of Ticket $Ticket to '$Param{Config}->{New}->{TypeID}'\n";
        }
        $TicketObject->TicketTypeSet(
            TicketID => $Param{TicketID},
            UserID   => $Param{UserID},
            TypeID   => $Param{Config}->{New}->{TypeID},
        );
    }

    # set new service
    if ( $Param{Config}->{New}->{Service} ) {
        if ( $Self->{NoticeSTDOUT} ) {
            print "  - set service of Ticket $Ticket to '$Param{Config}->{New}->{Service}'\n";
        }
        $TicketObject->TicketServiceSet(
            TicketID => $Param{TicketID},
            UserID   => $Param{UserID},
            Service  => $Param{Config}->{New}->{Service},
        );
    }
    if ( $Param{Config}->{New}->{ServiceID} ) {
        if ( $Self->{NoticeSTDOUT} ) {
            print "  - set service id of Ticket $Ticket to '$Param{Config}->{New}->{ServiceID}'\n";
        }
        $TicketObject->TicketServiceSet(
            TicketID  => $Param{TicketID},
            UserID    => $Param{UserID},
            ServiceID => $Param{Config}->{New}->{ServiceID},
        );
    }

    # set new sla
    if ( $Param{Config}->{New}->{SLA} ) {
        if ( $Self->{NoticeSTDOUT} ) {
            print "  - set sla of Ticket $Ticket to '$Param{Config}->{New}->{SLA}'\n";
        }
        $TicketObject->TicketSLASet(
            TicketID => $Param{TicketID},
            UserID   => $Param{UserID},
            SLA      => $Param{Config}->{New}->{SLA},
        );
    }
    if ( $Param{Config}->{New}->{SLAID} ) {
        if ( $Self->{NoticeSTDOUT} ) {
            print "  - set sla id of Ticket $Ticket to '$Param{Config}->{New}->{SLAID}'\n";
        }
        $TicketObject->TicketSLASet(
            TicketID => $Param{TicketID},
            UserID   => $Param{UserID},
            SLAID    => $Param{Config}->{New}->{SLAID},
        );
    }

    # set new priority
    if ( $Param{Config}->{New}->{Priority} ) {
        if ( $Self->{NoticeSTDOUT} ) {
            print "  - set priority of Ticket $Ticket to '$Param{Config}->{New}->{Priority}'\n";
        }
        $TicketObject->TicketPrioritySet(
            TicketID => $Param{TicketID},
            UserID   => $Param{UserID},
            Priority => $Param{Config}->{New}->{Priority},
        );
    }
    if ( $Param{Config}->{New}->{PriorityID} ) {
        if ( $Self->{NoticeSTDOUT} ) {
            print
                "  - set priority id of Ticket $Ticket to '$Param{Config}->{New}->{PriorityID}'\n";
        }
        $TicketObject->TicketPrioritySet(
            TicketID   => $Param{TicketID},
            UserID     => $Param{UserID},
            PriorityID => $Param{Config}->{New}->{PriorityID},
        );
    }

    # set new owner
    if ( $Param{Config}->{New}->{Owner} ) {
        if ( $Self->{NoticeSTDOUT} ) {
            print "  - set owner of Ticket $Ticket to '$Param{Config}->{New}->{Owner}'\n";
        }
        $TicketObject->TicketOwnerSet(
            TicketID => $Param{TicketID},
            UserID   => $Param{UserID},
            NewUser  => $Param{Config}->{New}->{Owner},
        );
    }
    if ( $Param{Config}->{New}->{OwnerID} ) {
        if ( $Self->{NoticeSTDOUT} ) {
            print "  - set owner id of Ticket $Ticket to '$Param{Config}->{New}->{OwnerID}'\n";
        }
        $TicketObject->TicketOwnerSet(
            TicketID  => $Param{TicketID},
            UserID    => $Param{UserID},
            NewUserID => $Param{Config}->{New}->{OwnerID},
        );
    }

    # set new responsible
    if ( $Param{Config}->{New}->{Responsible} ) {
        if ( $Self->{NoticeSTDOUT} ) {
            print
                "  - set responsible of Ticket $Ticket to '$Param{Config}->{New}->{Responsible}'\n";
        }
        $TicketObject->TicketResponsibleSet(
            TicketID => $Param{TicketID},
            UserID   => $Param{UserID},
            NewUser  => $Param{Config}->{New}->{Responsible},
        );
    }
    if ( $Param{Config}->{New}->{ResponsibleID} ) {
        if ( $Self->{NoticeSTDOUT} ) {
            print
                "  - set responsible id of Ticket $Ticket to '$Param{Config}->{New}->{ResponsibleID}'\n";
        }
        $TicketObject->TicketResponsibleSet(
            TicketID  => $Param{TicketID},
            UserID    => $Param{UserID},
            NewUserID => $Param{Config}->{New}->{ResponsibleID},
        );
    }

    # set new lock
    if ( $Param{Config}->{New}->{Lock} ) {
        if ( $Self->{NoticeSTDOUT} ) {
            print "  - set lock of Ticket $Ticket to '$Param{Config}->{New}->{Lock}'\n";
        }
        $TicketObject->TicketLockSet(
            TicketID => $Param{TicketID},
            UserID   => $Param{UserID},
            Lock     => $Param{Config}->{New}->{Lock},
        );
    }
    if ( $Param{Config}->{New}->{LockID} ) {
        if ( $Self->{NoticeSTDOUT} ) {
            print "  - set lock id of Ticket $Ticket to '$Param{Config}->{New}->{LockID}'\n";
        }
        $TicketObject->TicketLockSet(
            TicketID => $Param{TicketID},
            UserID   => $Param{UserID},
            LockID   => $Param{Config}->{New}->{LockID},
        );
    }

    # get dynamic field backend objects
    my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    # set new dynamic fields options
    # cycle trough the activated Dynamic Fields for this screen
    DYNAMICFIELD:
    for my $DynamicFieldConfig ( @{ $Self->{DynamicField} } ) {

        next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

        # extract the dynamic field value from the web request
        my $Value = $DynamicFieldBackendObject->EditFieldValueGet(
            DynamicFieldConfig => $DynamicFieldConfig,
            Template           => $Param{Config}->{New},
            TransformDates     => 0,
        );

        # check if we got a value or an empty value if
        # an empty value is configured as valid (PossibleNone)
        # for the current dynamic field
        if (
            defined $Value
            && (
                $DynamicFieldConfig->{Config}->{PossibleNone}
                || $Value ne ''
            )
            )
        {
            my $Success = $DynamicFieldBackendObject->ValueSet(
                DynamicFieldConfig => $DynamicFieldConfig,
                ObjectID           => $Param{TicketID},
                Value              => $Value,
                UserID             => 1,
            );

            if ($Success) {
                if ( $Self->{NoticeSTDOUT} ) {
                    my $ValueStrg = $DynamicFieldBackendObject->ReadableValueRender(
                        DynamicFieldConfig => $DynamicFieldConfig,
                        Value              => $Value,
                    );
                    print "  - set ticket dynamic field $DynamicFieldConfig->{Name} "
                        . "of Ticket $Ticket to $ValueStrg->{Title} '\n";
                }
            }
            else {
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'error',
                    Message  => "Could not set dynamic field $DynamicFieldConfig->{Name} "
                        . "for Ticket $Ticket.",
                );
            }
        }
    }

    # run module
    my $AllowCustomModuleExecution
        = $Kernel::OM->Get('Kernel::Config')->Get('Ticket::GenericAgentAllowCustomModuleExecution') || 0;

    if ( $Param{Config}->{New}->{Module} && $AllowCustomModuleExecution ) {
        if ( $Self->{NoticeSTDOUT} ) {
            print "  - Use module ($Param{Config}->{New}->{Module}) for Ticket $Ticket.\n";
        }
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'notice',
            Message  => "Use module ($Param{Config}->{New}->{Module}) for Ticket $Ticket.",
        );
        if ( $Self->{Debug} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'debug',
                Message  => "Try to load module: $Param{Config}->{New}->{Module}!",
            );
        }

        if ( $Kernel::OM->Get('Kernel::System::Main')->Require( $Param{Config}->{New}->{Module} ) )
        {

            # protect parent process
            eval {
                my $Object = $Param{Config}->{New}->{Module}->new(
                    Debug => $Self->{Debug},
                );
                if ($Object) {
                    $Object->Run(
                        %{ $Param{Config} },
                        TicketID => $Param{TicketID},
                    );
                }
            };

            if ($@) {
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'error',
                    Message  => $@
                );
            }
        }
    }
    elsif ( $Param{Config}->{New}->{Module} && !$AllowCustomModuleExecution ) {
        if ( $Self->{NoticeSTDOUT} ) {
            print "  - Use module ($Param{Config}->{New}->{Module}) is not allowed by the system configuration.\n";
        }
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Use module ($Param{Config}->{New}->{Module}) is not allowed by the system configuration.",
        );
    }

    # set new archive flag
    if (
        $Param{Config}->{New}->{ArchiveFlag}
        && $Kernel::OM->Get('Kernel::Config')->Get('Ticket::ArchiveSystem')
        )
    {
        if ( $Self->{NoticeSTDOUT} ) {
            print
                "  - set archive flag of Ticket $Ticket to '$Param{Config}->{New}->{ArchiveFlag}'\n";
        }
        $TicketObject->TicketArchiveFlagSet(
            TicketID    => $Param{TicketID},
            UserID      => $Param{UserID},
            ArchiveFlag => $Param{Config}->{New}->{ArchiveFlag},
        );
    }

    # delete ticket
    if ( $Param{Config}->{New}->{Delete} ) {
        if ( $Self->{NoticeSTDOUT} ) {
            print "  - Delete Ticket $Ticket.\n";
        }
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'notice',
            Message  => "Delete Ticket $Ticket.",
        );
        $TicketObject->TicketDelete(
            UserID   => $Param{UserID},
            TicketID => $Param{TicketID},
        );
    }
    return 1;
}

sub _JobUpdateRunTime {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Name UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # delete old run times
    return if !$DBObject->Do(
        SQL  => 'DELETE FROM generic_agent_jobs WHERE job_name = ? AND job_key IN (?, ?)',
        Bind => [ \$Param{Name}, \'ScheduleLastRun', \'ScheduleLastRunUnixTime' ],
    );

    # get time object
    my $DateTimeObject = $Kernel::OM->Create('Kernel::System::DateTime');

    # update new run time
    my %Insert = (
        ScheduleLastRun         => $DateTimeObject->ToString(),
        ScheduleLastRunUnixTime => $DateTimeObject->ToEpoch(),
    );

    for my $Key ( sort keys %Insert ) {
        $DBObject->Do(
            SQL  => 'INSERT INTO generic_agent_jobs (job_name,job_key, job_value) VALUES (?, ?, ?)',
            Bind => [ \$Param{Name}, \$Key, \$Insert{$Key} ],
        );
    }

    $Kernel::OM->Get('Kernel::System::Cache')->Delete(
        Key  => 'JobGet::' . $Param{Name},
        Type => 'GenericAgent',
    );

    return 1;
}

1;

=end Internal:

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
