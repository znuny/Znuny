# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::Service;

use strict;
use warnings;

use Kernel::System::VariableCheck (qw(:all));

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Cache',
    'Kernel::System::CheckItem',
    'Kernel::System::DB',
    'Kernel::System::Log',
    'Kernel::System::Main',
    'Kernel::System::Valid',
);

=head1 NAME

Kernel::System::Service - service lib

=head1 DESCRIPTION

All service functions.

=head1 PUBLIC INTERFACE

=head2 new()

create an object

    my $ServiceObject = $Kernel::OM->Get('Kernel::System::Service');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    $Self->{CacheType} = 'Service';
    $Self->{CacheTTL}  = 60 * 60 * 24 * 20;

    # load generator preferences module
    my $GeneratorModule = $Kernel::OM->Get('Kernel::Config')->Get('Service::PreferencesModule')
        || 'Kernel::System::Service::PreferencesDB';
    if ( $Kernel::OM->Get('Kernel::System::Main')->Require($GeneratorModule) ) {
        $Self->{PreferencesObject} = $GeneratorModule->new();
    }

    return $Self;
}

=head2 ServiceList()

return a hash list of services

    my %ServiceList = $ServiceObject->ServiceList(
        Valid  => 0,   # (optional) default 1 (0|1)
        UserID => 1,
    );

=cut

sub ServiceList {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{UserID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need UserID!',
        );
        return;
    }

    # check valid param
    if ( !defined $Param{Valid} ) {
        $Param{Valid} = 1;
    }

    # read cache
    my $CacheKey = 'ServiceList::Valid::' . $Param{Valid};

    if ( $Param{Valid} && defined $Param{KeepChildren} && $Param{KeepChildren} eq '1' ) {
        $CacheKey .= '::KeepChildren::' . $Param{KeepChildren};
    }

    my $Cache = $Kernel::OM->Get('Kernel::System::Cache')->Get(
        Type => $Self->{CacheType},
        Key  => $CacheKey,
    );
    return %{$Cache} if ref $Cache eq 'HASH';

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # ask database
    $DBObject->Prepare(
        SQL => 'SELECT id, name, valid_id FROM service',
    );

    # fetch the result
    my %ServiceList;
    my %ServiceValidList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ServiceList{ $Row[0] }      = $Row[1];
        $ServiceValidList{ $Row[0] } = $Row[2];
    }

    if ( !$Param{Valid} ) {
        $Kernel::OM->Get('Kernel::System::Cache')->Set(
            Type  => $Self->{CacheType},
            TTL   => $Self->{CacheTTL},
            Key   => $CacheKey,
            Value => \%ServiceList,
        );
        return %ServiceList if !$Param{Valid};
    }

    # get valid ids
    my @ValidIDs = $Kernel::OM->Get('Kernel::System::Valid')->ValidIDsGet();

    # duplicate service list
    my %ServiceListTmp = %ServiceList;

    # add suffix for correct sorting
    for my $ServiceID ( sort keys %ServiceListTmp ) {
        $ServiceListTmp{$ServiceID} .= '::';
    }

    my %ServiceInvalidList;
    SERVICEID:
    for my $ServiceID ( sort { $ServiceListTmp{$a} cmp $ServiceListTmp{$b} } keys %ServiceListTmp )
    {

        my $Valid = scalar grep { $_ eq $ServiceValidList{$ServiceID} } @ValidIDs;

        next SERVICEID if $Valid;

        $ServiceInvalidList{ $ServiceList{$ServiceID} } = 1;
        delete $ServiceList{$ServiceID};
    }

    # delete invalid services and children
    if ( !defined $Param{KeepChildren} || !$Param{KeepChildren} ) {
        for my $ServiceID ( sort keys %ServiceList ) {

            INVALIDNAME:
            for my $InvalidName ( sort keys %ServiceInvalidList ) {

                if ( $ServiceList{$ServiceID} =~ m{ \A \Q$InvalidName\E :: }xms ) {
                    delete $ServiceList{$ServiceID};
                    last INVALIDNAME;
                }
            }
        }
    }

    # set cache
    $Kernel::OM->Get('Kernel::System::Cache')->Set(
        Type  => $Self->{CacheType},
        TTL   => $Self->{CacheTTL},
        Key   => $CacheKey,
        Value => \%ServiceList,
    );

    return %ServiceList;
}

