# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

# because of direct open() calls
## nofilter(TidyAll::Plugin::Znuny::Perl::PerlCritic)

package Kernel::System::DBCRUD;

use strict;
use warnings;
use utf8;

use Data::UUID;

use Kernel::System::VariableCheck qw(:all);

use Kernel::System::DB;

use parent qw(Kernel::System::EventHandler);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Cache',
    'Kernel::System::DateTime',
    'Kernel::System::DB',
    'Kernel::System::Encode',
    'Kernel::System::JSON',
    'Kernel::System::Log',
    'Kernel::System::XML',
    'Kernel::System::YAML',
    'Kernel::System::DBCRUD::Format',
);

=head1 NAME

Kernel::System::DBCRUD

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $DBCRUDObject = $Kernel::OM->Get('Kernel::System::DBCRUD');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');

    $Self->InitConfig(%Param);

    $Self->{UUIDDatabaseTableColumnName} = 'dbcrud_uuid';

    if ( $Self->{DatabaseConfigKey} ) {
        my %DBConfig = %{ $ConfigObject->Get( $Self->{DatabaseConfigKey} ) || {} };
        CONFIG:
        for my $Key (qw( DatabaseHost Database DatabaseUser DatabasePw DatabaseDSN )) {
            if ( $DBConfig{$Key} ) {
                $DBConfig{DatabaseDSN} =~ s{\Q##$Key##\E}{$DBConfig{$Key}}msig;
                next CONFIG;
            }

            $LogObject->Log(
                Priority => 'error',
                Message  => "Can not find value for key '" . $Key
                    . "' of database configuration (SysConfig: " . $Self->{DatabaseConfigKey} . " )",
            );
            return;
        }

        $Self->{DBObject} = Kernel::System::DB->new(%DBConfig);

        # set charset for database
        if ( $DBConfig{DatabaseCharset} && $DBConfig{DatabaseCharset} !~ m{utf-8}i ) {
            $Self->{SourceCharset} = $DBConfig{DatabaseCharset};
        }
    }
    else {
        $Self->{DBObject} = $Kernel::OM->Get('Kernel::System::DB');
    }

    if ( $Self->{DBObject}->{DSN} =~ m{:pg}i ) {

        # in case of integer columns - postgresql can not compare 'integer' column with a 'varchar' value
        # we use the suffix '::text' to cast / mark this column as text / varchar
        # this query ("id LIKE 'varchar') will never match, but it needs less resources to add this suffix
        # instead to check the column type and the value type and skip this QueryCondition
        $Self->{DBObject}->{SearchKeySuffix} = '::text';
    }

    # use SysConfig as fallback for data search values
    if ( !IsArrayRefWithData( $Self->{DataSearchValueFields} ) ) {
        $Self->{DataSearchValueFields} = $ConfigObject->Get( 'DBCRUD::Search::' . $Self->{Name} . '::Fields' ) || [];
    }

    if ( !$Self->{DBObject} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Can not connect to the database!",
        );
        return;
    }

    my $EventModulePost = $ConfigObject->Get( $Self->{Name} . '::EventModulePost' );

    if ( defined $EventModulePost ) {

        # init of event handler
        $Self->EventHandlerInit(
            Config => $Self->{Name} . '::EventModulePost',
        );

    }
    else {
        # init of event handler for general DBCRUD Events
        $Self->EventHandlerInit(
            Config => 'DBCRUD::EventModulePost',
        );
    }

    return $Self;
}

=head2 DataAdd()

To use this function you need a DB CRUD module like e.g. Kernel::System::UnitTest::DBCRUD.

Add data to table.

    my $Success = $DBCRUDObject->DataAdd(
        ID          => '...',
        '...',
        CreateTime  => '...', # optional
        ChangeTime  => '...', # optional
    );

Returns:

    my $Success = 1;

=cut

sub DataAdd {
    my ( $Self, %Param ) = @_;

    my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');
    my $JSONObject  = $Kernel::OM->Get('Kernel::System::JSON');
    my $LogObject   = $Kernel::OM->Get('Kernel::System::Log');

    if ( !$Self->{FunctionDataAdd} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Functionality DataAdd not supported!",
        );
        return;
    }
    if ( $Self->{UserIDCheck} && !$Param{UserID} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Need UserID!",
        );
        return;
    }

    my @Bind;
    my @InsertColumns;
    my @InsertValues;

    PARAM:
    for my $ColumnParam ( sort keys %{ $Self->{Columns} } ) {
        my $Column = $Self->{Columns}->{$ColumnParam};
        $Column->{Name} = $ColumnParam;

        if ( !$Param{$ColumnParam} && $Column->{AddRequired} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $ColumnParam!"
            );
            return;
        }

        if ( defined $Param{$ColumnParam} && $Column->{ContentJSON} ) {
            my $JSON = $JSONObject->Encode(
                Data => $Param{$ColumnParam},
            );
            $JSON = $Self->_ConvertTo($JSON);

            push @InsertColumns, $Column->{Column};
            push @InsertValues,  '?';
            push @Bind,          \$JSON;
        }
        elsif ( defined $Param{$ColumnParam} ) {
            $Param{$ColumnParam} = $Self->_ConvertTo( $Param{$ColumnParam} );

            push @InsertColumns, $Column->{Column};
            push @InsertValues,  '?';
            push @Bind,          \$Param{$ColumnParam};
        }
        elsif ( $Column->{TimeStampAdd} ) {
            push @InsertColumns, $Column->{Column};
            push @InsertValues,  'current_timestamp';
        }
    }

    return 1 if !@InsertColumns;

    # Automatically create missing UUID database table columns (if configured).
    if ( $Self->{AutoCreateMissingUUIDDatabaseTableColumns} ) {
        return if !$Self->CreateMissingUUIDDatabaseTableColumns();
    }

    # Generate a UUID to retrieve the ID of the created database record.
    my $UUIDObject = Data::UUID->new();
    my $UUID       = $UUIDObject->create();
    $UUID = lc $UUIDObject->to_string($UUID);

    push @InsertColumns, $Self->{UUIDDatabaseTableColumnName};
    push @InsertValues,  '?';
    push @Bind,          \$UUID;

    my $SQL = '
        INSERT INTO
            ' . $Self->{DatabaseTable} . '
                (' . join( ', ', @InsertColumns ) . ')
            VALUES
                (' . join( ', ', @InsertValues ) . ')';

    return if !$Self->{DBObject}->Do(
        SQL  => $SQL,
        Bind => \@Bind,
    );

    # Get ID of created database record.
    return if !$Self->{DBObject}->Prepare(
        SQL => 'SELECT '
            . $Self->{Columns}->{ $Self->{Identifier} }->{Column}
            . ' FROM '
            . $Self->{DatabaseTable}
            . ' WHERE ' . $Self->{UUIDDatabaseTableColumnName} . ' = ?',
        Bind => [
            \$UUID,
        ],
        Limit => 1,
    );

    # fetch the result
    my $ID;
    while ( my @Row = $Self->{DBObject}->FetchrowArray() ) {
        $ID = $Row[0];
    }
    return if !$ID;

    # reset cache
    $CacheObject->CleanUp(
        Type => $Self->{CacheType},
    );

    # create history if possible
    if ( !$Self->{PreventHistory} && $Self->can('HistoryEventDataAdd') ) {
        $Self->HistoryEventDataAdd(
            Event => 'DBCRUDAdd',
            Data  => {
                $Self->{Identifier} => $ID,
                OldData             => {},
            },
            UserID => $Param{UserID} || 1,
        );
    }

    $Self->EventHandler(
        ModuleName        => ref $Self,
        UseHistoryBackend => $Self->{HistoryBackendIsSet} ? 1 : 0,
        Event             => 'DBCRUDAdd',
        Data              => {
            $Self->{Identifier} => $ID,
        },
        UserID => $Param{UserID} || 1,
    );

    return $ID;
}

=head2 DataUpdate()

To use this function you need a DB CRUD module like e.g. Kernel::System::UnitTest::DBCRUD.

