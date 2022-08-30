# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::DB::mssql;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::DateTime',
    'Kernel::System::Log',
    'Kernel::System::Main',
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub LoadPreferences {
    my ( $Self, %Param ) = @_;

    # db settings
    $Self->{'DB::Limit'}                = 'top';
    $Self->{'DB::DirectBlob'}           = 0;
    $Self->{'DB::QuoteSingle'}          = '\'';
    $Self->{'DB::QuoteBack'}            = 0;
    $Self->{'DB::QuoteSemicolon'}       = '';
    $Self->{'DB::QuoteUnderscoreStart'} = '[';
    $Self->{'DB::QuoteUnderscoreEnd'}   = ']';
    $Self->{'DB::CaseSensitive'}        = 0;
    $Self->{'DB::LikeEscapeString'}     = '';

    # how to determine server version
    # @@VERSION returns "Microsoft SQL Server 2012 - 11.0.2218.0 (X64) Jun 12 2012 13:05:25 Copyright..."
    # we only take what is left of the minus; our version string: "Microsoft SQL Server 2012"
    $Self->{'DB::Version'} = 'SELECT LEFT( @@VERSION, (CHARINDEX ( \'-\' ,@@VERSION) -2) )';

    # dbi attributes
    $Self->{'DB::Attribute'} = {
        LongTruncOk => 1,
        LongReadLen => 70 * 1024 * 1024,
    };

    # set current time stamp if different to "current_timestamp"
    $Self->{'DB::CurrentTimestamp'} = '';

    # set encoding of selected data to utf8
    $Self->{'DB::Encode'} = 1;

    # shell setting
    $Self->{'DB::Comment'}     = '-- ';
    $Self->{'DB::ShellCommit'} = ';';

    #$Self->{'DB::ShellConnect'} = '';

    # init sql setting on db connect
    if ( !$Kernel::OM->Get('Kernel::Config')->Get('Database::ShellOutput') ) {
        $Self->{'DB::Connect'} = 'SET DATEFORMAT ymd';
    }

    return 1;
}

sub Quote {
    my ( $Self, $Text, $Type ) = @_;

    if ( defined ${$Text} ) {
        if ( $Self->{'DB::QuoteBack'} ) {
            ${$Text} =~ s/\\/$Self->{'DB::QuoteBack'}\\/g;
        }
        if ( $Self->{'DB::QuoteSingle'} ) {
            ${$Text} =~ s/'/$Self->{'DB::QuoteSingle'}'/g;
        }
        if ( $Self->{'DB::QuoteSemicolon'} ) {
            ${$Text} =~ s/;/$Self->{'DB::QuoteSemicolon'};/g;
        }
        if ( $Type && $Type eq 'Like' ) {
            ${$Text} =~ s/\[/[[]/g;
            if ( $Self->{'DB::QuoteUnderscoreStart'} || $Self->{'DB::QuoteUnderscoreEnd'} ) {
                ${$Text}
                    =~ s/_/$Self->{'DB::QuoteUnderscoreStart'}_$Self->{'DB::QuoteUnderscoreEnd'}/g;
            }
        }
    }
    return $Text;
}

sub DatabaseCreate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{Name} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need Name!'
        );
        return;
    }

    # return SQL
    return ("CREATE DATABASE $Param{Name}");
}

sub DatabaseDrop {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{Name} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need Name!'
        );
        return;
    }

    # return SQL
    return ("DROP DATABASE $Param{Name}");
}

