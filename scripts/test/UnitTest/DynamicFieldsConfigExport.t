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

my $ZnunyHelperObject    = $Kernel::OM->Get('Kernel::System::ZnunyHelper');
my $ConfigObject         = $Kernel::OM->Get('Kernel::Config');
my $UnitTestHelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $YAMLObject           = $Kernel::OM->Get('Kernel::System::YAML');

# Create dynamic fields to test export
my @DynamicFieldConfigs = (
    {
        Name       => $UnitTestHelperObject->GetRandomID(),
        Label      => 'Dynamic field export test 1',
        ObjectType => 'Ticket',
        FieldType  => 'Text',
        Config     => {
            DefaultValue => "",
        },
    },
    {
        Name       => $UnitTestHelperObject->GetRandomID(),
        Label      => 'Dynamic field export test 2',
        ObjectType => 'Ticket',
        FieldType  => 'Text',
        Config     => {
            DefaultValue => "",
        },
    },
);

my $DynamicFieldsCreated = $ZnunyHelperObject->_DynamicFieldsCreate(@DynamicFieldConfigs);

$Self->True(
    scalar $DynamicFieldsCreated,
    'Dynamic fields must have been created successfully.',
);

my $InternalDynamicFieldName = $ConfigObject->Get('Process::DynamicFieldProcessManagementProcessID');
my @OptionalConfigKeys       = (qw(ChangeTime CreateTime ID InternalField ValidID));

# Test export
my @Tests = (
    {
        Name         => 'Export as Perl structure with internal fields and all config keys',
        ExportParams => {
            Format                => 'perl',
            IncludeInternalFields => 1,
            IncludeAllConfigKeys  => 1,
        },
    },
    {
        Name         => 'Export as Perl structure with internal fields and limited config keys',
        ExportParams => {
            Format                => 'perl',
            IncludeInternalFields => 1,
            IncludeAllConfigKeys  => 0,
        },
    },
    {
        Name         => 'Export as Perl structure without internal fields and all config keys',
        ExportParams => {
            Format                => 'perl',
            IncludeInternalFields => 0,
            IncludeAllConfigKeys  => 1,
        },
    },
    {
        Name         => 'Export as Perl structure without internal fields and limited config keys',
        ExportParams => {
            Format                => 'perl',
            IncludeInternalFields => 0,
            IncludeAllConfigKeys  => 0,
        },
    },
    {
        Name         => 'Export as YAML structure with internal fields and all config keys',
        ExportParams => {
            Format                => 'yml',
            IncludeInternalFields => 1,
            IncludeAllConfigKeys  => 1,
        },
    },
    {
        Name         => 'Export as YAML structure with internal fields and limited config keys',
        ExportParams => {
            Format                => 'yml',
            IncludeInternalFields => 1,
            IncludeAllConfigKeys  => 0,
        },
    },
    {
        Name         => 'Export as YAML structure without internal fields and all config keys',
        ExportParams => {
            Format                => 'yml',
            IncludeInternalFields => 0,
            IncludeAllConfigKeys  => 1,
        },
    },
    {
        Name         => 'Export as YAML structure without internal fields and limited config keys',
        ExportParams => {
            Format                => 'yml',
            IncludeInternalFields => 0,
            IncludeAllConfigKeys  => 0,
        },
    },
    {
        Name         => 'Export as value (array) with internal fields and all config keys',
        ExportParams => {
            Format                => 'var',
            Result                => 'array',
            IncludeInternalFields => 1,
            IncludeAllConfigKeys  => 1,
        },
    },
    {
        Name         => 'Export as value (hash) with internal fields and all config keys',
        ExportParams => {
            Format                => 'var',
            Result                => 'hash',
            IncludeInternalFields => 1,
            IncludeAllConfigKeys  => 1,
        },
    },
    {
        Name =>
            'Export as value (hash) with internal fields and all config keys, but restricted to the one created dynamic field',
        ExportParams => {
            Format                => 'var',
            Result                => 'hash',
            IncludeInternalFields => 1,
            IncludeAllConfigKeys  => 1,
            DynamicFields         => [
                $DynamicFieldConfigs[0]->{Name},
            ],
        },
    },
);