=head2 ServiceListGet()

return a list of services with the complete list of attributes for each service

    my $ServiceList = $ServiceObject->ServiceListGet(
        Valid  => 0,   # (optional) default 1 (0|1)
        UserID => 1,
    );

    returns

    $ServiceList = [
        {
            ServiceID  => 1,
            ParentID   => 0,
            Name       => 'MyService',
            NameShort  => 'MyService',
            ValidID    => 1,
            Comment    => 'Some Comment'
            CreateTime => '2011-02-08 15:08:00',
            ChangeTime => '2011-06-11 17:22:00',
            CreateBy   => 1,
            ChangeBy   => 1,
        },
        {
            ServiceID  => 2,
            ParentID   => 1,
            Name       => 'MyService::MySubService',
            NameShort  => 'MySubService',
            ValidID    => 1,
            Comment    => 'Some Comment'
            CreateTime => '2011-02-08 15:08:00',
            ChangeTime => '2011-06-11 17:22:00',
            CreateBy   => 1,
            ChangeBy   => 1,
        },
        # ...
    ];

=cut

sub ServiceListGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{UserID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need UserID!',
        );
        return;
    }

    # check valid param
    if ( !defined $Param{Valid} ) {
        $Param{Valid} = 1;
    }

    # check cached results
    my $CacheKey = 'Cache::ServiceListGet::Valid::' . $Param{Valid};
    my $Cache    = $Kernel::OM->Get('Kernel::System::Cache')->Get(
        Type => $Self->{CacheType},
        Key  => $CacheKey,
    );
    return $Cache if defined $Cache;

    # create SQL query
    my $SQL = 'SELECT id, name, valid_id, comments, create_time, create_by, change_time, change_by '
        . 'FROM service';

    if ( $Param{Valid} ) {
        $SQL .= ' WHERE valid_id IN (' . join ', ',
            $Kernel::OM->Get('Kernel::System::Valid')->ValidIDsGet() . ')';
    }

    $SQL .= ' ORDER BY name';

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # ask database
    $DBObject->Prepare(
        SQL => $SQL,
    );

    # fetch the result
    my @ServiceList;
    my %ServiceName2ID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        my %ServiceData;
        $ServiceData{ServiceID}  = $Row[0];
        $ServiceData{Name}       = $Row[1];
        $ServiceData{ValidID}    = $Row[2];
        $ServiceData{Comment}    = $Row[3] || '';
        $ServiceData{CreateTime} = $Row[4];
        $ServiceData{CreateBy}   = $Row[5];
        $ServiceData{ChangeTime} = $Row[6];
        $ServiceData{ChangeBy}   = $Row[7];

        # add service data to service list
        push @ServiceList, \%ServiceData;

        # build service id lookup hash
        $ServiceName2ID{ $ServiceData{Name} } = $ServiceData{ServiceID};
    }

    for my $ServiceData (@ServiceList) {

        # create short name and parentid
        $ServiceData->{NameShort} = $ServiceData->{Name};
        if ( $ServiceData->{Name} =~ m{ \A (.*) :: (.+?) \z }xms ) {
            my $ParentName = $1;
            $ServiceData->{NameShort} = $2;
            $ServiceData->{ParentID}  = $ServiceName2ID{$ParentName};
        }

        # get service preferences
        my %Preferences = $Self->ServicePreferencesGet(
            ServiceID => $ServiceData->{ServiceID},
        );

        # merge hash
        if (%Preferences) {
            %{$ServiceData} = ( %{$ServiceData}, %Preferences );
        }
    }

    if (@ServiceList) {

        # set cache
        $Kernel::OM->Get('Kernel::System::Cache')->Set(
            Type  => $Self->{CacheType},
            TTL   => $Self->{CacheTTL},
            Key   => $CacheKey,
            Value => \@ServiceList,
        );
    }

    return \@ServiceList;
}