sub TableCreate {
    my ( $Self, @Param ) = @_;

    # get config object
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    my $SQLStart     = '';
    my $SQLEnd       = '';
    my $SQL          = '';
    my @Column       = ();
    my $TableName    = '';
    my %Default      = ();
    my $ForeignKey   = ();
    my %Foreign      = ();
    my $IndexCurrent = ();
    my %Index        = ();
    my $UniqCurrent  = ();
    my %Uniq         = ();
    my $PrimaryKey   = '';
    my @Return       = ();

    for my $Tag (@Param) {

        if (
            ( $Tag->{Tag} eq 'Table' || $Tag->{Tag} eq 'TableCreate' )
            && $Tag->{TagType} eq 'Start'
            )
        {
            if ( $ConfigObject->Get('Database::ShellOutput') ) {
                $SQLStart .= $Self->{'DB::Comment'}
                    . "----------------------------------------------------------\n";
                $SQLStart .= $Self->{'DB::Comment'} . " create table $Tag->{Name}\n";
                $SQLStart .= $Self->{'DB::Comment'}
                    . "----------------------------------------------------------\n";
            }
        }
        if (
            ( $Tag->{Tag} eq 'Table' || $Tag->{Tag} eq 'TableCreate' )
            && $Tag->{TagType} eq 'Start'
            )
        {
            $SQLStart .= "CREATE TABLE $Tag->{Name} (\n";
            $TableName = $Tag->{Name};
        }
        if (
            ( $Tag->{Tag} eq 'Table' || $Tag->{Tag} eq 'TableCreate' )
            && $Tag->{TagType} eq 'End'
            )
        {
            $SQLEnd .= ')';
        }
        elsif ( $Tag->{Tag} eq 'Column' && $Tag->{TagType} eq 'Start' ) {
            push @Column, $Tag;
        }
        elsif ( $Tag->{Tag} eq 'Index' && $Tag->{TagType} eq 'Start' ) {
            $IndexCurrent = $Tag->{Name};
        }
        elsif ( $Tag->{Tag} eq 'IndexColumn' && $Tag->{TagType} eq 'Start' ) {
            push @{ $Index{$IndexCurrent} }, $Tag;
        }
        elsif ( $Tag->{Tag} eq 'Unique' && $Tag->{TagType} eq 'Start' ) {
            $UniqCurrent = $Tag->{Name} || $TableName . '_U_' . int( rand(999) );
        }
        elsif ( $Tag->{Tag} eq 'UniqueColumn' && $Tag->{TagType} eq 'Start' ) {
            push @{ $Uniq{$UniqCurrent} }, $Tag;
        }
        elsif ( $Tag->{Tag} eq 'ForeignKey' && $Tag->{TagType} eq 'Start' ) {
            $ForeignKey = $Tag->{ForeignTable};
        }
        elsif ( $Tag->{Tag} eq 'Reference' && $Tag->{TagType} eq 'Start' ) {
            push @{ $Foreign{$ForeignKey} }, $Tag;
        }
    }
    for my $Tag (@Column) {

        # type translation
        $Tag = $Self->_TypeTranslation($Tag);

        # add new line
        if ($SQL) {
            $SQL .= ",\n";
        }

        # normal data type
        $SQL .= "    $Tag->{Name} $Tag->{Type}";

        # handle require
        if ( $Tag->{Required} && lc $Tag->{Required} eq 'true' ) {
            $SQL .= ' NOT NULL';
        }
        else {
            $SQL .= ' NULL';
        }

        # auto increment
        if ( $Tag->{AutoIncrement} && $Tag->{AutoIncrement} =~ /^true$/i ) {
            $SQL .= ' IDENTITY(1,1) ';
        }

        # add primary key
        if ( $Tag->{PrimaryKey} && $Tag->{PrimaryKey} =~ /true/i ) {
            $PrimaryKey = "    PRIMARY KEY($Tag->{Name})";
        }

        # save default value
        if ( defined $Tag->{Default} ) {
            if ( $Tag->{Type} =~ /int/i ) {
                $Default{ $Tag->{Name} } = $Tag->{Default};
            }
            else {
                $Default{ $Tag->{Name} } = "'" . $Tag->{Default} . "'";
            }
        }
    }

    # add primary key
    if ($PrimaryKey) {
        if ($SQL) {
            $SQL .= ",\n";
        }
        $SQL .= $PrimaryKey;
    }

    # add uniqueness
    for my $Name ( sort keys %Uniq ) {
        if ($SQL) {
            $SQL .= ",\n";
        }
        $SQL .= "    CONSTRAINT $Name UNIQUE (";
        my @Array = @{ $Uniq{$Name} };
        for my $Index ( 0 .. $#Array ) {
            if ( $Index > 0 ) {
                $SQL .= ', ';
            }
            $SQL .= $Array[$Index]->{Name};
        }
        $SQL .= ')';
    }

    $SQL .= "\n";
    push @Return, $SQLStart . $SQL . $SQLEnd;

    # add default constraint
    for my $Column ( sort keys %Default ) {

        # create the default name
        my $DefaultName = 'DF_' . $TableName . '_' . $Column;

        push @Return,
            "ALTER TABLE $TableName ADD CONSTRAINT $DefaultName DEFAULT ($Default{$Column}) FOR $Column";
    }

    # add index
    for my $Name ( sort keys %Index ) {
        push(
            @Return,
            $Self->IndexCreate(
                TableName => $TableName,
                Name      => $Name,
                Data      => $Index{$Name},
            ),
        );
    }

    # add foreign keys
    for my $ForeignKey ( sort keys %Foreign ) {
        my @Array = @{ $Foreign{$ForeignKey} };
        for my $Index ( 0 .. $#Array ) {
            push(
                @{ $Self->{Post} },
                $Self->ForeignKeyCreate(
                    LocalTableName   => $TableName,
                    Local            => $Array[$Index]->{Local},
                    ForeignTableName => $ForeignKey,
                    Foreign          => $Array[$Index]->{Foreign},
                ),
            );
        }
    }
    return @Return;
}