TEST:
for my $Test (@Tests) {
    my $Export = $ZnunyHelperObject->_DynamicFieldsConfigExport( %{ $Test->{ExportParams} } );

    # Turn export into Perl structure.
    if ( $Test->{ExportParams}->{Format} eq 'perl' ) {
        $Export =~ s{\A(\$VAR1)}{\$Export};
        eval $Export;    ## nofilter(TidyAll::Plugin::Znuny::Perl::PerlCritic)
    }
    elsif ( $Test->{ExportParams}->{Format} eq 'yml' ) {
        $Export = $YAMLObject->Load(
            Data => $Export,
        );
    }
    elsif ( $Test->{ExportParams}->{Format} eq 'var' ) {

        # do nothing, export is already a perl value
    }
    else {
        return;
    }

    # turn hash into array
    if ( defined $Test->{ExportParams}->{Result} && $Test->{ExportParams}->{Result} eq 'hash' ) {
        $Export = [ values %{$Export} ];
    }

    # check if export has been restricted to the given dynamic fields
    my %RestrictToDynamicFields;
    if ( IsArrayRefWithData( $Test->{ExportParams}->{DynamicFields} ) ) {
        %RestrictToDynamicFields = map { $_ => 1 } @{ $Test->{ExportParams}->{DynamicFields} };
        for my $ExportedDynamicFieldConfig ( @{$Export} ) {
            $Self->True(
                $RestrictToDynamicFields{ $ExportedDynamicFieldConfig->{Name} },
                "$Test->{Name} - Dynamic field $ExportedDynamicFieldConfig->{Name} must not be contained in export.",
            );
        }
    }

    # Check for created dynamic fields
    EXPECTEDDYNAMICFIELDCONFIG:
    for my $ExpectedDynamicFieldConfig (@DynamicFieldConfigs) {
        next EXPECTEDDYNAMICFIELDCONFIG
            if %RestrictToDynamicFields && !$RestrictToDynamicFields{ $ExpectedDynamicFieldConfig->{Name} };

        my @ExportedDynamicFieldConfigs = grep { $_->{Name} eq $ExpectedDynamicFieldConfig->{Name} } @{$Export};

        $Self->Is(
            scalar @ExportedDynamicFieldConfigs,
            1,
            "$Test->{Name} - Dynamic field must be found in export.",
        ) || next TEST;

        my $ExportedDynamicFieldConfig = shift @ExportedDynamicFieldConfigs;

        # Compare some field values
        for my $Field (qw(Label ObjectType FieldType)) {
            $Self->Is(
                $ExportedDynamicFieldConfig->{$Field},
                $ExpectedDynamicFieldConfig->{$Field},
                "$Test->{Name} - Value of field $Field must match expected one.",
            );
        }

        # Internal fields must be included if parameter IncludeInternalFields has been given.
        # This will be tested with one of the standard OTRS dynamic fields of process management.
        my @ExportedInternalDynamicFieldConfigs = grep { $_->{Name} eq $InternalDynamicFieldName } @{$Export};
        if (
            $Test->{ExportParams}->{IncludeInternalFields}
            && (
                !%RestrictToDynamicFields
                || $RestrictToDynamicFields{$InternalDynamicFieldName}
            )
            )
        {
            $Self->Is(
                scalar @ExportedInternalDynamicFieldConfigs,
                1,
                "$Test->{Name} - Internal dynamic field $InternalDynamicFieldName must be found in export.",
            );
        }
        else {
            $Self->Is(
                scalar @ExportedInternalDynamicFieldConfigs,
                0,
                "$Test->{Name} - Internal dynamic field $InternalDynamicFieldName must not be found in export.",
            );
        }

        # Check that certain config keys are (not) present in the export.
        for my $OptionalConfigKey (@OptionalConfigKeys) {
            if ( $Test->{ExportParams}->{IncludeAllConfigKeys} ) {
                $Self->True(
                    exists $ExportedDynamicFieldConfig->{$OptionalConfigKey},
                    "$Test->{Name} - Config key $OptionalConfigKey must be found in export.",
                );
            }
            else {
                $Self->False(
                    exists $ExportedDynamicFieldConfig->{$OptionalConfigKey},
                    "$Test->{Name} - Config key $OptionalConfigKey must not be found in export.",
                );
            }
        }
    }
}

1;
