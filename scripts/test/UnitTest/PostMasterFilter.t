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

my $ZnunyHelperObject         = $Kernel::OM->Get('Kernel::System::ZnunyHelper');
my $HelperObject              = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $PostMasterFilterObject    = $Kernel::OM->Get('Kernel::System::PostMaster::Filter');
my $YAMLObject                = $Kernel::OM->Get('Kernel::System::YAML');
my $DynamicFieldObject        = $Kernel::OM->Get('Kernel::System::DynamicField');
my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

# delete existing filters
my %FilterList = $PostMasterFilterObject->FilterList();
if (%FilterList) {
    for my $Filter ( sort keys %FilterList ) {
        my $Deleted = $PostMasterFilterObject->FilterDelete(
            Name => $Filter,
        );
        $Self->True(
            $Deleted,
            'FilterDelete() - Delete existing filter with name:' . $Filter,
        );
    }
}

my $DynamicFieldName = 'NameOfDynamicField' . $HelperObject->GetRandomID();

my $DFCreated = $DynamicFieldObject->DynamicFieldAdd(
    InternalField => 0,
    Name          => $DynamicFieldName,
    Label         => 'a description',
    FieldOrder    => 999,
    FieldType     => 'Text',
    ObjectType    => 'Ticket',
    Config        => {},
    ValidID       => 1,
    UserID        => 1,
);

$Self->True(
    $DFCreated,
    'DynamicFieldAdd() - Add dynamic field that will be used in "Set" configuration of filters',
);

my @Filters = (
    {
        'Match' => {
            'Auto-Submitted' => '123',
            'From'           => '.*?@somemail1.com',
            'To'             => '.*?@somemail2.com',
        },
        'Name' => 'filter 1',
        'Not'  => {
            'Auto-Submitted' => undef,
            'From'           => undef,
            'To'             => undef,
        },
        'Set' => {
            "X-OTRS-DynamicField-$DynamicFieldName" => '123'
        },
        'StopAfterMatch' => '0'
    },
    {
        'Match' => {
            'Body' => '123',
            'Cc'   => '.*?@somemail1.com',
        },
        'Name' => 'filter 2',
        'Not'  => {
            'Body' => undef,
            'Cc'   => 1,
        },
        'Set' => {
            "X-OTRS-DynamicField-$DynamicFieldName" => '321'
        },
        'StopAfterMatch' => '1'
    },
);
my $Result = $ZnunyHelperObject->_PostMasterFilterCreate(@Filters);

$Self->True(
    $Result,
    '_PostMasterFilterCreate()',
);

for my $Filter (@Filters) {
    my %ConvertedStructure;
    for my $Attribute (qw(Match Not Set)) {
        $ConvertedStructure{$Attribute} = [
            map { Key => $_, Value => $Filter->{$Attribute}->{$_} }, sort keys %{ $Filter->{$Attribute} }
        ];
    }
    $Filter->{ConvertedStructure} = \%ConvertedStructure;
}

# export all filters
my $ExportDataMultiple = $PostMasterFilterObject->FilterExport(
    ExportAll => 1,
);

my @FiltersConverted = map {
    { ( %{$_}, %{ $_->{ConvertedStructure} } ) }
} @Filters;

for my $Filter (@FiltersConverted) {
    delete $Filter->{ConvertedStructure};
}

$Self->IsDeeply(
    $ExportDataMultiple,
    \@FiltersConverted,
    "FilterExport - Export all filters (Name: $Filters[0]->{Name}, $Filters[1]->{Name})",
);

# export single filter
my $ExportDataSingle = $PostMasterFilterObject->FilterExport(
    Name => $FiltersConverted[0]->{Name},
);

my $ExportExpectedDataSingle = [ $FiltersConverted[0] ];

$Self->IsDeeply(
    $ExportDataSingle,
    $ExportExpectedDataSingle,
    "FilterExport - Export all filters (Name: $Filters[0]->{Name}, $Filters[1]->{Name})",
);

