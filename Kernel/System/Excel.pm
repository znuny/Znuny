# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Excel;

use strict;
use warnings;

use Hash::Merge;
use Excel::Writer::XLSX;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::FileTemp',
    'Kernel::System::Log',
    'Kernel::System::Main',
    'Kernel::System::YAML',
);

use Kernel::System::VariableCheck qw(:all);

=head1 NAME

Kernel::System::Excel - all Excel functions

=head1 SYNOPSIS

All Excel functions.

=head1 PUBLIC INTERFACE

=head2 new()

create an object

    my $ExcelObject = $Kernel::OM->Get('Kernel::System::Excel');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=head2 Array2Excel()

Returns the Excel file content, format (for e.g. attachments) is 'application/vnd.ms-excel' / 'xls'.

    my $ExcelFileContent = $ExcelObject->Array2Excel(
        Data => [
            {
                Name        => 'Overview',
                FreezePanes => [
                    {
                        Row    => 2,
                        Column => 0,
                    },
                ],
                TableData   => [
                    [
                        {
                            Format => {
                                right    => 1,
                                bg_color => 'silver',
                            }
                        },
                        {
                            Format => {
                                left     => 1,
                                right    => 1,
                                bg_color => 'silver',
                            }
                        },
                        {
                            Format => {
                                left     => 1,
                                right    => 1,
                                bg_color => 'silver',
                            }
                        },
                        {
                            Value  => 'Response Time',
                            Merge  => 1,
                            Format => {
                                border   => 1,
                                bg_color => 'silver',
                                valign   => 'vcentre',
                                align    => 'center',
                            }
                        },
                        {
                            Merge => 2,
                        },
                        {
                            Merge => 3,
                        },
                        {
                            Value  => 'Solution Time',
                            Merge  => 1,
                            Format => {
                                border   => 1,
                                bg_color => 'silver',
                                valign   => 'vcentre',
                                align    => 'center',
                            }
                        },
                        {
                            Merge => 2,
                        },
                        {
                            Merge => 3,
                        },
                    ],
                    [
                        {
                            Value  => 'Service',
                            Format => {
                                right    => 1,
                                bottom   => 1,
                                bg_color => 'silver',
                                valign   => 'vcentre',
                                align    => 'center',
                            }
                        },
                        {
                            Value  => 'SLA',
                            Format => {
                                left     => 1,
                                right    => 1,
                                bottom   => 1,
                                bg_color => 'silver',
                                valign   => 'vcentre',
                                align    => 'center',
                            }
                        },
                        {
                            Value  => '#Tickets',
                            Format => {
                                left     => 1,
                                right    => 1,
                                bottom   => 1,
                                bg_color => 'silver',
                                valign   => 'vcentre',
                                align    => 'center',
                            }
                        },
                        {
                            Value  => '#IN',
                            Format => {
                                border   => 1,
                                bg_color => 'silver',
                            }
                        },
                        {
                            Value  => '%IN',
                            Format => {
                                border   => 1,
                                bg_color => 'silver',
                            }
                        },
                        {
                            Value  => '#OUT',
                            Format => {
                                border   => 1,
                                bg_color => 'silver',
                            }
                        },
                        {
                            Value  => '#IN',
                            Format => {
                                border   => 1,
                                bg_color => 'silver',
                            }
                        },
                        {
                            Value  => '%IN',
                            Format => {
                                border   => 1,
                                bg_color => 'silver',
                            }
                        },
                        {
                            Value  => '#OUT',
                            Format => {
                                border   => 1,
                                bg_color => 'silver',
                            }
                        },
                    ],
                    ...
                ],
            },
        ],
    );

=cut

