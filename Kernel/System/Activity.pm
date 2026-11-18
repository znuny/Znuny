# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Activity;

use strict;
use warnings;

use utf8;

use List::Util qw(any);

use parent qw(Kernel::System::DBCRUD);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::HTMLUtils',
    'Kernel::System::Log',
    'Kernel::System::Scheduler',
);

=head1 NAME

Kernel::System::Activity - to manage the activity

=head1 DESCRIPTION

All functions to manage the activity.

=head1 PUBLIC INTERFACE

=head2 new()

create an object

    my $ActivityObject = $Kernel::OM->Get('Kernel::System::Activity');

=cut

=head2 Add()

Creates data attributes.

    my $CreatedID = $ActivityObject->Add(
        ID               => '...',
        Type             => '...',
        Title            => '...',
        Text             => '...',
        State            => '...',
        Link             => '...',
        CreateTime       => '...',
        CreateBy         => '...',
        UserID           => 1,
    );

Returns:

    my $CreatedID = 1;

=cut

sub Add {
    my ( $Self, %Param ) = @_;

    my $HTMLUtilsObject = $Kernel::OM->Get('Kernel::System::HTMLUtils');

    my $Title = $HTMLUtilsObject->ToAscii( String => $Param{Title} );
    my $Text  = $HTMLUtilsObject->ToAscii( String => $Param{Text} );

    my $ActivityID = $Self->DataAdd(
        Type     => $Param{Type},
        Title    => $Title,
        Text     => $Text,
        State    => $Param{State},
        Link     => $Param{Link},
        CreateBy => $Param{CreateBy},
        UserID   => $Param{UserID},
    );

    my $TrimResult = $Self->TrimToMaxKeepActivities(
        UserID   => $Param{UserID},
        CreateBy => $Param{CreateBy},
    );
    return if !defined $TrimResult;

    return $ActivityID;
}

=head2 TrimToMaxKeepActivities()

Deletes oldest activities for the given user and creator until the configured limit is reached.

    my $DeletedCount = $ActivityObject->TrimToMaxKeepActivities(
        UserID   => 123,
        CreateBy => 1,
    );

Returns the number of deleted activities, 0 if none were deleted, or undef on error.

=cut

sub TrimToMaxKeepActivities {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');

    NEEDED:
    for my $Needed (qw(UserID CreateBy)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Need $Needed!",
        );
        return;
    }

    my @ExistingActivities = $Self->DataListGet(
        CreateBy => $Param{CreateBy},
        SortBy   => [ $Self->{Identifier}, ],
        OrderBy  => [ 'ASC', ],
        UserID   => $Param{UserID},
        Cache    => 0,
    );

    my $ActivityConfig             = $ConfigObject->Get('Activity') // {};
    my $MaxKeepActivities          = $Param{MaxKeepActivities} // $ActivityConfig->{MaxKeepActivities} // 50;
    my $NumberOfActivitiesToDelete = ( scalar @ExistingActivities ) - $MaxKeepActivities;
    return 0 if $NumberOfActivitiesToDelete <= 0;

    my @ActivitiesToDelete = splice @ExistingActivities, 0, $NumberOfActivitiesToDelete;
    for my $ActivityToDelete (@ActivitiesToDelete) {
        return if !$Self->DataDelete(
            $Self->{Identifier} => $ActivityToDelete->{ $Self->{Identifier} },
            UserID              => $Param{UserID},
        );
    }

    return scalar @ActivitiesToDelete;
}

=head2 CleanupExcessActivities()

Schedules deletion of oldest activities for all user and creator combinations until the configured limit is reached.

    my $ScheduledTaskCount = $ActivityObject->CleanupExcessActivities();

Returns the total number of scheduled tasks, or undef on error.

=cut

sub CleanupExcessActivities {
    my ( $Self, %Param ) = @_;

    my $LogObject       = $Kernel::OM->Get('Kernel::System::Log');
    my $SchedulerObject = $Kernel::OM->Get('Kernel::System::Scheduler');

    my $Groups = $Self->{DBObject}->SelectAll(
        SQL => '
            SELECT DISTINCT user_id, create_by
            FROM   activity',
    );

    return 0 if !$Groups || !@{$Groups};

    my $ScheduledTasks = 0;

    GROUP:
    for my $Group ( @{$Groups} ) {
        my $Success = $SchedulerObject->TaskAdd(
            Type                     => 'AsynchronousExecutor',
            Name                     => "Activity-TrimToMaxKeepActivities-UserID-$Group->[0]-CreateBy-$Group->[1]",
            MaximumParallelInstances => 1,
            Data                     => {
                Object   => ref $Self,
                Function => 'TrimToMaxKeepActivities',
                Params   => {
                    UserID   => $Group->[0],
                    CreateBy => $Group->[1],
                },
            },
        );

        if ( !$Success ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Could not schedule activity cleanup for UserID '$Group->[0]' and CreateBy '$Group->[1]'.",
            );
            return;
        }

        $ScheduledTasks++;
    }

    return $ScheduledTasks;
}

