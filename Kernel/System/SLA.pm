# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::SLA;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Cache',
    'Kernel::System::CheckItem',
    'Kernel::System::DB',
    'Kernel::System::Log',
    'Kernel::System::Valid',
);

=head1 NAME

Kernel::System::SLA - sla lib

=head1 DESCRIPTION

All sla functions.

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $SLAObject = $Kernel::OM->Get('Kernel::System::SLA');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # get configured preferences object
    my $GeneratorModule = $Kernel::OM->Get('Kernel::Config')->Get('SLA::PreferencesModule')
        || 'Kernel::System::SLA::PreferencesDB';

    # get preferences object
    $Self->{PreferencesObject} = $Kernel::OM->Get($GeneratorModule);

    $Self->{CacheType} = 'SLA';
    $Self->{CacheTTL}  = 60 * 60 * 24 * 20;

    return $Self;
}

=head2 SLAList()

return a hash list of slas

    my %SLAList = $SLAObject->SLAList(
        ServiceID => 1,  # (optional)
        Valid     => 0,  # (optional) default 1 (0|1)
        UserID    => 1,
    );

=cut

sub SLAList {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{UserID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need UserID!'
        );
        return;
    }

    # set valid param
    if ( !defined $Param{Valid} ) {
        $Param{Valid} = 1;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # add ServiceID
    my %SQLTable;
    $SQLTable{sla} = 'sla s';
    my @SQLWhere;
    if ( $Param{ServiceID} ) {

        # quote
        $Param{ServiceID} = $DBObject->Quote( $Param{ServiceID}, 'Integer' );

        $SQLTable{service} = 'service_sla r';
        push @SQLWhere, "s.id = r.sla_id AND r.service_id = $Param{ServiceID}";
    }

    # add valid part
    if ( $Param{Valid} ) {

        # get valid object
        my $ValidObject = $Kernel::OM->Get('Kernel::System::Valid');

        # create the valid list
        my $ValidIDs = join ', ', $ValidObject->ValidIDsGet();

        push @SQLWhere, "s.valid_id IN ( $ValidIDs )";
    }

    # create the table and where strings
    my $TableString = join q{, }, values %SQLTable;
    my $WhereString = @SQLWhere ? ' WHERE ' . join q{ AND }, @SQLWhere : '';

    # ask database
    $DBObject->Prepare(
        SQL => "SELECT s.id, s.name FROM $TableString $WhereString",
    );

    # fetch the result
    my %SLAList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $SLAList{ $Row[0] } = $Row[1];
    }

    return %SLAList;
}

=head2 SLAGet()

Returns an SLA as a hash

    my %SLAData = $SLAObject->SLAGet(
        SLAID  => 123,
        UserID => 1,
    );

Returns:

    my %SLAData = (
          'SLAID'               => '2',
          'Name'                => 'Diamond Pacific - S2',
          'Calendar'            => '2',
          'FirstResponseTime'   => '60',   # in minutes according to business hours
          'FirstResponseNotify' => '70',   # in percent
          'UpdateTime'          => '360',  # in minutes according to business hours
          'UpdateNotify'        => '70',   # in percent
          'SolutionTime'        => '960',  # in minutes according to business hours
          'SolutionNotify'      => '80',   # in percent
          'ServiceIDs'          => [ '4', '7', '8' ],
          'ValidID'             => '1',
          'Comment'             => 'Some Comment',
          'CreateBy'            => '93',
          'CreateTime'          => '2011-06-16 22:54:54',
          'ChangeBy'            => '93',
          'ChangeTime'          => '2011-06-16 22:54:54',
    );

=cut