=head2 ServiceGet()

return a service as hash

Return
    $ServiceData{ServiceID}
    $ServiceData{ParentID}
    $ServiceData{Name}
    $ServiceData{NameShort}
    $ServiceData{ValidID}
    $ServiceData{Comment}
    $ServiceData{CreateTime}
    $ServiceData{CreateBy}
    $ServiceData{ChangeTime}
    $ServiceData{ChangeBy}

    my %ServiceData = $ServiceObject->ServiceGet(
        ServiceID => 123,
        UserID    => 1,
    );

    my %ServiceData = $ServiceObject->ServiceGet(
        Name    => 'Service::SubService',
        UserID  => 1,
    );

=cut

sub ServiceGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{UserID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Need UserID!",
        );
        return;
    }

    # either ServiceID or Name must be passed
    if ( !$Param{ServiceID} && !$Param{Name} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need ServiceID or Name!',
        );
        return;
    }

    # check that not both ServiceID and Name are given
    if ( $Param{ServiceID} && $Param{Name} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need either ServiceID OR Name - not both!',
        );
        return;
    }

    # lookup the ServiceID
    if ( $Param{Name} ) {
        $Param{ServiceID} = $Self->ServiceLookup(
            Name => $Param{Name},
        );
    }

    # check cached results
    my $CacheKey = 'Cache::ServiceGet::' . $Param{ServiceID};
    my $Cache    = $Kernel::OM->Get('Kernel::System::Cache')->Get(
        Type => $Self->{CacheType},
        Key  => $CacheKey,
    );
    return %{$Cache} if ref $Cache eq 'HASH';

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # get service from db
    $DBObject->Prepare(
        SQL =>
            'SELECT id, name, valid_id, comments, create_time, create_by, change_time, change_by '
            . 'FROM service WHERE id = ?',
        Bind  => [ \$Param{ServiceID} ],
        Limit => 1,
    );

    # fetch the result
    my %ServiceData;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ServiceData{ServiceID}  = $Row[0];
        $ServiceData{Name}       = $Row[1];
        $ServiceData{ValidID}    = $Row[2];
        $ServiceData{Comment}    = $Row[3] || '';
        $ServiceData{CreateTime} = $Row[4];
        $ServiceData{CreateBy}   = $Row[5];
        $ServiceData{ChangeTime} = $Row[6];
        $ServiceData{ChangeBy}   = $Row[7];
    }

    # check service
    if ( !$ServiceData{ServiceID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "No such ServiceID ($Param{ServiceID})!",
        );
        return;
    }

    # create short name and parentid
    $ServiceData{NameShort} = $ServiceData{Name};
    if ( $ServiceData{Name} =~ m{ \A (.*) :: (.+?) \z }xms ) {
        $ServiceData{NameShort} = $2;

        # lookup parent
        my $ServiceID = $Self->ServiceLookup(
            Name => $1,
        );
        $ServiceData{ParentID} = $ServiceID;
    }

    # get service preferences
    my %Preferences = $Self->ServicePreferencesGet(
        ServiceID => $Param{ServiceID},
    );

    # merge hash
    if (%Preferences) {
        %ServiceData = ( %ServiceData, %Preferences );
    }

    # set cache
    $Kernel::OM->Get('Kernel::System::Cache')->Set(
        Type  => $Self->{CacheType},
        TTL   => $Self->{CacheTTL},
        Key   => $CacheKey,
        Value => \%ServiceData,
    );

    return %ServiceData;
}

=head2 ServiceLookup()

return a service name and id

    my $ServiceName = $ServiceObject->ServiceLookup(
        ServiceID => 123,
    );

    or

    my $ServiceID = $ServiceObject->ServiceLookup(
        Name => 'Service::SubService',
    );

=cut