Update data attributes.

    my $Success = $DBCRUDObject->DataUpdate(
        ID => 1234,
        UserID => 1,
        # all other attributes are optional
    );

Returns:

    my $Success = 1; # 1|0

=cut

sub DataUpdate {
    my ( $Self, %Param ) = @_;

    my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');
    my $JSONObject  = $Kernel::OM->Get('Kernel::System::JSON');
    my $LogObject   = $Kernel::OM->Get('Kernel::System::Log');

    if ( !$Self->{FunctionDataUpdate} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Functionality DataUpdate not supported!",
        );
        return;
    }
    if ( $Self->{UserIDCheck} && !$Param{UserID} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Need UserID!",
        );
        return;
    }

    my %DataGet = $Self->DataGet(
        $Self->{Identifier} => $Param{ $Self->{Identifier} },
        UserID              => $Param{UserID},
    );
    if ( !%DataGet ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Entry with the Identifier '$Param{ $Self->{Identifier} }' does not exist!",
        );
        return;
    }

    my @UpdateColumns;
    my @Bind;

    PARAM:
    for my $ColumnParam ( sort keys %{ $Self->{Columns} } ) {
        my $Column = $Self->{Columns}->{$ColumnParam};
        $Column->{Name} = $ColumnParam;

        if ( !$Param{$ColumnParam} && $Column->{AddRequired} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $ColumnParam!"
            );
            return;
        }

        next PARAM if $ColumnParam eq $Self->{Identifier};

        if ( defined $Param{$ColumnParam} && $Column->{ContentJSON} ) {
            my $JSON = $JSONObject->Encode(
                Data => $Param{$ColumnParam},
            );
            $JSON = $Self->_ConvertTo($JSON);

            push @UpdateColumns, $Column->{Column} . ' = ?';
            push @Bind,          \$JSON;
        }
        elsif ( defined $Param{$ColumnParam} ) {
            $Param{$ColumnParam} = $Self->_ConvertTo( $Param{$ColumnParam} );

            push @UpdateColumns, $Column->{Column} . ' = ?';
            push @Bind,          \$Param{$ColumnParam};
        }
        elsif ( exists $Param{$ColumnParam} ) {
            push @UpdateColumns, $Column->{Column} . ' = NULL';
        }
        elsif ( $Column->{TimeStampUpdate} ) {
            push @UpdateColumns, $Column->{Column} . ' = current_timestamp';
        }
    }

    push @Bind, \$Param{ $Self->{Identifier} };

    return 1 if !@UpdateColumns;

    my $SQL = 'UPDATE '
        . $Self->{DatabaseTable} . ' SET '
        . join( ', ', @UpdateColumns )
        . ' WHERE '
        . $Self->{Columns}->{ $Self->{Identifier} }->{Column} . ' = ?';

    return if !$Self->{DBObject}->Do(
        SQL  => $SQL,
        Bind => \@Bind,
    );

    $CacheObject->CleanUp(
        Type => $Self->{CacheType},
    );

    # create history if possible
    if ( !$Self->{PreventHistory} && $Self->can('HistoryEventDataAdd') ) {
        $Self->HistoryEventDataAdd(
            Event => $Self->{Name} . 'Update',
            Data  => {
                $Self->{Identifier} => $Param{ $Self->{Identifier} },
                OldData             => \%DataGet,
            },
            UserID => $Param{UserID} || 1,
        );
    }

    $Self->EventHandler(
        ModuleName        => ref $Self,
        UseHistoryBackend => $Self->{HistoryBackendIsSet} ? 1 : 0,
        Event             => 'DBCRUDUpdate',
        Data              => {
            $Self->{Identifier} => $Param{ $Self->{Identifier} },
            OldData             => \%DataGet,
        },
        UserID => $Param{UserID} || 1,
    );

    return 1;
}

sub DataProcedureAdd {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    if ( !$Self->{FunctionDataProcedureAdd} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Functionality DataProcedureAdd not supported!",
        );
        return;
    }
    if ( $Self->{UserIDCheck} && !$Param{UserID} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Need UserID!",
        );
        return;
    }

    my @Bind;
    my @DBGet = @{ $Self->{ProcedureAddOutput} };
    my @Where;

    # if the debug flag is set then we will
    # return all output columns with the value "1" as result
    return ( map { $_ => 1 } @DBGet ) if $Param{Debug};

    PARAM:
    for my $ColumnParam ( sort keys %{ $Self->{Columns} } ) {
        my $Column = $Self->{Columns}->{$ColumnParam};
        $Column->{Name} = $ColumnParam;

        if ( !$Param{$ColumnParam} && $Column->{ProcedureAddRequired} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $ColumnParam!"
            );
            return;
        }

        next PARAM if !defined $Param{$ColumnParam};

        $Param{$ColumnParam} = $Self->_ConvertTo( $Param{$ColumnParam} );

        # did not use bind for this because of bug
        # https://support.microsoft.com/en-us/kb/269011
        push @Where, '@' . $Column->{Column} . " =  '" . $Self->{DBObject}->Quote( $Param{$ColumnParam} ) . "'";
    }
    PARAM:
    for my $ColumnParam (@DBGet) {
        my $Column = $Self->{Columns}->{$ColumnParam};
        $Column->{Name} = $ColumnParam;

        # did not use bind for this because of bug
        # https://support.microsoft.com/en-us/kb/269011
        push @Where, '@' . $Column->{Column} . " =  ''";
    }

    # currently only MSSQL support
    my $SQL = 'EXEC ' . $Self->{DatabaseTable};

    if (@Where) {
        $SQL .= ' ' . join( ', ', @Where );
    }

    return if !$Self->{DBObject}->Prepare(
        SQL => $SQL,
    );

    my %Entry;
    while ( my @Data = $Self->{DBObject}->FetchrowArray() ) {
        for my $Index ( 0 .. $#DBGet ) {
            $Entry{ $DBGet[$Index] } = $Data[$Index] || '';
        }
    }

    return if !%Entry;

    $Self->EventHandler(
        ModuleName        => ref $Self,
        UseHistoryBackend => $Self->{HistoryBackendIsSet} ? 1 : 0,
        Event             => 'DBCRUDProcedureAdd',
        Data              => \%Entry,
        UserID            => $Param{UserID} || 1,
    );

    return %Entry;
}

=head2 DataGet()

To use this function you need a DB CRUD module like e.g. Kernel::System::UnitTest::DBCRUD.

Get data attributes.

    my %Data = $DBCRUDObject->DataGet(
        ID          => '...', # optional
        CreateTime  => '...', # optional
        ChangeTime  => '...', # optional
    );

Returns:

    my %Data = (
        ID          => '...',
        CreateTime  => '...',
        ChangeTime  => '...',
    );

=cut