sub SLAGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(SLAID UserID)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    # check if result is already cached
    my $CacheKey = 'Cache::SLAGet::' . $Param{SLAID};
    my $Cached   = $Kernel::OM->Get('Kernel::System::Cache')->Get(
        Type           => $Self->{CacheType},
        Key            => $CacheKey,
        CacheInMemory  => 1,
        CacheInBackend => 0,
    );

    if ( ref $Cached eq 'HASH' ) {
        return %{$Cached};
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # get sla from db
    $DBObject->Prepare(
        SQL => 'SELECT id, name, calendar_name, first_response_time, first_response_notify, '
            . 'update_time, update_notify, solution_time, solution_notify, '
            . 'valid_id, comments, create_time, create_by, change_time, change_by '
            . 'FROM sla WHERE id = ?',
        Bind => [
            \$Param{SLAID},
        ],
        Limit => 1,
    );

    # fetch the result
    my %SLAData;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $SLAData{SLAID}               = $Row[0];
        $SLAData{Name}                = $Row[1];
        $SLAData{Calendar}            = $Row[2] || '';
        $SLAData{FirstResponseTime}   = $Row[3];
        $SLAData{FirstResponseNotify} = $Row[4];
        $SLAData{UpdateTime}          = $Row[5];
        $SLAData{UpdateNotify}        = $Row[6];
        $SLAData{SolutionTime}        = $Row[7];
        $SLAData{SolutionNotify}      = $Row[8];
        $SLAData{ValidID}             = $Row[9];
        $SLAData{Comment}             = $Row[10] || '';
        $SLAData{CreateTime}          = $Row[11];
        $SLAData{CreateBy}            = $Row[12];
        $SLAData{ChangeTime}          = $Row[13];
        $SLAData{ChangeBy}            = $Row[14];
    }

    # check sla
    if ( !$SLAData{SLAID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "No such SLAID ($Param{SLAID})!",
        );
        return;
    }

    # get all service ids
    $DBObject->Prepare(
        SQL  => 'SELECT service_id FROM service_sla WHERE sla_id = ? ORDER BY service_id ASC',
        Bind => [ \$SLAData{SLAID} ],
    );

    # fetch the result
    my @ServiceIDs;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        push @ServiceIDs, $Row[0];
    }

    # add the ids
    $SLAData{ServiceIDs} = \@ServiceIDs;

    # get sla preferences
    my %Preferences = $Self->SLAPreferencesGet( SLAID => $Param{SLAID} );

    # merge hash
    if (%Preferences) {
        %SLAData = ( %SLAData, %Preferences );
    }

    # cache result
    $Kernel::OM->Get('Kernel::System::Cache')->Set(
        Type => $Self->{CacheType},
        TTL  => $Self->{CacheTTL},
        Key  => $CacheKey,

        # make a local copy of the sla data to avoid it being altered in-memory later
        Value          => {%SLAData},
        CacheInMemory  => 1,
        CacheInBackend => 0,
    );

    return %SLAData;
}

=head2 SLALookup()

returns the name or the sla id

    my $SLAName = $SLAObject->SLALookup(
        SLAID => 123,
    );

    or

    my $SLAID = $SLAObject->SLALookup(
        Name => 'SLA Name',
    );

=cut

sub SLALookup {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{SLAID} && !$Param{Name} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need SLAID or Name!',
        );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    if ( $Param{SLAID} ) {

        # check cache
        my $CacheKey = 'Cache::SLALookup::ID::' . $Param{SLAID};
        my $Cached   = $Kernel::OM->Get('Kernel::System::Cache')->Get(
            Type           => $Self->{CacheType},
            Key            => $CacheKey,
            CacheInMemory  => 1,
            CacheInBackend => 0,
        );
        if ( defined $Cached ) {
            return $Cached;
        }

        # lookup
        $DBObject->Prepare(
            SQL   => 'SELECT name FROM sla WHERE id = ?',
            Bind  => [ \$Param{SLAID}, ],
            Limit => 1,
        );

        # fetch the result
        my $Name = '';
        while ( my @Row = $DBObject->FetchrowArray() ) {
            $Name = $Row[0];
        }

        # cache
        $Kernel::OM->Get('Kernel::System::Cache')->Set(
            Type           => $Self->{CacheType},
            TTL            => $Self->{CacheTTL},
            Key            => $CacheKey,
            Value          => $Name,
            CacheInMemory  => 1,
            CacheInBackend => 0,
        );

        return $Name;
    }
    else {

        # check cache
        my $CacheKey = 'Cache::SLALookup::Name::' . $Param{Name};
        my $Cached   = $Kernel::OM->Get('Kernel::System::Cache')->Get(
            Type           => $Self->{CacheType},
            Key            => $CacheKey,
            CacheInMemory  => 1,
            CacheInBackend => 0,
        );
        if ( defined $Cached ) {
            return $Cached;
        }

        # lookup
        $DBObject->Prepare(
            SQL   => 'SELECT id FROM sla WHERE name = ?',
            Bind  => [ \$Param{Name} ],
            Limit => 1,
        );

        # fetch the result
        my $SLAID = '';
        while ( my @Row = $DBObject->FetchrowArray() ) {
            $SLAID = $Row[0];
        }

        # cache
        $Kernel::OM->Get('Kernel::System::Cache')->Set(
            Type           => $Self->{CacheType},
            TTL            => $Self->{CacheTTL},
            Key            => $CacheKey,
            Value          => $SLAID,
            CacheInMemory  => 1,
            CacheInBackend => 0,
        );

        return $SLAID;
    }
}

=head2 SLAAdd()