=head2 GetLink()

Returns a valid URL to the details dialog of the object with the given ID.

    my $String = $ActivityObject->GetLink(
        TicketID => 32,

        # OR:
        ApointmentID => 78,
    );

Returns:

    my $String = 'http://www.znuny.org/index.pl?Action=AgentTicketZoom;TicketID=1';

=cut

sub GetLink {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');

    if (
        ( !$Param{TicketID} && !$Param{AppointmentID} )
        || ( $Param{TicketID} && $Param{AppointmentID} )
        )
    {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Either give parameter 'TicketID' or 'AppointmentID'.",
        );

        return;
    }

    my $HttpType    = $ConfigObject->Get('HttpType');
    my $Hostname    = $ConfigObject->Get('FQDN');
    my $ScriptAlias = $ConfigObject->Get('ScriptAlias') // '';

    my $BaseURL = "$HttpType://$Hostname/$ScriptAlias" . "index.pl";
    my $Link    = '';

    if ( $Param{TicketID} ) {
        $Link = $BaseURL . "?Action=AgentTicketZoom;TicketID=" . $Param{TicketID};
    }
    elsif ( $Param{AppointmentID} ) {
        $Link = $BaseURL . "?Action=AgentAppointmentCalendarOverview;AppointmentID=" . $Param{AppointmentID};
    }

    return $Link;
}

=head2 Get()

Get data attributes with mapped icons.

    my %Activity = $ActivityObject->Get();
        ID         => 1,
        Type       => '...', # optional
        Title      => '...', # optional
        Text       => '...', # optional
        State      => '...', # optional
        Link       => '...', # optional
        CreateTime => '...', # optional
        CreateBy   => '...', # optional
        UserID     => 123,
    );

Returns:

    my %Activity = (
        ID         => '...',
        UserID     => 1,
        Type       => '...',
        Title      => '...',
        Text       => '...',
        State      => '...',
        Link       => '...',
        CreateTime => '...',
        CreateBy   => '...',
        Icon       => '...',   # if defined for Type
    );

=cut

sub Get {
    my ( $Self, %Param ) = @_;

    my %Data = $Self->DataGet(
        ID     => $Param{ID},
        UserID => $Param{UserID},
        %Param,
    );

    my $Icon = '';
    if ( $Data{Type} ) {
        $Icon = $Self->{TypeIconMap}->{ $Data{Type} } || '';
    }
    $Data{Icon} = $Icon;

    return %Data;
}

=head2 StatsGet()

Returns a hashref with statistics about the activities, currently the total
number of activities and a boolean indicationg whether there are any new ones.

    $Stats = $ActivityObject->StatsGet(
        ID         => '...', # optional
        Type       => '...', # optional
        Title      => '...', # optional
        Text       => '...', # optional
        State      => '...', # optional
        Link       => '...', # optional
        CreateTime => '...', # optional
        CreateBy   => '...', # optional
        UserID     => 123,
    );

Returns:

    $Stats = {
        Count  => 123,
        HasNew => 1,
    };

=cut

sub StatsGet {
    my ( $Self, %Param ) = @_;

    my @Activities = $Self->DataListGet(%Param);
    my $Count      = scalar @Activities;
    my $HasNew     = any { $_->{State} eq 'new' } @Activities;
    return {
        Count  => $Count,
        HasNew => $HasNew,
    };
}

=head2 ListGet()

Get list data with attributes with mapped icons.

    my @Activities = $ActivityObject->ListGet(
        ID         => '...', # optional
        Type       => '...', # optional
        Title      => '...', # optional
        Text       => '...', # optional
        State      => '...', # optional
        Link       => '...', # optional
        CreateTime => '...', # optional
        CreateBy   => '...', # optional
        UserID     => 123,
    );

Returns:

    my @Activities = (
        {
            ID         => '...',
            UserID     => 1,
            Type       => '...',
            Title      => '...',
            Text       => '...',
            State      => '...',
            Link       => '...',
            CreateTime => '...',
            CreateBy   => '...',
            Icon       => '...',   # if defined for Type
        },
        {
            ...
        }
    );

=cut

sub ListGet {
    my ( $Self, %Param ) = @_;

    my @Activities = $Self->DataListGet(
        UserID => $Param{UserID},
        %Param,
    );

    ACTIVITY:
    for my $Activity (@Activities) {
        $Activity->{Icon} = '';

        next ACTIVITY if !$Activity->{Type};
        next ACTIVITY if !$Self->{TypeIconMap};
        $Activity->{Icon} = $Self->{TypeIconMap}->{ $Activity->{Type} } // '';
    }

    return @Activities;
}

=head2 DataAdd()

creates data attributes

    my $CreatedID = $ActivityObject->DataAdd(
        ID         => '...',
        Type       => '...',
        Title      => '...',
        Text       => '...',
        State      => '...',
        Link       => '...',
        CreateTime => '...',
        CreateBy   => '...',
        UserID     => 1,
    );

Returns:

    my $CreatedID = 1;

=cut

=head2 DataGet()