sub ServiceLookup {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{ServiceID} && !$Param{Name} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need ServiceID or Name!',
        );
        return;
    }

    if ( $Param{ServiceID} ) {

        # check cache
        my $CacheKey = 'Cache::ServiceLookup::ID::' . $Param{ServiceID};
        my $Cache    = $Kernel::OM->Get('Kernel::System::Cache')->Get(
            Type => $Self->{CacheType},
            Key  => $CacheKey,
        );
        return $Cache if defined $Cache;

        # get database object
        my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

        # lookup
        $DBObject->Prepare(
            SQL   => 'SELECT name FROM service WHERE id = ?',
            Bind  => [ \$Param{ServiceID} ],
            Limit => 1,
        );

        my $Result = '';
        while ( my @Row = $DBObject->FetchrowArray() ) {
            $Result = $Row[0];
        }

        $Kernel::OM->Get('Kernel::System::Cache')->Set(
            Type  => $Self->{CacheType},
            TTL   => $Self->{CacheTTL},
            Key   => $CacheKey,
            Value => $Result,
        );

        return $Result;
    }
    else {

        # check cache
        my $CacheKey = 'Cache::ServiceLookup::Name::' . $Param{Name};
        my $Cache    = $Kernel::OM->Get('Kernel::System::Cache')->Get(
            Type => $Self->{CacheType},
            Key  => $CacheKey,
        );
        return $Cache if defined $Cache;

        # get database object
        my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

        # lookup
        $DBObject->Prepare(
            SQL   => 'SELECT id FROM service WHERE name = ?',
            Bind  => [ \$Param{Name} ],
            Limit => 1,
        );

        my $Result = '';
        while ( my @Row = $DBObject->FetchrowArray() ) {
            $Result = $Row[0];
        }

        $Kernel::OM->Get('Kernel::System::Cache')->Set(
            Type  => $Self->{CacheType},
            TTL   => $Self->{CacheTTL},
            Key   => $CacheKey,
            Value => $Result,
        );

        return $Result;
    }
}

=head2 ServiceAdd()

add a service

    my $ServiceID = $ServiceObject->ServiceAdd(
        Name     => 'Service Name',
        ParentID => 1,           # (optional)
        ValidID  => 1,
        Comment  => 'Comment',    # (optional)
        UserID   => 1,
    );

=cut

sub ServiceAdd {
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

    # set comment
    $Param{Comment} ||= '';

    # cleanup given params
    for my $Argument (qw(Name Comment)) {
        $Kernel::OM->Get('Kernel::System::CheckItem')->StringClean(
            StringRef         => \$Param{$Argument},
            RemoveAllNewlines => 1,
            RemoveAllTabs     => 1,
        );
    }

    # check service name
    if ( $Param{Name} =~ m{ :: }xms ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Can't add service! Invalid Service name '$Param{Name}'!",
        );
        return;
    }

    # create full name
    $Param{FullName} = $Param{Name};

    # get parent name
    if ( $Param{ParentID} ) {
        my $ParentName = $Self->ServiceLookup(
            ServiceID => $Param{ParentID},
        );
        if ($ParentName) {
            $Param{FullName} = $ParentName . '::' . $Param{Name};
        }
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # find existing service
    $DBObject->Prepare(
        SQL   => 'SELECT id FROM service WHERE name = ?',
        Bind  => [ \$Param{FullName} ],
        Limit => 1,
    );

    my $Exists;
    while ( $DBObject->FetchrowArray() ) {
        $Exists = 1;
    }

    # add service to database
    if ($Exists) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "A service with the name and parent '$Param{FullName}' already exists.",
        );
        return;
    }

    return if !$DBObject->Do(
        SQL => 'INSERT INTO service '
            . '(name, valid_id, comments, create_time, create_by, change_time, change_by) '
            . 'VALUES (?, ?, ?, current_timestamp, ?, current_timestamp, ?)',
        Bind => [
            \$Param{FullName}, \$Param{ValidID}, \$Param{Comment},
            \$Param{UserID}, \$Param{UserID},
        ],
    );

    # get service id
    $DBObject->Prepare(
        SQL   => 'SELECT id FROM service WHERE name = ?',
        Bind  => [ \$Param{FullName} ],
        Limit => 1,
    );
    my $ServiceID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ServiceID = $Row[0];
    }

    # reset cache
    $Kernel::OM->Get('Kernel::System::Cache')->CleanUp(
        Type => $Self->{CacheType},
    );

    return $ServiceID;
}

