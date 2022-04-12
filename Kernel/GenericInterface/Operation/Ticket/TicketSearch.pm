# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::GenericInterface::Operation::Ticket::TicketSearch;

use strict;
use warnings;

use Kernel::System::VariableCheck qw( :all );

use parent qw(
    Kernel::GenericInterface::Operation::Common
    Kernel::GenericInterface::Operation::Ticket::Common
);

our $ObjectManagerDisabled = 1;

=head1 NAME

Kernel::GenericInterface::Operation::Ticket::TicketSearch - GenericInterface Ticket Search Operation backend

=head1 PUBLIC INTERFACE

=head2 new()

usually, you want to create an instance of this
by using Kernel::GenericInterface::Operation->new();

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    # check needed objects
    for my $Needed (qw(DebuggerObject WebserviceID)) {
        if ( !$Param{$Needed} ) {
            return {
                Success      => 0,
                ErrorMessage => "Got no $Needed!",
            };
        }

        $Self->{$Needed} = $Param{$Needed};
    }

    # get config for this screen
    $Self->{Config} = $Kernel::OM->Get('Kernel::Config')->Get('GenericInterface::Operation::TicketSearch');

    return $Self;
}

=head2 Run()

perform TicketSearch Operation. This will return a Ticket ID list.

    my $Result = $OperationObject->Run(
        # ticket number (optional) as STRING or as ARRAYREF
        TicketNumber => '%123546%',
        TicketNumber => ['%123546%', '%123666%'],

        # ticket title (optional) as STRING or as ARRAYREF
        Title => '%SomeText%',
        Title => ['%SomeTest1%', '%SomeTest2%'],

        Queues   => ['system queue', 'other queue'],
        QueueIDs => [1, 42, 512],

        # use also sub queues of Queue|Queues in search
        UseSubQueues => 0,

        # You can use types like normal, ...
        Types   => ['normal', 'change', 'incident'],
        TypeIDs => [3, 4],

        # You can use states like new, open, pending reminder, ...
        States   => ['new', 'open'],
        StateIDs => [3, 4],

        # (Open|Closed) tickets for all closed or open tickets.
        StateType => 'Open',

        # You also can use real state types like new, open, closed,
        # pending reminder, pending auto, removed and merged.
        StateType    => ['open', 'new'],
        StateTypeIDs => [1, 2, 3],

        Priorities  => ['1 very low', '2 low', '3 normal'],
        PriorityIDs => [1, 2, 3],

        Services   => ['Service A', 'Service B'],
        ServiceIDs => [1, 2, 3],

        SLAs   => ['SLA A', 'SLA B'],
        SLAIDs => [1, 2, 3],

        Locks   => ['unlock'],
        LockIDs => [1, 2, 3],

        OwnerIDs => [1, 12, 455, 32]

        ResponsibleIDs => [1, 12, 455, 32]

        WatchUserIDs => [1, 12, 455, 32]

        # CustomerID (optional) as STRING or as ARRAYREF
        CustomerID => '123',
        CustomerID => ['123', 'ABC'],

        # CustomerIDRaw (optional) as STRING or as ARRAYREF
        # CustomerID without QueryCondition checking.
        # The param CustomerID will be ignored when CustomerIDRaw is set.
        # The raw values will be quoted and combined with 'OR' for the query.
        CustomerIDRaw => '123 + 345',
        CustomerIDRaw => ['123', 'ABC','123 && 456','ABC % efg'],

        # CustomerUserLogin (optional) as STRING as ARRAYREF
        CustomerUserLogin => 'uid123',
        CustomerUserLogin => ['uid123', 'uid777'],

        # create ticket properties (optional)
        CreatedUserIDs     => [1, 12, 455, 32]
        CreatedTypes       => ['normal', 'change', 'incident'],
        CreatedTypeIDs     => [1, 2, 3],
        CreatedPriorities  => ['1 very low', '2 low', '3 normal'],
        CreatedPriorityIDs => [1, 2, 3],
        CreatedStates      => ['new', 'open'],
        CreatedStateIDs    => [3, 4],
        CreatedQueues      => ['system queue', 'other queue'],
        CreatedQueueIDs    => [1, 42, 512],

        # DynamicFields
        #   At least one operator must be specified. Operators will be connected with AND,
        #       values in an operator with OR.
        #   You can also pass more than one argument to an operator: ['value1', 'value2']
        DynamicField_FieldNameX => {
            Empty             => 1,                       # will return dynamic fields without a value
                                                          #     set to 0 to search fields with a value present.
            Equals            => 123,
            Like              => 'value*',                # "equals" operator with wildcard support
            GreaterThan       => '2001-01-01 01:01:01',
            GreaterThanEquals => '2001-01-01 01:01:01',
            SmallerThan       => '2002-02-02 02:02:02',
            SmallerThanEquals => '2002-02-02 02:02:02',
        },

        # article stuff (optional)
        MIMEBase_From    => '%spam@example.com%',
        MIMEBase_To      => '%service@example.com%',
        MIMEBase_Cc      => '%client@example.com%',
        MIMEBase_Subject => '%VIRUS 32%',
        MIMEBase_Body    => '%VIRUS 32%',

        # attachment stuff (optional, applies only for ArticleStorageDB)
        AttachmentName => '%anyfile.txt%',

        # use full article text index if configured (optional, default off)
        FullTextIndex => 1,

        # article content search (AND or OR for From, To, Cc, Subject and Body) (optional)
        ContentSearch => 'AND',

        # content conditions for From,To,Cc,Subject,Body
        # Title,CustomerID and CustomerUserLogin (all optional)
        ConditionInline => 1,

        # articles created more than 60 minutes ago (article older than 60 minutes) (optional)
        ArticleCreateTimeOlderMinutes => 60,
        # articles created less than 120 minutes ago (article newer than 60 minutes) (optional)
        ArticleCreateTimeNewerMinutes => 120,

        # articles with create time after ... (article newer than this date) (optional)
        ArticleCreateTimeNewerDate => '2006-01-09 00:00:01',
        # articles with created time before ... (article older than this date) (optional)
        ArticleCreateTimeOlderDate => '2006-01-19 23:59:59',

        # tickets created more than 60 minutes ago (ticket older than 60 minutes)  (optional)
        TicketCreateTimeOlderMinutes => 60,
        # tickets created less than 120 minutes ago (ticket newer than 120 minutes) (optional)
        TicketCreateTimeNewerMinutes => 120,

        # tickets with create time after ... (ticket newer than this date) (optional)
        TicketCreateTimeNewerDate => '2006-01-09 00:00:01',
        # tickets with created time before ... (ticket older than this date) (optional)
        TicketCreateTimeOlderDate => '2006-01-19 23:59:59',

        # ticket history entries that created more than 60 minutes ago (optional)
        TicketChangeTimeOlderMinutes => 60,
        # ticket history entries that created less than 120 minutes ago (optional)
        TicketChangeTimeNewerMinutes => 120,

        # tickets changed more than 60 minutes ago (optional)
        TicketLastChangeTimeOlderMinutes => 60,
        # tickets changed less than 120 minutes ago (optional)
        TicketLastChangeTimeNewerMinutes => 120,

        # tickets with changed time after ... (ticket changed newer than this date) (optional)
        TicketLastChangeTimeNewerDate => '2006-01-09 00:00:01',
        # tickets with changed time before ... (ticket changed older than this date) (optional)
        TicketLastChangeTimeOlderDate => '2006-01-19 23:59:59',

        # ticket history entry create time after ... (ticket history entries newer than this date) (optional)
        TicketChangeTimeNewerDate => '2006-01-09 00:00:01',
        # ticket history entry create time before ... (ticket history entries older than this date) (optional)
        TicketChangeTimeOlderDate => '2006-01-19 23:59:59',

        # tickets closed more than 60 minutes ago (optional)
        TicketCloseTimeOlderMinutes => 60,
        # tickets closed less than 120 minutes ago (optional)
        TicketCloseTimeNewerMinutes => 120,

        # tickets with closed time after ... (ticket closed newer than this date) (optional)
        TicketCloseTimeNewerDate => '2006-01-09 00:00:01',
        # tickets with closed time before ... (ticket closed older than this date) (optional)
        TicketCloseTimeOlderDate => '2006-01-19 23:59:59',

        # tickets with pending time of more than 60 minutes ago (optional)
        TicketPendingTimeOlderMinutes => 60,
        # tickets with pending time of less than 120 minutes ago (optional)
        TicketPendingTimeNewerMinutes => 120,

        # tickets with pending time after ... (optional)
        TicketPendingTimeNewerDate => '2006-01-09 00:00:01',
        # tickets with pending time before ... (optional)
        TicketPendingTimeOlderDate => '2006-01-19 23:59:59',

        # you can use all following escalation options with this four different ways of escalations
        # TicketEscalationTime...
        # TicketEscalationUpdateTime...
        # TicketEscalationResponseTime...
        # TicketEscalationSolutionTime...

        # ticket escalation time of more than 60 minutes ago (optional)
        TicketEscalationTimeOlderMinutes => -60,
        # ticket escalation time of less than 120 minutes ago (optional)
        TicketEscalationTimeNewerMinutes => -120,

        # tickets with escalation time after ... (optional)
        TicketEscalationTimeNewerDate => '2006-01-09 00:00:01',
        # tickets with escalation time before ... (optional)
        TicketEscalationTimeOlderDate => '2006-01-09 23:59:59',

        # search in archive (optional, default is not to search in archived tickets)
        SearchInArchive => 'AllTickets',    # 'AllTickets' (normal and archived) or 'ArchivedTickets' (only archived)

        # OrderBy and SortBy (optional)
        OrderBy => 'Down',  # Down|Up
        SortBy  => 'Age',   # Owner|Responsible|CustomerID|State|TicketNumber|Queue|Priority|Age|Type|Lock
                            # Changed|Title|Service|SLA|PendingTime|EscalationTime
                            # EscalationUpdateTime|EscalationResponseTime|EscalationSolutionTime
                            # DynamicField_FieldNameX
                            # TicketFreeTime1-6|TicketFreeKey1-16|TicketFreeText1-16

        # OrderBy and SortBy as ARRAY for sub sorting (optional)
        OrderBy => ['Down', 'Up'],
        SortBy  => ['Priority', 'Age'],
        },
    );

    $Result = {
        Success      => 1,                                # 0 or 1
        ErrorMessage => '',                               # In case of an error
        Data         => {
            TicketID => [ 1, 2, 3, 4 ],
        },
    };

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    my $Result = $Self->Init(
        WebserviceID => $Self->{WebserviceID},
    );

    if ( !$Result->{Success} ) {
        $Self->ReturnError(
            ErrorCode    => 'Webservice.InvalidConfiguration',
            ErrorMessage => $Result->{ErrorMessage},
        );
    }

    my ( $UserID, $UserType ) = $Self->Auth(
        %Param,
    );

    return $Self->ReturnError(
        ErrorCode    => 'TicketSearch.AuthFail',
        ErrorMessage => "TicketSearch: Authorization failing!",
    ) if !$UserID;

    # all needed variables
    $Self->{SearchLimit} = $Param{Data}->{Limit}
        || $Self->{Config}->{SearchLimit}
        || 500;
    $Self->{SortBy} = $Param{Data}->{SortBy}
        || $Self->{Config}->{'SortBy::Default'}
        || 'Age';
    $Self->{OrderBy} = $Param{Data}->{OrderBy}
        || $Self->{Config}->{'Order::Default'}
        || 'Down';
    $Self->{FullTextIndex} = $Param{Data}->{FullTextIndex} || 0;

    # get parameter from data
    my %GetParam = $Self->_GetParams( %{ $Param{Data} } );

    # create time settings
    %GetParam = $Self->_CreateTimeSettings(%GetParam);

    # get dynamic fields
    my %DynamicFieldSearchParameters = $Self->_GetDynamicFields( %{ $Param{Data} } );

    # perform ticket search
    $UserType = ( $UserType eq 'Customer' ) ? 'CustomerUserID' : 'UserID';
    my @TicketIDs = $Kernel::OM->Get('Kernel::System::Ticket')->TicketSearch(
        %GetParam,
        %DynamicFieldSearchParameters,
        Result              => 'ARRAY',
        SortBy              => $Self->{SortBy},
        OrderBy             => $Self->{OrderBy},
        Limit               => $Self->{SearchLimit},
        $UserType           => $UserID,
        ConditionInline     => $Self->{Config}->{ExtendedSearchCondition},
        ContentSearchPrefix => '*',
        ContentSearchSuffix => '*',
        FullTextIndex       => $Self->{FullTextIndex},
    );

    if (@TicketIDs) {

        return {
            Success => 1,
            Data    => {
                TicketID => \@TicketIDs,
            },
        };
    }

    # return result
    return {
        Success => 1,
        Data    => {},
    };
}