sub TableDrop {
    my ( $Self, @Param ) = @_;

    # get config object
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    my $SQL = '';
    for my $Tag (@Param) {
        if ( $Tag->{Tag} eq 'Table' && $Tag->{TagType} eq 'Start' ) {
            if ( $ConfigObject->Get('Database::ShellOutput') ) {
                $SQL .= $Self->{'DB::Comment'}
                    . "----------------------------------------------------------\n";
                $SQL .= $Self->{'DB::Comment'} . " drop table $Tag->{Name}\n";
                $SQL .= $Self->{'DB::Comment'}
                    . "----------------------------------------------------------\n";
            }
        }
        $SQL .= 'DROP TABLE ' . $Tag->{Name};
        return ($SQL);
    }
    return ();
}

sub TableAlter {
    my ( $Self, @Param ) = @_;

    # get config object
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    my $SQLStart      = '';
    my @SQL           = ();
    my @Index         = ();
    my $IndexName     = ();
    my $ForeignTable  = '';
    my $ReferenceName = '';
    my @Reference     = ();
    my $Table         = '';

    my $Start = '';
    if ( $ConfigObject->Get('Database::ShellOutput') ) {
        $Start = "GO\n";
    }

    for my $Tag (@Param) {

        if ( $Tag->{Tag} eq 'TableAlter' && $Tag->{TagType} eq 'Start' ) {
            $Table = $Tag->{Name} || $Tag->{NameNew};
            if ( $ConfigObject->Get('Database::ShellOutput') ) {
                $SQLStart .= $Self->{'DB::Comment'}
                    . "----------------------------------------------------------\n";
                $SQLStart .= $Self->{'DB::Comment'} . " alter table $Table\n";
                $SQLStart .= $Self->{'DB::Comment'}
                    . "----------------------------------------------------------\n";
            }

            # rename table
            if ( $Tag->{NameOld} && $Tag->{NameNew} ) {
                push @SQL,
                    $SQLStart
                    . $Start
                    . "EXEC sp_rename '$Tag->{NameOld}', '$Tag->{NameNew}'\n"
                    . $Start;
            }
            $SQLStart .= "ALTER TABLE $Table";
        }
        elsif ( $Tag->{Tag} eq 'ColumnAdd' && $Tag->{TagType} eq 'Start' ) {

            # Type translation
            $Tag = $Self->_TypeTranslation($Tag);

            # normal data type
            push @SQL, $SQLStart . " ADD $Tag->{Name} $Tag->{Type} NULL";

            # investigate the default value
            my $Default = '';
            if ( $Tag->{Type} =~ /int/i ) {
                $Default = defined $Tag->{Default} ? $Tag->{Default} : 0;
            }
            else {
                $Default = defined $Tag->{Default} ? "'$Tag->{Default}'" : "''";
            }

            # investigate the require
            my $Required = ( $Tag->{Required} && lc $Tag->{Required} eq 'true' ) ? 1 : 0;

            # handle default and require
            if ( $Required || defined $Tag->{Default} ) {

                # fill up empty rows
                push @SQL,
                    $Start . "UPDATE $Table SET $Tag->{Name} = $Default WHERE $Tag->{Name} IS NULL";

                # add require
                my $SQLAlter = "ALTER TABLE $Table ALTER COLUMN $Tag->{Name} $Tag->{Type}";
                if ($Required) {
                    $SQLAlter .= ' NOT NULL';
                }
                else {
                    $SQLAlter .= ' NULL';
                }
                push @SQL, $Start . $SQLAlter;

                # add default
                my $DefaultName = 'DF_' . $Table . '_' . $Tag->{Name};
                if ( defined $Tag->{Default} ) {
                    push @SQL, $Start
                        . "ALTER TABLE $Table ADD CONSTRAINT $DefaultName DEFAULT ($Default) FOR $Tag->{Name}";
                }
            }
        }
        elsif ( $Tag->{Tag} eq 'ColumnChange' && $Tag->{TagType} eq 'Start' ) {

            # Type translation
            $Tag = $Self->_TypeTranslation($Tag);

            # rename oldname to newname
            if ( $Tag->{NameOld} ne $Tag->{NameNew} ) {
                push @SQL, $Start
                    . "EXECUTE sp_rename N'$Table.$Tag->{NameOld}', N'$Tag->{NameNew}', 'COLUMN'";
            }

            # alter table name modify
            if ( !$Tag->{Name} && $Tag->{NameNew} ) {
                $Tag->{Name} = $Tag->{NameNew};
            }
            if ( !$Tag->{Name} && $Tag->{NameOld} ) {
                $Tag->{Name} = $Tag->{NameOld};
            }
            push @SQL, $Start . "ALTER TABLE $Table ALTER COLUMN $Tag->{Name} $Tag->{Type} NULL";

            # create the default name
            my $DefaultName = 'DF_' . $Table . '_' . $Tag->{Name};

            # remove possible default
            push @SQL, $Start . "IF EXISTS (SELECT * FROM dbo.sysobjects WHERE "
                . "name = '$DefaultName' )\n"
                . "ALTER TABLE $Table DROP CONSTRAINT $DefaultName";

            # investigate the default value
            my $Default = '';
            if ( $Tag->{Type} =~ /int/i ) {
                $Default = defined $Tag->{Default} ? $Tag->{Default} : 0;
            }
            else {
                $Default = defined $Tag->{Default} ? "'$Tag->{Default}'" : "''";
            }

            # investigate the require
            my $Required = ( $Tag->{Required} && lc $Tag->{Required} eq 'true' ) ? 1 : 0;

            # handle default and require
            if ( $Required || defined $Tag->{Default} ) {

                # fill up empty rows
                push @SQL, $Start
                    . "UPDATE $Table SET $Tag->{NameNew} = $Default WHERE $Tag->{NameNew} IS NULL";

                # add require
                my $SQLAlter = "ALTER TABLE $Table ALTER COLUMN $Tag->{Name} $Tag->{Type}";
                if ($Required) {
                    $SQLAlter .= ' NOT NULL';
                }
                else {
                    $SQLAlter .= ' NULL';
                }
                push @SQL, $Start . $SQLAlter;

                # add default
                if ( defined $Tag->{Default} ) {
                    push @SQL, $Start
                        . "ALTER TABLE $Table ADD CONSTRAINT $DefaultName DEFAULT ($Default) FOR $Tag->{Name}";
                }
            }
        }
        elsif ( $Tag->{Tag} eq 'ColumnDrop' && $Tag->{TagType} eq 'Start' ) {

            # create the default name
            my $DefaultName = 'DF_' . $Table . '_' . $Tag->{Name};

            # remove possible default
            push @SQL, sprintf(
                <<END
                DECLARE \@defname%s VARCHAR(200), \@cmd%s VARCHAR(2000)
                SET \@defname%s = (
                    SELECT name FROM sysobjects so JOIN sysconstraints sc ON so.id = sc.constid
                    WHERE object_name(so.parent_obj) = '%s' AND so.xtype = 'D' AND sc.colid = (
                        SELECT colid FROM syscolumns WHERE id = object_id('%s') AND name = '%s'
                    )
                )
                SET \@cmd%s = 'ALTER TABLE %s DROP CONSTRAINT ' + \@defname%s
                EXEC(\@cmd%s)
END
                , $Table . $Tag->{Name}, $Table . $Tag->{Name}, $Table . $Tag->{Name}, $Table,
                $Table, $Tag->{Name}, $Table . $Tag->{Name}, $Table, $Table . $Tag->{Name},
                $Table . $Tag->{Name},
            );

            # remove all possible constrains
            push @SQL, sprintf(
                <<HEREDOC
                    DECLARE \@sql%s NVARCHAR(4000)

                    WHILE 1=1
                    BEGIN
                        SET \@sql%s = (SELECT TOP 1 'ALTER TABLE %s DROP CONSTRAINT [' + constraint_name + ']'
                        -- SELECT *
                        FROM information_schema.CONSTRAINT_COLUMN_USAGE where table_name='%s' and column_name='%s'
                        )
                        IF \@sql%s IS NULL BREAK
                        EXEC (\@sql%s)
                    END
HEREDOC
                , $Table . $Tag->{Name}, $Table . $Tag->{Name}, $Table, $Table, $Tag->{Name},
                $Table . $Tag->{Name}, $Table . $Tag->{Name},
            );

            push @SQL, $SQLStart . " DROP COLUMN $Tag->{Name}";
        }
        elsif ( $Tag->{Tag} =~ /^((Index|Unique)(Create|Drop))/ ) {
            my $Method = $Tag->{Tag};
            if ( $Tag->{Name} ) {
                $IndexName = $Tag->{Name};
            }
            if ( $Tag->{TagType} eq 'End' ) {
                push @SQL, $Self->$Method(
                    TableName => $Table,
                    Name      => $IndexName,
                    Data      => \@Index,
                );
                $IndexName = '';
                @Index     = ();
            }
        }
        elsif ( $Tag->{Tag} =~ /^(IndexColumn|UniqueColumn)/ && $Tag->{TagType} eq 'Start' ) {
            push @Index, $Tag;
        }
        elsif ( $Tag->{Tag} =~ /^((ForeignKey)(Create|Drop))/ ) {
            my $Method = $Tag->{Tag};
            if ( $Tag->{ForeignTable} ) {
                $ForeignTable = $Tag->{ForeignTable};
            }
            if ( $Tag->{TagType} eq 'End' ) {
                for my $Reference (@Reference) {
                    push @SQL, $Self->$Method(
                        LocalTableName   => $Table,
                        Local            => $Reference->{Local},
                        ForeignTableName => $ForeignTable,
                        Foreign          => $Reference->{Foreign},
                    );
                }
                $ReferenceName = '';
                @Reference     = ();
            }
        }
        elsif ( $Tag->{Tag} =~ /^(Reference)/ && $Tag->{TagType} eq 'Start' ) {
            push @Reference, $Tag;
        }
    }

    return @SQL;
}

