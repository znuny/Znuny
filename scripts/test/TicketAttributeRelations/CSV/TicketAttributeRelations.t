# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));

use Kernel::System::VariableCheck qw(:all);

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);

my $HelperObject                   = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $CSVObject                      = $Kernel::OM->Get('Kernel::System::CSV');
my $TicketAttributeRelationsObject = $Kernel::OM->Get('Kernel::System::TicketAttributeRelations');

my $UserID = 1;

my @CSVFileContent = (
    [
        [ 'DynamicField_UnitTestDropdown1', 'DynamicField_UnitTestDropdown2' ],
        [ 'a',                              '1' ],
        [ 'b',                              '2' ],
        [ 'c',                              '3' ],
    ],
    [
        [ 'DynamicField_UnitTestDropdown3', 'DynamicField_UnitTestDropdown4' ],
        [ 'w',                              '5' ],
        [ 'x',                              '50' ],
        [ 'y',                              '26' ],
        [ 'z',                              '9' ],
    ],
    [
        [ 'DynamicField_UnitTestDropdown5', 'DynamicField_UnitTestDropdown6' ],
        [ 'f',                              '372' ],
        [ 'i',                              '157' ],
    ],
);

my $GenerateCSVFileStrings = sub {
    my (%Param) = @_;

    my @CSVFileStrings;
    for my $CSVFileContent ( @{ $Param{CSVFileContent} } ) {
        my $CSVString = $CSVObject->Array2CSV(
            Data      => $CSVFileContent,
            Separator => ';',
            Quote     => '"',
            Format    => 'CSV',
        );

        push @CSVFileStrings, $CSVString;
    }

    return @CSVFileStrings;
};

my @CSVFileStrings = &$GenerateCSVFileStrings( CSVFileContent => \@CSVFileContent );

#
# Create structure in the following form:
#
# my @TicketAttributeRelationsData = (
#     [
#         {
#             DynamicField_UnitTestDropdown1 => 'a',
#             DynamicField_UnitTestDropdown2 => '1',
#         },
#         {
#             DynamicField_UnitTestDropdown1 => 'b',
#             DynamicField_UnitTestDropdown2 => '2',
#         },
#         {
#             DynamicField_UnitTestDropdown1 => 'c',
#             DynamicField_UnitTestDropdown2 => '3',
#         },
#     ],
#     # ...
# );
#
my $GenerateTicketAttributeRelationsData = sub {
    my (%Param) = @_;

    my @TicketAttributeRelationsData;
    for my $CSVFileContent ( @{ $Param{CSVFileContent} } ) {
        my @CurrentTicketAttributeRelationsData;

        my ( $Attribute1, $Attribute2 );

        my $RowIndex = 0;
        ROW:
        for my $Row ( @{$CSVFileContent} ) {
            if ( $RowIndex == 0 ) {
                ( $Attribute1, $Attribute2 ) = @{$Row};
            }
            else {
                push @CurrentTicketAttributeRelationsData, {
                    $Attribute1 => $Row->[0],
                    $Attribute2 => $Row->[1],
                };
            }

            $RowIndex++;
        }

        push @TicketAttributeRelationsData, \@CurrentTicketAttributeRelationsData;
    }

    return @TicketAttributeRelationsData;
};

my @TicketAttributeRelationsData = &$GenerateTicketAttributeRelationsData( CSVFileContent => \@CSVFileContent );