sub Array2Excel {
    my ( $Self, %Param ) = @_;

    my $LogObject      = $Kernel::OM->Get('Kernel::System::Log');
    my $FileTempObject = $Kernel::OM->Get('Kernel::System::FileTemp');

    # Spreadsheet::Excel needs a temporary file to write in
    my ( $FH, $Filename ) = $FileTempObject->TempFile();

    # create a new Excel workbook in temporary file
    my $Workbook = Excel::Writer::XLSX->new($Filename);

    # see: http://search.cpan.org/~jmcnamara/Excel-Writer-XLSX/lib/Excel/Writer/XLSX.pm#SPEED_AND_MEMORY_USAGE
    # Performance change #2:
    # Reduces the memory load from 460 MB to 260 MB for 10_000 tickets
    $Workbook->set_optimization();

    # Performance change #4:
    # bring values of parameters Worksheet and Data
    # in an array ref format we can handle
    # because working with a ref reduces the memory load from 240 MB to 230 MB for 10_000 tickets
    my $Worksheets;
    if ( IsArrayRefWithData( $Param{Worksheets} ) ) {
        $Worksheets = $Param{Worksheets};
    }
    elsif (
        IsArrayRefWithData( $Param{Data} )
        && IsArrayRefWithData( $Param{Data}->[0] )
        )
    {
        # check if we already have a structure with sub worksheets
        # or if we have only data for one worksheet
        if ( IsArrayRefWithData( $Param{Data}->[0]->[0] ) ) {
            $Worksheets = $Param{Data};
        }
        else {
            push @{$Worksheets}, $Param{Data};
        }
    }

    # sanity check
    if ( !IsArrayRefWithData($Worksheets) ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Invalid Data or Worksheets parameter structure.",
        );
        return;
    }

    # get format definition for one
    # or multiple worksheets
    my @FormatDefinition;
    if ( IsHashRefWithData( $Param{FormatDefinition} ) ) {
        push @FormatDefinition, $Param{FormatDefinition};
    }
    elsif ( IsArrayRefWithData( $Param{FormatDefinition} ) ) {
        @FormatDefinition = @{ $Param{FormatDefinition} };
    }

    my %WorkbookProperties;
    if ( IsHashRefWithData( $Param{Stat} ) ) {
        $WorkbookProperties{title} = $Param{Stat}->{Title};
    }

    my %ColorStorage;
    my $ColorIndex              = 63;
    my $FormatDefinitionCounter = 0;
    WORKSHEET:
    for my $WorksheetData ( @{$Worksheets} ) {

        # check if we have a flat csv like structure
        # or if we have an already formatted excel structure
        my %WorksheetData;
        if ( IsArrayRefWithData($WorksheetData) ) {
            $WorksheetData{TableData} = $WorksheetData;
        }
        elsif ( IsHashRefWithData($WorksheetData) ) {
            %WorksheetData = %{$WorksheetData};
        }

        # sanity check
        if ( !%WorksheetData ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Invalid data format in 'Worksheet' parameter.",
            );
            next WORKSHEET;
        }

        # get format definition for worksheet if given
        my %WorksheetFormatDefinition;
        if ( IsHashRefWithData( $FormatDefinition[$FormatDefinitionCounter] ) ) {
            %WorksheetFormatDefinition = %{ $FormatDefinition[$FormatDefinitionCounter] };
        }

        # set/update workbook properties if defined
        if ( IsHashRefWithData( $WorksheetFormatDefinition{Properties} ) ) {
            %WorkbookProperties = (
                %WorkbookProperties,
                %{ $WorksheetFormatDefinition{Properties} }
            );
        }

        if (%WorkbookProperties) {
            $Workbook->set_properties(%WorkbookProperties);
        }

        # make sure worksheet name is a string that's
        # not longer than the 31 chars limit
        my $WorksheetName;
        if ( IsStringWithData( $WorksheetFormatDefinition{Name} ) ) {
            $WorksheetName = substr( $WorksheetFormatDefinition{Name}, 0, 31 );
        }
        elsif ( IsStringWithData( $WorksheetData{Name} ) ) {
            $WorksheetName = substr( $WorksheetData{Name}, 0, 31 );
        }

        # create new worksheet to work with
        my $Worksheet = $Workbook->add_worksheet($WorksheetName);

        my $RowCounter = 0;
        my %ColumnWidth;
        my %RowHeight;
        my %Merge;
        my %DefaultFormatDefinition;

        if ( IsHashRefWithData( $WorksheetFormatDefinition{DEFAULT} ) ) {
            %DefaultFormatDefinition = %{ $WorksheetFormatDefinition{DEFAULT} };
        }

        my $LastColumn;
        my $LastRow = int scalar @{ $WorksheetData{TableData} };

        # Performance change #3:
        # Reduces the memory load from 260 MB to 240 MB for 10_000 tickets
        my $Row;
        ROW:
        while ( defined( $Row = shift @{ $WorksheetData{TableData} } ) ) {

            my $ColumnCounter = 0;
            $RowCounter++;

            my %RowFormatDefinition;

            # get format definition for last row
            # or current row if given
            if (
                $RowCounter == $LastRow
                && $WorksheetFormatDefinition{LASTROW}
                )
            {
                %RowFormatDefinition = %{ $WorksheetFormatDefinition{LASTROW} };
            }
            elsif ( IsHashRefWithData( $WorksheetFormatDefinition{$RowCounter} ) ) {
                %RowFormatDefinition = %{ $WorksheetFormatDefinition{$RowCounter} };
            }

            # store row height if present
            $RowHeight{$RowCounter} = $RowFormatDefinition{Height};
            $RowHeight{$RowCounter} ||= $DefaultFormatDefinition{Height};

            $LastColumn = int scalar @{$Row};
            CELL:
            for my $Cell ( @{$Row} ) {

                # check if we have a flat csv like structure
                # or if we have an already formatted excel structure
                my %CellData;
                if ( IsStringWithData($Cell) ) {
                    $CellData{Value} = $Cell;
                }
                elsif ( IsHashRefWithData($Cell) ) {
                    %CellData = %{$Cell};
                }

                # make sure that the value is at least an empty string
                if ( !defined $CellData{Value} ) {
                    $CellData{Value} = '';
                }

                # check if we have to extend the column width
                # otherwise it may be not visible completely
                # in Excel / OpenOffice
                # it will be set after each cell was checked
                # for its width
                if ( IsStringWithData( $CellData{Value} ) ) {
                    if ( !$ColumnWidth{$ColumnCounter} ) {
                        $ColumnWidth{$ColumnCounter} = 1.1 * int length $CellData{Value};
                    }
                    elsif ( $ColumnWidth{$ColumnCounter} && $ColumnWidth{$ColumnCounter} < int length $CellData{Value} )
                    {
                        $ColumnWidth{$ColumnCounter} = 1.1 * int length $CellData{Value};
                    }
                }

                # width column identifiers are starting with 0
                # but with 1 when used with merge
                # so we have to increase it after the width check
                $ColumnCounter++;

                # build cell identifier for format definition
                # lookup and merge start and end information
                my $ColumnIdentifier = $Self->GetColumnIdentifierByNumber(
                    ColumnNumber => $ColumnCounter
                );
                my $CellIdentifier = $ColumnIdentifier . $RowCounter;

                # get format definition for last column
                # or current column if given
                my %ColumnFormatDefinition;
                if (
                    $ColumnCounter == $LastColumn
                    && $WorksheetFormatDefinition{LASTCOLUMN}
                    )
                {
                    %ColumnFormatDefinition = %{ $WorksheetFormatDefinition{LASTCOLUMN} };
                }
                elsif ( IsHashRefWithData( $WorksheetFormatDefinition{$ColumnIdentifier} ) ) {
                    %ColumnFormatDefinition = %{ $WorksheetFormatDefinition{$ColumnIdentifier} };
                }

                # get format definition for current column if given
                my %CellFormatDefinition;
                if ( IsHashRefWithData( $WorksheetFormatDefinition{$CellIdentifier} ) ) {
                    %CellFormatDefinition = %{ $WorksheetFormatDefinition{$CellIdentifier} };
                }

                # get and convert format if given
                my %Format = $Self->MergeFormatDefinitions(
                    Merge             => $WorksheetFormatDefinition{MergeFormatDefinitions},
                    FormatDefinitions => [
                        $CellFormatDefinition{Format},
                        $RowFormatDefinition{Format},
                        $ColumnFormatDefinition{Format},
                        $Merge{Format},
                        $CellData{Format},
                        $DefaultFormatDefinition{Format},
                    ],
                );

                # merge definitions
                my %MergedDefinitions = (
                    %DefaultFormatDefinition,
                    %CellData,
                    %Merge,
                    %ColumnFormatDefinition,
                    %RowFormatDefinition,
                    %CellFormatDefinition,
                );

                # overwrite column width if defined
                if ( $MergedDefinitions{Width} ) {

                    # decrease since we had increased it already
                    my $ColumnWidthCounter = $ColumnCounter - 1;

                    # overwrite
                    $ColumnWidth{$ColumnWidthCounter} = int $MergedDefinitions{Width};
                }

                # check if we have a merge cell
                if ( $CellData{Merge} ) {

                    # special handling for first merge cell
                    if ( int $CellData{Merge} == 1 ) {

                        # check if the previous cells have to get merged
                        if (%Merge) {

                            my $Format = $Workbook->add_format(%Format);
                            $Worksheet->merge_range(
                                $Merge{MergeStart} . ':' . $Merge{MergeEnd},
                                $Merge{Value}, $Format
                            );

                            # clear data
                            %Merge = ();
                        }

                        # take format and value from first merge cell
                        $Merge{Format} = $CellData{Format};
                        $Merge{Value}  = $CellData{Value} || '';

                        # store first merge cell in merge info data
                        $Merge{MergeStart} = $CellIdentifier;
                    }

                    # store last cell in merge info data
                    # will be overwritten till the last
                    # cell will be arrived
                    $Merge{MergeEnd} = $CellIdentifier;
                }

                # if merge data is present we need to check if we have:
                # a) a new cell that is no part of the merge
                # b) a merged cell that is the last in the row
                # c) a skippable merge cell where no 'write' is necessary
                if (%Merge) {

                    # write value and merge cell for case a) or b)
                    if (
                        !$CellData{Merge}
                        || $ColumnCounter == int scalar @{$Row}
                        )
                    {
                        my $Format = $Workbook->add_format(%Format);
                        $Worksheet->merge_range( $Merge{MergeStart} . ':' . $Merge{MergeEnd}, $Merge{Value}, $Format );

                        %Merge = ();
                    }

                    # skip further write for case b) or c)
                    next CELL if $CellData{Merge};
                }

                # content format sanity check
                my $ColumnContentFormat = $Self->GetColumnContentFormat(
                    Value  => $CellData{Value},
                    Format => \%Format,
                );

                if (
                    IsStringWithData( $MergedDefinitions{ContentFormat} )
                    && grep { lc $MergedDefinitions{ContentFormat} eq lc $_ } qw( String Number DateTime )
                    )
                {
                    $ColumnContentFormat = $MergedDefinitions{ContentFormat};
                }

                # color handling
                my %DefaultColorsMapping = (
                    bg_color => 'white',
                    color    => 'black',
                );

                COLORELEMENT:
                for my $CurrentColorElement (qw(bg_color color)) {

                    next COLORELEMENT if !$Format{$CurrentColorElement};
                    next COLORELEMENT if $Format{$CurrentColorElement} !~ /^[0-9a-f]{6}$/i;

                    if ( !$ColorStorage{ $Format{$CurrentColorElement} } ) {

                        if ( $ColorIndex >= 0 ) {
                            $ColorStorage{ $Format{$CurrentColorElement} }
                                = $Workbook->set_custom_color( $ColorIndex, '#' . $Format{$CurrentColorElement} );
                            $ColorIndex--;
                        }
                        else {
                            $LogObject->Log(
                                Priority => 'error',
                                Message =>
                                    "More than 64 colors used in statistic formatting. Falling back to default color '$DefaultColorsMapping{$CurrentColorElement}'.",
                            );
                            $ColorStorage{ $Format{$CurrentColorElement} }
                                = $DefaultColorsMapping{$CurrentColorElement};
                        }
                    }

                    $Format{$CurrentColorElement} = $ColorStorage{ $Format{$CurrentColorElement} };
                }

                # prevent formulas
                $CellData{Value} =~ s{\A=}{ =}m;

                # Yes, empty Formats are really expensive!
                # Performance change #1:
                # Reduces the memory load from 2_600 MB to 460 MB for 10_000 tickets
                my $Format;

                # write_number
                if ( lc $ColumnContentFormat eq lc 'Number' ) {

                    if (%Format) {
                        $Format = $Workbook->add_format(%Format);
                    }
                    $Worksheet->write_number( $RowCounter - 1, $ColumnCounter - 1, $CellData{Value}, $Format );
                }

                # write_string
                elsif ( lc $ColumnContentFormat eq lc 'String' ) {

                    if (%Format) {
                        $Format = $Workbook->add_format(%Format);
                    }
                    $Worksheet->write_string( $RowCounter - 1, $ColumnCounter - 1, $CellData{Value}, $Format );
                }

                # write_url
                elsif ( lc $ColumnContentFormat eq lc 'URL' ) {

                    if (%Format) {
                        $Format = $Workbook->add_format(%Format);
                    }

                    if ( $CellData{Value} =~ m{(http.*?:\/\/[^\s)\"]+)}xm ) {
                        $Worksheet->write_url( $RowCounter - 1, $ColumnCounter - 1, $1, $Format );
                    }

                    # also write string if exists
                    $Worksheet->write_string( $RowCounter - 1, $ColumnCounter - 1, $CellData{Value}, $Format );
                }
                elsif
                    (
                    lc $ColumnContentFormat eq lc 'DateTime'
                    && $CellData{Value} =~ m{(\d{2,4})-(\d{1,2})-(\d{1,2})(?:\s(\d{1,2}):(\d{1,2}):(\d{1,2}))?}xm
                    )
                {
                    $Format{num_format} = $MergedDefinitions{DateFormat};
                    my $DefaultDateFormat = 'yyyy-mm-dd';

                    # Change to the date format required by write_date_time().
                    my $DateValue = sprintf "%4d-%02d-%02dT", $1, $2, $3;
                    if ( $4 && $5 && $6 ) {
                        $DateValue         .= sprintf "%02d:%02d:%02d", $4, $5, $6;
                        $DefaultDateFormat .= ' hh:mm';
                    }
                    $Format{num_format} ||= $DefaultDateFormat;

                    if (%Format) {
                        $Format = $Workbook->add_format(%Format);
                    }
                    $Worksheet->write_date_time( $RowCounter - 1, $ColumnCounter - 1, $DateValue, $Format );
                }

                # write without content content format information
                else {

                    if (%Format) {
                        $Format = $Workbook->add_format(%Format);
                    }
                    $Worksheet->write( $RowCounter - 1, $ColumnCounter - 1, $CellData{Value}, $Format );
                }
            }
        }

        # loop over the collected column widths
        # and write it to the the worksheet
        for my $ColumnID ( sort keys %ColumnWidth ) {
            $Worksheet->set_column( $ColumnID, $ColumnID, $ColumnWidth{$ColumnID} );
        }

        # loop over the collected row height
        # and write it to the worksheet
        for my $RowCounter ( sort keys %RowHeight ) {

            my $Height = $RowHeight{$RowCounter};

            # we have to reduce the row counter since the worksheet needs IDs
            $Worksheet->set_row( $RowCounter - 1, $Height );
        }

        # after everything else is done we can now freeze panes, if needed
        my @FreezePanes;
        if ( IsArrayRefWithData( $WorksheetFormatDefinition{FreezePanes} ) ) {
            @FreezePanes = @{ $WorksheetFormatDefinition{FreezePanes} };
        }
        elsif ( IsArrayRefWithData( $WorksheetData{FreezePanes} ) ) {
            @FreezePanes = @{ $WorksheetData{FreezePanes} };
        }

        for my $FreezePane (@FreezePanes) {

            my %FreezePane;
            for my $Key (qw(Row TopRow)) {
                $FreezePane{$Key} = $Self->_ReplaceDataSeries(
                    Type    => 'LastRow',
                    LastRow => $LastRow,
                    Value   => $FreezePane->{$Key},
                );
            }
            for my $Key (qw(Column LeftColumn)) {
                $FreezePane{$Key} = $Self->_ReplaceDataSeries(
                    Type       => 'LastColumn',
                    LastColumn => $LastColumn,
                    Value      => $FreezePane->{$Key},
                );
            }

            $Worksheet->freeze_panes(
                $FreezePane{Row}, $FreezePane{Column}, $FreezePane{TopRow},
                $FreezePane{LeftColumn}
            );
        }

        # after everything else is done we can now set auto filters, if needed
        my @Autofilters;
        if ( IsArrayRefWithData( $WorksheetFormatDefinition{Autofilters} ) ) {
            @Autofilters = @{ $WorksheetFormatDefinition{Autofilters} };
        }
        elsif ( IsArrayRefWithData( $WorksheetData{Autofilters} ) ) {
            @Autofilters = @{ $WorksheetData{Autofilters} };
        }

        for my $Autofilter (@Autofilters) {

            my %Autofilter;
            for my $Key (qw(FirstRow LastRow)) {
                $Autofilter{$Key} = $Self->_ReplaceDataSeries(
                    Type    => 'LastRow',
                    LastRow => $LastRow,
                    Value   => $Autofilter->{$Key},
                );
            }
            for my $Key (qw(FirstColumn LastColumn)) {
                $Autofilter{$Key} = $Self->_ReplaceDataSeries(
                    Type       => 'LastColumn',
                    LastColumn => $LastColumn,
                    Value      => $Autofilter->{$Key},
                );
            }

            $Worksheet->autofilter(
                $Autofilter{FirstRow} - 1, $Autofilter{FirstColumn} - 1, $Autofilter{LastRow} - 1,
                $Autofilter{LastColumn} - 1
            );
        }

        # after everything else is done we can now merge ranges, if needed
        my @MergeRanges;
        if ( IsArrayRefWithData( $WorksheetFormatDefinition{MergeRanges} ) ) {
            @MergeRanges = @{ $WorksheetFormatDefinition{MergeRanges} };
        }
        elsif ( IsArrayRefWithData( $WorksheetData{MergeRanges} ) ) {
            @MergeRanges = @{ $WorksheetData{MergeRanges} };
        }

        for my $MergeRange (@MergeRanges) {

            my $Format;
            if ( IsHashRefWithData( $MergeRange->{Format} ) ) {
                $Format = $Workbook->add_format(
                    %{ $MergeRange->{Format} },
                );
            }

            $Worksheet->merge_range( $MergeRange->{Range}, $MergeRange->{Text}, $Format );
        }
    }

    # close workbook and write
    # information to temporary file
    $Workbook->close();

    # get content from temporary file
    my $Content = '';
    if ( open( my $ExcelFH, "<", $Filename ) ) {    ## no critic
        while (<$ExcelFH>) {
            $Content .= $_;
        }
        close $ExcelFH;
    }
    else {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Can't open temporary excel file '$Filename': $!",
        );
        return;
    }

    return $Content if $Content;

    $LogObject->Log(
        Priority => 'error',
        Message  => "No content in temporary excel file '$Filename': $!",
    );
    return;
}