=begin Internal:

=head2 _GetParams()

get search parameters.

    my %GetParam = _GetParams(
        %Params,                          # all ticket parameters
    );

    returns:

    %GetParam = {
        AllowedParams => 'WithContent', # return not empty parameters for search
    }

=cut

sub _GetParams {
    my ( $Self, %Param ) = @_;

    # get single params
    my %GetParam;

    my %SearchableFields = $Kernel::OM->Get('Kernel::System::Ticket::Article')->ArticleSearchableFieldsList();

    for my $Item (
        sort keys %SearchableFields,
        qw(
        Agent ResultForm TimeSearchType ChangeTimeSearchType LastChangeTimeSearchType CloseTimeSearchType UseSubQueues
        ArticleTimeSearchType SearchInArchive
        Fulltext ContentSearch ShownAttributes
        )
        )
    {

        # get search string params (get submitted params)
        if ( IsStringWithData( $Param{$Item} ) ) {

            $GetParam{$Item} = $Param{$Item};

            # remove white space on the start and end
            $GetParam{$Item} =~ s/\s+$//g;
            $GetParam{$Item} =~ s/^\s+//g;
        }
    }

    # get array params
    for my $Item (
        qw(TicketNumber TicketID Title
        StateIDs StateTypeIDs QueueIDs PriorityIDs OwnerIDs
        CreatedUserIDs WatchUserIDs ResponsibleIDs
        TypeIDs ServiceIDs SLAIDs LockIDs Queues Types States
        Priorities Services SLAs Locks
        CreatedTypes CreatedTypeIDs CreatedPriorities
        CreatedPriorityIDs CreatedStates CreatedStateIDs
        CreatedQueues CreatedQueueIDs StateType CustomerID
        CustomerIDRaw CustomerUserLogin )
        )
    {

        # get search array params
        my @Values;
        if ( IsArrayRefWithData( $Param{$Item} ) ) {
            @Values = @{ $Param{$Item} };
        }
        elsif ( IsStringWithData( $Param{$Item} ) ) {
            @Values = ( $Param{$Item} );
        }
        $GetParam{$Item} = \@Values if scalar @Values;
    }

    # get escalation times
    my %EscalationTimes = (
        1 => '',
        2 => 'Update',
        3 => 'Response',
        4 => 'Solution',
    );

    for my $Index ( sort keys %EscalationTimes ) {
        for my $PostFix (qw( OlderMinutes NewerMinutes NewerDate OlderDate )) {
            my $Item = 'TicketEscalation' . $EscalationTimes{$Index} . 'Time' . $PostFix;

            # get search string params (get submitted params)
            if ( IsStringWithData( $Param{$Item} ) ) {
                $GetParam{$Item} = $Param{$Item};

                # remove white space on the start and end
                $GetParam{$Item} =~ s/\s+$//g;
                $GetParam{$Item} =~ s/^\s+//g;
            }
        }
    }

    my @Prefixes = (
        'TicketCreateTime',
        'TicketChangeTime',
        'TicketLastChangeTime',
        'TicketCloseTime',
        'TicketPendingTime',
        'ArticleCreateTime',
    );

    my @Postfixes = (
        'Point',
        'PointFormat',
        'PointStart',
        'Start',
        'StartDay',
        'StartMonth',
        'StartYear',
        'Stop',
        'StopDay',
        'StopMonth',
        'StopYear',
        'OlderMinutes',
        'NewerMinutes',
        'OlderDate',
        'NewerDate',
    );

    for my $Prefix (@Prefixes) {

        # get search string params (get submitted params)
        if ( IsStringWithData( $Param{$Prefix} ) ) {
            $GetParam{$Prefix} = $Param{$Prefix};

            # remove white space on the start and end
            $GetParam{$Prefix} =~ s/\s+$//g;
            $GetParam{$Prefix} =~ s/^\s+//g;
        }

        for my $Postfix (@Postfixes) {
            my $Item = $Prefix . $Postfix;

            # get search string params (get submitted params)
            if ( IsStringWithData( $Param{$Item} ) ) {
                $GetParam{$Item} = $Param{$Item};

                # remove white space on the start and end
                $GetParam{$Item} =~ s/\s+$//g;
                $GetParam{$Item} =~ s/^\s+//g;
            }
        }
    }

    return %GetParam;

}