get data attributes

    my %Data = $ActivityObject->DataGet(
        ID         => '...', # optional
        Type       => '...', # optional
        Title      => '...', # optional
        Text       => '...', # optional
        State      => '...', # optional
        Link       => '...', # optional
        CreateTime => '...', # optional
        CreateBy   => '...', # optional
        UserID     => 1,
    );

Returns:

    my %Data = (
        ID         => '...',
        UserID     => 1,
        Type       => '...',
        Title      => '...',
        Text       => '...',
        State      => '...',
        Link       => '...',
        CreateTime => '...',
        CreateBy   => '...',
    );

=cut

=head2 DataListGet()

get list data with attributes

    my @Data = $ActivityObject->DataListGet(
        ID         => '...', # optional
        Type       => '...', # optional
        Title      => '...', # optional
        Text       => '...', # optional
        State      => '...', # optional
        Link       => '...', # optional
        CreateTime => '...', # optional
        CreateBy   => '...', # optional
        UserID     => 1,
    );

Returns:

    my @Data = (
        {
            ID         => '...',
            UserID     => 1,
            Type       => '...',
            Title      => '...',
            Text       => '...',
            State      => '...',
            Link       => '...',
            CreateTime => '...',
            CreateBy   => '...',
        },
        # ...
    );

=cut

=head2 DataUpdate()

update data attributes

    my $Success = $ActivityObject->DataUpdate(
        ID     => 1234,
        UserID => 1,
        # all other attributes are optional
    );

Returns:

    my $Success = 1; # 1|0

=cut

=head2 DataDelete()

deletes data attributes - at least one is required.

    my $Success = $ActivityObject->DataDelete(
        ID         => '...', # optional
        Type       => '...', # optional
        Title      => '...', # optional
        Text       => '...', # optional
        State      => '...', # optional
        Link       => '...', # optional
        CreateTime => '...', # optional
        CreateBy   => '...', # optional
        UserID     => 1,
    );

Returns:

    my $Success = 1; # 1|0

=cut

=head2 DataSearch()

search for value in defined attributes

    my %Data = $ActivityObject->DataSearch(
        Search     => 'test*test',
        ID         => '...', # optional
        Type       => '...', # optional
        Title      => '...', # optional
        Text       => '...', # optional
        State      => '...', # optional
        Link       => '...', # optional
        CreateTime => '...', # optional
        CreateBy   => '...', # optional
        UserID     => 1,
    );

Returns:

    my %Data = (
        '1' => {
            'ID'         => '...',
            'Type'       => '...',
            'Title'      => '...',
            'Text'       => '...',
            'State'      => '...',
            'Link'       => '...',
            'CreateTime' => '...',
            'CreateBy'   => '...',
            'UserID'     => 1,
        },
        # ...
    );

=cut

=head2 InitConfig()

init config for object

    my $Success = $ActivityObject->InitConfig();

Returns:

    my $Success = 1;

=cut

sub InitConfig {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    $Self->{Columns} = {
        ID => {
            Column => 'id',
        },
        UserID => {
            Column       => 'user_id',
            SearchTarget => 1,
        },
        Type => {
            Column       => 'activity_type',
            SearchTarget => 1,
        },
        Title => {
            Column       => 'activity_title',
            SearchTarget => 1,
        },
        Text => {
            Column       => 'activity_text',
            SearchTarget => 1,
        },
        State => {
            Column       => 'activity_state',
            SearchTarget => 1,
        },
        Link => {
            Column       => 'activity_link',
            SearchTarget => 1,
        },
        CreateTime => {
            Column       => 'create_time',
            SearchTarget => 0,
            TimeStampAdd => 1,
        },
        CreateBy => {
            Column       => 'create_by',
            SearchTarget => 0,
        },
    };

    # base table activity
    $Self->{Name}           = 'Activity';
    $Self->{Identifier}     = 'ID';
    $Self->{DatabaseTable}  = 'activity';
    $Self->{DefaultSortBy}  = 'CreateTime';
    $Self->{DefaultOrderBy} = 'DESC';
    $Self->{CacheType}      = 'Activity';
    $Self->{CacheTTL}       = $ConfigObject->Get( 'DBCRUD::' . $Self->{Name} . '::CacheTTL' ) || 60 * 60 * 8;

    $Self->{AutoCreateMissingUUIDDatabaseTableColumns} = 1;

    # base function activation
    $Self->{FunctionDataAdd}         = 1;
    $Self->{FunctionDataUpdate}      = 1;
    $Self->{FunctionDataDelete}      = 1;
    $Self->{FunctionDataGet}         = 1;
    $Self->{FunctionDataListGet}     = 1;
    $Self->{FunctionDataSearch}      = 1;
    $Self->{FunctionDataSearchValue} = 1;

    my $Config = $ConfigObject->Get('Activity');
    %{ $Self->{TypeIconMap} }  = %{ $Config->{TypeIconMapping}  || {} };
    %{ $Self->{EventTypeMap} } = %{ $Config->{EventTypeMapping} || {} };

    return 1;
}

1;