sub DataGet {
    my ( $Self, %Param ) = @_;

    my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');
    my $JSONObject  = $Kernel::OM->Get('Kernel::System::JSON');
    my $LogObject   = $Kernel::OM->Get('Kernel::System::Log');

    if ( !$Self->{FunctionDataGet} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Functionality DataGet not supported!",
        );
        return;
    }
    if ( $Self->{UserIDCheck} && !$Param{UserID} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Need UserID!",
        );
        return;
    }

    my @Bind;
    my @Cache;
    my @DBGet;
    my @Select;
    my @Where;

    PARAM:
    for my $ColumnParam ( sort keys %{ $Self->{Columns} } ) {
        my $Column = $Self->{Columns}->{$ColumnParam};
        $Column->{Name} = $ColumnParam;

        if ( !$Param{$ColumnParam} && $Column->{GetRequired} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $ColumnParam!"
            );
            return;
        }

        push @Select, $Column->{Column};
        push @DBGet,  $ColumnParam;

        if ( $Column->{TimeStamp} || $Column->{TimeStampAdd} || $Column->{TimeStampUpdate} ) {
            my %Result = $Self->_WhereTimeStamp(
                Param  => \%Param,
                Column => $Column,
            );

            if ( $Result{Bind} && $Result{Where} ) {
                push @Cache, @{ $Result{Cache} };
                push @Bind,  @{ $Result{Bind} };
                push @Where, @{ $Result{Where} };
            }
        }

        next PARAM if !exists $Param{$ColumnParam};

        # in case of oracle we need a way to disable columns for
        # where conditions (for longblobs)
        # ORA-00932: inconsistent datatypes: expected - got CLOB
        if ( $Column->{DisableWhere} ) {
            $LogObject->Log(
                Priority => 'error',
                Message =>
                    "Do not use $ColumnParam for where conditions ('DisabledWhere' is set)! It should get excluded. Typical reason could be to prevent longblob columns in where conditions in case of an oracle system.",
            );
            return;
        }

        if ( IsArrayRefWithData( $Param{$ColumnParam} ) ) {
            push @Cache, $Column->{Column} . '::' . join( ', ', @{ $Param{$ColumnParam} } );

            my @InValues;
            for my $Value ( @{ $Param{$ColumnParam} } ) {
                $Value = $Self->_ConvertTo($Value);

                push @InValues, "'" . $Self->{DBObject}->Quote($Value) . "'";
            }

            push @Where, $Column->{Column} . " IN (" . join( ', ', @InValues ) . ")";
        }
        elsif ( defined $Param{$ColumnParam} ) {
            $Param{$ColumnParam} = $Self->_ConvertTo( $Param{$ColumnParam} );

            push @Bind,  \$Param{$ColumnParam};
            push @Cache, $Column->{Column} . '::' . $Param{$ColumnParam};
            push @Where, $Column->{Column} . ' = ?';
        }
        elsif ( exists $Param{$ColumnParam} ) {
            push @Cache, $Column->{Column} . '::NULL';
            push @Where, $Column->{Column} . ' IS NULL';
        }
    }

    my $CacheKeysSort = $Self->_CacheKeysSortGet(%Param);
    @Cache = ( @Cache, @{$CacheKeysSort} );

    my $CacheKey = $Self->{DatabaseTable} . '::DataGet::' . join( '::', @Cache );
    my $Cache    = $CacheObject->Get(
        Type => $Self->{CacheType},
        Key  => $CacheKey,
    );

    #     return %{$Cache} if $Cache;

    my $SQL = '
        SELECT
            ' . join( ', ', @Select ) . '
        FROM
            ' . $Self->{DatabaseTable};

    if (@Where) {
        $SQL .= ' WHERE ' . join( ' AND ', @Where );
    }

    $SQL .= $Self->_SQLSortPrepare(%Param);

    return if !$Self->{DBObject}->Prepare(
        SQL   => $SQL,
        Bind  => \@Bind,
        Limit => 1,
    );

    my %Entry;
    while ( my @Data = $Self->{DBObject}->FetchrowArray() ) {
        COLUMN:
        for my $Index ( 0 .. $#DBGet ) {
            $Entry{ $DBGet[$Index] } = $Self->_ConvertFrom( $Data[$Index] );
            $Entry{ $DBGet[$Index] } = $Self->_ContentValueGet(
                Value  => $Entry{ $DBGet[$Index] },
                Config => $Self->{Columns}->{ $DBGet[$Index] },
            );
        }
    }

    return if !%Entry;

    $CacheObject->Set(
        Type  => $Self->{CacheType},
        TTL   => $Self->{CacheTTL},
        Key   => $CacheKey,
        Value => \%Entry,
    );

    $Self->EventHandler(
        ModuleName        => ref $Self,
        UseHistoryBackend => $Self->{HistoryBackendIsSet} ? 1 : 0,
        Event             => 'DBCRUDGet',
        Data              => \%Entry,
        UserID            => $Param{UserID} || 1,
    );

    return %Entry;
}

=head2 DataListGet()

To use this function you need a DB CRUD module like e.g. Kernel::System::UnitTest::DBCRUD.

Get list data with attributes.

    my @Data = $DBCRUDObject->DataListGet(
        ID          => '...', # optional
        CreateTime  => '...', # optional
        ChangeTime  => '...', # optional
    );

Returns:

    my @Data = (
        {
            ID          => '...',
            CreateTime  => '...',
            ChangeTime  => '...',
        },
        ...
    );

=cut

sub DataListGet {
    my ( $Self, %Param ) = @_;

    my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');
    my $JSONObject  = $Kernel::OM->Get('Kernel::System::JSON');
    my $LogObject   = $Kernel::OM->Get('Kernel::System::Log');

    if ( !$Self->{FunctionDataListGet} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Functionality DataListGet not supported!",
        );
        return;
    }
    if ( $Self->{UserIDCheck} && !$Param{UserID} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Need UserID!",
        );
        return;
    }

    my @Bind;
    my @Cache;
    my @DBGet;
    my @Select;
    my @Where;

    my $Limit = $Param{Limit} || 0;
    $Param{Cache} //= 1;

    PARAM:
    for my $ColumnParam ( sort keys %{ $Self->{Columns} } ) {
        my $Column = $Self->{Columns}->{$ColumnParam};
        $Column->{Name} = $ColumnParam;

        if ( !$Param{$ColumnParam} && $Column->{ListGetRequired} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $ColumnParam!"
            );
            return;
        }

        push @Select, $Column->{Column};
        push @DBGet,  $ColumnParam;

        if ( $Column->{TimeStamp} || $Column->{TimeStampAdd} || $Column->{TimeStampUpdate} ) {
            my %Result = $Self->_WhereTimeStamp(
                Param  => \%Param,
                Column => $Column,
            );

            if ( $Result{Bind} && $Result{Where} ) {
                push @Cache, @{ $Result{Cache} };
                push @Bind,  @{ $Result{Bind} };
                push @Where, @{ $Result{Where} };
            }
        }

        next PARAM if !exists $Param{$ColumnParam};

        # in case of oracle we need a way to disable columns for
        # where conditions (for longblobs)
        # ORA-00932: inconsistent datatypes: expected - got CLOB
        if ( $Column->{DisableWhere} ) {
            $LogObject->Log(
                Priority => 'error',
                Message =>
                    "Do not use $ColumnParam for where conditions ('DisabledWhere' is set)! It should get excluded. Typical reason could be to prevent longblob columns in where conditions in case of an oracle system.",
            );
            return;
        }

        if ( IsArrayRefWithData( $Param{$ColumnParam} ) ) {
            push @Cache, $Column->{Column} . '::' . join( ', ', @{ $Param{$ColumnParam} } );

            my @InValues;
            for my $Value ( @{ $Param{$ColumnParam} } ) {
                $Value = $Self->_ConvertTo($Value);

                push @InValues, "'" . $Self->{DBObject}->Quote($Value) . "'";
            }

            push @Where, $Column->{Column} . " IN (" . join( ', ', @InValues ) . ")";
        }
        elsif ( defined $Param{$ColumnParam} ) {
            $Param{$ColumnParam} = $Self->_ConvertTo( $Param{$ColumnParam} );

            push @Bind,  \$Param{$ColumnParam};
            push @Cache, $Column->{Column} . '::' . $Param{$ColumnParam};
            push @Where, $Column->{Column} . ' = ?';
        }
        elsif ( exists $Param{$ColumnParam} ) {
            $Param{$ColumnParam} = $Self->_ConvertTo( $Param{$ColumnParam} );

            push @Cache, $Column->{Column} . '::NULL';
            push @Where, $Column->{Column} . ' IS NULL';
        }
    }

    my $CacheKeysSort = $Self->_CacheKeysSortGet(%Param);
    @Cache = ( @Cache, @{$CacheKeysSort} );

    my $CacheKey = $Self->{DatabaseTable} . '::DataListGet::' . $Limit . '::' . join( '::', @Cache );
    my $Cache    = $CacheObject->Get(
        Type => $Self->{CacheType},
        Key  => $CacheKey,
    );
    return @{$Cache} if $Cache && $Param{Cache};

    my $SQL = '
        SELECT
            ' . join( ', ', @Select ) . '
        FROM
            ' . $Self->{DatabaseTable};

    if (@Where) {
        $SQL .= ' WHERE ' . join( ' AND ', @Where );
    }

    $SQL .= $Self->_SQLSortPrepare(%Param);

    return if !$Self->{DBObject}->Prepare(
        SQL   => $SQL,
        Bind  => \@Bind,
        Limit => $Limit || 1_000_000,
    );

    my @List;
    while ( my @Data = $Self->{DBObject}->FetchrowArray() ) {

        my %Entry;
        COLUMN:
        for my $Index ( 0 .. $#DBGet ) {
            $Entry{ $DBGet[$Index] } = $Self->_ConvertFrom( $Data[$Index] );
            $Entry{ $DBGet[$Index] } = $Self->_ContentValueGet(
                Value  => $Entry{ $DBGet[$Index] },
                Config => $Self->{Columns}->{ $DBGet[$Index] },
            );
        }

        push @List, \%Entry;
    }

    return if !@List;

    if ( $Param{Cache} ) {
        $CacheObject->Set(
            Type  => $Self->{CacheType},
            TTL   => $Self->{CacheTTL},
            Key   => $CacheKey,
            Value => \@List,
        );
    }

    $Self->EventHandler(
        ModuleName        => ref $Self,
        UseHistoryBackend => $Self->{HistoryBackendIsSet} ? 1 : 0,
        Event             => 'DBCRUDListGet',
        Data              => \@List,
        UserID            => $Param{UserID} || 1,
    );

    return @List;
}