=head2 _GetDynamicFields()

get search parameters.

    my %DynamicFieldSearchParameters = _GetDynamicFields(
        %Params,                          # all ticket parameters
    );

    returns:

    %DynamicFieldSearchParameters = {
        'AllAllowedDF' => 'WithData',   # return not empty parameters for search
    }

=cut

sub _GetDynamicFields {
    my ( $Self, %Param ) = @_;

    # dynamic fields search parameters for ticket search
    my %DynamicFieldSearchParameters;

    # get single params
    my %AttributeLookup;

    # get the dynamic fields for ticket object
    $Self->{DynamicField} = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldListGet(
        Valid      => 1,
        ObjectType => ['Ticket'],
    );

    my %DynamicFieldsRaw;
    if ( $Param{DynamicField} ) {
        my %SearchParams;
        if ( IsHashRefWithData( $Param{DynamicField} ) ) {
            $DynamicFieldsRaw{ $Param{DynamicField}->{Name} } = $Param{DynamicField};
        }
        elsif ( IsArrayRefWithData( $Param{DynamicField} ) ) {
            %DynamicFieldsRaw = map { $_->{Name} => $_ } @{ $Param{DynamicField} };
        }
        else {
            return %DynamicFieldSearchParameters;
        }

    }
    else {

        # Compatibility with older versions of the web service.
        for my $ParameterName ( sort keys %Param ) {
            if ( $ParameterName =~ m{\A DynamicField_ ( [a-zA-Z\d]+ ) \z}xms ) {
                $DynamicFieldsRaw{$1} = $Param{$ParameterName};
            }
        }
    }

    # loop over the dynamic fields configured
    DYNAMICFIELD:
    for my $DynamicFieldConfig ( @{ $Self->{DynamicField} } ) {
        next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);
        next DYNAMICFIELD if !$DynamicFieldConfig->{Name};

        # skip all fields that does not match with current field name
        next DYNAMICFIELD if !$DynamicFieldsRaw{ $DynamicFieldConfig->{Name} };

        next DYNAMICFIELD if !IsHashRefWithData( $DynamicFieldsRaw{ $DynamicFieldConfig->{Name} } );

        my %SearchOperators = %{ $DynamicFieldsRaw{ $DynamicFieldConfig->{Name} } };

        delete $SearchOperators{Name};

        # set search parameter
        $DynamicFieldSearchParameters{ 'DynamicField_' . $DynamicFieldConfig->{Name} } = \%SearchOperators;
    }

    # allow free fields

    return %DynamicFieldSearchParameters;

}