sub IndexCreate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(TableName Name Data)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }
    my $SQL   = "CREATE INDEX $Param{Name} ON $Param{TableName} (";
    my @Array = @{ $Param{Data} };
    for my $Index ( 0 .. $#Array ) {
        if ( $Index > 0 ) {
            $SQL .= ', ';
        }
        $SQL .= $Array[$Index]->{Name};
        if ( $Array[$Index]->{Size} ) {

            #           $SQL .= "($Array[$Index]->{Size})";
        }
    }
    $SQL .= ')';

    # return SQL
    return ($SQL);

}

sub IndexDrop {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(TableName Name)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }
    my $SQL = 'DROP INDEX ' . $Param{TableName} . '.' . $Param{Name};
    return ($SQL);
}

sub ForeignKeyCreate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(LocalTableName Local ForeignTableName Foreign)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    # create foreign key name
    my $ForeignKey = "FK_$Param{LocalTableName}_$Param{Local}_$Param{Foreign}";
    if ( length($ForeignKey) > 60 ) {
        my $MD5 = $Kernel::OM->Get('Kernel::System::Main')->MD5sum(
            String => $ForeignKey,
        );
        $ForeignKey = substr $ForeignKey, 0, 58;
        $ForeignKey .= substr $MD5, 0,  1;
        $ForeignKey .= substr $MD5, 31, 1;
    }

    # add foreign key
    my $SQL = "ALTER TABLE $Param{LocalTableName} ADD CONSTRAINT $ForeignKey FOREIGN KEY "
        . "($Param{Local}) REFERENCES $Param{ForeignTableName} ($Param{Foreign})";

    return ($SQL);
}