=head2 DataSearch()

To use this function you need a DB CRUD module like e.g. Kernel::System::UnitTest::DBCRUD.

Search for value in defined attributes.

    my %Data = $DBCRUDObject->DataSearch(
        Search      => 'test*test',
        ID          => '...', # optional
        CreateTime  => '...', # optional
        ChangeTime  => '...', # optional
    );

Returns:

    my %Data = (
        '1' => {
            ID          => '...',
            CreateTime  => '...',
            ChangeTime  => '...',
        },
        ...
    );

=cut

sub DataSearch {
    my ( $Self, %Param ) = @_;

    my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');
    my $LogObject   = $Kernel::OM->Get('Kernel::System::Log');

    if ( !$Self->{FunctionDataSearch} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Functionality DataSearch not supported!",
        );
        return;
    }
    if ( $Self->{UserIDCheck} && !$Param{UserID} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Need UserID!",
        );
        return;
    }

    my @Bind;
    my @Cache;
    my @DBGet;
    my @Select;
    my @Where;
    my @SearchFields;
    my $SearchKeySuffix = $Self->{DBObject}->{'SearchKeySuffix'} || '';

    my $Search = $Param{Search};
    my $Limit  = $Param{Limit} || 0;
    my $Result = 'HASH';
    if ( defined $Param{Result} && $Param{Result} eq 'ARRAY' ) {
        $Result = $Param{Result};
    }

    return if !$Search;

    PARAM:
    for my $ColumnParam ( sort keys %{ $Self->{Columns} } ) {
        my $Column = $Self->{Columns}->{$ColumnParam};
        $Column->{Name} = $ColumnParam;

        push @Select, $Column->{Column};
        push @DBGet,  $ColumnParam;

        if ( $Column->{SearchTarget} ) {
            push @SearchFields, $Column->{Column} . $SearchKeySuffix;
        }

        if ( $Column->{TimeStamp} || $Column->{TimeStampAdd} || $Column->{TimeStampUpdate} ) {

            my %Result = $Self->_WhereTimeStamp(
                Param  => \%Param,
                Column => $Column,
            );

            if ( $Result{Bind} && $Result{Where} ) {
                push @Cache, @{ $Result{Cache} };
                push @Bind,  @{ $Result{Bind} };
                push @Where, @{ $Result{Where} };
            }
        }

        next PARAM if !exists $Param{$ColumnParam};

        # in case of oracle we need a way to disable columns for
        # where conditions (for longblobs)
        # ORA-00932: inconsistent datatypes: expected - got CLOB
        if ( $Column->{DisableWhere} ) {
            $LogObject->Log(
                Priority => 'error',
                Message =>
                    "Do not use $ColumnParam for where conditions ('DisabledWhere' is set)! It should get excluded. Typical reason could be to prevent longblob columns in where conditions in case of an oracle system.",
            );
            return;
        }

        if ( IsArrayRefWithData( $Param{$ColumnParam} ) ) {
            push @Cache, $Column->{Column} . '::' . join( ', ', @{ $Param{$ColumnParam} } );

            my @InValues;
            for my $Value ( @{ $Param{$ColumnParam} } ) {
                $Value = $Self->_ConvertTo($Value);

                push @InValues, "'" . $Self->{DBObject}->Quote($Value) . "'";
            }

            push @Where, $Column->{Column} . " IN (" . join( ', ', @InValues ) . ")";
        }
        elsif ( defined $Param{$ColumnParam} ) {
            $Param{$ColumnParam} = $Self->_ConvertTo( $Param{$ColumnParam} );

            push @Bind,  \$Param{$ColumnParam};
            push @Cache, $Column->{Column} . '::' . $Param{$ColumnParam};
            push @Where, $Column->{Column} . ' = ?';
        }
        elsif ( exists $Param{$ColumnParam} ) {
            push @Cache, $Column->{Column} . '::NULL';
            push @Where, $Column->{Column} . ' IS NULL';
        }
    }

    my %QueryCondition = $Self->{DBObject}->QueryCondition(
        Key           => \@SearchFields,
        Value         => $Search,
        SearchPrefix  => '*',
        SearchSuffix  => '*',
        CaseSensitive => $Self->{DBObject}->{'DB::CaseSensitive'},
        BindMode      => 1,
    );

    push @Bind,  @{ $QueryCondition{Values} };
    push @Cache, 'Search::' . join( '::', map { ${$_} } @{ $QueryCondition{Values} } );
    push @Where, $Self->_ConvertTo( $QueryCondition{SQL} );

    my $CacheKeysSort = $Self->_CacheKeysSortGet(%Param);
    @Cache = ( @Cache, @{$CacheKeysSort} );

    my $CacheKey = $Self->{DatabaseTable} . '::DataListGet::' . $Limit . '::' . join( '::', @Cache );
    my $Cache    = $CacheObject->Get(
        Type => $Self->{CacheType},
        Key  => $CacheKey,
    );
    return ( $Result eq 'ARRAY' ? @{$Cache} : %{$Cache} ) if $Cache;

    my $SQL = '
        SELECT
            ' . join( ', ', @Select ) . '
        FROM
            ' . $Self->{DatabaseTable};

    if (@Where) {
        $SQL .= ' WHERE ' . join( ' AND ', @Where );
    }

    $SQL .= $Self->_SQLSortPrepare(%Param);

    return if !$Self->{DBObject}->Prepare(
        SQL   => $SQL,
        Bind  => \@Bind,
        Limit => $Limit || 1_000_000,
    );

    my %List;
    my @List;
    while ( my @Data = $Self->{DBObject}->FetchrowArray() ) {

        my $IdentifierIndex;

        my %Entry;
        for my $Index ( 0 .. $#DBGet ) {
            $Entry{ $DBGet[$Index] } = $Self->_ConvertFrom( $Data[$Index] );
            $Entry{ $DBGet[$Index] } = $Self->_ContentValueGet(
                Value  => $Entry{ $DBGet[$Index] },
                Config => $Self->{Columns}->{ $DBGet[$Index] },
            );
        }

        if ( $Result eq 'ARRAY' ) {
            push @List, \%Entry;
        }
        else {
            $List{ $Entry{ $Self->{Identifier} } } = \%Entry;
        }
    }

    return if !%List && !@List;

    $CacheObject->Set(
        Type  => $Self->{CacheType},
        TTL   => $Self->{CacheTTL},
        Key   => $CacheKey,
        Value => ( $Result eq 'ARRAY' ? \@List : \%List ),
    );

    $Self->EventHandler(
        ModuleName        => ref $Self,
        UseHistoryBackend => $Self->{HistoryBackendIsSet} ? 1 : 0,
        Event             => 'DBCRUDSearch',
        Data              => {
            ID => $Result eq 'ARRAY' ? \@List : \%List,
        },
        UserID => $Param{UserID} || 1,
    );

    return $Result eq 'ARRAY' ? @List : %List;
}