=head2 ServiceUpdate()

update an existing service

    my $True = $ServiceObject->ServiceUpdate(
        ServiceID => 123,
        ParentID  => 1,           # (optional)
        Name      => 'Service Name',
        ValidID   => 1,
        Comment   => 'Comment',    # (optional)
        UserID    => 1,
    );

=cut

sub ServiceUpdate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(ServiceID Name ValidID UserID)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    # set default comment
    $Param{Comment} ||= '';

    # cleanup given params
    for my $Argument (qw(Name Comment)) {
        $Kernel::OM->Get('Kernel::System::CheckItem')->StringClean(
            StringRef         => \$Param{$Argument},
            RemoveAllNewlines => 1,
            RemoveAllTabs     => 1,
        );
    }

    # check service name
    if ( $Param{Name} =~ m{ :: }xms ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Can't update service! Invalid Service name '$Param{Name}'!",
        );
        return;
    }

    # get old name of service
    my $OldServiceName = $Self->ServiceLookup(
        ServiceID => $Param{ServiceID},
    );

    if ( !$OldServiceName ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Can't update service! Service '$Param{ServiceID}' does not exist.",
        );
        return;
    }

    # create full name
    $Param{FullName} = $Param{Name};

    # get parent name
    if ( $Param{ParentID} ) {

        # lookup service
        my $ParentName = $Self->ServiceLookup(
            ServiceID => $Param{ParentID},
        );

        if ($ParentName) {
            $Param{FullName} = $ParentName . '::' . $Param{Name};
        }

        # check, if selected parent was a child of this service
        if ( $Param{FullName} =~ m{ \A ( \Q$OldServiceName\E ) :: }xms ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => 'Can\'t update service! Invalid parent was selected.'
            );
            return;
        }
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # find exists service
    $DBObject->Prepare(
        SQL   => 'SELECT id FROM service WHERE name = ?',
        Bind  => [ \$Param{FullName} ],
        Limit => 1,
    );
    my $Exists;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        if ( $Param{ServiceID} ne $Row[0] ) {
            $Exists = 1;
        }
    }

    # update service
    if ($Exists) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "A service with the name and parent '$Param{FullName}' already exists.",
        );
        return;

    }

    # update service
    return if !$DBObject->Do(
        SQL => 'UPDATE service SET name = ?, valid_id = ?, comments = ?, '
            . ' change_time = current_timestamp, change_by = ? WHERE id = ?',
        Bind => [
            \$Param{FullName}, \$Param{ValidID}, \$Param{Comment},
            \$Param{UserID}, \$Param{ServiceID},
        ],
    );

    my $LikeService = $DBObject->Quote( $OldServiceName, 'Like' ) . '::%';

    # find all childs
    $DBObject->Prepare(
        SQL  => "SELECT id, name FROM service WHERE name LIKE ?",
        Bind => [ \$LikeService ],
    );

    my @Childs;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        my %Child;
        $Child{ServiceID} = $Row[0];
        $Child{Name}      = $Row[1];
        push @Childs, \%Child;
    }

    # update childs
    for my $Child (@Childs) {
        $Child->{Name} =~ s{ \A ( \Q$OldServiceName\E ) :: }{$Param{FullName}::}xms;
        $DBObject->Do(
            SQL  => 'UPDATE service SET name = ? WHERE id = ?',
            Bind => [ \$Child->{Name}, \$Child->{ServiceID} ],
        );
    }

    # reset cache
    $Kernel::OM->Get('Kernel::System::Cache')->CleanUp(
        Type => $Self->{CacheType},
    );

    return 1;
}

=head2 ServiceSearch()

