# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::Type;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Cache',
    'Kernel::System::DB',
    'Kernel::System::Log',
    'Kernel::System::Valid',
);

=head1 NAME

Kernel::System::Type - type lib

=head1 DESCRIPTION

All type functions.

=head1 PUBLIC INTERFACE

=head2 new()

create an object

    my $TypeObject = $Kernel::OM->Get('Kernel::System::Type');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    $Self->{CacheType} = 'Type';
    $Self->{CacheTTL}  = 60 * 60 * 24 * 20;

    return $Self;
}

=head2 TypeAdd()

add a new ticket type

    my $ID = $TypeObject->TypeAdd(
        Name    => 'New Type',
        ValidID => 1,
        UserID  => 123,
    );

=cut

sub TypeAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Name ValidID UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    # check if a type with this name already exists
    if ( $Self->NameExistsCheck( Name => $Param{Name} ) ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "A type with the name '$Param{Name}' already exists.",
        );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Do(
        SQL => 'INSERT INTO ticket_type (name, valid_id, '
            . ' create_time, create_by, change_time, change_by)'
            . ' VALUES (?, ?, current_timestamp, ?, current_timestamp, ?)',
        Bind => [ \$Param{Name}, \$Param{ValidID}, \$Param{UserID}, \$Param{UserID} ],
    );

    # get new type id
    return if !$DBObject->Prepare(
        SQL   => 'SELECT id FROM ticket_type WHERE name = ?',
        Bind  => [ \$Param{Name} ],
        Limit => 1,
    );

    # fetch the result
    my $ID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ID = $Row[0];
    }
    return if !$ID;

    # reset cache
    $Kernel::OM->Get('Kernel::System::Cache')->CleanUp(
        Type => $Self->{CacheType},
    );

    return $ID;
}

=head2 TypeGet()

get types attributes

    my %Type = $TypeObject->TypeGet(
        ID => 123,
    );

    my %Type = $TypeObject->TypeGet(
        Name => 'default',
    );

Returns:

    Type = (
        ID                  => '123',
        Name                => 'Service Request',
        ValidID             => '1',
        CreateTime          => '2010-04-07 15:41:15',
        CreateBy            => '321',
        ChangeTime          => '2010-04-07 15:59:45',
        ChangeBy            => '223',
    );

=cut

sub TypeGet {
    my ( $Self, %Param ) = @_;

    # either ID or Name must be passed
    if ( !$Param{ID} && !$Param{Name} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need ID or Name!',
        );
        return;
    }

    # check that not both ID and Name are given
    if ( $Param{ID} && $Param{Name} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need either ID OR Name - not both!',
        );
        return;
    }

    # lookup the ID
    if ( $Param{Name} ) {
        $Param{ID} = $Self->TypeLookup(
            Type => $Param{Name},
        );
        if ( !$Param{ID} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "TypeID for Type '$Param{Name}' not found!",
            );
            return;
        }
    }

    # check cache
    my $CacheKey = 'TypeGet::ID::' . $Param{ID};
    my $Cache    = $Kernel::OM->Get('Kernel::System::Cache')->Get(
        Type => $Self->{CacheType},
        Key  => $CacheKey,
    );
    return %{$Cache} if $Cache;

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # ask the database
    return if !$DBObject->Prepare(
        SQL => 'SELECT id, name, valid_id, '
            . 'create_time, create_by, change_time, change_by '
            . 'FROM ticket_type WHERE id = ?',
        Bind => [ \$Param{ID} ],
    );

    # fetch the result
    my %Type;
    while ( my @Data = $DBObject->FetchrowArray() ) {
        $Type{ID}         = $Data[0];
        $Type{Name}       = $Data[1];
        $Type{ValidID}    = $Data[2];
        $Type{CreateTime} = $Data[3];
        $Type{CreateBy}   = $Data[4];
        $Type{ChangeTime} = $Data[5];
        $Type{ChangeBy}   = $Data[6];
    }

    # no data found
    if ( !%Type ) {
        my $Error = $Param{Name} ? "Type '$Param{Name}'" : "TypeID '$Param{ID}'";
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => $Error . " not found!",
        );
        return;
    }

    # set cache
    $Kernel::OM->Get('Kernel::System::Cache')->Set(
        Type  => $Self->{CacheType},
        TTL   => $Self->{CacheTTL},
        Key   => $CacheKey,
        Value => \%Type,
    );

    return %Type;
}

=head2 TypeUpdate()