=head2 DataDelete()

To use this function you need a DB CRUD module like e.g. Kernel::System::UnitTest::DBCRUD.

Remove data from table.

    my $Success = $DBCRUDObject->DataDelete(
        ID          => '...', # optional
        CreateTime  => '...', # optional
        ChangeTime  => '...', # optional
    );

Returns:

    my $Success = 1;

=cut

sub DataDelete {
    my ( $Self, %Param ) = @_;

    my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');
    my $LogObject   = $Kernel::OM->Get('Kernel::System::Log');

    if ( !$Self->{FunctionDataDelete} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Functionality DataDelete not supported!",
        );
        return;
    }
    if ( $Self->{UserIDCheck} && !$Param{UserID} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Need UserID!",
        );
        return;
    }

    my @Bind;
    my @Cache;
    my @Where;

    my $Limit = $Param{Limit} || 1_000_000;

    PARAM:
    for my $ColumnParam ( sort keys %{ $Self->{Columns} } ) {
        my $Column = $Self->{Columns}->{$ColumnParam};
        $Column->{Name} = $ColumnParam;

        if ( !$Param{$ColumnParam} && $Column->{ListGetRequired} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $ColumnParam!"
            );
            return;
        }

        if ( $Column->{TimeStamp} || $Column->{TimeStampAdd} || $Column->{TimeStampUpdate} ) {
            my %Result = $Self->_WhereTimeStamp(
                Param  => \%Param,
                Column => $Column,
            );

            if ( $Result{Bind} && $Result{Where} ) {
                push @Cache, @{ $Result{Cache} };
                push @Bind,  @{ $Result{Bind} };
                push @Where, @{ $Result{Where} };
            }
        }

        next PARAM if !exists $Param{$ColumnParam};

        # in case of oracle we need a way to disable columns for
        # where conditions (for longblobs)
        # ORA-00932: inconsistent datatypes: expected - got CLOB
        if ( $Column->{DisableWhere} ) {
            $LogObject->Log(
                Priority => 'error',
                Message =>
                    "Do not use $ColumnParam for where conditions ('DisabledWhere' is set)! It should get excluded. Typical reason could be to prevent longblob columns in where conditions in case of an oracle system.",
            );
            return;
        }

        if ( IsArrayRefWithData( $Param{$ColumnParam} ) ) {
            push @Cache, $Column->{Column} . '::' . join( ', ', @{ $Param{$ColumnParam} } );

            my @InValues;
            for my $Value ( @{ $Param{$ColumnParam} } ) {
                $Value = $Self->_ConvertTo($Value);

                push @InValues, "'" . $Self->{DBObject}->Quote($Value) . "'";
            }

            push @Where, $Column->{Column} . " IN (" . join( ', ', @InValues ) . ")";
        }
        elsif ( defined $Param{$ColumnParam} ) {
            $Param{$ColumnParam} = $Self->_ConvertTo( $Param{$ColumnParam} );

            push @Bind,  \$Param{$ColumnParam};
            push @Cache, $Column->{Column} . '::' . $Param{$ColumnParam};
            push @Where, $Column->{Column} . ' = ?';
        }
        elsif ( exists $Param{$ColumnParam} ) {
            push @Cache, $Column->{Column} . '::NULL';
            push @Where, $Column->{Column} . ' IS NULL';
        }
    }

    my @HistoryRemoveIDs;
    if ( !$Self->{PreventHistory} && $Self->can('HistoryEventDataDelete') ) {
        my $SQL = 'SELECT ' . $Self->{Columns}->{ $Self->{Identifier} }->{Column} . ' FROM ' . $Self->{DatabaseTable};

        if (@Where) {
            $SQL .= ' WHERE ' . join( ' AND ', @Where );
        }

        return if !$Self->{DBObject}->Prepare(
            SQL   => $SQL,
            Bind  => \@Bind,
            Limit => 1_000_000,
        );

        while ( my @Row = $Self->{DBObject}->FetchrowArray() ) {
            push @HistoryRemoveIDs, $Row[0];
        }
    }

    # special case for postgres:
    # postgres can not handle the limit parameter for the DELETE statement
    # so we find the rows which we want to delete and delete them by id
    # instead of the where limit clause
    if ( $Self->{DBObject}->{'DB::Type'} eq 'postgresql' && $Limit ) {
        my @Result = $Self->DataListGet(%Param);

        my @DeleteIDs;
        for my $Entry (@Result) {
            push @DeleteIDs, $Entry->{ $Self->{Identifier} };
        }

        if ( !@DeleteIDs ) {

            # trigger event
            $Self->EventHandler(
                ModuleName        => ref $Self,
                UseHistoryBackend => $Self->{HistoryBackendIsSet} ? 1 : 0,
                Event             => 'DBCRUDDelete',
                Data              => \%Param,
                UserID            => $Param{UserID} || 1,
            );

            return 1;
        }

        @Where = ();
        push @Where, $Self->{Columns}->{ $Self->{Identifier} }->{Column} . " IN (" . join( ', ', @DeleteIDs ) . ")";

        undef @Bind;
        undef $Limit;
    }

    my $SQL = 'DELETE FROM ' . $Self->{DatabaseTable};

    if (@Where) {
        $SQL .= ' WHERE ' . join( ' AND ', @Where );
    }

    return if !$Self->{DBObject}->Prepare(
        SQL   => $SQL,
        Bind  => \@Bind,
        Limit => $Limit,
    );

    $CacheObject->CleanUp(
        Type => $Self->{CacheType},
    );

    # create history if possible
    if ( !$Self->{PreventHistory} && $Self->can('HistoryEventDataDelete') ) {
        for my $ID (@HistoryRemoveIDs) {
            $Self->HistoryEventDataDelete(
                Event => $Self->{Name} . 'Delete',
                Data  => {
                    $Self->{Identifier} => $ID,
                },
                UserID => $Param{UserID} || 1,
            );
        }
    }

    $Self->EventHandler(
        ModuleName        => ref $Self,
        UseHistoryBackend => $Self->{HistoryBackendIsSet} ? 1 : 0,
        Event             => 'DBCRUDDelete',
        Data              => \%Param,
        UserID            => $Param{UserID} || 1,
    );

    return 1;
}

=head2 DataExport()

To use this function you need a DB CRUD module like e.g. Kernel::System::UnitTest::DBCRUD.

Exports data.

    my $Export = $DBCRUDObject->DataExport(
        Format => 'yml',
        Cache  => 0,
        Filter => {
            Source => '...'
        }
    );

Returns:

    my $Export = 'STRING';

=cut