return service ids as an array

    my @ServiceList = $ServiceObject->ServiceSearch(
        Name   => 'Service Name', # (optional)
        Limit  => 122,            # (optional) default 1000
        UserID => 1,
    );

=cut

sub ServiceSearch {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{UserID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need UserID!',
        );
        return;
    }

    # set default limit
    $Param{Limit} ||= 1000;

    # create sql query
    my $SQL
        = "SELECT id FROM service WHERE valid_id IN ( ${\(join ', ', $Kernel::OM->Get('Kernel::System::Valid')->ValidIDsGet())} )";
    my @Bind;

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    if ( $Param{Name} ) {

        # quote
        $Param{Name} = $DBObject->Quote( $Param{Name}, 'Like' );

        # replace * with % and clean the string
        $Param{Name} =~ s{ \*+ }{%}xmsg;
        $Param{Name} =~ s{ %+ }{%}xmsg;
        my $LikeString = '%' . $Param{Name} . '%';
        push @Bind, \$LikeString;

        $SQL .= " AND name LIKE ?";
    }

    $SQL .= ' ORDER BY name';

    # search service in db
    $DBObject->Prepare(
        SQL  => $SQL,
        Bind => \@Bind,
    );

    my @ServiceList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        push @ServiceList, $Row[0];
    }

    return @ServiceList;
}

=head2 CustomerUserServiceMemberList()

returns a list of customeruser/service members

    ServiceID: service id
    CustomerUserLogin: customer user login
    DefaultServices: activate or deactivate default services

    Result: HASH -> returns a hash of key => service id, value => service name
            Name -> returns an array of user names
            ID   -> returns an array of user ids

    Example (get services of customer user):

    $ServiceObject->CustomerUserServiceMemberList(
        CustomerUserLogin => 'Test',
        Result            => 'HASH',
        DefaultServices   => 0,
    );

    Example (get customer user of service):

    $ServiceObject->CustomerUserServiceMemberList(
        ServiceID => $ID,
        Result    => 'HASH',
    );

=cut