update type attributes

    $TypeObject->TypeUpdate(
        ID      => 123,
        Name    => 'New Type',
        ValidID => 1,
        UserID  => 123,
    );

=cut

sub TypeUpdate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(ID Name ValidID UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    # check if a type with this name already exists
    if (
        $Self->NameExistsCheck(
            Name => $Param{Name},
            ID   => $Param{ID}
        )
        )
    {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "A type with the name '$Param{Name}' already exists.",
        );
        return;
    }

    my %Type = $Self->TypeGet(
        ID => $Param{ID},
    );

    # check if the type is set as a default ticket type
    if (
        $Kernel::OM->Get('Kernel::Config')->Get('Ticket::Type::Default') eq $Type{Name}
        && $Param{ValidID} != 1
        )
    {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "The ticket type is set as a default ticket type, so it cannot be set to invalid!"
        );
        return;
    }

    # sql
    return if !$Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL => 'UPDATE ticket_type SET name = ?, valid_id = ?, '
            . ' change_time = current_timestamp, change_by = ? WHERE id = ?',
        Bind => [
            \$Param{Name}, \$Param{ValidID}, \$Param{UserID}, \$Param{ID},
        ],
    );

    # reset cache
    $Kernel::OM->Get('Kernel::System::Cache')->CleanUp(
        Type => $Self->{CacheType},
    );

    return 1;
}

=head2 TypeList()

get type list

    my %List = $TypeObject->TypeList();

or

    my %List = $TypeObject->TypeList(
        Valid => 0,
    );

=cut

sub TypeList {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    my $Valid = 1;
    if ( !$Param{Valid} && defined $Param{Valid} ) {
        $Valid = 0;
    }

    # check cache
    my $CacheKey = "TypeList::Valid::$Valid";
    my $Cache    = $Kernel::OM->Get('Kernel::System::Cache')->Get(
        Type => $Self->{CacheType},
        Key  => $CacheKey,
    );
    return %{$Cache} if $Cache;

    # create the valid list
    my $ValidIDs = join ', ', $Kernel::OM->Get('Kernel::System::Valid')->ValidIDsGet();

    # build SQL
    my $SQL = 'SELECT id, name FROM ticket_type';

    # add WHERE statement
    if ($Valid) {
        $SQL .= ' WHERE valid_id IN (' . $ValidIDs . ')';
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # ask database
    return if !$DBObject->Prepare(
        SQL => $SQL,
    );

    # fetch the result
    my %TypeList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $TypeList{ $Row[0] } = $Row[1];
    }

    # set cache
    $Kernel::OM->Get('Kernel::System::Cache')->Set(
        Type  => $Self->{CacheType},
        TTL   => $Self->{CacheTTL},
        Key   => $CacheKey,
        Value => \%TypeList,
    );

    return %TypeList;
}

=head2 TypeLookup()

get id or name for a ticket type

    my $Type = $TypeObject->TypeLookup( TypeID => $TypeID );

    my $TypeID = $TypeObject->TypeLookup( Type => $Type );

=cut

sub TypeLookup {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{Type} && !$Param{TypeID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Got no Type or TypeID!',
        );
        return;
    }

    # get (already cached) type list
    my %TypeList = $Self->TypeList(
        Valid => 0,
    );

    my $Key;
    my $Value;
    my $ReturnData;
    if ( $Param{TypeID} ) {
        $Key        = 'TypeID';
        $Value      = $Param{TypeID};
        $ReturnData = $TypeList{ $Param{TypeID} };
    }
    else {
        $Key   = 'Type';
        $Value = $Param{Type};
        my %TypeListReverse = reverse %TypeList;
        $ReturnData = $TypeListReverse{ $Param{Type} };
    }

    # check if data exists
    if ( !defined $ReturnData ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "No $Key for $Value found!",
        );
        return;
    }

    return $ReturnData;
}

=head2 NameExistsCheck()

    return 1 if another type with this name already exits

        $Exist = $TypeObject->NameExistsCheck(
            Name => 'Some::Template',
            ID => 1, # optional
        );

=cut

sub NameExistsCheck {
    my ( $Self, %Param ) = @_;

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');
    return if !$DBObject->Prepare(
        SQL  => 'SELECT id FROM ticket_type WHERE name = ?',
        Bind => [ \$Param{Name} ],
    );

    # fetch the result
    my $Flag;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        if ( !$Param{ID} || $Param{ID} ne $Row[0] ) {
            $Flag = 1;
        }
    }
    if ($Flag) {
        return 1;
    }
    return 0;
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