add a sla

    my $SLAID = $SLAObject->SLAAdd(
        ServiceIDs          => [ 1, 5, 7 ],  # (optional)
        Name                => 'SLA Name',
        Calendar            => 'Calendar1',  # (optional)
        FirstResponseTime   => 120,          # (optional)
        FirstResponseNotify => 60,           # (optional) notify agent if first response escalation is 60% reached
        UpdateTime          => 180,          # (optional)
        UpdateNotify        => 80,           # (optional) notify agent if update escalation is 80% reached
        SolutionTime        => 580,          # (optional)
        SolutionNotify      => 80,           # (optional) notify agent if solution escalation is 80% reached
        ValidID             => 1,
        Comment             => 'Comment',    # (optional)
        UserID              => 1,
    );

=cut

sub SLAAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(Name ValidID UserID)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    # check service ids
    if ( defined $Param{ServiceIDs} && ref $Param{ServiceIDs} ne 'ARRAY' ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'ServiceIDs needs to be an array reference!',
        );
        return;
    }

    # set default values
    $Param{ServiceIDs}          ||= [];
    $Param{Calendar}            ||= '';
    $Param{Comment}             ||= '';
    $Param{FirstResponseTime}   ||= 0;
    $Param{FirstResponseNotify} ||= 0;
    $Param{UpdateTime}          ||= 0;
    $Param{UpdateNotify}        ||= 0;
    $Param{SolutionTime}        ||= 0;
    $Param{SolutionNotify}      ||= 0;

    # get check item object
    my $CheckItemObject = $Kernel::OM->Get('Kernel::System::CheckItem');

    # cleanup given params
    for my $Argument (qw(Name Comment)) {
        $CheckItemObject->StringClean(
            StringRef         => \$Param{$Argument},
            RemoveAllNewlines => 1,
            RemoveAllTabs     => 1,
        );
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # find exiting sla's with the same name
    $DBObject->Prepare(
        SQL   => 'SELECT id FROM sla WHERE name = ?',
        Bind  => [ \$Param{Name} ],
        Limit => 1,
    );

    # fetch the result
    my $NoAdd;
    while ( $DBObject->FetchrowArray() ) {
        $NoAdd = 1;
    }

    # abort insert of new sla, if name already exists
    if ($NoAdd) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "An SLA with the name '$Param{Name}' already exists.",
        );
        return;
    }

    # add sla to database
    return if !$DBObject->Do(
        SQL => 'INSERT INTO sla '
            . '(name, calendar_name, first_response_time, first_response_notify, '
            . 'update_time, update_notify, solution_time, solution_notify, '
            . 'valid_id, comments, create_time, create_by, change_time, change_by) VALUES '
            . '(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, current_timestamp, ?, current_timestamp, ?)',
        Bind => [
            \$Param{Name},                \$Param{Calendar},       \$Param{FirstResponseTime},
            \$Param{FirstResponseNotify}, \$Param{UpdateTime},     \$Param{UpdateNotify},
            \$Param{SolutionTime},        \$Param{SolutionNotify}, \$Param{ValidID}, \$Param{Comment},
            \$Param{UserID}, \$Param{UserID},
        ],
    );

    # get sla id
    return if !$DBObject->Prepare(
        SQL   => 'SELECT id FROM sla WHERE name = ?',
        Bind  => [ \$Param{Name} ],
        Limit => 1,
    );

    # fetch the result
    my $SLAID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $SLAID = $Row[0];
    }

    # check sla id
    if ( !$SLAID ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Can't find SLAID for '$Param{Name}'!",
        );
        return;
    }

    # remove all existing allocations
    $DBObject->Do(
        SQL  => 'DELETE FROM service_sla WHERE sla_id = ?',
        Bind => [ \$SLAID ],
    );

    # add the new allocations
    for my $ServiceID ( @{ $Param{ServiceIDs} } ) {

        # add one allocation
        $DBObject->Do(
            SQL  => 'INSERT INTO service_sla (service_id, sla_id) VALUES (?, ?)',
            Bind => [ \$ServiceID, \$SLAID ],
        );
    }

    return $SLAID;
}

=head2 SLAUpdate()

update a existing sla

    my $True = $SLAObject->SLAUpdate(
        SLAID               => 2,
        ServiceIDs          => [ 1, 2, 3 ],  # (optional)
        Name                => 'Service Name',
        Calendar            => 'Calendar1',  # (optional)
        FirstResponseTime   => 120,          # (optional)
        FirstResponseNotify => 60,           # (optional) notify agent if first response escalation is 60% reached
        UpdateTime          => 180,          # (optional)
        UpdateNotify        => 80,           # (optional) notify agent if update escalation is 80% reached
        SolutionTime        => 580,          # (optional)
        SolutionNotify      => 80,           # (optional) notify agent if solution escalation is 80% reached
        ValidID             => 1,
        Comment             => 'Comment',    # (optional)
        UserID              => 1,
    );