sub CustomerUserServiceMemberList {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{Result} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need Result!',
        );
        return;
    }

    # set default (only 1 or 0 is allowed to correctly set the cache key)
    if ( !defined $Param{DefaultServices} || $Param{DefaultServices} ) {
        $Param{DefaultServices} = 1;
    }
    else {
        $Param{DefaultServices} = 0;
    }

    # get options for default services for unknown customers
    my $DefaultServiceUnknownCustomer
        = $Kernel::OM->Get('Kernel::Config')->Get('Ticket::Service::Default::UnknownCustomer');
    if (
        $DefaultServiceUnknownCustomer
        && $Param{DefaultServices}
        && !$Param{ServiceID}
        && !$Param{CustomerUserLogin}
        )
    {
        $Param{CustomerUserLogin} = '<DEFAULT>';
    }

    # check more needed stuff
    if ( !$Param{ServiceID} && !$Param{CustomerUserLogin} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need ServiceID or CustomerUserLogin!',
        );
        return;
    }

    # create cache key
    my $CacheKey = 'CustomerUserServiceMemberList::' . $Param{Result} . '::'
        . 'DefaultServices::' . $Param{DefaultServices} . '::';
    if ( $Param{ServiceID} ) {
        $CacheKey .= 'ServiceID::' . $Param{ServiceID};
    }
    elsif ( $Param{CustomerUserLogin} ) {
        $CacheKey .= 'CustomerUserLogin::' . $Param{CustomerUserLogin};
    }

    # check cache
    my $Cache = $Kernel::OM->Get('Kernel::System::Cache')->Get(
        Type => $Self->{CacheType},
        Key  => $CacheKey,
    );
    if ( $Param{Result} eq 'HASH' ) {
        return %{$Cache} if ref $Cache eq 'HASH';
    }
    else {
        return @{$Cache} if ref $Cache eq 'ARRAY';
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # db quote
    for my $Key ( sort keys %Param ) {
        $Param{$Key} = $DBObject->Quote( $Param{$Key} );
    }
    for my $Key (qw(ServiceID)) {
        $Param{$Key} = $DBObject->Quote( $Param{$Key}, 'Integer' );
    }

    # sql
    my %Data;
    my @Data;
    my $SQL = 'SELECT scu.service_id, scu.customer_user_login, s.name '
        . ' FROM '
        . ' service_customer_user scu, service s'
        . ' WHERE '
        . " s.valid_id IN ( ${\(join ', ', $Kernel::OM->Get('Kernel::System::Valid')->ValidIDsGet())} ) AND "
        . ' s.id = scu.service_id AND ';

    if ( $Param{ServiceID} ) {
        $SQL .= " scu.service_id = $Param{ServiceID}";
    }
    elsif ( $Param{CustomerUserLogin} ) {
        $SQL .= " scu.customer_user_login = '$Param{CustomerUserLogin}'";
    }

    $DBObject->Prepare( SQL => $SQL );

    while ( my @Row = $DBObject->FetchrowArray() ) {

        my $Value = '';
        if ( $Param{ServiceID} ) {
            $Data{ $Row[1] } = $Row[0];
            $Value = $Row[0];
        }
        else {
            $Data{ $Row[0] } = $Row[2];
        }
    }
    if (
        $Param{CustomerUserLogin}
        && $Param{CustomerUserLogin} ne '<DEFAULT>'
        && $Param{DefaultServices}
        && !keys(%Data)
        )
    {
        %Data = $Self->CustomerUserServiceMemberList(
            CustomerUserLogin => '<DEFAULT>',
            Result            => 'HASH',
            DefaultServices   => 0,
        );
    }

    # return result
    if ( $Param{Result} eq 'HASH' ) {
        $Kernel::OM->Get('Kernel::System::Cache')->Set(
            Type  => $Self->{CacheType},
            TTL   => $Self->{CacheTTL},
            Key   => $CacheKey,
            Value => \%Data,
        );
        return %Data;
    }
    if ( $Param{Result} eq 'Name' ) {
        @Data = values %Data;
    }
    else {
        @Data = keys %Data;
    }
    $Kernel::OM->Get('Kernel::System::Cache')->Set(
        Type  => $Self->{CacheType},
        TTL   => $Self->{CacheTTL},
        Key   => $CacheKey,
        Value => \@Data,
    );
    return @Data;
}

=head2 CustomerUserServiceMemberAdd()

to add a member to a service

if 'Active' is 0, the customer is removed from the service

    $ServiceObject->CustomerUserServiceMemberAdd(
        CustomerUserLogin => 'Test1',
        ServiceID         => 6,
        Active            => 1,
        UserID            => 123,
    );

=cut

sub CustomerUserServiceMemberAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(CustomerUserLogin ServiceID UserID)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # delete existing relation
    return if !$DBObject->Do(
        SQL  => 'DELETE FROM service_customer_user WHERE customer_user_login = ? AND service_id = ?',
        Bind => [ \$Param{CustomerUserLogin}, \$Param{ServiceID} ],
    );

    # return if relation is not active
    if ( !$Param{Active} ) {
        $Kernel::OM->Get('Kernel::System::Cache')->CleanUp(
            Type => $Self->{CacheType},
        );
        return;
    }

    # insert new relation
    my $Success = $DBObject->Do(
        SQL => 'INSERT INTO service_customer_user '
            . '(customer_user_login, service_id, create_time, create_by) '
            . 'VALUES (?, ?, current_timestamp, ?)',
        Bind => [ \$Param{CustomerUserLogin}, \$Param{ServiceID}, \$Param{UserID} ]
    );

    $Kernel::OM->Get('Kernel::System::Cache')->CleanUp(
        Type => $Self->{CacheType},
    );

    return $Success;
}

=head2 ServicePreferencesSet()

set service preferences

    $ServiceObject->ServicePreferencesSet(
        ServiceID => 123,
        Key       => 'UserComment',
        Value     => 'some comment',
        UserID    => 123,
    );

=cut