=head2 _CreateTimeSettings()

get search parameters.

    my %GetParam = _CreateTimeSettings(
        %Params,                          # all ticket parameters
    );

    returns:

    %GetParam = {
        AllowedTimeSettings => 'WithData',   # return not empty parameters for search
    }

=cut

sub _CreateTimeSettings {
    my ( $Self, %Param ) = @_;

    # get single params
    my %GetParam = %Param;

    # get change time settings
    if ( !$GetParam{ChangeTimeSearchType} ) {

        # do nothing on time stuff
    }
    elsif ( $GetParam{ChangeTimeSearchType} eq 'TimeSlot' ) {
        for my $Key (qw(Month Day)) {
            $GetParam{"TicketChangeTimeStart$Key"} = sprintf( "%02d", $GetParam{"TicketChangeTimeStart$Key"} );
        }
        for my $Key (qw(Month Day)) {
            $GetParam{"TicketChangeTimeStop$Key"} = sprintf( "%02d", $GetParam{"TicketChangeTimeStop$Key"} );
        }
        if (
            $GetParam{TicketChangeTimeStartDay}
            && $GetParam{TicketChangeTimeStartMonth}
            && $GetParam{TicketChangeTimeStartYear}
            )
        {
            $GetParam{TicketChangeTimeNewerDate} = $GetParam{TicketChangeTimeStartYear} . '-'
                . $GetParam{TicketChangeTimeStartMonth} . '-'
                . $GetParam{TicketChangeTimeStartDay}
                . ' 00:00:00';
        }
        if (
            $GetParam{TicketChangeTimeStopDay}
            && $GetParam{TicketChangeTimeStopMonth}
            && $GetParam{TicketChangeTimeStopYear}
            )
        {
            $GetParam{TicketChangeTimeOlderDate} = $GetParam{TicketChangeTimeStopYear} . '-'
                . $GetParam{TicketChangeTimeStopMonth} . '-'
                . $GetParam{TicketChangeTimeStopDay}
                . ' 23:59:59';
        }
    }
    elsif ( $GetParam{ChangeTimeSearchType} eq 'TimePoint' ) {
        if (
            $GetParam{TicketChangeTimePoint}
            && $GetParam{TicketChangeTimePointStart}
            && $GetParam{TicketChangeTimePointFormat}
            )
        {
            my $Time = 0;
            if ( $GetParam{TicketChangeTimePointFormat} eq 'minute' ) {
                $Time = $GetParam{TicketChangeTimePoint};
            }
            elsif ( $GetParam{TicketChangeTimePointFormat} eq 'hour' ) {
                $Time = $GetParam{TicketChangeTimePoint} * 60;
            }
            elsif ( $GetParam{TicketChangeTimePointFormat} eq 'day' ) {
                $Time = $GetParam{TicketChangeTimePoint} * 60 * 24;
            }
            elsif ( $GetParam{TicketChangeTimePointFormat} eq 'week' ) {
                $Time = $GetParam{TicketChangeTimePoint} * 60 * 24 * 7;
            }
            elsif ( $GetParam{TicketChangeTimePointFormat} eq 'month' ) {
                $Time = $GetParam{TicketChangeTimePoint} * 60 * 24 * 30;
            }
            elsif ( $GetParam{TicketChangeTimePointFormat} eq 'year' ) {
                $Time = $GetParam{TicketChangeTimePoint} * 60 * 24 * 365;
            }
            if ( $GetParam{TicketChangeTimePointStart} eq 'Before' ) {
                $GetParam{TicketChangeTimeOlderMinutes} = $Time;
            }
            else {
                $GetParam{TicketChangeTimeNewerMinutes} = $Time;
            }
        }
    }

    # get last change time settings
    if ( !$GetParam{LastChangeTimeSearchType} ) {

        # do nothing on time stuff
    }
    elsif ( $GetParam{LastChangeTimeSearchType} eq 'TimeSlot' ) {
        for my $Key (qw(Month Day)) {
            $GetParam{"TicketLastChangeTimeStart$Key"} = sprintf( "%02d", $GetParam{"TicketLastChangeTimeStart$Key"} );
        }
        for my $Key (qw(Month Day)) {
            $GetParam{"TicketLastChangeTimeStop$Key"} = sprintf( "%02d", $GetParam{"TicketLastChangeTimeStop$Key"} );
        }
        if (
            $GetParam{TicketLastChangeTimeStartDay}
            && $GetParam{TicketLastChangeTimeStartMonth}
            && $GetParam{TicketLastChangeTimeStartYear}
            )
        {
            $GetParam{TicketLastChangeTimeNewerDate} = $GetParam{TicketLastChangeTimeStartYear} . '-'
                . $GetParam{TicketLastChangeTimeStartMonth} . '-'
                . $GetParam{TicketLastChangeTimeStartDay}
                . ' 00:00:00';
        }
        if (
            $GetParam{TicketLastChangeTimeStopDay}
            && $GetParam{TicketLastChangeTimeStopMonth}
            && $GetParam{TicketLastChangeTimeStopYear}
            )
        {
            $GetParam{TicketLastChangeTimeOlderDate} = $GetParam{TicketLastChangeTimeStopYear} . '-'
                . $GetParam{TicketLastChangeTimeStopMonth} . '-'
                . $GetParam{TicketLastChangeTimeStopDay}
                . ' 23:59:59';
        }
    }
    elsif ( $GetParam{LastChangeTimeSearchType} eq 'TimePoint' ) {
        if (
            $GetParam{TicketLastChangeTimePoint}
            && $GetParam{TicketLastChangeTimePointStart}
            && $GetParam{TicketLastChangeTimePointFormat}
            )
        {
            my $Time = 0;
            if ( $GetParam{TicketLastChangeTimePointFormat} eq 'minute' ) {
                $Time = $GetParam{TicketLastChangeTimePoint};
            }
            elsif ( $GetParam{TicketLastChangeTimePointFormat} eq 'hour' ) {
                $Time = $GetParam{TicketLastChangeTimePoint} * 60;
            }
            elsif ( $GetParam{TicketLastChangeTimePointFormat} eq 'day' ) {
                $Time = $GetParam{TicketLastChangeTimePoint} * 60 * 24;
            }
            elsif ( $GetParam{TicketLastChangeTimePointFormat} eq 'week' ) {
                $Time = $GetParam{TicketLastChangeTimePoint} * 60 * 24 * 7;
            }
            elsif ( $GetParam{TicketLastChangeTimePointFormat} eq 'month' ) {
                $Time = $GetParam{TicketLastChangeTimePoint} * 60 * 24 * 30;
            }
            elsif ( $GetParam{TicketLastChangeTimePointFormat} eq 'year' ) {
                $Time = $GetParam{TicketLastChangeTimePoint} * 60 * 24 * 365;
            }
            if ( $GetParam{TicketLastChangeTimePointStart} eq 'Before' ) {
                $GetParam{TicketLastChangeTimeOlderMinutes} = $Time;
            }
            else {
                $GetParam{TicketLastChangeTimeNewerMinutes} = $Time;
            }
        }
    }

    # get close time settings
    if ( !$GetParam{CloseTimeSearchType} ) {

        # do nothing on time stuff
    }
    elsif ( $GetParam{CloseTimeSearchType} eq 'TimeSlot' ) {
        for my $Key (qw(Month Day)) {
            $GetParam{"TicketCloseTimeStart$Key"} = sprintf( "%02d", $GetParam{"TicketCloseTimeStart$Key"} );
        }
        for my $Key (qw(Month Day)) {
            $GetParam{"TicketCloseTimeStop$Key"} = sprintf( "%02d", $GetParam{"TicketCloseTimeStop$Key"} );
        }
        if (
            $GetParam{TicketCloseTimeStartDay}
            && $GetParam{TicketCloseTimeStartMonth}
            && $GetParam{TicketCloseTimeStartYear}
            )
        {
            $GetParam{TicketCloseTimeNewerDate} = $GetParam{TicketCloseTimeStartYear} . '-'
                . $GetParam{TicketCloseTimeStartMonth} . '-'
                . $GetParam{TicketCloseTimeStartDay}
                . ' 00:00:00';
        }
        if (
            $GetParam{TicketCloseTimeStopDay}
            && $GetParam{TicketCloseTimeStopMonth}
            && $GetParam{TicketCloseTimeStopYear}
            )
        {
            $GetParam{TicketCloseTimeOlderDate} = $GetParam{TicketCloseTimeStopYear} . '-'
                . $GetParam{TicketCloseTimeStopMonth} . '-'
                . $GetParam{TicketCloseTimeStopDay}
                . ' 23:59:59';
        }
    }
    elsif ( $GetParam{CloseTimeSearchType} eq 'TimePoint' ) {
        if (
            $GetParam{TicketCloseTimePoint}
            && $GetParam{TicketCloseTimePointStart}
            && $GetParam{TicketCloseTimePointFormat}
            )
        {
            my $Time = 0;
            if ( $GetParam{TicketCloseTimePointFormat} eq 'minute' ) {
                $Time = $GetParam{TicketCloseTimePoint};
            }
            elsif ( $GetParam{TicketCloseTimePointFormat} eq 'hour' ) {
                $Time = $GetParam{TicketCloseTimePoint} * 60;
            }
            elsif ( $GetParam{TicketCloseTimePointFormat} eq 'day' ) {
                $Time = $GetParam{TicketCloseTimePoint} * 60 * 24;
            }
            elsif ( $GetParam{TicketCloseTimePointFormat} eq 'week' ) {
                $Time = $GetParam{TicketCloseTimePoint} * 60 * 24 * 7;
            }
            elsif ( $GetParam{TicketCloseTimePointFormat} eq 'month' ) {
                $Time = $GetParam{TicketCloseTimePoint} * 60 * 24 * 30;
            }
            elsif ( $GetParam{TicketCloseTimePointFormat} eq 'year' ) {
                $Time = $GetParam{TicketCloseTimePoint} * 60 * 24 * 365;
            }
            if ( $GetParam{TicketCloseTimePointStart} eq 'Before' ) {
                $GetParam{TicketCloseTimeOlderMinutes} = $Time;
            }
            else {
                $GetParam{TicketCloseTimeNewerMinutes} = $Time;
            }
        }
    }

    # prepare full text search
    if ( $GetParam{Fulltext} ) {
        $GetParam{ContentSearch} = 'OR';
        for my $Key (qw(From To Cc Subject Body)) {
            $GetParam{$Key} = $GetParam{Fulltext};
        }
    }

    # prepare archive flag
    if ( $Kernel::OM->Get('Kernel::Config')->Get('Ticket::ArchiveSystem') ) {

        $GetParam{SearchInArchive} ||= '';
        if ( $GetParam{SearchInArchive} eq 'AllTickets' ) {
            $GetParam{ArchiveFlags} = [ 'y', 'n' ];
        }
        elsif ( $GetParam{SearchInArchive} eq 'ArchivedTickets' ) {
            $GetParam{ArchiveFlags} = ['y'];
        }
        else {
            $GetParam{ArchiveFlags} = ['n'];
        }
    }

    return %GetParam;
}

=end Internal:

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut

1;