sub DataExport {
    my ( $Self, %Param ) = @_;

    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');
    my $YAMLObject   = $Kernel::OM->Get('Kernel::System::YAML');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    my $FormatObject = $Kernel::OM->Create(
        'Kernel::System::DBCRUD::Format',
        ObjectParams => {
            ObjectName => $Self->{Name},
        },
    );

    if ( !$Self->{FunctionDataExport} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Functionality DataExport not supported!",
        );
        return;
    }
    my $ExportConfig = $ConfigObject->Get('DBCRUD')->{Export} || {};
    my $CustomConfig = $ConfigObject->Get( $Self->{Name} )    || {};
    $CustomConfig = $CustomConfig->{Export} || {};

    $Param{Format} = lc( $Param{Format} || $CustomConfig->{DefaultFormat} || $ExportConfig->{DefaultFormat} );
    my @PossibleFormats = ( 'yml', 'csv', 'excel', 'xlsx' );
    if ( !grep {/$Param{Format}/} @PossibleFormats ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Invalid value '$Param{Format}' for parameter Format. Format currently not supported.",
        );
        return;
    }

    # rebuild Columns to export only attributes with Export => 1,
    my %ColumnsExport;
    my $ColumnsBackUp = $Self->{Columns};

    COLUMN:
    for my $Column ( sort keys %{ $Self->{Columns} } ) {
        next COLUMN if !$Self->{Columns}->{$Column}->{Export} && $Column ne $Self->{Identifier};
        next COLUMN
            if $Self->{Columns}->{$Column}->{Export}
            && $Self->{Columns}->{$Column}->{Export} < 1
            && $Column ne $Self->{Identifier};
        $ColumnsExport{$Column} = $Self->{Columns}->{$Column};
    }

    my %ColumnsExportOrder = map { $_ => $Self->{Columns}->{$_}->{Export} }
        grep { $Self->{Columns}->{$_}->{Export} } sort keys %{ $Self->{Columns} };
    @{ $Param{ColumnsOrder} }
        = map {$_} sort { $ColumnsExportOrder{$a} cmp $ColumnsExportOrder{$b} } keys %ColumnsExportOrder;

    # if no ColumnsOrder exists
    # than no explicit ColumnsExport exist
    # in this case export all columns
    if ( IsArrayRefWithData( $Param{ColumnsOrder} ) ) {
        $Self->{Columns} = \%ColumnsExport;
    }

    my @Export = $Self->DataListGet(
        UserID => 1,
        Cache  => 0,
        %Param,
        %{ $Param{Filter} },
    );

    # set original Columns
    $Self->{Columns} = $ColumnsBackUp;

    my $IdentifierExists = grep { $_->{ $Self->{Identifier} } } @Export;

    if ( !$Self->{Columns}->{ $Self->{Identifier} }->{Export} && $IdentifierExists ) {
        for my $Export (@Export) {
            delete $Export->{ $Self->{Identifier} };
        }
    }

    @{ $Param{Content} } = @Export;

    my $ExportString = $FormatObject->SetContent(%Param);
    return $ExportString;
}

=head2 DataImport()

To use this function you need a DB CRUD module like e.g. Kernel::System::UnitTest::DBCRUD.

Imports data.

    my $Success = $DBCRUDObject->DataImport(
        Content   => $ContentString,
        Format    => 'yml',                 # optional - default
        Overwrite => 1,                     # optional to overwrite existing data
        Data      => {                      # additional data if not all needed data exists
            ValidID => 1,
        }
    );

Returns:

    my $Success = 1;

=cut

sub DataImport {
    my ( $Self, %Param ) = @_;

    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');
    my $YAMLObject   = $Kernel::OM->Get('Kernel::System::YAML');
    my $FormatObject = $Kernel::OM->Create(
        'Kernel::System::DBCRUD::Format',
        ObjectParams => {
            ObjectName => $Self->{Name},
        },
    );

    if ( !$Self->{FunctionDataImport} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Functionality DataImport not supported!",
        );
        return;
    }

    my $Content = $FormatObject->GetContent(%Param);
    return 0 if !$Content;

    my %Identifiers;

    # get import identifier for DataGet
    # to check if data already exists
    #  Name => {
    #      Column   => 'name',
    #      Export   => 1,
    #      ImportID => 1,
    #  },

    COLUMN:
    for my $Column ( sort keys %{ $Self->{Columns} } ) {
        next COLUMN if !$Self->{Columns}->{$Column}->{ImportID};
        $Identifiers{$Column} = 1;
    }

    for my $Data ( @{$Content} ) {

        # get import identifier values
        # example:
        # Name => 'test',       # ImportID => 1
        # Age  => '50',         # ImportID => 1
        for my $Identifier ( sort keys %Identifiers ) {
            $Identifiers{$Identifier} = $Data->{$Identifier};
        }

        my %Result = $Self->DataGet(
            %Identifiers,
            UserID => 1,
        );

        if ( %Result && $Param{Overwrite} ) {
            my $Success = $Self->DataUpdate(
                $Self->{Identifier} => $Result{ $Self->{Identifier} },
                %{ $Param{Data} },
                %{$Data},
                UserID => 1,
            );
        }
        elsif ( !%Result ) {
            my $CreatedID = $Self->DataAdd(
                %{ $Param{Data} },
                %{$Data},
                CreateBy => 1,
                ChangeBy => 1,
                UserID   => 1,
            );
        }
    }
    return 1;
}

=head2 DataCopy()

To use this function you need a DB CRUD module like e.g. Kernel::System::UnitTest::DBCRUD.

Copies object.

    my $ObjectID = $DBCRUDObject->DataCopy(
        ID     => 123,
        UserID => 123,
    );

Returns:

    my $ObjectID = 141;

=cut

sub DataCopy {
    my ( $Self, %Param ) = @_;

    my %Data = $Self->DataGet(
        ID     => $Param{ID},
        UserID => $Param{UserID},
    );

    COLUMN:
    for my $Column ( sort keys %{ $Self->{Columns} } ) {
        next COLUMN if !$Self->{Columns}->{$Column}->{CopyDelete};
        delete $Data{$Column};
    }

    delete $Data{ $Self->{Identifier} };
    delete $Data{CreateTime};
    delete $Data{CreateBy};
    delete $Data{ChangeTime};
    delete $Data{ChangeBy};

    my $ObjectID = $Self->DataAdd(
        %Data,
        UserID => $Param{UserID},
    );

    return $ObjectID;
}

=head2 DataNameExists()

Checks if the given name already exists in the table 'name'.

    my $Success = $DBCRUDObject->DataNameExists(
        Name   => 'name',
        UserID => 123,
    );

Returns:

    my $Success = 1;

=cut

sub DataNameExists {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    if ( !$Self->{FunctionDataNameExists} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Functionality DataNameExists not supported!",
        );
        return;
    }
    if ( $Self->{UserIDCheck} && !$Param{UserID} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Need UserID!",
        );
        return;
    }
    if ( !IsHashRefWithData( $Self->{Columns}->{Name} ) ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Name column does not exist!",
        );
        return;
    }

    NEEDED:
    for my $Needed (qw(Name)) {

        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my @DataByName = $Self->DataListGet(
        Name   => $Param{Name},
        UserID => $Self->{UserIDCheck} ? $Param{UserID} : undef,
    );

    return   if !@DataByName;
    return 1 if !$Param{ $Self->{Identifier} };

    my %DataByID = $Self->DataGet(
        $Self->{Identifier} => $Param{ $Self->{Identifier} },
        UserID              => $Self->{UserIDCheck} ? $Param{UserID} : undef,
    );

    if ( !%DataByID ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "There is no entry with the ID '" . $Param{ $Self->{Identifier} } . "'!",
        );
        return;
    }

    my $NameExists;
    DATA:
    for my $Entry (@DataByName) {
        next DATA if $DataByID{ $Self->{Identifier} } eq $Entry->{ $Self->{Identifier} };

        $NameExists = 1;

        last DATA;
    }

    return $NameExists;
}

sub DataSearchValue {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    if ( !$Self->{FunctionDataSearchValue} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Functionality DataSearchValue not supported!",
        );
        return;
    }
    if ( $Self->{UserIDCheck} && !$Param{UserID} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Need UserID!",
        );
        return;
    }

    my $SearchValue = '';

    return $SearchValue if !IsHashRefWithData( $Param{Data} );

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $Fields       = $Self->{DataSearchValueFields};

    my @Values;
    for my $Field ( @{$Fields} ) {
        push @Values, $Param{Data}->{$Field} || '';
    }

    $SearchValue = join ' ', @Values;
    $SearchValue .= ' (' . $Param{Data}->{ $Self->{Identifier} } . ')';

    return $SearchValue;
}

=head2 IsUUIDDatabaseTableColumnPresent()

    Checks if the column for the UUID.

    my $UUIDColumnPresent = $DBCRUDObject->IsUUIDDatabaseTableColumnPresent();

    Returns true value if column for UUID is present.