sub ServicePreferencesSet {
    my ( $Self, %Param ) = @_;

    $Self->{PreferencesObject}->ServicePreferencesSet(%Param);

    $Kernel::OM->Get('Kernel::System::Cache')->CleanUp(
        Type => $Self->{CacheType},
    );
    return 1;
}

=head2 ServicePreferencesGet()

get service preferences

    my %Preferences = $ServiceObject->ServicePreferencesGet(
        ServiceID => 123,
        UserID    => 123,
    );

=cut

sub ServicePreferencesGet {
    my ( $Self, %Param ) = @_;

    return $Self->{PreferencesObject}->ServicePreferencesGet(%Param);
}

=head2 ServiceParentsGet()

return an ordered list all parent service IDs for the given service from the root parent to the
current service parent

    my $ServiceParentsList = $ServiceObject->ServiceParentsGet(
        ServiceID => 123,
        UserID    => 1,
    );

    returns

    $ServiceParentsList = [ 1, 2, ...];

=cut

sub ServiceParentsGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(UserID ServiceID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => 'Need $Needed!',
            );
            return;
        }
    }

    # read cache
    my $CacheKey = 'ServiceParentsGet::' . $Param{ServiceID};
    my $Cache    = $Kernel::OM->Get('Kernel::System::Cache')->Get(
        Type => $Self->{CacheType},
        Key  => $CacheKey,
    );
    return $Cache if ref $Cache;

    # get the list of services
    my $ServiceList = $Self->ServiceListGet(
        Valid  => 0,
        UserID => 1,
    );

    # get a service lookup table
    my %ServiceLookup;
    SERVICE:
    for my $ServiceData ( @{$ServiceList} ) {
        next SERVICE if !$ServiceData;
        next SERVICE if !IsHashRefWithData($ServiceData);
        next SERVICE if !$ServiceData->{ServiceID};

        $ServiceLookup{ $ServiceData->{ServiceID} } = $ServiceData;
    }

    # exit if ServiceID is invalid
    return if !$ServiceLookup{ $Param{ServiceID} };

    # to store the return structure
    my @ServiceParents;

    # get the ServiceParentID from the requested service
    my $ServiceParentID = $ServiceLookup{ $Param{ServiceID} }->{ParentID};

    # get all partents for the requested service
    while ($ServiceParentID) {

        # add service parent ID to the return structure
        push @ServiceParents, $ServiceParentID;

        # set next ServiceParentID (the parent of the current parent)
        $ServiceParentID = $ServiceLookup{$ServiceParentID}->{ParentID} || 0;

    }

    # reverse the return array to get the list ordered from old to young (in parent context)
    my @Data = reverse @ServiceParents;

    # set cache
    $Kernel::OM->Get('Kernel::System::Cache')->Set(
        Type  => $Self->{CacheType},
        TTL   => $Self->{CacheTTL},
        Key   => $CacheKey,
        Value => \@Data,
    );

    return \@Data;
}

=head2 GetAllCustomServices()

get all custom services of one user

    my @Services = $ServiceObject->GetAllCustomServices( UserID => 123 );

=cut

sub GetAllCustomServices {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{UserID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need UserID!',
        );
        return;
    }

    # check cache
    my $CacheKey = 'GetAllCustomServices::' . $Param{UserID};
    my $Cache    = $Kernel::OM->Get('Kernel::System::Cache')->Get(
        Type => $Self->{CacheType},
        Key  => $CacheKey,
    );

    return @{$Cache} if $Cache;

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # search all custom services
    return if !$DBObject->Prepare(
        SQL => '
            SELECT service_id
            FROM personal_services
            WHERE user_id = ?',
        Bind => [ \$Param{UserID} ],
    );

    # fetch the result
    my @ServiceIDs;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        push @ServiceIDs, $Row[0];
    }

    # set cache
    $Kernel::OM->Get('Kernel::System::Cache')->Set(
        Type  => $Self->{CacheType},
        TTL   => $Self->{CacheTTL},
        Key   => $CacheKey,
        Value => \@ServiceIDs,
    );

    return @ServiceIDs;
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