my $ValidFiltersContentDataYAML = $YAMLObject->Dump( Data => $ExportDataMultiple );

# import previously exported filters with the same name
my $FilterImport = $PostMasterFilterObject->FilterImport(
    Content                  => $ValidFiltersContentDataYAML,
    OverwriteExistingFilters => 0,
);

my $FiltersNameStrg = "$Filters[0]->{Name}, $Filters[1]->{Name}";

$Self->IsDeeply(
    $FilterImport,
    {
        'Updated'          => '',
        'AdditionalErrors' => [],
        'Errors'           => '',
        'Added'            => '',
        'Success'          => 1,
        'NotUpdated'       => $FiltersNameStrg,
    },
    "FilterImport - Import filters when other filters with the same name ($FiltersNameStrg) already exists, OverwriteExistingFilters set to 0",
);

# import previously exported filters with the same name, while trying to overwrite them
$FilterImport = $PostMasterFilterObject->FilterImport(
    Content                  => $ValidFiltersContentDataYAML,
    OverwriteExistingFilters => 1,
);

$Self->IsDeeply(
    $FilterImport,
    {
        'Added'            => '',
        'AdditionalErrors' => [],
        'Errors'           => '',
        'NotUpdated'       => '',
        'Success'          => 1,
        'Updated'          => $FiltersNameStrg,
    },
    "FilterImport - Import filters when other filters with the same name ($FiltersNameStrg) already exists, OverwriteExistingFilters set to 1",
);

# delete all filters
for my $Filter (@Filters) {
    my $Deleted = $PostMasterFilterObject->FilterDelete(
        Name => $Filter->{Name},
    );
    $Self->True(
        $Deleted,
        'FilterDelete() - Delete existing filter with name: ' . $Filter->{Name},
    );
}

# import filter configurations with some errors
my $InvalidExportData = $ExportDataMultiple;

# check if error will occur due to invalid regex
$InvalidExportData->[0]->{Match}->[0]->{Value} = '*SomeInvalidRegex';

# check missing key error
delete $InvalidExportData->[1]->{Match}->[0]->{Key};

my $InValidFiltersContentDataYAML = $YAMLObject->Dump( Data => $InvalidExportData );

# import previously exported filters with the same name
$FilterImport = $PostMasterFilterObject->FilterImport(
    Content                  => $InValidFiltersContentDataYAML,
    OverwriteExistingFilters => 1,
);

my $ErrorsImportResponse = {
    'Errors'           => $FiltersNameStrg,
    'AdditionalErrors' => [],
    'Success'          => 1,
    'Updated'          => '',
    'NotUpdated'       => '',
    'Added'            => ''
};

$Self->IsDeeply(
    $FilterImport,
    $ErrorsImportResponse,
    "FilterImport - Import invalid configuration of filters",
);

# now import valid configuration of filters
# import previously exported filters
$FilterImport = $PostMasterFilterObject->FilterImport(
    Content                  => $ValidFiltersContentDataYAML,
    OverwriteExistingFilters => 0,
);

my $AddedImportResponse = {
    'Added'            => 'filter 1, filter 2',
    'NotUpdated'       => '',
    'Updated'          => '',
    'Errors'           => '',
    'Success'          => 1,
    'AdditionalErrors' => []
};
$Self->IsDeeply(
    $FilterImport,
    $AddedImportResponse,
    "FilterImport - Import valid configuration of filters",
);

# copy filter that does not exists
my $NewFilterName = $PostMasterFilterObject->FilterCopy(
    Name => 'filter-' . $HelperObject->GetRandomID(),
);

$Self->False(
    $NewFilterName,
    'FilterCopy() - Copy filter that does not exists',
);

# copy filter that does exists
$NewFilterName = $PostMasterFilterObject->FilterCopy(
    Name => $Filters[0]->{Name},
);

$Self->True(
    $NewFilterName,
    'FilterCopy() - Copy filter that does exists',
);

1;