=cut

sub SLAUpdate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(SLAID Name ValidID UserID)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    # check service ids
    if ( defined $Param{ServiceIDs} && ref $Param{ServiceIDs} ne 'ARRAY' ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'ServiceIDs need to be an array reference!',
        );
        return;
    }

    # set default values
    $Param{ServiceIDs}          ||= [];
    $Param{Calendar}            ||= '';
    $Param{Comment}             ||= '';
    $Param{FirstResponseTime}   ||= 0;
    $Param{FirstResponseNotify} ||= 0;
    $Param{UpdateTime}          ||= 0;
    $Param{UpdateNotify}        ||= 0;
    $Param{SolutionTime}        ||= 0;
    $Param{SolutionNotify}      ||= 0;

    # get check item object
    my $CheckItemObject = $Kernel::OM->Get('Kernel::System::CheckItem');

    # cleanup given params
    for my $Argument (qw(Name Comment)) {
        $CheckItemObject->StringClean(
            StringRef         => \$Param{$Argument},
            RemoveAllNewlines => 1,
            RemoveAllTabs     => 1,
        );
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # find exiting sla's with the same name
    return if !$DBObject->Prepare(
        SQL   => 'SELECT id FROM sla WHERE name = ?',
        Bind  => [ \$Param{Name} ],
        Limit => 1,
    );

    # fetch the result
    my $Update = 0;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        if ( $Row[0] != $Param{SLAID} ) {
            $Update = $Row[0];
        }
    }

    # abort update of sla, if name already exists
    if ($Update) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "An SLA with the name '$Param{Name}' already exists.",
        );
        return;
    }

    # reset cache
    $Kernel::OM->Get('Kernel::System::Cache')->Delete(
        Type => $Self->{CacheType},
        Key  => 'Cache::SLAGet::' . $Param{SLAID},
    );
    $Kernel::OM->Get('Kernel::System::Cache')->Delete(
        Type => $Self->{CacheType},
        Key  => 'Cache::SLALookup::Name::' . $Param{Name},
    );
    $Kernel::OM->Get('Kernel::System::Cache')->Delete(
        Type => $Self->{CacheType},
        Key  => 'Cache::SLALookup::ID::' . $Param{SLAID},
    );

    # update service
    return if !$DBObject->Do(
        SQL => 'UPDATE sla SET name = ?, calendar_name = ?, '
            . 'first_response_time = ?, first_response_notify = ?, '
            . 'update_time = ?, update_notify = ?, solution_time = ?, solution_notify = ?, '
            . 'valid_id = ?, comments = ?, change_time = current_timestamp, change_by = ? '
            . 'WHERE id = ?',
        Bind => [
            \$Param{Name},                \$Param{Calendar},       \$Param{FirstResponseTime},
            \$Param{FirstResponseNotify}, \$Param{UpdateTime},     \$Param{UpdateNotify},
            \$Param{SolutionTime},        \$Param{SolutionNotify}, \$Param{ValidID}, \$Param{Comment},
            \$Param{UserID}, \$Param{SLAID},
        ],
    );

    # remove all existing allocations
    return if !$DBObject->Do(
        SQL  => 'DELETE FROM service_sla WHERE sla_id = ?',
        Bind => [ \$Param{SLAID}, ]
    );

    # add the new allocations
    for my $ServiceID ( @{ $Param{ServiceIDs} } ) {

        # add one allocation
        return if !$DBObject->Do(
            SQL  => 'INSERT INTO service_sla (service_id, sla_id) VALUES (?, ?)',
            Bind => [ \$ServiceID, \$Param{SLAID} ],
        );
    }

    return 1;
}

=head2 SLAPreferencesSet()

set SLA preferences

    $SLAObject->SLAPreferencesSet(
        SLAID  => 123,
        Key    => 'UserComment',
        Value  => 'some comment',
        UserID => 123,
    );

=cut

sub SLAPreferencesSet {
    my ( $Self, %Param ) = @_;

    return $Self->{PreferencesObject}->SLAPreferencesSet(%Param);
}

=head2 SLAPreferencesGet()

get SLA preferences

    my %Preferences = $SLAObject->SLAPreferencesGet(
        SLAID  => 123,
        UserID => 123,
    );

=cut

sub SLAPreferencesGet {
    my ( $Self, %Param ) = @_;

    return $Self->{PreferencesObject}->SLAPreferencesGet(%Param);
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