=head2 GetColumnIdentifierByNumber()

Returns the column identifier for a number since columns are identified by chars e.g. A, Z or A..Z.

    my $ColumnIdentifier = $ExcelObject->GetColumnIdentifierByNumber(
        ColumnNumber => 27,
    );

Returns:

    my $ColumnIdentifier = 'ZA';

=cut

sub GetColumnIdentifierByNumber {
    my ( $Self, %Param ) = @_;

    my @ColumnIdentifiers             = qw(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z);
    my $ColumnNumber                  = $Param{ColumnNumber};
    my $ColumnIdentifierPrefix        = '';
    my $ColumnIdentifierPrefixCounter = 0;

    while ( int $ColumnNumber > int scalar @ColumnIdentifiers ) {

        $ColumnIdentifierPrefixCounter = $ColumnNumber;

        $ColumnNumber = $ColumnNumber % 26 || 26;

        $ColumnIdentifierPrefixCounter = $ColumnIdentifierPrefixCounter - $ColumnNumber;
    }

    my $ColumnIdentifier = '';
    if ($ColumnIdentifierPrefixCounter) {
        $ColumnIdentifier .= $Self->GetColumnIdentifierByNumber(
            ColumnNumber => $ColumnIdentifierPrefixCounter / 26,
        );
    }
    $ColumnIdentifier .= $ColumnIdentifiers[ $ColumnNumber - 1 ];

    return $ColumnIdentifier;
}