sub ForeignKeyDrop {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(LocalTableName Local ForeignTableName Foreign)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    # create foreign key name
    my $ForeignKey = "FK_$Param{LocalTableName}_$Param{Local}_$Param{Foreign}";
    if ( length($ForeignKey) > 60 ) {
        my $MD5 = $Kernel::OM->Get('Kernel::System::Main')->MD5sum(
            String => $ForeignKey,
        );
        $ForeignKey = substr $ForeignKey, 0, 58;
        $ForeignKey .= substr $MD5, 0,  1;
        $ForeignKey .= substr $MD5, 31, 1;
    }

    # drop foreign key
    my $SQL = "ALTER TABLE $Param{LocalTableName} DROP CONSTRAINT $ForeignKey";

    return ($SQL);
}

sub UniqueCreate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(TableName Name Data)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }
    my $SQL   = "ALTER TABLE $Param{TableName} ADD CONSTRAINT $Param{Name} UNIQUE (";
    my @Array = @{ $Param{Data} };
    for my $Index ( 0 .. $#Array ) {
        if ( $Index > 0 ) {
            $SQL .= ', ';
        }
        $SQL .= $Array[$Index]->{Name};
    }
    $SQL .= ')';

    # return SQL
    return ($SQL);

}

sub UniqueDrop {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Index (qw(TableName Name)) {
        if ( !$Param{$Index} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Index!"
            );
            return;
        }
    }
    my $SQL = "ALTER TABLE $Param{TableName} DROP CONSTRAINT $Param{Name}";
    return ($SQL);
}