=cut

sub IsUUIDDatabaseTableColumnPresent {
    my ( $Self, %Param ) = @_;

    # Don't write errors of the database table column check to the log.
    {
        my $Errors;
        my $FileHandle = local (*STDERR);
        open $FileHandle, '>', \$Errors;

        my $DBPrepareOK = $Self->{DBObject}->Prepare(
            SQL   => "SELECT " . $Self->{UUIDDatabaseTableColumnName} . " FROM " . $Self->{DatabaseTable},
            Limit => 1,
        );

        close $FileHandle;

        return if !$DBPrepareOK;
    };

    # Finish query to omit warnings.
    while ( my @Row = $Self->{DBObject}->FetchrowArray() ) { }

    return 1;
}

=head2 CreateUUIDDatabaseTableColumn()

    Creates the UUID database table column.

    my $UUIDColumnCreated = $DBCRUDObject->CreateUUIDDatabaseTableColumn();

    Returns true value if column has been created successfully.

=cut

sub CreateUUIDDatabaseTableColumn {
    my ( $Self, $Text ) = @_;

    my $XMLObject = $Kernel::OM->Get('Kernel::System::XML');

    my $XML = '
        <TableAlter Name="' . $Self->{DatabaseTable} . '">
            <ColumnAdd Name="' . $Self->{UUIDDatabaseTableColumnName} . '" Required="false" Size="36" Type="VARCHAR"/>
            <UniqueCreate Name="' . $Self->{DatabaseTable} . '_uuid">
                <UniqueColumn Name="' . $Self->{UUIDDatabaseTableColumnName} . '"/>
            </UniqueCreate>
        </TableAlter>
    ';

    my @XML = $XMLObject->XMLParse( String => $XML );
    return if !@XML;

    my @SQL = $Self->{DBObject}->SQLProcessor( Database => \@XML );
    return if !@SQL;

    for my $SQL (@SQL) {
        return if !$Self->{DBObject}->Do( SQL => $SQL );
    }

    return 1;
}

=head2 CreateMissingUUIDDatabaseTableColumns()

    Creates missing UUID database table column in backend's database table
    and it's history database table, if one is configured.

    my $Success = $DBCRUDObject->CreateMissingUUIDDatabaseTableColumns();

    Returns true value on success (also if columns already existed).
    Returns false value if something went wrong.

=cut

sub CreateMissingUUIDDatabaseTableColumns {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    my $UUIDColumnPresent = $Self->IsUUIDDatabaseTableColumnPresent();
    if ( !$UUIDColumnPresent ) {
        my $UUIDColumnCreated = $Self->CreateUUIDDatabaseTableColumn();
        if ( !$UUIDColumnCreated ) {
            $LogObject->Log(
                Priority => 'error',
                Message =>
                    "Column $Self->{UUIDDatabaseTableColumnName} could not be created in database table $Self->{DatabaseTable}.",
            );
            return;
        }
    }

    # Check/create history table UUID column.
    return 1 if !$Self->can('CreateMissingUUIDHistoryDatabaseTableColumn');

    my $UUIDHistoryColumnCreated = $Self->CreateMissingUUIDHistoryDatabaseTableColumn();
    return if !$UUIDHistoryColumnCreated;

    return 1;
}

=head2 MigrateUUIDDatabaseTableColumns()

    Renames the UUID column from z4o_database_backend_uuid (used up until Znuny 6.0) or
    database_backend_uuid (used in Znuny 6.1 and 6.2) to dbcrud_uuid (Znuny 6.3 and up).
    Also includes table from history backend, if present.

    my $Success = $DBCRUDObject->MigrateUUIDDatabaseTableColumns();

    Returns true value on success.

=cut

sub MigrateUUIDDatabaseTableColumns {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');
    my $XMLObject = $Kernel::OM->Get('Kernel::System::XML');

    #
    # Check if UUID column with one of the old names is present.
    #
    my $OldUUIDColumnName;

    # Don't write errors of the database table column check to the log.
    {
        my $Errors;
        my $FileHandle = local (*STDERR);
        open $FileHandle, '>', \$Errors;

        # Check for (z4o_)database_backend_uuid
        OLDUUIDCOLUMNNAME:
        for my $CurrentOldUUIDColumnName (qw(z4o_database_backend_uuid database_backend_uuid)) {
            my $DBPrepareOK = $Self->{DBObject}->Prepare(
                SQL => "SELECT $CurrentOldUUIDColumnName"
                    . " FROM "
                    . $Self->{DatabaseTable},
                Limit => 1,
            );

            next OLDUUIDCOLUMNNAME if !$DBPrepareOK;

            $OldUUIDColumnName = $CurrentOldUUIDColumnName;
            last OLDUUIDCOLUMNNAME;
        }

        close $FileHandle;
    };

    if ($OldUUIDColumnName) {

        # Finish query to omit warnings.
        while ( my @Row = $Self->{DBObject}->FetchrowArray() ) { }

        #
        # Rename UUID column and adjust index.
        #
        my $NewUUIDColumnName = $Self->{UUIDDatabaseTableColumnName};

        my $XML = '
            <TableAlter Name="' . $Self->{DatabaseTable} . '">
                <UniqueDrop Name="' . $Self->{DatabaseTable} . '_uuid"/>
                <ColumnChange NameOld="'
            . $OldUUIDColumnName
            . '" NameNew="'
            . $NewUUIDColumnName
            . '" Required="false" Size="36" Type="VARCHAR"/>
                 <UniqueCreate Name="' . $Self->{DatabaseTable} . '_uuid">
                     <UniqueColumn Name="' . $Self->{UUIDDatabaseTableColumnName} . '"/>
                 </UniqueCreate>
            </TableAlter>
        ';

        my @XML = $XMLObject->XMLParse( String => $XML );
        return if !@XML;

        my @SQL = $Self->{DBObject}->SQLProcessor( Database => \@XML );
        return if !@SQL;

        SQL:
        for my $SQL (@SQL) {
            next SQL if $Self->{DBObject}->Do( SQL => $SQL );

            $LogObject->Log(
                Priority => 'error',
                Message =>
                    "Error: Unable to execute SQL: $SQL",
            );

            return;
        }
    }

    # Check/create history table UUID column.
    return 1 if !$Self->can('MigrateUUIDHistoryDatabaseTableColumn');

    my $UUIDHistoryColumnMigrated = $Self->MigrateUUIDHistoryDatabaseTableColumn();
    return if !$UUIDHistoryColumnMigrated;

    return 1;
}

sub _ConvertFrom {
    my ( $Self, $Text ) = @_;

    my $EncodeObject = $Kernel::OM->Get('Kernel::System::Encode');

    return       if !defined $Text;
    return $Text if !$Self->{SourceCharset};

    return $EncodeObject->Convert(
        Text => $Text,
        From => $Self->{SourceCharset},
        To   => 'utf-8',
    );
}

sub _ConvertTo {
    my ( $Self, $Text ) = @_;

    return if !defined $Text;

    my $EncodeObject = $Kernel::OM->Get('Kernel::System::Encode');

    if ( !$Self->{SourceCharset} ) {
        $EncodeObject->EncodeInput( \$Text );
        return $Text;
    }

    return $EncodeObject->Convert(
        Text => $Text,
        To   => $Self->{SourceCharset},
        From => 'utf-8',
    );
}

=head2 _WhereTimeStamp()

Additional WHERE to handle TimeStamp clauses.

    my %Result = $Self->_WhereTimeStamp(
        Param  => {
            'ChangeTimeNewerDate'  => '2016-04-15 10:45:00',
            'ChangeTimeNewerUnit'  => 'Minutes',
            'ChangeTimeNewerValue' => 2
        }
        Column => {
            'TimeStampAdd' => 1,
            'Column'       => 'create_time',
            'Name'         => 'CreateTime',
            'TimeStamp'    => 1
        }
    );