=head2 GetFormatDefinition()

Returns a hash reference of the giving stats/statsnumber.

    my $GetFormatDefinition = $ExcelObject->GetFormatDefinition(
        Stat => $Stat,
    );

Returns:

    my $GetFormatDefinition = {
        'Name' => 'Worksheet',
        '1' => {
            'Format' => {
                'align'    => 'center',
                'bg_color' => 'silver',
                'bold'     => '1',
                'border'   => '1',
                'valign'   => 'vcentre'
            }
        },
        'B3' => {
            'Format' => {
                'bold' => '1'
            }
        },
        'D' => {
            'Format' => {
                'align'  => 'center',
                'bold'   => '1',
                'color'  => 'red',
                'valign' => 'vcentre'
            }
        },
        'FreezePanes' => [
            {
                'Column' => '0',
                'Row' => '1'
            }
        ],
        'H' => {
            'Format' => {
                'align'    => 'center',
                'bg_color' => 'ccffff',
                'bold'     => '1',
                'color'    => 'ED053B',
                'valign'   => 'vcentre'
            }
        },
        'LASTCOLUMN' => {
            'Format' => {
                'border' => '1'
            }
        },
        'LASTROW' => {
            'Format' => {
                'bold'   => '1',
                'bottom' => '1'
            }
        },
    };