sub Insert {
    my ( $Self, @Param ) = @_;

    # get needed objects
    my $ConfigObject   = $Kernel::OM->Get('Kernel::Config');
    my $DateTimeObject = $Kernel::OM->Create('Kernel::System::DateTime');

    my $SQL    = '';
    my @Keys   = ();
    my @Values = ();
    TAG:
    for my $Tag (@Param) {
        if ( $Tag->{Tag} eq 'Insert' && $Tag->{TagType} eq 'Start' ) {
            if ( $ConfigObject->Get('Database::ShellOutput') ) {
                $SQL .= $Self->{'DB::Comment'}
                    . "----------------------------------------------------------\n";
                $SQL .= $Self->{'DB::Comment'} . " insert into table $Tag->{Table}\n";
                $SQL .= $Self->{'DB::Comment'}
                    . "----------------------------------------------------------\n";
            }
            $SQL .= "INSERT INTO $Tag->{Table} ";
        }
        if ( $Tag->{Tag} eq 'Data' && $Tag->{TagType} eq 'Start' ) {

            # do not use auto increment values
            if ( $Tag->{Type} && $Tag->{Type} =~ /^AutoIncrement$/i ) {
                next TAG;
            }
            $Tag->{Key} = ${ $Self->Quote( \$Tag->{Key} ) };
            push @Keys, $Tag->{Key};
            my $Value;
            if ( defined $Tag->{Value} ) {
                $Value = $Tag->{Value};
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'error',
                    Message  => 'The content for inserts is not longer appreciated '
                        . 'attribut Value, use Content from now on! Reason: You can\'t '
                        . 'use new lines in attributes.',
                );
            }
            elsif ( defined $Tag->{Content} ) {
                $Value = $Tag->{Content};
            }
            else {
                $Value = '';
            }
            if ( $Tag->{Type} && $Tag->{Type} eq 'Quote' ) {
                $Value = "'" . ${ $Self->Quote( \$Value ) } . "'";
            }
            else {
                $Value = ${ $Self->Quote( \$Value ) };
            }
            push @Values, $Value;
        }
    }
    my $Key = '';
    for my $CurrentKey (@Keys) {
        if ( $Key ne '' ) {
            $Key .= ', ';
        }
        $Key .= $CurrentKey;
    }
    my $Value = '';
    for my $Tmp (@Values) {
        if ( $Value ne '' ) {
            $Value .= ', ';
        }
        if ( $Tmp eq 'current_timestamp' ) {
            if ( $ConfigObject->Get('Database::ShellOutput') ) {
                $Value .= $Tmp;
            }
            else {
                my $Timestamp = $DateTimeObject->ToString();
                $Value .= '\'' . $Timestamp . '\'';
            }
        }
        else {
            $Value .= $Tmp;
        }
    }
    $SQL .= "($Key)\n    VALUES\n    ($Value)";
    return ($SQL);
}

sub _TypeTranslation {
    my ( $Self, $Tag ) = @_;

    if ( $Tag->{Type} =~ /^DATE$/i ) {
        $Tag->{Type} = 'DATETIME';
    }
    elsif ( $Tag->{Type} =~ /^VARCHAR$/i ) {
        if ( $Tag->{Size} > 4000 ) {
            $Tag->{Type} = 'NVARCHAR (MAX)';
        }
        else {
            $Tag->{Type} = 'NVARCHAR (' . $Tag->{Size} . ')';
        }
    }
    elsif ( $Tag->{Type} =~ /^longblob$/i ) {
        $Tag->{Type} = 'NVARCHAR (MAX)';
    }
    elsif ( $Tag->{Type} =~ /^DECIMAL$/i ) {
        $Tag->{Type} = 'DECIMAL (' . $Tag->{Size} . ')';
    }
    return $Tag;
}

1;