Returns:

    my %Result = {
        'Where' => [
            'change_time >= ?'
        ],
        'Bind' => [
            \'2016-04-15 10:47:00'
        ],
        'Cache' => [
            'ChangeTimeNewerDate::2016-04-15 10:47:00'
        ]
    };

=cut

sub _WhereTimeStamp {
    my ( $Self, %Param ) = @_;

    my $DBObject       = $Kernel::OM->Get('Kernel::System::DB');
    my $DateTimeObject = $Kernel::OM->Create('Kernel::System::DateTime');

    my $ColumnKey  = $Param{Column}->{Name};
    my $ColumnName = $Param{Column}->{Column};

    my %TimeTypes = (
        $ColumnKey . 'NewerValue' => {
            Type     => 'Value',
            Operator => '>=',
            Unit     => $ColumnKey . 'NewerUnit',
            Date     => $ColumnKey . 'NewerDate',
        },
        $ColumnKey . 'OlderValue' => {
            Type     => 'Value',
            Operator => '<=',
            Unit     => $ColumnKey . 'OlderUnit',
            Date     => $ColumnKey . 'OlderDate',
        },
        $ColumnKey . 'NewerDate' => {
            Type     => 'Date',
            Operator => '>=',
            Unit     => $ColumnKey . 'NewerUnit',
        },
        $ColumnKey . 'OlderDate' => {
            Type     => 'Date',
            Operator => '<=',
            Unit     => $ColumnKey . 'OlderUnit',
        },
    );

    my @TimeUnits = (
        'Years',
        'Months',
        'Weeks',
        'Days',
        'Hours',
        'Minutes',
        'Seconds',
    );

    my %Result;
    TIMETYPE:
    for my $Key ( sort keys %TimeTypes ) {

        next TIMETYPE if !$Param{Param}->{$Key};

        my $Value;
        if ( $TimeTypes{$Key}->{Type} eq 'Value' && $TimeTypes{$Key}->{Unit} ) {

            next TIMETYPE if !$Param{Param}->{ $TimeTypes{$Key}->{Unit} };

            my $TimeUnit  = $Param{Param}->{ $TimeTypes{$Key}->{Unit} };
            my $TimeValue = $Param{Param}->{$Key};

            my $IsValidTimeUnit = grep { $TimeUnit eq $_ } @TimeUnits;
            next TIMETYPE if !$IsValidTimeUnit;

            my $TimeStamp = $DateTimeObject->Clone();

            # if XXXNewerDate XXXOlderDate defined use this date as source
            if ( $TimeTypes{$Key}->{Date} && $Param{Param}->{ $TimeTypes{$Key}->{Date} } ) {
                my $DateTimeObject = $Kernel::OM->Create(
                    'Kernel::System::DateTime',
                    ObjectParams => {
                        String => $Param{Param}->{ $TimeTypes{$Key}->{Date} },
                    }
                );
                $TimeStamp = $DateTimeObject->Clone();
            }
            $TimeStamp->Subtract( $TimeUnit => $TimeValue );

            $Value = $TimeStamp->ToString();

        }

        # only if type is date and no Unit is in param
        elsif ( $TimeTypes{$Key}->{Type} eq 'Date' && !$Param{Param}->{ $TimeTypes{$Key}->{Unit} } ) {
            $Value = $Param{Param}->{$Key};
        }

        my $Operator = $TimeTypes{$Key}->{Operator};

        next TIMETYPE if !$Value;
        next TIMETYPE if !$Operator;

        $Value = $DBObject->Quote($Value);

        push @{ $Result{Where} }, $ColumnName . ' ' . $Operator . ' ?';
        push @{ $Result{Bind} },  \$Value;
        push @{ $Result{Cache} }, $Key . '::' . $Value;
    }

    return %Result;
}

sub _SQLSortPrepare {
    my ( $Self, %Param ) = @_;

    my $SQLSort = '';
    my $SortBy  = [];
    my $OrderBy = [];
    if ( $Param{SortBy} && $Param{OrderBy} ) {
        $SortBy  = $Param{SortBy};
        $OrderBy = $Param{OrderBy};
    }
    elsif ( $Self->{DefaultSortBy} && $Self->{DefaultOrderBy} ) {
        $SortBy  = $Self->{DefaultSortBy};
        $OrderBy = $Self->{DefaultOrderBy};
    }

    if ( !IsArrayRefWithData($SortBy) ) {
        $SortBy = [$SortBy];
    }
    if ( !IsArrayRefWithData($OrderBy) ) {
        $OrderBy = [$OrderBy];
    }

    return '' if !IsArrayRefWithData($SortBy) || !IsArrayRefWithData($OrderBy);
    return '' if scalar @{$SortBy} != scalar @{$OrderBy};

    my @OrderBySQL;
    for my $Index ( 0 .. $#{$SortBy} ) {
        my $CurrentSortBy = $SortBy->[$Index];

        return '' if !defined $Self->{Columns}->{$CurrentSortBy};

        push @OrderBySQL, $Self->{Columns}->{$CurrentSortBy}->{Column} . ' ' . $OrderBy->[$Index];
    }

    $SQLSort .= ' ORDER BY ' . join( ', ', @OrderBySQL );

    # Additionally sort by identifier
    my $SortedByIdentifier = grep { $_ eq $Self->{Identifier} } @{$SortBy};
    return $SQLSort if $SortedByIdentifier;

    $SQLSort .= ', ' . $Self->{Columns}->{ $Self->{Identifier} }->{Column} . ' ASC';

    return $SQLSort;
}

sub _CacheKeysSortGet {
    my ( $Self, %Param ) = @_;

    my $SortBy  = [];
    my $OrderBy = [];
    if ( $Param{SortBy} && $Param{OrderBy} ) {
        $SortBy  = $Param{SortBy};
        $OrderBy = $Param{OrderBy};
    }
    elsif ( $Self->{DefaultSortBy} && $Self->{DefaultOrderBy} ) {
        $SortBy  = $Self->{DefaultSortBy};
        $OrderBy = $Self->{DefaultOrderBy};
    }

    if ( !IsArrayRefWithData($SortBy) ) {
        $SortBy = [$SortBy];
    }
    if ( !IsArrayRefWithData($OrderBy) ) {
        $OrderBy = [$OrderBy];
    }

    my @CacheKeys;
    return \@CacheKeys if !IsArrayRefWithData($SortBy) || !IsArrayRefWithData($OrderBy);

    INDEX:
    for my $Index ( 0 .. $#{$SortBy} ) {
        my $CurrentSortBy = $SortBy->[$Index];

        next INDEX if !defined $Self->{Columns}->{$CurrentSortBy};

        push @CacheKeys, 'Sort::' . $Self->{Columns}->{$CurrentSortBy}->{Column} . '::' . $OrderBy->[$Index];
    }

    # Additionally sort by identifier
    my $SortedByIdentifier = grep { $_ eq $Self->{Identifier} } @{$SortBy};
    return \@CacheKeys if $SortedByIdentifier;

    push @CacheKeys, 'Sort::' . $Self->{Columns}->{ $Self->{Identifier} }->{Column} . '::ASC';

    return \@CacheKeys;
}

sub _ContentValueGet {
    my ( $Self, %Param ) = @_;

    my $LogObject  = $Kernel::OM->Get('Kernel::System::Log');
    my $JSONObject = $Kernel::OM->Get('Kernel::System::JSON');

    NEEDED:
    for my $Needed (qw(Config)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my $Value  = $Param{Value};
    my $Config = $Param{Config};

    return $Value if !$Value;
    return $Value if $Value eq '""' && $Config->{ContentJSON};

    if ( $Config->{ContentJSON} ) {
        return $JSONObject->Decode(
            Data => $Value,
        );
    }

    return $Value;
}

sub DESTROY {
    my $Self = shift;

    # execute all transaction events
    $Self->EventHandlerTransaction();

    # disconnect if it's not a parent DBObject
    return if !$Self->{DBObject};
    $Self->{DBObject}->Disconnect();
    return 1;
}

1;