=cut

sub GetFormatDefinition {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');
    my $MainObject   = $Kernel::OM->Get('Kernel::System::Main');
    my $YAMLObject   = $Kernel::OM->Get('Kernel::System::YAML');

    my $FormatDefinition      = {};
    my @FormatDefinitionFiles = ('DEFAULT');
    if ( IsHashRefWithData( $Param{Stat} ) ) {
        push @FormatDefinitionFiles, $Param{Stat}->{StatNumber};

        if (
            IsHashRefWithData( $Param{Stat}->{ObjectBehaviours} )
            && $Param{Stat}->{ObjectBehaviours}->{ExcelFormatDefinition}
            && $Kernel::OM->Get( $Param{Stat}->{ObjectModule} )->can('ExcelFormatDefinition')
            )
        {
            $FormatDefinition = $Kernel::OM->Get( $Param{Stat}->{ObjectModule} )->ExcelFormatDefinition();
        }
    }

    FILE:
    for my $FormatDefinitionFile (@FormatDefinitionFiles) {
        my $FormatDefinitionFileLocation = $ConfigObject->Get('Home')
            . '/var/stats/formatdefinition/excel/'
            . $FormatDefinitionFile . '.yml';

        next FILE if !-e $FormatDefinitionFileLocation;

        # read format definition file
        my $FormatDefinitionContent = $MainObject->FileRead(
            Location => $FormatDefinitionFileLocation,
        );

        if ( !$FormatDefinitionContent ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Can't read format definition file '$FormatDefinitionFileLocation'!"
            );
            next FILE;
        }

        my $FileFormatDefinition = $YAMLObject->Load(
            Data => ${$FormatDefinitionContent}
        );

        if ( !$FileFormatDefinition ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Invalid YAML structure in format definition file '$FormatDefinitionFileLocation'!"
            );
            next FILE;
        }

        $FormatDefinition = Hash::Merge::merge(
            $FileFormatDefinition,
            $FormatDefinition
        );
    }

    return                   if !defined $FormatDefinition;
    return $FormatDefinition if IsHashRefWithData($FormatDefinition);
    return $FormatDefinition if IsArrayRefWithData($FormatDefinition);

    my $ErrorMessage = 'Invalid format definition';

    if ( IsHashRefWithData( $Param{Stat} ) ) {
        $ErrorMessage .= " for statistic with StatNumber '" . $Param{Stat}->{StatNumber}
            . "', ObjectModule '" . $Param{Stat}->{ObjectModule} . "'";
    }
    $ErrorMessage .= '.';

    $LogObject->Log(
        Priority => 'error',
        Message  => $ErrorMessage,
    );

    return;
}

