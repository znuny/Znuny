# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));

# get config object
my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

# theres is not really needed to add the dynamic fields for this test, we can define a static
# set of configurations
my %DynamicFieldConfigs = (
    Text => {
        ID            => 123,
        InternalField => 0,
        Name          => 'TextField',
        Label         => 'TextField',
        FieldOrder    => 123,
        FieldType     => 'Text',
        ObjectType    => 'Ticket',
        Config        => {
            DefaultValue => '',
            Link         => '',
        },
        ValidID    => 1,
        CreateTime => '2011-02-08 15:08:00',
        ChangeTime => '2011-06-11 17:22:00',
    },
    TextArea => {
        ID            => 123,
        InternalField => 0,
        Name          => 'TextAreaField',
        Label         => 'TextAreaField',
        FieldOrder    => 123,
        FieldType     => 'TextArea',
        ObjectType    => 'Ticket',
        Config        => {
            DefaultValue => '',
            Rows         => '',
            Cols         => '',
        },
        ValidID    => 1,
        CreateTime => '2011-02-08 15:08:00',
        ChangeTime => '2011-06-11 17:22:00',
    },
    Checkbox => {
        ID            => 123,
        InternalField => 0,
        Name          => 'CheckboxField',
        Label         => 'CheckboxField',
        FieldOrder    => 123,
        FieldType     => 'Checkbox',
        ObjectType    => 'Ticket',
        Config        => {
            DefaultValue => '',
        },
        ValidID    => 1,
        CreateTime => '2011-02-08 15:08:00',
        ChangeTime => '2011-06-11 17:22:00',
    },
    Dropdown => {
        ID            => 123,
        InternalField => 0,
        Name          => 'DropdownField',
        Label         => 'DropdownField',
        FieldOrder    => 123,
        FieldType     => 'Dropdown',
        ObjectType    => 'Ticket',
        Config        => {
            DefaultValue       => '',
            Link               => '',
            PossibleNone       => 1,
            TranslatableValues => '',
            PossibleValues     => {
                1 => 'A',
                2 => 'B',
            },
        },
        ValidID    => 1,
        CreateTime => '2011-02-08 15:08:00',
        ChangeTime => '2011-06-11 17:22:00',
    },
    Multiselect => {
        ID            => 123,
        InternalField => 0,
        Name          => 'MultiselectField',
        Label         => 'MultiselectField',
        FieldOrder    => 123,
        FieldType     => 'Multiselect',
        ObjectType    => 'Ticket',
        Config        => {
            DefaultValue       => '',
            PossibleNone       => 1,
            TranslatableValues => '',
            PossibleValues     => {
                1 => 'A',
                2 => 'B',
            },
        },
        ValidID    => 1,
        CreateTime => '2011-02-08 15:08:00',
        ChangeTime => '2011-06-11 17:22:00',
    },
    DateTime => {
        ID            => 123,
        InternalField => 0,
        Name          => 'DateTimeField',
        Label         => 'DateTimeField',
        FieldOrder    => 123,
        FieldType     => 'DateTime',
        ObjectType    => 'Ticket',
        Config        => {
            DefaultValue  => '',
            Link          => '',
            YearsPeriod   => '',
            YearsInFuture => '',
            YearsInPast   => '',
        },
        ValidID    => 1,
        CreateTime => '2011-02-08 15:08:00',
        ChangeTime => '2011-06-11 17:22:00',
    },
    Date => {
        ID            => 123,
        InternalField => 0,
        Name          => 'DateField',
        Label         => 'DateField',
        FieldOrder    => 123,
        FieldType     => 'Date',
        ObjectType    => 'Ticket',
        Config        => {
            DefaultValue  => '',
            Link          => '',
            YearsPeriod   => '',
            YearsInFuture => '',
            YearsInPast   => '',
        },
        ValidID    => 1,
        CreateTime => '2011-02-08 15:08:00',
        ChangeTime => '2011-06-11 17:22:00',
    },
);

# add dynamic field registration settings to the new config object
$ConfigObject->Set(
    Key   => 'DynamicFields::Extension::Backend###100-DFDummy',
    Value => {
        Module => 'scripts::test::sample::DynamicField::DummyBackend',
    },
);

$ConfigObject->Set(
    Key   => 'DynamicFields::Extension::Driver::Text###100-DFDummy',
    Value => {
        Module    => 'scripts::test::sample::DynamicField::Driver::DummyText',
        Behaviors => {
            Dummy1 => 1,
        },
    },
);
$ConfigObject->Set(
    Key   => 'DynamicFields::Extension::Driver::TextArea###100-DFDummy',
    Value => {
        Module    => 'scripts::test::sample::DynamicField::Driver::DummyTextArea',
        Behaviors => {
            Dummy1 => 1,
        },
    },
);
$ConfigObject->Set(
    Key   => 'DynamicFields::Extension::Driver::Checkbox###100-DFDummy',
    Value => {
        Module    => 'scripts::test::sample::DynamicField::Driver::DummyCheckbox',
        Behaviors => {
            Dummy1 => 1,
            Dummy2 => 1,
        },
    },
);
$ConfigObject->Set(
    Key   => 'DynamicFields::Extension::Driver::Dropdown###100-DFDummy',
    Value => {
        Module    => 'scripts::test::sample::DynamicField::Driver::DummyDropdown',
        Behaviors => {
            Dummy1 => 0,
            Dummy2 => 1,
        },
    },
);
$ConfigObject->Set(
    Key   => 'DynamicFields::Extension::Driver::Multiselect###100-DFDummy',
    Value => {
        Module    => 'scripts::test::sample::DynamicField::Driver::DummyMultiselect',
        Behaviors => {
            Dummy1 => 0,
            Dummy2 => 1,
        },
    },
);
$ConfigObject->Set(
    Key   => 'DynamicFields::Extension::Driver::Date###100-DFDummy',
    Value => {
        Module    => 'scripts::test::sample::DynamicField::Driver::DummyDate',
        Behaviors => {
            Dummy1 => 0,
            Dummy2 => 0,
        },
    },
);
$ConfigObject->Set(
    Key   => 'DynamicFields::Extension::Driver::DateTime###100-DFDummy',
    Value => {
        Module => 'scripts::test::sample::DynamicField::Driver::DummyDateTime',
    },
);