my $GenerateExpectedTicketAttributeRelations = sub {
    my (%Param) = @_;

    my @ExpectedTicketAttributeRelations;

    my $FileIndex = 0;
    for my $CSVFileString ( @{ $Param{CSVFileStrings} } ) {
        my $Filename = "unit-test-$FileIndex.csv";
        my $Priority = $FileIndex + 1;

        my $ID = $TicketAttributeRelationsObject->AddTicketAttributeRelations(
            Filename => $Filename,
            Data     => $CSVFileString,
            Priority => $Priority,
            UserID   => $UserID,
        );

        $Self->True(
            $ID,
            'AddTicketAttributeRelations() must return ID of created record.',
        );

        my %ExpectedTicketAttributeRelations = (
            ID         => $ID,
            Filename   => $Filename,
            Priority   => $Priority,
            Attribute1 => $Param{CSVFileContent}->[$FileIndex]->[0]->[0],
            Attribute2 => $Param{CSVFileContent}->[$FileIndex]->[0]->[1],
            RawData    => $CSVFileString,
            Data       => $Param{TicketAttributeRelationsData}->[$FileIndex],
        );
        push @ExpectedTicketAttributeRelations, \%ExpectedTicketAttributeRelations;

        my $TicketAttributeRelations = $TicketAttributeRelationsObject->GetTicketAttributeRelations(
            ID     => $ID,
            UserID => $UserID,
        );

        # Delete some irrelevant fields from fetched ticket attribute relations
        # that cannot be easily verified/compared.
        for my $FieldName (qw(CreatedBy CreatedTime ChangedBy ChangeTime)) {
            delete $TicketAttributeRelations->{$FieldName};
        }

        $Self->IsDeeply(
            $TicketAttributeRelations,
            \%ExpectedTicketAttributeRelations,
            'GetTicketAttributeRelations() must return expected data when called with parameter "ID".',
        );

        #
        # Also test GetTicketAttributeRelations with parameter "Filename" instead of "ID".
        #
        my $TicketAttributeRelationsByFilename = $TicketAttributeRelationsObject->GetTicketAttributeRelations(
            Filename => $Filename,
            UserID   => $UserID,
        );

        # Delete some irrelevant fields from fetched ticket attribute relations
        # that cannot be easily verified/compared.
        for my $FieldName (qw(CreatedBy CreatedTime ChangedBy ChangeTime)) {
            delete $TicketAttributeRelationsByFilename->{$FieldName};
        }

        $Self->IsDeeply(
            $TicketAttributeRelationsByFilename,
            \%ExpectedTicketAttributeRelations,
            'GetTicketAttributeRelations() must return expected data when called with parameter "Filename".',
        );

        $FileIndex++;
    }

    return @ExpectedTicketAttributeRelations;
};

my @ExpectedTicketAttributeRelations = &$GenerateExpectedTicketAttributeRelations(
    CSVFileStrings               => \@CSVFileStrings,
    CSVFileContent               => \@CSVFileContent,
    TicketAttributeRelationsData => \@TicketAttributeRelationsData,
);

my $TestGetAllTicketAttributeRelations = sub {
    my (%Param) = @_;

    my $AllTicketAttributeRelations = $TicketAttributeRelationsObject->GetAllTicketAttributeRelations(
        UserID => $UserID,
    );

    for my $ExpectedTicketAttributeRelations ( @{ $Param{ExpectedTicketAttributeRelations} } ) {
        my @FoundTicketAttributeRelations = grep { $_->{ID} == $ExpectedTicketAttributeRelations->{ID} }
            @{$AllTicketAttributeRelations};

        $Self->Is(
            scalar @FoundTicketAttributeRelations,
            1,
            'GetTicketAttributeRelations() must contain ticket attribute relations record with expected ID.',
        );

        my $FoundTicketAttributeRelations = shift @FoundTicketAttributeRelations;

        # Delete some irrelevant fields from fetched ticket attribute relations
        # that cannot be easily verified/compared.
        for my $FieldName (qw(CreatedBy CreatedTime ChangedBy ChangeTime)) {
            delete $FoundTicketAttributeRelations->{$FieldName};
        }

        $Self->IsDeeply(
            $FoundTicketAttributeRelations,
            $ExpectedTicketAttributeRelations,
            'GetAllTicketAttributeRelations() must return expected data.',
        );
    }
};

&$TestGetAllTicketAttributeRelations( ExpectedTicketAttributeRelations => \@ExpectedTicketAttributeRelations );

#
# Update priority of second element from 2 to 1.
#
# Should result in priorities:
# Element 1 => 2
# Element 2 => 1,
# Element 3 => 3, # unchanged
#
my $TicketAttributeRelationsUpdated = $TicketAttributeRelationsObject->UpdateTicketAttributeRelations(
    ID       => $ExpectedTicketAttributeRelations[1]->{ID},
    Filename => $ExpectedTicketAttributeRelations[1]->{Filename},
    Data     => $CSVFileStrings[1],
    Priority => 1,
    UserID   => $UserID,
);

# Update expected priorities in expected data.
$ExpectedTicketAttributeRelations[0]->{Priority} = 2;
$ExpectedTicketAttributeRelations[1]->{Priority} = 1;
$ExpectedTicketAttributeRelations[2]->{Priority} = 3;    # unchanged

$Self->True(
    scalar $TicketAttributeRelationsUpdated,
    'UpdateTicketAttributeRelations() must be successful.',
);

&$TestGetAllTicketAttributeRelations( ExpectedTicketAttributeRelations => \@ExpectedTicketAttributeRelations );

#
# Update priority of second element from 1 to 3.
#
# Should result in priorities:
# Element 1 => 1
# Element 2 => 3,
# Element 3 => 2,
#
$TicketAttributeRelationsUpdated = $TicketAttributeRelationsObject->UpdateTicketAttributeRelations(
    ID       => $ExpectedTicketAttributeRelations[1]->{ID},
    Filename => $ExpectedTicketAttributeRelations[1]->{Filename},
    Data     => $CSVFileStrings[1],
    Priority => 3,
    UserID   => $UserID,
);