=head2 GetColumnContentFormat()

Returns the ColumnContentFormat.

    my $ColumnContentFormat = $ExcelObject->GetColumnContentFormat(
        Value  => '123',
        Format => {},
    );

Returns:

    my $ColumnContentFormat = 'String';     # String, URL, DateTime, Number

=cut

sub GetColumnContentFormat {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    NEEDED:
    for my $Needed (qw(Value)) {

        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my %Format;
    if ( $Param{Format} ) {
        %Format = %{ $Param{Format} };
    }
    my $ColumnContentFormat = 'String';

    # if catch date times like 2016-01-14 17:06:57 in a user / agent cell, remove 'out of office' and date part
    # Test test *** out of office until 2016-12-15 (31 d left) ***
    # or use more general regex '(.*)\s\*\*\*\sout\sof\soffice\suntil.*'
    if (
        $Param{Value}
        =~ m{(.*)\s\*\*\*\sout\sof\soffice\suntil\s(\d{2,4})-(\d{1,2})-(\d{1,2})(?:\s(\d{1,2}):(\d{1,2}):(\d{1,2}))?.*}
        )
    {
        $Param{Value}
            =~ s/\s\*\*\*\sout\sof\soffice\suntil\s(\d{2,4})-(\d{1,2})-(\d{1,2})(?:\s(\d{1,2}):(\d{1,2}):(\d{1,2}))?.*//g;
        $ColumnContentFormat = 'String';
    }

    # OutOfOffice
    if (
        $Param{Value}
        =~ m{(.*)\s\*\*\*\slogged\sout\s\*\*\*\s\*\*\*\sout\sof\soffice\still\s(\d{2,4})-(\d{1,2})-(\d{1,2})(?:\s(\d{1,2}):(\d{1,2}):(\d{1,2}))?.*}
        )
    {
        $Param{Value}
            =~ s/(.*)\s\*\*\*\slogged\sout\s\*\*\*\s\*\*\*\sout\sof\soffice\still\s(\d{2,4})-(\d{1,2})-(\d{1,2})(?:\s(\d{1,2}):(\d{1,2}):(\d{1,2}))?.*//g;
        $ColumnContentFormat = 'String';
    }

    # catch urls like https://www.znuny.com/
    elsif ( $Param{Value} =~ m{(http.*?:\/\/[^\s)\"]+)} ) {
        $ColumnContentFormat = 'URL';
    }

    # catch date times like 2016-01-14 17:06:57
    elsif ( $Param{Value} =~ m{\A(\d{2,4})-(\d{1,2})-(\d{1,2})(?:\s(\d{1,2}):(\d{1,2}):(\d{1,2}))?} ) {
        $ColumnContentFormat = 'DateTime';
    }
    elsif ( $Param{Value} =~ m{^\s?\-?\d+\s?$}xms ) {

   # http://stackoverflow.com/questions/27608592/how-to-disable-the-scientific-notation-when-working-with-perl-and-excel
        if ( length $Param{Value} > 15 ) {
            $Format{num_format} = '@';
        }
        else {
            $ColumnContentFormat = 'Number';
        }
    }

    return $ColumnContentFormat;
}

=head2 MergeFormatDefinitions()

Return merged format definitions as hash.

    my %Format = $ExcelObject->MergeFormatDefinitions(
        Merge             => 1,                 # if 1, merges all format definitions from last to first in array 'FormatDefinitions'
                                                # if 0, use the first format definitions in array 'FormatDefinitions'
        FormatDefinitions => [
            # $CellFormatDefinition{Format},
            {
                'color' => 'silver',
                'right' => 1,
                'valign' => 'vcentre',
            },
            # $RowFormatDefinition{Format},
            {
                'color' => 'red',
                'right' => 0,
                'bold'  => 1,
            },
            # $ColumnFormatDefinition{Format},
            # $Merge{Format},
            # $CellData{Format},
            # $DefaultFormatDefinition{Format},
        ],
    );

Returns:

    my %Format = (
        'color'  => 'silver',
        'right'  => 1,
        'bold'   => 1,
        'valign' => 'vcentre',
    );

=cut

sub MergeFormatDefinitions {
    my ( $Self, %Param ) = @_;

    my $Result = {};
    if ( $Param{Merge} ) {
        my @MergedDefinitions = grep { IsHashRefWithData($_) } @{ $Param{FormatDefinitions} };

        for my $MergedDefinition ( reverse @MergedDefinitions ) {
            $Result = {
                %{$Result},
                %{$MergedDefinition},
            };
        }
    }
    else {

        DEFINITION:
        for my $FormatDefinition ( @{ $Param{FormatDefinitions} } ) {
            next DEFINITION if !IsHashRefWithData($FormatDefinition);
            $Result = $FormatDefinition;
            last DEFINITION;
        }
    }

    return () if !IsHashRefWithData($Result);
    return %{$Result};
}

=head2 _ReplaceDataSeries()

Replaces given value with 'LastRow' or 'LastColumn' if defined.

    my $Value = $ExcelObject->_ReplaceDataSeries(
        Type    => 'LastRow',
        LastRow => 'NewValue',
        Value   => 1,

        # or

        Type       => 'LastColumn',
        LastColumn => 'NewValue',
        Value      => 1,
    );

Returns:

    my $Value = 1;

=cut

sub _ReplaceDataSeries {
    my ( $Self, %Param ) = @_;

    return $Param{Value} if !$Param{LastRow} && !$Param{LastColumn};

    return $Param{Value} if !IsStringWithData( $Param{Value} );
    return $Param{Value} if lc $Param{Value} ne lc $Param{Type};
    return $Param{ $Param{Type} };
}

1;