# get a new backend object including the extension registrations from the config object
my $DFBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

my @Behaviors = (qw(Dummy1 Dummy2));
my %Functions = (
    Dummy1 => ['DummyFunction1'],
    Dummy2 => ['DummyFunction2'],
);

# define tests
my @Tests = (
    {
        Name   => 'Dynamic Field Text',
        Config => {
            FieldConfig => $DynamicFieldConfigs{Text},
        },
        ExpectedResutls => {
            Functions => {
                DummyFunction1 => 1,
                DummyFunction2 => undef,
            },
            Behaviors => {
                Dummy1 => 1,
                Dummy2 => undef,
            },
        },
    },
    {
        Name   => 'Dynamic Field TextArea',
        Config => {
            FieldConfig => $DynamicFieldConfigs{TextArea},
        },
        ExpectedResutls => {
            Functions => {
                DummyFunction1 => 'TextArea',
                DummyFunction2 => undef,
            },
            Behaviors => {
                Dummy1 => 1,
                Dummy2 => undef,
            },
        },
    },
    {
        Name   => 'Dynamic Field Checkbox',
        Config => {
            FieldConfig => $DynamicFieldConfigs{Checkbox},
        },
        ExpectedResutls => {
            Functions => {
                DummyFunction1 => 1,
                DummyFunction2 => 2,
            },
            Behaviors => {
                Dummy1 => 1,
                Dummy2 => 1,
            },
        },
    },
    {
        Name   => 'Dynamic Field Dropdown',
        Config => {
            FieldConfig => $DynamicFieldConfigs{Dropdown},
        },
        ExpectedResutls => {
            Functions => {
                DummyFunction1 => undef,
                DummyFunction2 => 1,
            },
            Behaviors => {
                Dummy1 => undef,
                Dummy2 => 1,
            },
        },
    },
    {
        Name   => 'Dynamic Field Multiselect',
        Config => {
            FieldConfig => $DynamicFieldConfigs{Multiselect},
        },
        ExpectedResutls => {
            Functions => {
                DummyFunction1 => undef,
                DummyFunction2 => 'Multiselect',
            },
            Behaviors => {
                Dummy1 => undef,
                Dummy2 => 1,
            },
        },
    },
    {
        Name   => 'Dyanmic Field Multiselect',
        Config => {
            FieldConfig => $DynamicFieldConfigs{Multiselect},
        },
        ExpectedResutls => {
            Functions => {
                DummyFunction1 => undef,
                DummyFunction2 => 'Multiselect',
            },
            Behaviors => {
                Dummy1 => undef,
                Dummy2 => 1,
            },
        },
    },
    {
        Name   => 'Dynamic Field Date',
        Config => {
            FieldConfig => $DynamicFieldConfigs{Date},
        },
        ExpectedResutls => {
            Functions => {
                DummyFunction1 => 1,
                DummyFunction2 => 1,
            },
            Behaviors => {
                Dummy1 => undef,
                Dummy2 => undef,
            },
        },
    },
    {
        Name   => 'Dynamic Field DateTime',
        Config => {
            FieldConfig => $DynamicFieldConfigs{DateTime},
        },
        ExpectedResutls => {
            Functions => {
                DummyFunction1 => 'DateTime',
                DummyFunction2 => 'DynamicField',
            },
            Behaviors => {
                Dummy1 => undef,
                Dummy2 => undef,
            },
        },
    },
);

# execute tests
for my $Test (@Tests) {
    for my $Behavior (@Behaviors) {
        my $HasBehaviorResult = $DFBackendObject->HasBehavior(
            DynamicFieldConfig => $Test->{Config}->{FieldConfig},
            Behavior           => $Behavior,
        );

        $Self->Is(
            $HasBehaviorResult,
            $Test->{ExpectedResutls}->{Behaviors}->{$Behavior},
            "$Test->{Name} HasBehavior $Behavior",
        );
        for my $FunctionName ( @{ $Functions{$Behavior} } ) {
            my $FunctionResult = $DFBackendObject->$FunctionName(
                DynamicFieldConfig => $Test->{Config}->{FieldConfig},
            );

            $Self->Is(
                $FunctionResult,
                $Test->{ExpectedResutls}->{Functions}->{$FunctionName},
                "$Test->{Name} Function $FunctionName",
            );
        }
    }
}

# we don't need any cleanup

1;
