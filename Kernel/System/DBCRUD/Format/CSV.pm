# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::DBCRUD::Format::CSV;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::CSV',
);

use Kernel::System::VariableCheck qw(:all);

=head1 NAME

Kernel::System::DBCRUD::Format::CSV - DBCRUD CSV lib

=head1 SYNOPSIS

All DBCRUD format CSV functions.

=head1 PUBLIC INTERFACE

=head2 new()

create an object

    my $DBCRUDCSVObject = $Kernel::OM->Get('Kernel::System::DBCRUD::Format::CSV');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    $Self->{CacheType} = 'DBCRUDCSV';
    $Self->{CacheTTL}  = 60 * 60 * 24 * 20;

    for my $Item ( sort keys %Param ) {
        $Self->{$Item} = $Param{$Item};
    }

    return $Self;
}

=head2 GetContent()

return content of CSV String as array-ref.

    my $Array = $DBCRUDCSVObject->GetContent(
        Content => $ContentString,
    );

Returns:

    my $Array = [];

=cut

sub GetContent {
    my ( $Self, %Param ) = @_;

    my $CSVObject = $Kernel::OM->Get('Kernel::System::CSV');

    my $DataArray = $CSVObject->CSV2Array(
        String => $Param{Content},
    );

    my @Columns = @{ shift @{$DataArray} || [] };
    my @Result;

    ROW:
    for my $CSVRow ( @{$DataArray} ) {
        my %Data;
        for my $ColumnIndex ( 0 .. @Columns - 1 ) {
            $Data{ $Columns[$ColumnIndex] } = $CSVRow->[$ColumnIndex];
        }
        next ROW if !%Data;
        push @Result, \%Data;
    }

    return \@Result;
}

=head2 SetContent()

return content of array as csv string.

    my $ExportString = $DBCRUDCSVObject->SetContent(
        Content => $Array,
    );

Returns:

    my $ExportString = '---';

=cut

sub SetContent {
    my ( $Self, %Param ) = @_;

    my $CSVObject    = $Kernel::OM->Get('Kernel::System::CSV');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    my $ExportConfig = $ConfigObject->Get('DBCRUD')->{Export}->{CSV};
    my $CustomConfig = $ConfigObject->Get( $Self->{ObjectName} )->{Export}->{CSV};

    if ( IsHashRefWithData($CustomConfig) ) {
        $ExportConfig = $CustomConfig;
    }
    my @Header;

    COLUMN:
    for my $ColumnOrder ( @{ $Param{ColumnsOrder} } ) {
        next COLUMN if !$Param{Content}->[0]->{$ColumnOrder};
        push @Header, $ColumnOrder;
    }

    my @Data;
    for my $Data ( @{ $Param{Content} } ) {
        my @Row;

        # backup for header
        if ( !@Header ) {
            @Header = sort keys %{$Data};
        }

        # create Data for Array2CSV
        for my $Entry (@Header) {
            push @Row, $Data->{$Entry};
        }
        push @Data, [@Row];
    }

    my $ExportString = $CSVObject->Array2CSV(
        Head      => \@Header,
        Data      => \@Data,
        Separator => $ExportConfig->{Separator} || ';',
        Quote     => $ExportConfig->{Quote} || '"',
        Format    => 'CSV',
    );

    return $ExportString;
}

1;