# Update expected priorities in expected data.
$ExpectedTicketAttributeRelations[0]->{Priority} = 1;
$ExpectedTicketAttributeRelations[1]->{Priority} = 3;
$ExpectedTicketAttributeRelations[2]->{Priority} = 2;

$Self->True(
    scalar $TicketAttributeRelationsUpdated,
    'UpdateTicketAttributeRelations() must be successful.',
);

&$TestGetAllTicketAttributeRelations( ExpectedTicketAttributeRelations => \@ExpectedTicketAttributeRelations );

#
# Update content of second CSV file
# Use complete data so that the priority of the generated expected data is correct.
#
my @UpdatedCSVFileContent = (
    [
        [ 'DynamicField_UnitTestDropdown7', 'DynamicField_UnitTestDropdown8' ],
        [ 'w1',                             '52' ],
        [ 'x2',                             '502' ],
        [ 'y3',                             '262' ],
        [ 'z4',                             '92' ],
    ],
);

my @UpdatedCSVFileStrings = &$GenerateCSVFileStrings( CSVFileContent => \@UpdatedCSVFileContent );
my @UpdatedTicketAttributeRelationsData
    = &$GenerateTicketAttributeRelationsData( CSVFileContent => \@UpdatedCSVFileContent );

$ExpectedTicketAttributeRelations[1]->{Attribute1} = 'DynamicField_UnitTestDropdown7';
$ExpectedTicketAttributeRelations[1]->{Attribute2} = 'DynamicField_UnitTestDropdown8';
$ExpectedTicketAttributeRelations[1]->{RawData}    = $UpdatedCSVFileStrings[0];
$ExpectedTicketAttributeRelations[1]->{Data}       = $UpdatedTicketAttributeRelationsData[0];

$TicketAttributeRelationsUpdated = $TicketAttributeRelationsObject->UpdateTicketAttributeRelations(
    ID       => $ExpectedTicketAttributeRelations[1]->{ID},
    Filename => $ExpectedTicketAttributeRelations[1]->{Filename},
    Data     => $ExpectedTicketAttributeRelations[1]->{RawData},

    #     Priority => 3, # not part of the update
    UserID => $UserID,
);

&$TestGetAllTicketAttributeRelations( ExpectedTicketAttributeRelations => \@ExpectedTicketAttributeRelations );

#
# Tests for ExistsTicketAttributeRelationsFilename
#
for my $ExpectedTicketAttributeRelations (@ExpectedTicketAttributeRelations) {
    my $TicketAttributeRelationsID = $TicketAttributeRelationsObject->ExistsTicketAttributeRelationsFilename(
        Filename => $ExpectedTicketAttributeRelations->{Filename},
    );

    $Self->Is(
        scalar $TicketAttributeRelationsID,
        $ExpectedTicketAttributeRelations->{ID},
        'ExistsTicketAttributeRelationsFilename() must return expected ID.',
    );
}

my $TicketAttributeRelationsID = $TicketAttributeRelationsObject->ExistsTicketAttributeRelationsFilename(
    Filename => 'NONEXISTINGNAME',
);

$Self->False(
    scalar $TicketAttributeRelationsID,
    'ExistsTicketAttributeRelationsFilename() must not return an ID for an unknown filename.',
);

#
# Deletion of ticket attribute relations.
#
while ( my $ExpectedTicketAttributeRelations = shift @ExpectedTicketAttributeRelations ) {
    my $TicketAttributeRelationsID = $ExpectedTicketAttributeRelations->{ID};

    my $TicketAttributeRelatiobsDeleted = $TicketAttributeRelationsObject->DeleteTicketAttributeRelations(
        ID     => $TicketAttributeRelationsID,
        UserID => $UserID,
    );

    $Self->True(
        scalar $TicketAttributeRelatiobsDeleted,
        'DeleteTicketAttributeRelations() must be successful.',
    );

    # Update priorities of remaining expected ticket attribute relations to match the one stored
    # in the database.
    my @RemainingExpectedTicketAttributeRelations = @ExpectedTicketAttributeRelations;
    @RemainingExpectedTicketAttributeRelations
        = sort { $a->{Priority} <=> $b->{Priority} } @RemainingExpectedTicketAttributeRelations;

    my $Priority = 1;
    for my $RemainingExpectedTicketAttributeRelations (@RemainingExpectedTicketAttributeRelations) {
        $RemainingExpectedTicketAttributeRelations->{Priority} = $Priority;
        $Priority++;
    }

    &$TestGetAllTicketAttributeRelations(
        ExpectedTicketAttributeRelations => \@RemainingExpectedTicketAttributeRelations
    );
}

1;
