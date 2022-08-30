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

use Kernel::Output::HTML::Layout;

use Kernel::System::VariableCheck qw(:all);

# get needed objects
my $HelperObject    = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $DFBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
my $ParamObject     = $Kernel::OM->Get('Kernel::System::Web::Request');

# use a fixed year to compare the time selection results
$HelperObject->FixedTimeSet(
    $Kernel::OM->Create(
        'Kernel::System::DateTime',
        ObjectParams => {
            String => '2013-12-12 00:00:00',
        },
    )->ToEpoch()
);

my $LayoutObject = Kernel::Output::HTML::Layout->new(
    Lang         => 'en',
    UserTimeZone => 'UTC',
);

my $UserID = 1;

# theres is not really needed to add the dynamic fields for this test, we can define a static
# set of configurations
my %DynamicFieldConfigs = (
    Text => {
        ID            => 123,
        InternalField => 0,
        Name          => 'TextField',
        Label         => 'TextField <special chars="äüø">',
        LabelEscaped  => 'TextField &lt;special chars=&quot;äüø&quot;&gt;',
        FieldOrder    => 123,
        FieldType     => 'Text',
        ObjectType    => 'Ticket',
        Config        => {
            DefaultValue => 'Default',
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
        Label         => 'TextAreaField <special chars="äüø">',
        LabelEscaped  => 'TextAreaField &lt;special chars=&quot;äüø&quot;&gt;',
        FieldOrder    => 123,
        FieldType     => 'TextArea',
        ObjectType    => 'Ticket',
        Config        => {
            DefaultValue => "Multi\nLine",
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
        Label         => 'CheckboxField <special chars="äüø">',
        LabelEscaped  => 'CheckboxField &lt;special chars=&quot;äüø&quot;&gt;',
        FieldOrder    => 123,
        FieldType     => 'Checkbox',
        ObjectType    => 'Ticket',
        Config        => {
            DefaultValue => '1',
        },
        ValidID    => 1,
        CreateTime => '2011-02-08 15:08:00',
        ChangeTime => '2011-06-11 17:22:00',
    },
    Dropdown => {
        ID            => 123,
        InternalField => 0,
        Name          => 'DropdownField',
        Label         => 'DropdownField <special chars="äüø">',
        LabelEscaped  => 'DropdownField &lt;special chars=&quot;äüø&quot;&gt;',
        FieldOrder    => 123,
        FieldType     => 'Dropdown',
        ObjectType    => 'Ticket',
        Config        => {
            DefaultValue       => 2,
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
        Label         => 'MultiselectField <special chars="äüø">',
        LabelEscaped  => 'MultiselectField &lt;special chars=&quot;äüø&quot;&gt;',
        FieldOrder    => 123,
        FieldType     => 'Multiselect',
        ObjectType    => 'Ticket',
        Config        => {
            DefaultValue       => 2,
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
        Label         => 'DateTimeField <special chars="äüø">',
        LabelEscaped  => 'DateTimeField &lt;special chars=&quot;äüø&quot;&gt;',
        FieldOrder    => 123,
        FieldType     => 'DateTime',
        ObjectType    => 'Ticket',
        Config        => {
            DefaultValue  => '2013-08-21 16:45:00',
            Link          => '',
            YearsPeriod   => '1',
            YearsInFuture => '5',
            YearsInPast   => '5',
        },
        ValidID    => 1,
        CreateTime => '2011-02-08 15:08:00',
        ChangeTime => '2011-06-11 17:22:00',
    },
    Date => {
        ID            => 123,
        InternalField => 0,
        Name          => 'DateField',
        Label         => 'DateField <special chars="äüø">',
        LabelEscaped  => 'DateField &lt;special chars=&quot;äüø&quot;&gt;',
        FieldOrder    => 123,
        FieldType     => 'Date',
        ObjectType    => 'Ticket',
        Config        => {
            DefaultValue  => '2013-08-21 00:00:00',
            Link          => '',
            YearsPeriod   => '1',
            YearsInFuture => '5',
            YearsInPast   => '5',
        },
        ValidID    => 1,
        CreateTime => '2011-02-08 15:08:00',
        ChangeTime => '2011-06-11 17:22:00',
    },
);

# define tests
my @Tests = (
    {
        Name    => 'No Params',
        Config  => undef,
        Success => 0,
    },

    {
        Name    => 'Empty Config',
        Config  => {},
        Success => 0,
    },
    {
        Name   => 'Missing DynamicFieldConfig',
        Config => {
            DynamicFieldConfig => undef,
        },
        Success => 0,
    },
    {
        Name   => 'Missing LayoutObject',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{Text},
            LayoutObject       => undef,
            ParamObject        => $ParamObject,
        },
        Success => 0,
    },
    {
        Name   => 'Missing ParamObject',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{Text},
            LayoutObject       => $LayoutObject,
            ParamObject        => undef,
        },
        Success => 0,
    },

    # Dynamic Field Text
    {
        Name   => 'Text: No value',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{Text},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Class              => 'MyClass',
            UseDefaultValue    => 0,
        },
        ExpectedResults => {
            Field => <<"EOF",
<input type="text" class="DynamicFieldText W50pc MyClass" id="DynamicField_$DynamicFieldConfigs{Text}->{Name}" name="DynamicField_$DynamicFieldConfigs{Text}->{Name}" title="$DynamicFieldConfigs{Text}->{LabelEscaped}" value="" />
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{Text}->{Name}" for="DynamicField_$DynamicFieldConfigs{Text}->{Name}">
$DynamicFieldConfigs{Text}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },
    {
        Name   => 'Text: No value / Default',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{Text},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Class              => 'MyClass',
        },
        ExpectedResults => {
            Field => <<"EOF",
<input type="text" class="DynamicFieldText W50pc MyClass" id="DynamicField_$DynamicFieldConfigs{Text}->{Name}" name="DynamicField_$DynamicFieldConfigs{Text}->{Name}" title="$DynamicFieldConfigs{Text}->{LabelEscaped}" value="Default" />
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{Text}->{Name}" for="DynamicField_$DynamicFieldConfigs{Text}->{Name}">
$DynamicFieldConfigs{Text}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },
    {
        Name   => 'Text: special chars',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{Text},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Value              => '<special chars="äüø">',
            Class              => 'MyClass',
        },
        ExpectedResults => {
            Field => <<"EOF",
<input type="text" class="DynamicFieldText W50pc MyClass" id="DynamicField_$DynamicFieldConfigs{Text}->{Name}" name="DynamicField_$DynamicFieldConfigs{Text}->{Name}" title="$DynamicFieldConfigs{Text}->{LabelEscaped}" value="&lt;special chars=&quot;äüø&quot;&gt;" />
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{Text}->{Name}" for="DynamicField_$DynamicFieldConfigs{Text}->{Name}">
$DynamicFieldConfigs{Text}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },
    {
        Name   => 'Text: UTF8 value direct',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{Text},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Value              => 'äëïöüÄËÏÖÜáéíóúÁÉÍÓÚñÑ€исß',
            Class              => 'MyClass',
            UseDefaultValue    => 0,
        },
        ExpectedResults => {
            Field => <<"EOF",
<input type="text" class="DynamicFieldText W50pc MyClass" id="DynamicField_$DynamicFieldConfigs{Text}->{Name}" name="DynamicField_$DynamicFieldConfigs{Text}->{Name}" title="$DynamicFieldConfigs{Text}->{LabelEscaped}" value="äëïöüÄËÏÖÜáéíóúÁÉÍÓÚñÑ€исß" />
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{Text}->{Name}" for="DynamicField_$DynamicFieldConfigs{Text}->{Name}">
$DynamicFieldConfigs{Text}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },
    {
        Name   => 'Text: UTF8 value web request',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{Text},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Class              => 'MyClass',
            UseDefaultValue    => 0,
            CGIParam           => {
                DynamicField_TextField => 'äëïöüÄËÏÖÜáéíóúÁÉÍÓÚñÑ€исß',
            },
        },
        ExpectedResults => {
            Field => <<"EOF",
<input type="text" class="DynamicFieldText W50pc MyClass" id="DynamicField_$DynamicFieldConfigs{Text}->{Name}" name="DynamicField_$DynamicFieldConfigs{Text}->{Name}" title="$DynamicFieldConfigs{Text}->{LabelEscaped}" value="äëïöüÄËÏÖÜáéíóúÁÉÍÓÚñÑ€исß" />
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{Text}->{Name}" for="DynamicField_$DynamicFieldConfigs{Text}->{Name}">
$DynamicFieldConfigs{Text}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },
    {
        Name   => 'Text: UTF8 value template',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{Text},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Class              => 'MyClass',
            UseDefaultValue    => 0,
            Template           => {
                DynamicField_TextField => 'äëïöüÄËÏÖÜáéíóúÁÉÍÓÚñÑ€исß',
            },
        },
        ExpectedResults => {
            Field => <<"EOF",
<input type="text" class="DynamicFieldText W50pc MyClass" id="DynamicField_$DynamicFieldConfigs{Text}->{Name}" name="DynamicField_$DynamicFieldConfigs{Text}->{Name}" title="$DynamicFieldConfigs{Text}->{LabelEscaped}" value="äëïöüÄËÏÖÜáéíóúÁÉÍÓÚñÑ€исß" />
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{Text}->{Name}" for="DynamicField_$DynamicFieldConfigs{Text}->{Name}">
$DynamicFieldConfigs{Text}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },
    {
        Name   => 'Text: Mandatory',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{Text},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Value              => 'A Value',
            Class              => 'MyClass',
            UseDefaultValue    => 0,
            Mandatory          => 1,
        },
        ExpectedResults => {
            Field => <<"EOF",
<input type="text" class="DynamicFieldText W50pc MyClass Validate_Required" id="DynamicField_$DynamicFieldConfigs{Text}->{Name}" name="DynamicField_$DynamicFieldConfigs{Text}->{Name}" title="$DynamicFieldConfigs{Text}->{LabelEscaped}" value="A Value" />
<div id="DynamicField_$DynamicFieldConfigs{Text}->{Name}Error" class="TooltipErrorMessage">
    <p>
        This field is required.
    </p>
</div>
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{Text}->{Name}" for="DynamicField_$DynamicFieldConfigs{Text}->{Name}" class="Mandatory">
    <span class="Marker">*</span>
$DynamicFieldConfigs{Text}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },
    {
        Name   => 'Text: Server Error',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{Text},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Value              => 'A Value',
            Class              => 'MyClass',
            UseDefaultValue    => 0,
            ServerError        => 1,
            ErrorMessage       => 'This is an error.'
        },
        ExpectedResults => {
            Field => <<"EOF",
<input type="text" class="DynamicFieldText W50pc MyClass ServerError" id="DynamicField_$DynamicFieldConfigs{Text}->{Name}" name="DynamicField_$DynamicFieldConfigs{Text}->{Name}" title="$DynamicFieldConfigs{Text}->{LabelEscaped}" value="A Value" />
<div id="DynamicField_$DynamicFieldConfigs{Text}->{Name}ServerError" class="TooltipErrorMessage">
    <p>
        This is an error.
    </p>
</div>
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{Text}->{Name}" for="DynamicField_$DynamicFieldConfigs{Text}->{Name}">
$DynamicFieldConfigs{Text}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },

    # Dynamic Field TextArea
    {
        Name   => 'TextArea: No value',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{TextArea},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Class              => 'MyClass',
            UseDefaultValue    => 0,
        },
        ExpectedResults => {
            Field => <<"EOF",
<textarea class="DynamicFieldTextArea MyClass Validate_MaxLength" id="DynamicField_$DynamicFieldConfigs{TextArea}->{Name}" name="DynamicField_$DynamicFieldConfigs{TextArea}->{Name}" title="$DynamicFieldConfigs{TextArea}->{LabelEscaped}" rows="7" cols="42" data-maxlength="3800"></textarea>
<div id="DynamicField_$DynamicFieldConfigs{TextArea}->{Name}Error" class="TooltipErrorMessage">
    <p>
        The field content is too long! Maximum size is 3800 characters.
    </p>
</div>
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{TextArea}->{Name}" for="DynamicField_$DynamicFieldConfigs{TextArea}->{Name}">
$DynamicFieldConfigs{TextArea}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },
    {
        Name   => 'TextArea: No value / Default',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{TextArea},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Class              => 'MyClass',
        },
        ExpectedResults => {
            Field => <<"EOF",
<textarea class="DynamicFieldTextArea MyClass Validate_MaxLength" id="DynamicField_$DynamicFieldConfigs{TextArea}->{Name}" name="DynamicField_$DynamicFieldConfigs{TextArea}->{Name}" title="$DynamicFieldConfigs{TextArea}->{LabelEscaped}" rows="7" cols="42" data-maxlength="3800">Multi
Line</textarea>
<div id="DynamicField_$DynamicFieldConfigs{TextArea}->{Name}Error" class="TooltipErrorMessage">
    <p>
        The field content is too long! Maximum size is 3800 characters.
    </p>
</div>
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{TextArea}->{Name}" for="DynamicField_$DynamicFieldConfigs{TextArea}->{Name}">
$DynamicFieldConfigs{TextArea}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },
    {
        Name   => 'TextArea: special chars',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{TextArea},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Value              => '<special chars="äüø">',
            Class              => 'MyClass',
        },
        ExpectedResults => {
            Field => <<"EOF",
<textarea class="DynamicFieldTextArea MyClass Validate_MaxLength" id="DynamicField_$DynamicFieldConfigs{TextArea}->{Name}" name="DynamicField_$DynamicFieldConfigs{TextArea}->{Name}" title="$DynamicFieldConfigs{TextArea}->{LabelEscaped}" rows="7" cols="42" data-maxlength="3800">&lt;special chars=&quot;äüø&quot;&gt;</textarea>
<div id="DynamicField_$DynamicFieldConfigs{TextArea}->{Name}Error" class="TooltipErrorMessage">
    <p>
        The field content is too long! Maximum size is 3800 characters.
    </p>
</div>
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{TextArea}->{Name}" for="DynamicField_$DynamicFieldConfigs{TextArea}->{Name}">
$DynamicFieldConfigs{TextArea}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },
    {
        Name   => 'TextArea: UTF8 value direct',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{TextArea},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Value              => 'äëïöüÄËÏÖÜáéíóúÁÉÍÓÚñÑ€исß',
            Class              => 'MyClass',
            UseDefaultValue    => 0,
        },
        ExpectedResults => {
            Field => <<"EOF",
<textarea class="DynamicFieldTextArea MyClass Validate_MaxLength" id="DynamicField_$DynamicFieldConfigs{TextArea}->{Name}" name="DynamicField_$DynamicFieldConfigs{TextArea}->{Name}" title="$DynamicFieldConfigs{TextArea}->{LabelEscaped}" rows="7" cols="42" data-maxlength="3800">äëïöüÄËÏÖÜáéíóúÁÉÍÓÚñÑ€исß</textarea>
<div id="DynamicField_$DynamicFieldConfigs{TextArea}->{Name}Error" class="TooltipErrorMessage">
    <p>
        The field content is too long! Maximum size is 3800 characters.
    </p>
</div>
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{TextArea}->{Name}" for="DynamicField_$DynamicFieldConfigs{TextArea}->{Name}">
$DynamicFieldConfigs{TextArea}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },
    {
        Name   => 'TextArea: UTF8 value web request',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{TextArea},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Class              => 'MyClass',
            UseDefaultValue    => 0,
            CGIParam           => {
                DynamicField_TextAreaField =>
                    'äëïöüÄËÏÖÜáéíóúÁÉÍÓÚñÑ€исß',
            },
        },
        ExpectedResults => {
            Field => <<"EOF",
<textarea class="DynamicFieldTextArea MyClass Validate_MaxLength" id="DynamicField_$DynamicFieldConfigs{TextArea}->{Name}" name="DynamicField_$DynamicFieldConfigs{TextArea}->{Name}" title="$DynamicFieldConfigs{TextArea}->{LabelEscaped}" rows="7" cols="42" data-maxlength="3800">äëïöüÄËÏÖÜáéíóúÁÉÍÓÚñÑ€исß</textarea>
<div id="DynamicField_$DynamicFieldConfigs{TextArea}->{Name}Error" class="TooltipErrorMessage">
    <p>
        The field content is too long! Maximum size is 3800 characters.
    </p>
</div>
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{TextArea}->{Name}" for="DynamicField_$DynamicFieldConfigs{TextArea}->{Name}">
$DynamicFieldConfigs{TextArea}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },
    {
        Name   => 'TextArea: UTF8 value template',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{TextArea},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Class              => 'MyClass',
            UseDefaultValue    => 0,
            Template           => {
                DynamicField_TextAreaField =>
                    'äëïöüÄËÏÖÜáéíóúÁÉÍÓÚñÑ€исß',
            },
        },
        ExpectedResults => {
            Field => <<"EOF",
<textarea class="DynamicFieldTextArea MyClass Validate_MaxLength" id="DynamicField_$DynamicFieldConfigs{TextArea}->{Name}" name="DynamicField_$DynamicFieldConfigs{TextArea}->{Name}" title="$DynamicFieldConfigs{TextArea}->{LabelEscaped}" rows="7" cols="42" data-maxlength="3800">äëïöüÄËÏÖÜáéíóúÁÉÍÓÚñÑ€исß</textarea>
<div id="DynamicField_$DynamicFieldConfigs{TextArea}->{Name}Error" class="TooltipErrorMessage">
    <p>
        The field content is too long! Maximum size is 3800 characters.
    </p>
</div>
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{TextArea}->{Name}" for="DynamicField_$DynamicFieldConfigs{TextArea}->{Name}">
$DynamicFieldConfigs{TextArea}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },
    {
        Name   => 'TextArea: Mandatory',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{TextArea},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Value              => 'A Value',
            Class              => 'MyClass',
            UseDefaultValue    => 0,
            Mandatory          => 1,
        },
        ExpectedResults => {
            Field => <<"EOF",
<textarea class="DynamicFieldTextArea MyClass Validate_Required Validate_MaxLength" id="DynamicField_$DynamicFieldConfigs{TextArea}->{Name}" name="DynamicField_$DynamicFieldConfigs{TextArea}->{Name}" title="$DynamicFieldConfigs{TextArea}->{LabelEscaped}" rows="7" cols="42" data-maxlength="3800">A Value</textarea>
<div id="DynamicField_$DynamicFieldConfigs{TextArea}->{Name}Error" class="TooltipErrorMessage">
    <p>
        This field is required or The field content is too long! Maximum size is 3800 characters.
    </p>
</div>
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{TextArea}->{Name}" for="DynamicField_$DynamicFieldConfigs{TextArea}->{Name}" class="Mandatory">
    <span class="Marker">*</span>
$DynamicFieldConfigs{TextArea}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },
    {
        Name   => 'TextArea: Server Error',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{TextArea},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Value              => 'A Value',
            Class              => 'MyClass',
            UseDefaultValue    => 0,
            ServerError        => 1,
            ErrorMessage       => 'This is an error.'
        },
        ExpectedResults => {
            Field => <<"EOF",
<textarea class="DynamicFieldTextArea MyClass ServerError Validate_MaxLength" id="DynamicField_$DynamicFieldConfigs{TextArea}->{Name}" name="DynamicField_$DynamicFieldConfigs{TextArea}->{Name}" title="$DynamicFieldConfigs{TextArea}->{LabelEscaped}" rows="7" cols="42" data-maxlength="3800">A Value</textarea>
<div id="DynamicField_$DynamicFieldConfigs{TextArea}->{Name}Error" class="TooltipErrorMessage">
    <p>
        The field content is too long! Maximum size is 3800 characters.
    </p>
</div>
<div id="DynamicField_$DynamicFieldConfigs{TextArea}->{Name}ServerError" class="TooltipErrorMessage">
    <p>
        This is an error.
    </p>
</div>
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{TextArea}->{Name}" for="DynamicField_$DynamicFieldConfigs{TextArea}->{Name}">
$DynamicFieldConfigs{TextArea}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },

    # Dynamic Field Checkbox
    {
        Name   => 'Checkbox: No value',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{Checkbox},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Class              => 'MyClass',
            UseDefaultValue    => 0,
        },
        ExpectedResults => {
            Field => <<"EOF",
<input type="hidden" id="DynamicField_$DynamicFieldConfigs{Checkbox}->{Name}Used" name="DynamicField_$DynamicFieldConfigs{Checkbox}->{Name}Used" value="1" />
<input type="checkbox" class="DynamicFieldCheckbox MyClass" id="DynamicField_$DynamicFieldConfigs{Checkbox}->{Name}" name="DynamicField_$DynamicFieldConfigs{Checkbox}->{Name}" title="$DynamicFieldConfigs{Checkbox}->{LabelEscaped}"  value="1" />
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{Checkbox}->{Name}" for="DynamicField_$DynamicFieldConfigs{Checkbox}->{Name}">
$DynamicFieldConfigs{Checkbox}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },
    {
        Name   => 'Checkbox: No value / Default',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{Checkbox},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Class              => 'MyClass',
        },
        ExpectedResults => {
            Field => <<"EOF",
<input type="hidden" id="DynamicField_$DynamicFieldConfigs{Checkbox}->{Name}Used" name="DynamicField_$DynamicFieldConfigs{Checkbox}->{Name}Used" value="1" />
<input type="checkbox" class="DynamicFieldCheckbox MyClass" id="DynamicField_$DynamicFieldConfigs{Checkbox}->{Name}" name="DynamicField_$DynamicFieldConfigs{Checkbox}->{Name}" title="$DynamicFieldConfigs{Checkbox}->{LabelEscaped}" checked="checked" value="1" />
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{Checkbox}->{Name}" for="DynamicField_$DynamicFieldConfigs{Checkbox}->{Name}">
$DynamicFieldConfigs{Checkbox}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },
    {
        Name   => 'Checkbox: Value direct',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{Checkbox},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Value              => 1,
            Class              => 'MyClass',
            UseDefaultValue    => 0,
        },
        ExpectedResults => {
            Field => <<"EOF",
<input type="hidden" id="DynamicField_$DynamicFieldConfigs{Checkbox}->{Name}Used" name="DynamicField_$DynamicFieldConfigs{Checkbox}->{Name}Used" value="1" />
<input type="checkbox" class="DynamicFieldCheckbox MyClass" id="DynamicField_$DynamicFieldConfigs{Checkbox}->{Name}" name="DynamicField_$DynamicFieldConfigs{Checkbox}->{Name}" title="$DynamicFieldConfigs{Checkbox}->{LabelEscaped}" checked="checked" value="1" />
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{Checkbox}->{Name}" for="DynamicField_$DynamicFieldConfigs{Checkbox}->{Name}">
$DynamicFieldConfigs{Checkbox}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },
    {
        Name   => 'Checkbox: Value web request',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{Checkbox},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Class              => 'MyClass',
            UseDefaultValue    => 0,
            CGIParam           => {
                DynamicField_CheckboxFieldUsed => 1,
                DynamicField_CheckboxField     => 1,
            },
        },
        ExpectedResults => {
            Field => <<"EOF",
<input type="hidden" id="DynamicField_$DynamicFieldConfigs{Checkbox}->{Name}Used" name="DynamicField_$DynamicFieldConfigs{Checkbox}->{Name}Used" value="1" />
<input type="checkbox" class="DynamicFieldCheckbox MyClass" id="DynamicField_$DynamicFieldConfigs{Checkbox}->{Name}" name="DynamicField_$DynamicFieldConfigs{Checkbox}->{Name}" title="$DynamicFieldConfigs{Checkbox}->{LabelEscaped}" checked="checked" value="1" />
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{Checkbox}->{Name}" for="DynamicField_$DynamicFieldConfigs{Checkbox}->{Name}">
$DynamicFieldConfigs{Checkbox}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },
    {
        Name   => 'Checkbox: Value web request (not used)',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{Checkbox},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Class              => 'MyClass',
            UseDefaultValue    => 0,
            CGIParam           => {
                DynamicField_CheckboxFieldUsed => undef,
                DynamicField_CheckboxField     => 1,
            },
        },
        ExpectedResults => {
            Field => <<"EOF",
<input type="hidden" id="DynamicField_$DynamicFieldConfigs{Checkbox}->{Name}Used" name="DynamicField_$DynamicFieldConfigs{Checkbox}->{Name}Used" value="1" />
<input type="checkbox" class="DynamicFieldCheckbox MyClass" id="DynamicField_$DynamicFieldConfigs{Checkbox}->{Name}" name="DynamicField_$DynamicFieldConfigs{Checkbox}->{Name}" title="$DynamicFieldConfigs{Checkbox}->{LabelEscaped}"  value="1" />
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{Checkbox}->{Name}" for="DynamicField_$DynamicFieldConfigs{Checkbox}->{Name}">
$DynamicFieldConfigs{Checkbox}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },
    {
        Name   => 'Checkbox: Value template',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{Checkbox},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Class              => 'MyClass',
            UseDefaultValue    => 0,
            Template           => {
                DynamicField_CheckboxFieldUsed => 1,
                DynamicField_CheckboxField     => 1,
            },
        },
        ExpectedResults => {
            Field => <<"EOF",
<input type="hidden" id="DynamicField_$DynamicFieldConfigs{Checkbox}->{Name}Used" name="DynamicField_$DynamicFieldConfigs{Checkbox}->{Name}Used" value="1" />
<input type="checkbox" class="DynamicFieldCheckbox MyClass" id="DynamicField_$DynamicFieldConfigs{Checkbox}->{Name}" name="DynamicField_$DynamicFieldConfigs{Checkbox}->{Name}" title="$DynamicFieldConfigs{Checkbox}->{LabelEscaped}" checked="checked" value="1" />
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{Checkbox}->{Name}" for="DynamicField_$DynamicFieldConfigs{Checkbox}->{Name}">
$DynamicFieldConfigs{Checkbox}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },
    {
        Name   => 'Checkbox: Value template (not used)',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{Checkbox},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Class              => 'MyClass',
            UseDefaultValue    => 0,
            Template           => {
                DynamicField_CheckboxFieldUsed => undef,
                DynamicField_CheckboxField     => 1,
            },
        },
        ExpectedResults => {
            Field => <<"EOF",
<input type="hidden" id="DynamicField_$DynamicFieldConfigs{Checkbox}->{Name}Used" name="DynamicField_$DynamicFieldConfigs{Checkbox}->{Name}Used" value="1" />
<input type="checkbox" class="DynamicFieldCheckbox MyClass" id="DynamicField_$DynamicFieldConfigs{Checkbox}->{Name}" name="DynamicField_$DynamicFieldConfigs{Checkbox}->{Name}" title="$DynamicFieldConfigs{Checkbox}->{LabelEscaped}"  value="1" />
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{Checkbox}->{Name}" for="DynamicField_$DynamicFieldConfigs{Checkbox}->{Name}">
$DynamicFieldConfigs{Checkbox}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },
    {
        Name   => 'Checkbox: Mandatory',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{Checkbox},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Value              => 1,
            Class              => 'MyClass',
            UseDefaultValue    => 0,
            Mandatory          => 1,
        },
        ExpectedResults => {
            Field => <<"EOF",
<input type="hidden" id="DynamicField_$DynamicFieldConfigs{Checkbox}->{Name}Used" name="DynamicField_$DynamicFieldConfigs{Checkbox}->{Name}Used" value="1" />
<input type="checkbox" class="DynamicFieldCheckbox MyClass Validate_Required" id="DynamicField_$DynamicFieldConfigs{Checkbox}->{Name}" name="DynamicField_$DynamicFieldConfigs{Checkbox}->{Name}" title="$DynamicFieldConfigs{Checkbox}->{LabelEscaped}" checked="checked" value="1" />
<div id="DynamicField_$DynamicFieldConfigs{Checkbox}->{Name}Error" class="TooltipErrorMessage">
    <p>
        This field is required.
    </p>
</div>
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{Checkbox}->{Name}" for="DynamicField_$DynamicFieldConfigs{Checkbox}->{Name}" class="Mandatory">
    <span class="Marker">*</span>
$DynamicFieldConfigs{Checkbox}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },
    {
        Name   => 'Checkbox: Server Error',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{Checkbox},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Value              => 1,
            Class              => 'MyClass',
            UseDefaultValue    => 0,
            ServerError        => 1,
            ErrorMessage       => 'This is an error.'
        },
        ExpectedResults => {
            Field => <<"EOF",
<input type="hidden" id="DynamicField_$DynamicFieldConfigs{Checkbox}->{Name}Used" name="DynamicField_$DynamicFieldConfigs{Checkbox}->{Name}Used" value="1" />
<input type="checkbox" class="DynamicFieldCheckbox MyClass ServerError" id="DynamicField_$DynamicFieldConfigs{Checkbox}->{Name}" name="DynamicField_$DynamicFieldConfigs{Checkbox}->{Name}" title="$DynamicFieldConfigs{Checkbox}->{LabelEscaped}" checked="checked" value="1" />
<div id="DynamicField_$DynamicFieldConfigs{Checkbox}->{Name}ServerError" class="TooltipErrorMessage">
    <p>
        This is an error.
    </p>
</div>
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{Checkbox}->{Name}" for="DynamicField_$DynamicFieldConfigs{Checkbox}->{Name}">
$DynamicFieldConfigs{Checkbox}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },
    {
        Name   => 'Checkbox: Confirmation Needed',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{Checkbox},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Value              => 1,
            Class              => 'MyClass',
            UseDefaultValue    => 0,
            ConfirmationNeeded => 1
        },
        ExpectedResults => {
            Field => <<"EOF",
<input type="radio" id="DynamicField_$DynamicFieldConfigs{Checkbox}->{Name}Used0" name="DynamicField_$DynamicFieldConfigs{Checkbox}->{Name}Used" value="" checked="checked" />
Ignore this field.
<div class="clear"></div>
<input type="radio" id="DynamicField_$DynamicFieldConfigs{Checkbox}->{Name}Used1" name="DynamicField_$DynamicFieldConfigs{Checkbox}->{Name}Used" value="1"  />
<input type="checkbox" class="DynamicFieldCheckbox MyClass" id="DynamicField_$DynamicFieldConfigs{Checkbox}->{Name}" name="DynamicField_$DynamicFieldConfigs{Checkbox}->{Name}" title="$DynamicFieldConfigs{Checkbox}->{LabelEscaped}" checked="checked" value="1" />
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{Checkbox}->{Name}" for="DynamicField_$DynamicFieldConfigs{Checkbox}->{Name}">
$DynamicFieldConfigs{Checkbox}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },

    # Dynamic Field Dropdown
    {
        Name   => 'Dropdown: No value',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{Dropdown},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Class              => 'MyClass',
            UseDefaultValue    => 0,
        },
        ExpectedResults => {
            Field => <<"EOF" . '</select>',
<select class="DynamicFieldText Modernize MyClass" id="DynamicField_$DynamicFieldConfigs{Dropdown}->{Name}" name="DynamicField_$DynamicFieldConfigs{Dropdown}->{Name}" size="1">
  <option value="">-</option>
  <option value="1">A</option>
  <option value="2">B</option>
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{Dropdown}->{Name}" for="DynamicField_$DynamicFieldConfigs{Dropdown}->{Name}">
$DynamicFieldConfigs{Dropdown}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },
    {
        Name   => 'Dropdown: No value / Default',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{Dropdown},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Class              => 'MyClass',
        },
        ExpectedResults => {
            Field => <<"EOF" . '</select>',
<select class="DynamicFieldText Modernize MyClass" id="DynamicField_$DynamicFieldConfigs{Dropdown}->{Name}" name="DynamicField_$DynamicFieldConfigs{Dropdown}->{Name}" size="1">
  <option value="">-</option>
  <option value="1">A</option>
  <option value="2" selected="selected">B</option>
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{Dropdown}->{Name}" for="DynamicField_$DynamicFieldConfigs{Dropdown}->{Name}">
$DynamicFieldConfigs{Dropdown}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },
    {
        Name   => 'Dropdown: Value direct',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{Dropdown},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Value              => 1,
            Class              => 'MyClass',
            UseDefaultValue    => 0,
        },
        ExpectedResults => {
            Field => <<"EOF" . '</select>',
<select class="DynamicFieldText Modernize MyClass" id="DynamicField_$DynamicFieldConfigs{Dropdown}->{Name}" name="DynamicField_$DynamicFieldConfigs{Dropdown}->{Name}" size="1">
  <option value="">-</option>
  <option value="1" selected="selected">A</option>
  <option value="2">B</option>
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{Dropdown}->{Name}" for="DynamicField_$DynamicFieldConfigs{Dropdown}->{Name}">
$DynamicFieldConfigs{Dropdown}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },
    {
        Name   => 'Dropdown: Value web request',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{Dropdown},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Class              => 'MyClass',
            UseDefaultValue    => 0,
            CGIParam           => {
                DynamicField_DropdownField => 1,
            },
        },
        ExpectedResults => {
            Field => <<"EOF" . '</select>',
<select class="DynamicFieldText Modernize MyClass" id="DynamicField_$DynamicFieldConfigs{Dropdown}->{Name}" name="DynamicField_$DynamicFieldConfigs{Dropdown}->{Name}" size="1">
  <option value="">-</option>
  <option value="1" selected="selected">A</option>
  <option value="2">B</option>
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{Dropdown}->{Name}" for="DynamicField_$DynamicFieldConfigs{Dropdown}->{Name}">
$DynamicFieldConfigs{Dropdown}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },
    {
        Name   => 'Dropdown: Value template',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{Dropdown},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Class              => 'MyClass',
            UseDefaultValue    => 0,
            Template           => {
                DynamicField_DropdownField => 1,
            },
        },
        ExpectedResults => {
            Field => <<"EOF" . '</select>',
<select class="DynamicFieldText Modernize MyClass" id="DynamicField_$DynamicFieldConfigs{Dropdown}->{Name}" name="DynamicField_$DynamicFieldConfigs{Dropdown}->{Name}" size="1">
  <option value="">-</option>
  <option value="1" selected="selected">A</option>
  <option value="2">B</option>
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{Dropdown}->{Name}" for="DynamicField_$DynamicFieldConfigs{Dropdown}->{Name}">
$DynamicFieldConfigs{Dropdown}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },
    {
        Name   => 'Dropdown: Mandatory',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{Dropdown},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Value              => 2,
            Class              => 'MyClass',
            UseDefaultValue    => 0,
            Mandatory          => 1,
        },
        ExpectedResults => {
            Field => <<"EOF",
<select class="DynamicFieldText Modernize MyClass Validate_Required" id="DynamicField_$DynamicFieldConfigs{Dropdown}->{Name}" name="DynamicField_$DynamicFieldConfigs{Dropdown}->{Name}" size="1">
  <option value="">-</option>
  <option value="1">A</option>
  <option value="2" selected="selected">B</option>
</select>
<div id="DynamicField_$DynamicFieldConfigs{Dropdown}->{Name}Error" class="TooltipErrorMessage">
    <p>
        This field is required.
    </p>
</div>
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{Dropdown}->{Name}" for="DynamicField_$DynamicFieldConfigs{Dropdown}->{Name}" class="Mandatory">
    <span class="Marker">*</span>
$DynamicFieldConfigs{Dropdown}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },
    {
        Name   => 'Dropdown: Server Error',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{Dropdown},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Value              => 2,
            Class              => 'MyClass',
            UseDefaultValue    => 0,
            ServerError        => 1,
            ErrorMessage       => 'This is an error.'
        },
        ExpectedResults => {
            Field => <<"EOF",
<select class="DynamicFieldText Modernize MyClass ServerError" id="DynamicField_$DynamicFieldConfigs{Dropdown}->{Name}" name="DynamicField_$DynamicFieldConfigs{Dropdown}->{Name}" size="1">
  <option value="">-</option>
  <option value="1">A</option>
  <option value="2" selected="selected">B</option>
</select>
<div id="DynamicField_$DynamicFieldConfigs{Dropdown}->{Name}ServerError" class="TooltipErrorMessage">
    <p>
        This is an error.
    </p>
</div>
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{Dropdown}->{Name}" for="DynamicField_$DynamicFieldConfigs{Dropdown}->{Name}">
$DynamicFieldConfigs{Dropdown}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },
    {
        Name   => 'Dropdown: Possible Values Filter',
        Config => {
            DynamicFieldConfig   => $DynamicFieldConfigs{Dropdown},
            LayoutObject         => $LayoutObject,
            ParamObject          => $ParamObject,
            Value                => 2,
            Class                => 'MyClass',
            UseDefaultValue      => 0,
            PossibleValuesFilter => {
                2 => 'Value2',
            },
        },
        ExpectedResults => {
            Field => <<"EOF" . '</select>',
<select class="DynamicFieldText Modernize MyClass" id="DynamicField_$DynamicFieldConfigs{Dropdown}->{Name}" name="DynamicField_$DynamicFieldConfigs{Dropdown}->{Name}" size="1">
  <option value="2" selected="selected">Value2</option>
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{Dropdown}->{Name}" for="DynamicField_$DynamicFieldConfigs{Dropdown}->{Name}">
$DynamicFieldConfigs{Dropdown}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },
    {
        Name   => 'Dropdown: No Possible None',
        Config => {
            DynamicFieldConfig   => $DynamicFieldConfigs{Dropdown},
            LayoutObject         => $LayoutObject,
            ParamObject          => $ParamObject,
            Value                => 1,
            Class                => 'MyClass',
            UseDefaultValue      => 0,
            OverridePossibleNone => 0,
        },
        ExpectedResults => {
            Field => <<"EOF" . '</select>',
<select class="DynamicFieldText Modernize MyClass" id="DynamicField_$DynamicFieldConfigs{Dropdown}->{Name}" name="DynamicField_$DynamicFieldConfigs{Dropdown}->{Name}" size="1">
  <option value="1" selected="selected">A</option>
  <option value="2">B</option>
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{Dropdown}->{Name}" for="DynamicField_$DynamicFieldConfigs{Dropdown}->{Name}">
$DynamicFieldConfigs{Dropdown}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },
    {
        Name   => 'Dropdown: Confirmation needed',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{Dropdown},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Value              => 1,
            Class              => 'MyClass',
            UseDefaultValue    => 0,
            ConfirmationNeeded => 1,
        },
        ExpectedResults => {
            Field => <<"EOF" . '</select>',
<select class="DynamicFieldText Modernize MyClass" id="DynamicField_$DynamicFieldConfigs{Dropdown}->{Name}" name="DynamicField_$DynamicFieldConfigs{Dropdown}->{Name}" size="5">
  <option value="">-</option>
  <option value="1" selected="selected">A</option>
  <option value="2">B</option>
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{Dropdown}->{Name}" for="DynamicField_$DynamicFieldConfigs{Dropdown}->{Name}">
$DynamicFieldConfigs{Dropdown}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },
    {
        Name   => 'Dropdown: AJAX Options',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{Dropdown},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Value              => 1,
            Class              => 'MyClass',
            UseDefaultValue    => 0,
            AJAXUpdate         => 1,
            UpdatableFields    => [ 'StateID', 'PriorityID', ],
        },
        ExpectedResults => {
            Field => <<"EOF",
<select class="DynamicFieldText Modernize MyClass" id="DynamicField_$DynamicFieldConfigs{Dropdown}->{Name}" name="DynamicField_$DynamicFieldConfigs{Dropdown}->{Name}" size="1">
  <option value="">-</option>
  <option value="1" selected="selected">A</option>
  <option value="2">B</option>
</select>
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{Dropdown}->{Name}" for="DynamicField_$DynamicFieldConfigs{Dropdown}->{Name}">
$DynamicFieldConfigs{Dropdown}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },

    # Dynamic Field Multiselect
    {
        Name   => 'Multiselect: No value',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{Multiselect},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Class              => 'MyClass',
            UseDefaultValue    => 0,
        },
        ExpectedResults => {
            Field => <<"EOF" . '</select>',
<select class="DynamicFieldText Modernize MyClass" id="DynamicField_$DynamicFieldConfigs{Multiselect}->{Name}" multiple="multiple" name="DynamicField_$DynamicFieldConfigs{Multiselect}->{Name}">
  <option value="">-</option>
  <option value="1">A</option>
  <option value="2">B</option>
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{Multiselect}->{Name}" for="DynamicField_$DynamicFieldConfigs{Multiselect}->{Name}">
$DynamicFieldConfigs{Multiselect}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },
    {
        Name   => 'Multiselect: No value / Default',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{Multiselect},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Class              => 'MyClass',
        },
        ExpectedResults => {
            Field => <<"EOF" . '</select>',
<select class="DynamicFieldText Modernize MyClass" id="DynamicField_$DynamicFieldConfigs{Multiselect}->{Name}" multiple="multiple" name="DynamicField_$DynamicFieldConfigs{Multiselect}->{Name}">
  <option value="">-</option>
  <option value="1">A</option>
  <option value="2" selected="selected">B</option>
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{Multiselect}->{Name}" for="DynamicField_$DynamicFieldConfigs{Multiselect}->{Name}">
$DynamicFieldConfigs{Multiselect}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },
    {
        Name   => 'Multiselect: Value direct',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{Multiselect},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Value              => 1,
            Class              => 'MyClass',
            UseDefaultValue    => 0,
        },
        ExpectedResults => {
            Field => <<"EOF" . '</select>',
<select class="DynamicFieldText Modernize MyClass" id="DynamicField_$DynamicFieldConfigs{Multiselect}->{Name}" multiple="multiple" name="DynamicField_$DynamicFieldConfigs{Multiselect}->{Name}">
  <option value="">-</option>
  <option value="1" selected="selected">A</option>
  <option value="2">B</option>
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{Multiselect}->{Name}" for="DynamicField_$DynamicFieldConfigs{Multiselect}->{Name}">
$DynamicFieldConfigs{Multiselect}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },
    {
        Name   => 'Multiselect: Value direct (multiple)',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{Multiselect},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Value              => [ 1, 2 ],
            Class              => 'MyClass',
            UseDefaultValue    => 0,
        },
        ExpectedResults => {
            Field => <<"EOF" . '</select>',
<select class="DynamicFieldText Modernize MyClass" id="DynamicField_$DynamicFieldConfigs{Multiselect}->{Name}" multiple="multiple" name="DynamicField_$DynamicFieldConfigs{Multiselect}->{Name}">
  <option value="">-</option>
  <option value="1" selected="selected">A</option>
  <option value="2" selected="selected">B</option>
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{Multiselect}->{Name}" for="DynamicField_$DynamicFieldConfigs{Multiselect}->{Name}">
$DynamicFieldConfigs{Multiselect}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },
    {
        Name   => 'Multiselect: Value web request',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{Multiselect},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Class              => 'MyClass',
            UseDefaultValue    => 0,
            CGIParam           => {
                DynamicField_MultiselectField => 1,
            },
        },
        ExpectedResults => {
            Field => <<"EOF" . '</select>',
<select class="DynamicFieldText Modernize MyClass" id="DynamicField_$DynamicFieldConfigs{Multiselect}->{Name}" multiple="multiple" name="DynamicField_$DynamicFieldConfigs{Multiselect}->{Name}">
  <option value="">-</option>
  <option value="1" selected="selected">A</option>
  <option value="2">B</option>
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{Multiselect}->{Name}" for="DynamicField_$DynamicFieldConfigs{Multiselect}->{Name}">
$DynamicFieldConfigs{Multiselect}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },
    {
        Name   => 'Multiselect: Value web request (multiple)',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{Multiselect},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Class              => 'MyClass',
            UseDefaultValue    => 0,
            CGIParam           => {
                DynamicField_MultiselectField => [ 1, 2 ],
            },
        },
        ExpectedResults => {
            Field => <<"EOF" . '</select>',
<select class="DynamicFieldText Modernize MyClass" id="DynamicField_$DynamicFieldConfigs{Multiselect}->{Name}" multiple="multiple" name="DynamicField_$DynamicFieldConfigs{Multiselect}->{Name}">
  <option value="">-</option>
  <option value="1" selected="selected">A</option>
  <option value="2" selected="selected">B</option>
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{Multiselect}->{Name}" for="DynamicField_$DynamicFieldConfigs{Multiselect}->{Name}">
$DynamicFieldConfigs{Multiselect}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },
    {
        Name   => 'Multiselect: Value template',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{Multiselect},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Class              => 'MyClass',
            UseDefaultValue    => 0,
            Template           => {
                DynamicField_MultiselectField => 1,
            },
        },
        ExpectedResults => {
            Field => <<"EOF" . '</select>',
<select class="DynamicFieldText Modernize MyClass" id="DynamicField_$DynamicFieldConfigs{Multiselect}->{Name}" multiple="multiple" name="DynamicField_$DynamicFieldConfigs{Multiselect}->{Name}">
  <option value="">-</option>
  <option value="1" selected="selected">A</option>
  <option value="2">B</option>
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{Multiselect}->{Name}" for="DynamicField_$DynamicFieldConfigs{Multiselect}->{Name}">
$DynamicFieldConfigs{Multiselect}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },
    {
        Name   => 'Multiselect: Value template (multiple)',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{Multiselect},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Class              => 'MyClass',
            UseDefaultValue    => 0,
            Template           => {
                DynamicField_MultiselectField => [ 1, 2 ],
            },
        },
        ExpectedResults => {
            Field => <<"EOF" . '</select>',
<select class="DynamicFieldText Modernize MyClass" id="DynamicField_$DynamicFieldConfigs{Multiselect}->{Name}" multiple="multiple" name="DynamicField_$DynamicFieldConfigs{Multiselect}->{Name}">
  <option value="">-</option>
  <option value="1" selected="selected">A</option>
  <option value="2" selected="selected">B</option>
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{Multiselect}->{Name}" for="DynamicField_$DynamicFieldConfigs{Multiselect}->{Name}">
$DynamicFieldConfigs{Multiselect}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },
    {
        Name   => 'Multiselect: Mandatory',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{Multiselect},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Value              => 2,
            Class              => 'MyClass',
            UseDefaultValue    => 0,
            Mandatory          => 1,
        },
        ExpectedResults => {
            Field => <<"EOF",
<select class="DynamicFieldText Modernize MyClass Validate_Required" id="DynamicField_$DynamicFieldConfigs{Multiselect}->{Name}" multiple="multiple" name="DynamicField_$DynamicFieldConfigs{Multiselect}->{Name}">
  <option value="">-</option>
  <option value="1">A</option>
  <option value="2" selected="selected">B</option>
</select>
<div id="DynamicField_$DynamicFieldConfigs{Multiselect}->{Name}Error" class="TooltipErrorMessage">
    <p>
        This field is required.
    </p>
</div>
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{Multiselect}->{Name}" for="DynamicField_$DynamicFieldConfigs{Multiselect}->{Name}" class="Mandatory">
    <span class="Marker">*</span>
$DynamicFieldConfigs{Multiselect}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },
    {
        Name   => 'Multiselect: Server Error',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{Multiselect},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Value              => 2,
            Class              => 'MyClass',
            UseDefaultValue    => 0,
            ServerError        => 1,
            ErrorMessage       => 'This is an error.'
        },
        ExpectedResults => {
            Field => <<"EOF",
<select class="DynamicFieldText Modernize MyClass ServerError" id="DynamicField_$DynamicFieldConfigs{Multiselect}->{Name}" multiple="multiple" name="DynamicField_$DynamicFieldConfigs{Multiselect}->{Name}">
  <option value="">-</option>
  <option value="1">A</option>
  <option value="2" selected="selected">B</option>
</select>
<div id="DynamicField_$DynamicFieldConfigs{Multiselect}->{Name}ServerError" class="TooltipErrorMessage">
    <p>
        This is an error.
    </p>
</div>
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{Multiselect}->{Name}" for="DynamicField_$DynamicFieldConfigs{Multiselect}->{Name}">
$DynamicFieldConfigs{Multiselect}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },
    {
        Name   => 'Multiselect: Possible Values Filter',
        Config => {
            DynamicFieldConfig   => $DynamicFieldConfigs{Multiselect},
            LayoutObject         => $LayoutObject,
            ParamObject          => $ParamObject,
            Value                => 2,
            Class                => 'MyClass',
            UseDefaultValue      => 0,
            PossibleValuesFilter => {
                2 => 'Value2',
            },
        },
        ExpectedResults => {
            Field => <<"EOF" . '</select>',
<select class="DynamicFieldText Modernize MyClass" id="DynamicField_$DynamicFieldConfigs{Multiselect}->{Name}" multiple="multiple" name="DynamicField_$DynamicFieldConfigs{Multiselect}->{Name}">
  <option value="2" selected="selected">Value2</option>
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{Multiselect}->{Name}" for="DynamicField_$DynamicFieldConfigs{Multiselect}->{Name}">
$DynamicFieldConfigs{Multiselect}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },
    {
        Name   => 'Multiselect: No Possible None',
        Config => {
            DynamicFieldConfig   => $DynamicFieldConfigs{Multiselect},
            LayoutObject         => $LayoutObject,
            ParamObject          => $ParamObject,
            Value                => 1,
            Class                => 'MyClass',
            UseDefaultValue      => 0,
            OverridePossibleNone => 0,
        },
        ExpectedResults => {
            Field => <<"EOF" . '</select>',
<select class="DynamicFieldText Modernize MyClass" id="DynamicField_$DynamicFieldConfigs{Multiselect}->{Name}" multiple="multiple" name="DynamicField_$DynamicFieldConfigs{Multiselect}->{Name}">
  <option value="1" selected="selected">A</option>
  <option value="2">B</option>
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{Multiselect}->{Name}" for="DynamicField_$DynamicFieldConfigs{Multiselect}->{Name}">
$DynamicFieldConfigs{Multiselect}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },
    {
        Name   => 'Multiselect: AJAX Options',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{Multiselect},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Value              => 1,
            Class              => 'MyClass',
            UseDefaultValue    => 0,
            AJAXUpdate         => 1,
            UpdatableFields    => [ 'StateID', 'PriorityID', ],
        },
        ExpectedResults => {
            Field => <<"EOF",
<select class="DynamicFieldText Modernize MyClass" id="DynamicField_$DynamicFieldConfigs{Multiselect}->{Name}" multiple="multiple" name="DynamicField_$DynamicFieldConfigs{Multiselect}->{Name}">
  <option value="">-</option>
  <option value="1" selected="selected">A</option>
  <option value="2">B</option>
</select>
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{Multiselect}->{Name}" for="DynamicField_$DynamicFieldConfigs{Multiselect}->{Name}">
$DynamicFieldConfigs{Multiselect}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },

    # Dynamic Field DateTime
    {
        Name   => 'DateTime: No value / Default',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{DateTime},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Class              => 'MyClass',
            UseDefaultValue    => 1,
        },
        ExpectedResults => {
            Field => <<"EOF",
<input type="checkbox" name="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Used" id="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Used" value="1" checked="checked" class="DynamicFieldText DateSelection MyClass" title="Check to activate this date" />&nbsp;<select class="Validate_DateMonth DynamicFieldText DateSelection MyClass" id="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Month" name="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Month" title="Month">
  <option value="1">01</option>
  <option value="2">02</option>
  <option value="3">03</option>
  <option value="4">04</option>
  <option value="5">05</option>
  <option value="6">06</option>
  <option value="7">07</option>
  <option value="8" selected="selected">08</option>
  <option value="9">09</option>
  <option value="10">10</option>
  <option value="11">11</option>
  <option value="12">12</option>
</select>/<select class="Validate_DateDay Validate_DateYear_DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Year Validate_DateMonth_DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Month Validate_DateHour_DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Hour Validate_DateMinute_DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Minute DynamicFieldText DateSelection MyClass" id="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Day" name="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Day" title="Day">
  <option value="1">01</option>
  <option value="2">02</option>
  <option value="3">03</option>
  <option value="4">04</option>
  <option value="5">05</option>
  <option value="6">06</option>
  <option value="7">07</option>
  <option value="8">08</option>
  <option value="9">09</option>
  <option value="10">10</option>
  <option value="11">11</option>
  <option value="12">12</option>
  <option value="13">13</option>
  <option value="14">14</option>
  <option value="15">15</option>
  <option value="16">16</option>
  <option value="17">17</option>
  <option value="18">18</option>
  <option value="19">19</option>
  <option value="20">20</option>
  <option value="21" selected="selected">21</option>
  <option value="22">22</option>
  <option value="23">23</option>
  <option value="24">24</option>
  <option value="25">25</option>
  <option value="26">26</option>
  <option value="27">27</option>
  <option value="28">28</option>
  <option value="29">29</option>
  <option value="30">30</option>
  <option value="31">31</option>
</select>/<select class="Validate_DateYear DynamicFieldText DateSelection MyClass" id="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Year" name="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Year" title="Year">
  <option value="2008">2008</option>
  <option value="2009">2009</option>
  <option value="2010">2010</option>
  <option value="2011">2011</option>
  <option value="2012">2012</option>
  <option value="2013" selected="selected">2013</option>
  <option value="2014">2014</option>
  <option value="2015">2015</option>
  <option value="2016">2016</option>
  <option value="2017">2017</option>
  <option value="2018">2018</option>
</select> - <select class="Validate_DateHour DynamicFieldText DateSelection MyClass" id="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Hour" name="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Hour" title="Hours">
  <option value="0">00</option>
  <option value="1">01</option>
  <option value="2">02</option>
  <option value="3">03</option>
  <option value="4">04</option>
  <option value="5">05</option>
  <option value="6">06</option>
  <option value="7">07</option>
  <option value="8">08</option>
  <option value="9">09</option>
  <option value="10">10</option>
  <option value="11">11</option>
  <option value="12">12</option>
  <option value="13">13</option>
  <option value="14">14</option>
  <option value="15">15</option>
  <option value="16" selected="selected">16</option>
  <option value="17">17</option>
  <option value="18">18</option>
  <option value="19">19</option>
  <option value="20">20</option>
  <option value="21">21</option>
  <option value="22">22</option>
  <option value="23">23</option>
</select>:<select class="Validate_DateMinute DynamicFieldText DateSelection MyClass" id="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Minute" name="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Minute" title="Minutes">
  <option value="0">00</option>
  <option value="1">01</option>
  <option value="2">02</option>
  <option value="3">03</option>
  <option value="4">04</option>
  <option value="5">05</option>
  <option value="6">06</option>
  <option value="7">07</option>
  <option value="8">08</option>
  <option value="9">09</option>
  <option value="10">10</option>
  <option value="11">11</option>
  <option value="12">12</option>
  <option value="13">13</option>
  <option value="14">14</option>
  <option value="15">15</option>
  <option value="16">16</option>
  <option value="17">17</option>
  <option value="18">18</option>
  <option value="19">19</option>
  <option value="20">20</option>
  <option value="21">21</option>
  <option value="22">22</option>
  <option value="23">23</option>
  <option value="24">24</option>
  <option value="25">25</option>
  <option value="26">26</option>
  <option value="27">27</option>
  <option value="28">28</option>
  <option value="29">29</option>
  <option value="30">30</option>
  <option value="31">31</option>
  <option value="32">32</option>
  <option value="33">33</option>
  <option value="34">34</option>
  <option value="35">35</option>
  <option value="36">36</option>
  <option value="37">37</option>
  <option value="38">38</option>
  <option value="39">39</option>
  <option value="40">40</option>
  <option value="41">41</option>
  <option value="42">42</option>
  <option value="43">43</option>
  <option value="44">44</option>
  <option value="45" selected="selected">45</option>
  <option value="46">46</option>
  <option value="47">47</option>
  <option value="48">48</option>
  <option value="49">49</option>
  <option value="50">50</option>
  <option value="51">51</option>
  <option value="52">52</option>
  <option value="53">53</option>
  <option value="54">54</option>
  <option value="55">55</option>
  <option value="56">56</option>
  <option value="57">57</option>
  <option value="58">58</option>
  <option value="59">59</option>
</select>
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{DateTime}->{Name}Used" for="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Used">
$DynamicFieldConfigs{DateTime}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },
    {
        Name   => 'DateTime: Value direct',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{DateTime},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Value              => '2013-12-12 00:00:00',
            Class              => 'MyClass',
            UseDefaultValue    => 0,
        },
        ExpectedResults => {
            Field => <<"EOF",
<input type="checkbox" name="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Used" id="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Used" value="1" checked="checked" class="DynamicFieldText DateSelection MyClass" title="Check to activate this date" />&nbsp;<select class="Validate_DateMonth DynamicFieldText DateSelection MyClass" id="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Month" name="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Month" title="Month">
  <option value="1">01</option>
  <option value="2">02</option>
  <option value="3">03</option>
  <option value="4">04</option>
  <option value="5">05</option>
  <option value="6">06</option>
  <option value="7">07</option>
  <option value="8">08</option>
  <option value="9">09</option>
  <option value="10">10</option>
  <option value="11">11</option>
  <option value="12" selected="selected">12</option>
</select>/<select class="Validate_DateDay Validate_DateYear_DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Year Validate_DateMonth_DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Month Validate_DateHour_DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Hour Validate_DateMinute_DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Minute DynamicFieldText DateSelection MyClass" id="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Day" name="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Day" title="Day">
  <option value="1">01</option>
  <option value="2">02</option>
  <option value="3">03</option>
  <option value="4">04</option>
  <option value="5">05</option>
  <option value="6">06</option>
  <option value="7">07</option>
  <option value="8">08</option>
  <option value="9">09</option>
  <option value="10">10</option>
  <option value="11">11</option>
  <option value="12" selected="selected">12</option>
  <option value="13">13</option>
  <option value="14">14</option>
  <option value="15">15</option>
  <option value="16">16</option>
  <option value="17">17</option>
  <option value="18">18</option>
  <option value="19">19</option>
  <option value="20">20</option>
  <option value="21">21</option>
  <option value="22">22</option>
  <option value="23">23</option>
  <option value="24">24</option>
  <option value="25">25</option>
  <option value="26">26</option>
  <option value="27">27</option>
  <option value="28">28</option>
  <option value="29">29</option>
  <option value="30">30</option>
  <option value="31">31</option>
</select>/<select class="Validate_DateYear DynamicFieldText DateSelection MyClass" id="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Year" name="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Year" title="Year">
  <option value="2008">2008</option>
  <option value="2009">2009</option>
  <option value="2010">2010</option>
  <option value="2011">2011</option>
  <option value="2012">2012</option>
  <option value="2013" selected="selected">2013</option>
  <option value="2014">2014</option>
  <option value="2015">2015</option>
  <option value="2016">2016</option>
  <option value="2017">2017</option>
  <option value="2018">2018</option>
</select> - <select class="Validate_DateHour DynamicFieldText DateSelection MyClass" id="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Hour" name="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Hour" title="Hours">
  <option value="0" selected="selected">00</option>
  <option value="1">01</option>
  <option value="2">02</option>
  <option value="3">03</option>
  <option value="4">04</option>
  <option value="5">05</option>
  <option value="6">06</option>
  <option value="7">07</option>
  <option value="8">08</option>
  <option value="9">09</option>
  <option value="10">10</option>
  <option value="11">11</option>
  <option value="12">12</option>
  <option value="13">13</option>
  <option value="14">14</option>
  <option value="15">15</option>
  <option value="16">16</option>
  <option value="17">17</option>
  <option value="18">18</option>
  <option value="19">19</option>
  <option value="20">20</option>
  <option value="21">21</option>
  <option value="22">22</option>
  <option value="23">23</option>
</select>:<select class="Validate_DateMinute DynamicFieldText DateSelection MyClass" id="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Minute" name="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Minute" title="Minutes">
  <option value="0" selected="selected">00</option>
  <option value="1">01</option>
  <option value="2">02</option>
  <option value="3">03</option>
  <option value="4">04</option>
  <option value="5">05</option>
  <option value="6">06</option>
  <option value="7">07</option>
  <option value="8">08</option>
  <option value="9">09</option>
  <option value="10">10</option>
  <option value="11">11</option>
  <option value="12">12</option>
  <option value="13">13</option>
  <option value="14">14</option>
  <option value="15">15</option>
  <option value="16">16</option>
  <option value="17">17</option>
  <option value="18">18</option>
  <option value="19">19</option>
  <option value="20">20</option>
  <option value="21">21</option>
  <option value="22">22</option>
  <option value="23">23</option>
  <option value="24">24</option>
  <option value="25">25</option>
  <option value="26">26</option>
  <option value="27">27</option>
  <option value="28">28</option>
  <option value="29">29</option>
  <option value="30">30</option>
  <option value="31">31</option>
  <option value="32">32</option>
  <option value="33">33</option>
  <option value="34">34</option>
  <option value="35">35</option>
  <option value="36">36</option>
  <option value="37">37</option>
  <option value="38">38</option>
  <option value="39">39</option>
  <option value="40">40</option>
  <option value="41">41</option>
  <option value="42">42</option>
  <option value="43">43</option>
  <option value="44">44</option>
  <option value="45">45</option>
  <option value="46">46</option>
  <option value="47">47</option>
  <option value="48">48</option>
  <option value="49">49</option>
  <option value="50">50</option>
  <option value="51">51</option>
  <option value="52">52</option>
  <option value="53">53</option>
  <option value="54">54</option>
  <option value="55">55</option>
  <option value="56">56</option>
  <option value="57">57</option>
  <option value="58">58</option>
  <option value="59">59</option>
</select>
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{DateTime}->{Name}Used" for="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Used">
$DynamicFieldConfigs{DateTime}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },
    {
        Name   => 'DateTime: Value web request',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{DateTime},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Class              => 'MyClass',
            UseDefaultValue    => 0,
            CGIParam           => {
                DynamicField_DateTimeFieldUsed   => 1,
                DynamicField_DateTimeFieldYear   => 2013,
                DynamicField_DateTimeFieldMonth  => 12,
                DynamicField_DateTimeFieldDay    => 12,
                DynamicField_DateTimeFieldHour   => 0,
                DynamicField_DateTimeFieldMinute => 0,
            },
        },
        ExpectedResults => {
            Field => <<"EOF",
<input type="checkbox" name="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Used" id="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Used" value="1" checked="checked" class="DynamicFieldText DateSelection MyClass" title="Check to activate this date" />&nbsp;<select class="Validate_DateMonth DynamicFieldText DateSelection MyClass" id="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Month" name="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Month" title="Month">
  <option value="1">01</option>
  <option value="2">02</option>
  <option value="3">03</option>
  <option value="4">04</option>
  <option value="5">05</option>
  <option value="6">06</option>
  <option value="7">07</option>
  <option value="8">08</option>
  <option value="9">09</option>
  <option value="10">10</option>
  <option value="11">11</option>
  <option value="12" selected="selected">12</option>
</select>/<select class="Validate_DateDay Validate_DateYear_DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Year Validate_DateMonth_DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Month Validate_DateHour_DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Hour Validate_DateMinute_DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Minute DynamicFieldText DateSelection MyClass" id="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Day" name="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Day" title="Day">
  <option value="1">01</option>
  <option value="2">02</option>
  <option value="3">03</option>
  <option value="4">04</option>
  <option value="5">05</option>
  <option value="6">06</option>
  <option value="7">07</option>
  <option value="8">08</option>
  <option value="9">09</option>
  <option value="10">10</option>
  <option value="11">11</option>
  <option value="12" selected="selected">12</option>
  <option value="13">13</option>
  <option value="14">14</option>
  <option value="15">15</option>
  <option value="16">16</option>
  <option value="17">17</option>
  <option value="18">18</option>
  <option value="19">19</option>
  <option value="20">20</option>
  <option value="21">21</option>
  <option value="22">22</option>
  <option value="23">23</option>
  <option value="24">24</option>
  <option value="25">25</option>
  <option value="26">26</option>
  <option value="27">27</option>
  <option value="28">28</option>
  <option value="29">29</option>
  <option value="30">30</option>
  <option value="31">31</option>
</select>/<select class="Validate_DateYear DynamicFieldText DateSelection MyClass" id="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Year" name="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Year" title="Year">
  <option value="2008">2008</option>
  <option value="2009">2009</option>
  <option value="2010">2010</option>
  <option value="2011">2011</option>
  <option value="2012">2012</option>
  <option value="2013" selected="selected">2013</option>
  <option value="2014">2014</option>
  <option value="2015">2015</option>
  <option value="2016">2016</option>
  <option value="2017">2017</option>
  <option value="2018">2018</option>
</select> - <select class="Validate_DateHour DynamicFieldText DateSelection MyClass" id="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Hour" name="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Hour" title="Hours">
  <option value="0" selected="selected">00</option>
  <option value="1">01</option>
  <option value="2">02</option>
  <option value="3">03</option>
  <option value="4">04</option>
  <option value="5">05</option>
  <option value="6">06</option>
  <option value="7">07</option>
  <option value="8">08</option>
  <option value="9">09</option>
  <option value="10">10</option>
  <option value="11">11</option>
  <option value="12">12</option>
  <option value="13">13</option>
  <option value="14">14</option>
  <option value="15">15</option>
  <option value="16">16</option>
  <option value="17">17</option>
  <option value="18">18</option>
  <option value="19">19</option>
  <option value="20">20</option>
  <option value="21">21</option>
  <option value="22">22</option>
  <option value="23">23</option>
</select>:<select class="Validate_DateMinute DynamicFieldText DateSelection MyClass" id="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Minute" name="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Minute" title="Minutes">
  <option value="0" selected="selected">00</option>
  <option value="1">01</option>
  <option value="2">02</option>
  <option value="3">03</option>
  <option value="4">04</option>
  <option value="5">05</option>
  <option value="6">06</option>
  <option value="7">07</option>
  <option value="8">08</option>
  <option value="9">09</option>
  <option value="10">10</option>
  <option value="11">11</option>
  <option value="12">12</option>
  <option value="13">13</option>
  <option value="14">14</option>
  <option value="15">15</option>
  <option value="16">16</option>
  <option value="17">17</option>
  <option value="18">18</option>
  <option value="19">19</option>
  <option value="20">20</option>
  <option value="21">21</option>
  <option value="22">22</option>
  <option value="23">23</option>
  <option value="24">24</option>
  <option value="25">25</option>
  <option value="26">26</option>
  <option value="27">27</option>
  <option value="28">28</option>
  <option value="29">29</option>
  <option value="30">30</option>
  <option value="31">31</option>
  <option value="32">32</option>
  <option value="33">33</option>
  <option value="34">34</option>
  <option value="35">35</option>
  <option value="36">36</option>
  <option value="37">37</option>
  <option value="38">38</option>
  <option value="39">39</option>
  <option value="40">40</option>
  <option value="41">41</option>
  <option value="42">42</option>
  <option value="43">43</option>
  <option value="44">44</option>
  <option value="45">45</option>
  <option value="46">46</option>
  <option value="47">47</option>
  <option value="48">48</option>
  <option value="49">49</option>
  <option value="50">50</option>
  <option value="51">51</option>
  <option value="52">52</option>
  <option value="53">53</option>
  <option value="54">54</option>
  <option value="55">55</option>
  <option value="56">56</option>
  <option value="57">57</option>
  <option value="58">58</option>
  <option value="59">59</option>
</select>
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{DateTime}->{Name}Used" for="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Used">
$DynamicFieldConfigs{DateTime}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },
    {
        Name   => 'DateTime: Value web request (using default value)',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{DateTime},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Class              => 'MyClass',
            UseDefaultValue    => 1,
            CGIParam           => {
                DynamicField_DateTimeFieldUsed   => 1,
                DynamicField_DateTimeFieldYear   => 2013,
                DynamicField_DateTimeFieldMonth  => 12,
                DynamicField_DateTimeFieldDay    => 12,
                DynamicField_DateTimeFieldHour   => 0,
                DynamicField_DateTimeFieldMinute => 0,
            },
        },
        ExpectedResults => {
            Field => <<"EOF",
<input type="checkbox" name="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Used" id="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Used" value="1" checked="checked" class="DynamicFieldText DateSelection MyClass" title="Check to activate this date" />&nbsp;<select class="Validate_DateMonth DynamicFieldText DateSelection MyClass" id="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Month" name="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Month" title="Month">
  <option value="1">01</option>
  <option value="2">02</option>
  <option value="3">03</option>
  <option value="4">04</option>
  <option value="5">05</option>
  <option value="6">06</option>
  <option value="7">07</option>
  <option value="8">08</option>
  <option value="9">09</option>
  <option value="10">10</option>
  <option value="11">11</option>
  <option value="12" selected="selected">12</option>
</select>/<select class="Validate_DateDay Validate_DateYear_DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Year Validate_DateMonth_DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Month Validate_DateHour_DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Hour Validate_DateMinute_DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Minute DynamicFieldText DateSelection MyClass" id="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Day" name="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Day" title="Day">
  <option value="1">01</option>
  <option value="2">02</option>
  <option value="3">03</option>
  <option value="4">04</option>
  <option value="5">05</option>
  <option value="6">06</option>
  <option value="7">07</option>
  <option value="8">08</option>
  <option value="9">09</option>
  <option value="10">10</option>
  <option value="11">11</option>
  <option value="12" selected="selected">12</option>
  <option value="13">13</option>
  <option value="14">14</option>
  <option value="15">15</option>
  <option value="16">16</option>
  <option value="17">17</option>
  <option value="18">18</option>
  <option value="19">19</option>
  <option value="20">20</option>
  <option value="21">21</option>
  <option value="22">22</option>
  <option value="23">23</option>
  <option value="24">24</option>
  <option value="25">25</option>
  <option value="26">26</option>
  <option value="27">27</option>
  <option value="28">28</option>
  <option value="29">29</option>
  <option value="30">30</option>
  <option value="31">31</option>
</select>/<select class="Validate_DateYear DynamicFieldText DateSelection MyClass" id="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Year" name="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Year" title="Year">
  <option value="2008">2008</option>
  <option value="2009">2009</option>
  <option value="2010">2010</option>
  <option value="2011">2011</option>
  <option value="2012">2012</option>
  <option value="2013" selected="selected">2013</option>
  <option value="2014">2014</option>
  <option value="2015">2015</option>
  <option value="2016">2016</option>
  <option value="2017">2017</option>
  <option value="2018">2018</option>
</select> - <select class="Validate_DateHour DynamicFieldText DateSelection MyClass" id="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Hour" name="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Hour" title="Hours">
  <option value="0" selected="selected">00</option>
  <option value="1">01</option>
  <option value="2">02</option>
  <option value="3">03</option>
  <option value="4">04</option>
  <option value="5">05</option>
  <option value="6">06</option>
  <option value="7">07</option>
  <option value="8">08</option>
  <option value="9">09</option>
  <option value="10">10</option>
  <option value="11">11</option>
  <option value="12">12</option>
  <option value="13">13</option>
  <option value="14">14</option>
  <option value="15">15</option>
  <option value="16">16</option>
  <option value="17">17</option>
  <option value="18">18</option>
  <option value="19">19</option>
  <option value="20">20</option>
  <option value="21">21</option>
  <option value="22">22</option>
  <option value="23">23</option>
</select>:<select class="Validate_DateMinute DynamicFieldText DateSelection MyClass" id="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Minute" name="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Minute" title="Minutes">
  <option value="0" selected="selected">00</option>
  <option value="1">01</option>
  <option value="2">02</option>
  <option value="3">03</option>
  <option value="4">04</option>
  <option value="5">05</option>
  <option value="6">06</option>
  <option value="7">07</option>
  <option value="8">08</option>
  <option value="9">09</option>
  <option value="10">10</option>
  <option value="11">11</option>
  <option value="12">12</option>
  <option value="13">13</option>
  <option value="14">14</option>
  <option value="15">15</option>
  <option value="16">16</option>
  <option value="17">17</option>
  <option value="18">18</option>
  <option value="19">19</option>
  <option value="20">20</option>
  <option value="21">21</option>
  <option value="22">22</option>
  <option value="23">23</option>
  <option value="24">24</option>
  <option value="25">25</option>
  <option value="26">26</option>
  <option value="27">27</option>
  <option value="28">28</option>
  <option value="29">29</option>
  <option value="30">30</option>
  <option value="31">31</option>
  <option value="32">32</option>
  <option value="33">33</option>
  <option value="34">34</option>
  <option value="35">35</option>
  <option value="36">36</option>
  <option value="37">37</option>
  <option value="38">38</option>
  <option value="39">39</option>
  <option value="40">40</option>
  <option value="41">41</option>
  <option value="42">42</option>
  <option value="43">43</option>
  <option value="44">44</option>
  <option value="45">45</option>
  <option value="46">46</option>
  <option value="47">47</option>
  <option value="48">48</option>
  <option value="49">49</option>
  <option value="50">50</option>
  <option value="51">51</option>
  <option value="52">52</option>
  <option value="53">53</option>
  <option value="54">54</option>
  <option value="55">55</option>
  <option value="56">56</option>
  <option value="57">57</option>
  <option value="58">58</option>
  <option value="59">59</option>
</select>
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{DateTime}->{Name}Used" for="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Used">
$DynamicFieldConfigs{DateTime}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },
    {
        Name   => 'DateTime: Value template',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{DateTime},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Class              => 'MyClass',
            UseDefaultValue    => 0,
            Template           => {
                DynamicField_DateTimeFieldUsed   => 1,
                DynamicField_DateTimeFieldYear   => 2013,
                DynamicField_DateTimeFieldMonth  => 12,
                DynamicField_DateTimeFieldDay    => 12,
                DynamicField_DateTimeFieldHour   => 0,
                DynamicField_DateTimeFieldMinute => 0,
            },
        },
        ExpectedResults => {
            Field => <<"EOF",
<input type="checkbox" name="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Used" id="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Used" value="1" checked="checked" class="DynamicFieldText DateSelection MyClass" title="Check to activate this date" />&nbsp;<select class="Validate_DateMonth DynamicFieldText DateSelection MyClass" id="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Month" name="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Month" title="Month">
  <option value="1">01</option>
  <option value="2">02</option>
  <option value="3">03</option>
  <option value="4">04</option>
  <option value="5">05</option>
  <option value="6">06</option>
  <option value="7">07</option>
  <option value="8">08</option>
  <option value="9">09</option>
  <option value="10">10</option>
  <option value="11">11</option>
  <option value="12" selected="selected">12</option>
</select>/<select class="Validate_DateDay Validate_DateYear_DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Year Validate_DateMonth_DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Month Validate_DateHour_DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Hour Validate_DateMinute_DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Minute DynamicFieldText DateSelection MyClass" id="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Day" name="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Day" title="Day">
  <option value="1">01</option>
  <option value="2">02</option>
  <option value="3">03</option>
  <option value="4">04</option>
  <option value="5">05</option>
  <option value="6">06</option>
  <option value="7">07</option>
  <option value="8">08</option>
  <option value="9">09</option>
  <option value="10">10</option>
  <option value="11">11</option>
  <option value="12" selected="selected">12</option>
  <option value="13">13</option>
  <option value="14">14</option>
  <option value="15">15</option>
  <option value="16">16</option>
  <option value="17">17</option>
  <option value="18">18</option>
  <option value="19">19</option>
  <option value="20">20</option>
  <option value="21">21</option>
  <option value="22">22</option>
  <option value="23">23</option>
  <option value="24">24</option>
  <option value="25">25</option>
  <option value="26">26</option>
  <option value="27">27</option>
  <option value="28">28</option>
  <option value="29">29</option>
  <option value="30">30</option>
  <option value="31">31</option>
</select>/<select class="Validate_DateYear DynamicFieldText DateSelection MyClass" id="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Year" name="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Year" title="Year">
  <option value="2008">2008</option>
  <option value="2009">2009</option>
  <option value="2010">2010</option>
  <option value="2011">2011</option>
  <option value="2012">2012</option>
  <option value="2013" selected="selected">2013</option>
  <option value="2014">2014</option>
  <option value="2015">2015</option>
  <option value="2016">2016</option>
  <option value="2017">2017</option>
  <option value="2018">2018</option>
</select> - <select class="Validate_DateHour DynamicFieldText DateSelection MyClass" id="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Hour" name="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Hour" title="Hours">
  <option value="0" selected="selected">00</option>
  <option value="1">01</option>
  <option value="2">02</option>
  <option value="3">03</option>
  <option value="4">04</option>
  <option value="5">05</option>
  <option value="6">06</option>
  <option value="7">07</option>
  <option value="8">08</option>
  <option value="9">09</option>
  <option value="10">10</option>
  <option value="11">11</option>
  <option value="12">12</option>
  <option value="13">13</option>
  <option value="14">14</option>
  <option value="15">15</option>
  <option value="16">16</option>
  <option value="17">17</option>
  <option value="18">18</option>
  <option value="19">19</option>
  <option value="20">20</option>
  <option value="21">21</option>
  <option value="22">22</option>
  <option value="23">23</option>
</select>:<select class="Validate_DateMinute DynamicFieldText DateSelection MyClass" id="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Minute" name="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Minute" title="Minutes">
  <option value="0" selected="selected">00</option>
  <option value="1">01</option>
  <option value="2">02</option>
  <option value="3">03</option>
  <option value="4">04</option>
  <option value="5">05</option>
  <option value="6">06</option>
  <option value="7">07</option>
  <option value="8">08</option>
  <option value="9">09</option>
  <option value="10">10</option>
  <option value="11">11</option>
  <option value="12">12</option>
  <option value="13">13</option>
  <option value="14">14</option>
  <option value="15">15</option>
  <option value="16">16</option>
  <option value="17">17</option>
  <option value="18">18</option>
  <option value="19">19</option>
  <option value="20">20</option>
  <option value="21">21</option>
  <option value="22">22</option>
  <option value="23">23</option>
  <option value="24">24</option>
  <option value="25">25</option>
  <option value="26">26</option>
  <option value="27">27</option>
  <option value="28">28</option>
  <option value="29">29</option>
  <option value="30">30</option>
  <option value="31">31</option>
  <option value="32">32</option>
  <option value="33">33</option>
  <option value="34">34</option>
  <option value="35">35</option>
  <option value="36">36</option>
  <option value="37">37</option>
  <option value="38">38</option>
  <option value="39">39</option>
  <option value="40">40</option>
  <option value="41">41</option>
  <option value="42">42</option>
  <option value="43">43</option>
  <option value="44">44</option>
  <option value="45">45</option>
  <option value="46">46</option>
  <option value="47">47</option>
  <option value="48">48</option>
  <option value="49">49</option>
  <option value="50">50</option>
  <option value="51">51</option>
  <option value="52">52</option>
  <option value="53">53</option>
  <option value="54">54</option>
  <option value="55">55</option>
  <option value="56">56</option>
  <option value="57">57</option>
  <option value="58">58</option>
  <option value="59">59</option>
</select>
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{DateTime}->{Name}Used" for="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Used">
$DynamicFieldConfigs{DateTime}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },
    {
        Name   => 'DateTime: Mandatory',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{DateTime},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Value              => '2013-12-12 00:00:00',
            Class              => 'MyClass',
            UseDefaultValue    => 0,
            Mandatory          => 1,
        },
        ExpectedResults => {
            Field => <<"EOF",
<input type="checkbox" name="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Used" id="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Used" value="1" checked="checked" class="DynamicFieldText DateSelection MyClass Validate_Required" title="Check to activate this date" />&nbsp;<select class="Validate_DateMonth DynamicFieldText DateSelection MyClass Validate_Required" id="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Month" name="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Month" title="Month">
  <option value="1">01</option>
  <option value="2">02</option>
  <option value="3">03</option>
  <option value="4">04</option>
  <option value="5">05</option>
  <option value="6">06</option>
  <option value="7">07</option>
  <option value="8">08</option>
  <option value="9">09</option>
  <option value="10">10</option>
  <option value="11">11</option>
  <option value="12" selected="selected">12</option>
</select>/<select class="Validate_DateDay Validate_DateYear_DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Year Validate_DateMonth_DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Month Validate_DateHour_DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Hour Validate_DateMinute_DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Minute DynamicFieldText DateSelection MyClass Validate_Required" id="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Day" name="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Day" title="Day">
  <option value="1">01</option>
  <option value="2">02</option>
  <option value="3">03</option>
  <option value="4">04</option>
  <option value="5">05</option>
  <option value="6">06</option>
  <option value="7">07</option>
  <option value="8">08</option>
  <option value="9">09</option>
  <option value="10">10</option>
  <option value="11">11</option>
  <option value="12" selected="selected">12</option>
  <option value="13">13</option>
  <option value="14">14</option>
  <option value="15">15</option>
  <option value="16">16</option>
  <option value="17">17</option>
  <option value="18">18</option>
  <option value="19">19</option>
  <option value="20">20</option>
  <option value="21">21</option>
  <option value="22">22</option>
  <option value="23">23</option>
  <option value="24">24</option>
  <option value="25">25</option>
  <option value="26">26</option>
  <option value="27">27</option>
  <option value="28">28</option>
  <option value="29">29</option>
  <option value="30">30</option>
  <option value="31">31</option>
</select>/<select class="Validate_DateYear DynamicFieldText DateSelection MyClass Validate_Required" id="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Year" name="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Year" title="Year">
  <option value="2008">2008</option>
  <option value="2009">2009</option>
  <option value="2010">2010</option>
  <option value="2011">2011</option>
  <option value="2012">2012</option>
  <option value="2013" selected="selected">2013</option>
  <option value="2014">2014</option>
  <option value="2015">2015</option>
  <option value="2016">2016</option>
  <option value="2017">2017</option>
  <option value="2018">2018</option>
</select> - <select class="Validate_DateHour DynamicFieldText DateSelection MyClass Validate_Required" id="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Hour" name="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Hour" title="Hours">
  <option value="0" selected="selected">00</option>
  <option value="1">01</option>
  <option value="2">02</option>
  <option value="3">03</option>
  <option value="4">04</option>
  <option value="5">05</option>
  <option value="6">06</option>
  <option value="7">07</option>
  <option value="8">08</option>
  <option value="9">09</option>
  <option value="10">10</option>
  <option value="11">11</option>
  <option value="12">12</option>
  <option value="13">13</option>
  <option value="14">14</option>
  <option value="15">15</option>
  <option value="16">16</option>
  <option value="17">17</option>
  <option value="18">18</option>
  <option value="19">19</option>
  <option value="20">20</option>
  <option value="21">21</option>
  <option value="22">22</option>
  <option value="23">23</option>
</select>:<select class="Validate_DateMinute DynamicFieldText DateSelection MyClass Validate_Required" id="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Minute" name="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Minute" title="Minutes">
  <option value="0" selected="selected">00</option>
  <option value="1">01</option>
  <option value="2">02</option>
  <option value="3">03</option>
  <option value="4">04</option>
  <option value="5">05</option>
  <option value="6">06</option>
  <option value="7">07</option>
  <option value="8">08</option>
  <option value="9">09</option>
  <option value="10">10</option>
  <option value="11">11</option>
  <option value="12">12</option>
  <option value="13">13</option>
  <option value="14">14</option>
  <option value="15">15</option>
  <option value="16">16</option>
  <option value="17">17</option>
  <option value="18">18</option>
  <option value="19">19</option>
  <option value="20">20</option>
  <option value="21">21</option>
  <option value="22">22</option>
  <option value="23">23</option>
  <option value="24">24</option>
  <option value="25">25</option>
  <option value="26">26</option>
  <option value="27">27</option>
  <option value="28">28</option>
  <option value="29">29</option>
  <option value="30">30</option>
  <option value="31">31</option>
  <option value="32">32</option>
  <option value="33">33</option>
  <option value="34">34</option>
  <option value="35">35</option>
  <option value="36">36</option>
  <option value="37">37</option>
  <option value="38">38</option>
  <option value="39">39</option>
  <option value="40">40</option>
  <option value="41">41</option>
  <option value="42">42</option>
  <option value="43">43</option>
  <option value="44">44</option>
  <option value="45">45</option>
  <option value="46">46</option>
  <option value="47">47</option>
  <option value="48">48</option>
  <option value="49">49</option>
  <option value="50">50</option>
  <option value="51">51</option>
  <option value="52">52</option>
  <option value="53">53</option>
  <option value="54">54</option>
  <option value="55">55</option>
  <option value="56">56</option>
  <option value="57">57</option>
  <option value="58">58</option>
  <option value="59">59</option>
</select>
<div id="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}UsedError" class="TooltipErrorMessage">
    <p>
        This field is required.
    </p>
</div>
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{DateTime}->{Name}Used" for="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Used" class="Mandatory">
    <span class="Marker">*</span>
$DynamicFieldConfigs{DateTime}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },
    {
        Name   => 'DateTime: Server Error',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{DateTime},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Value              => '2013-12-12 00:00:00',
            Class              => 'MyClass',
            UseDefaultValue    => 0,
            ServerError        => 1,
            ErrorMessage       => 'This is an error.'
        },
        ExpectedResults => {
            Field => <<"EOF",
<input type="checkbox" name="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Used" id="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Used" value="1" checked="checked" class="DynamicFieldText DateSelection MyClass ServerError" title="Check to activate this date" />&nbsp;<select class="Validate_DateMonth DynamicFieldText DateSelection MyClass ServerError" id="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Month" name="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Month" title="Month">
  <option value="1">01</option>
  <option value="2">02</option>
  <option value="3">03</option>
  <option value="4">04</option>
  <option value="5">05</option>
  <option value="6">06</option>
  <option value="7">07</option>
  <option value="8">08</option>
  <option value="9">09</option>
  <option value="10">10</option>
  <option value="11">11</option>
  <option value="12" selected="selected">12</option>
</select>/<select class="Validate_DateDay Validate_DateYear_DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Year Validate_DateMonth_DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Month Validate_DateHour_DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Hour Validate_DateMinute_DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Minute DynamicFieldText DateSelection MyClass ServerError" id="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Day" name="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Day" title="Day">
  <option value="1">01</option>
  <option value="2">02</option>
  <option value="3">03</option>
  <option value="4">04</option>
  <option value="5">05</option>
  <option value="6">06</option>
  <option value="7">07</option>
  <option value="8">08</option>
  <option value="9">09</option>
  <option value="10">10</option>
  <option value="11">11</option>
  <option value="12" selected="selected">12</option>
  <option value="13">13</option>
  <option value="14">14</option>
  <option value="15">15</option>
  <option value="16">16</option>
  <option value="17">17</option>
  <option value="18">18</option>
  <option value="19">19</option>
  <option value="20">20</option>
  <option value="21">21</option>
  <option value="22">22</option>
  <option value="23">23</option>
  <option value="24">24</option>
  <option value="25">25</option>
  <option value="26">26</option>
  <option value="27">27</option>
  <option value="28">28</option>
  <option value="29">29</option>
  <option value="30">30</option>
  <option value="31">31</option>
</select>/<select class="Validate_DateYear DynamicFieldText DateSelection MyClass ServerError" id="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Year" name="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Year" title="Year">
  <option value="2008">2008</option>
  <option value="2009">2009</option>
  <option value="2010">2010</option>
  <option value="2011">2011</option>
  <option value="2012">2012</option>
  <option value="2013" selected="selected">2013</option>
  <option value="2014">2014</option>
  <option value="2015">2015</option>
  <option value="2016">2016</option>
  <option value="2017">2017</option>
  <option value="2018">2018</option>
</select> - <select class="Validate_DateHour DynamicFieldText DateSelection MyClass ServerError" id="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Hour" name="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Hour" title="Hours">
  <option value="0" selected="selected">00</option>
  <option value="1">01</option>
  <option value="2">02</option>
  <option value="3">03</option>
  <option value="4">04</option>
  <option value="5">05</option>
  <option value="6">06</option>
  <option value="7">07</option>
  <option value="8">08</option>
  <option value="9">09</option>
  <option value="10">10</option>
  <option value="11">11</option>
  <option value="12">12</option>
  <option value="13">13</option>
  <option value="14">14</option>
  <option value="15">15</option>
  <option value="16">16</option>
  <option value="17">17</option>
  <option value="18">18</option>
  <option value="19">19</option>
  <option value="20">20</option>
  <option value="21">21</option>
  <option value="22">22</option>
  <option value="23">23</option>
</select>:<select class="Validate_DateMinute DynamicFieldText DateSelection MyClass ServerError" id="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Minute" name="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Minute" title="Minutes">
  <option value="0" selected="selected">00</option>
  <option value="1">01</option>
  <option value="2">02</option>
  <option value="3">03</option>
  <option value="4">04</option>
  <option value="5">05</option>
  <option value="6">06</option>
  <option value="7">07</option>
  <option value="8">08</option>
  <option value="9">09</option>
  <option value="10">10</option>
  <option value="11">11</option>
  <option value="12">12</option>
  <option value="13">13</option>
  <option value="14">14</option>
  <option value="15">15</option>
  <option value="16">16</option>
  <option value="17">17</option>
  <option value="18">18</option>
  <option value="19">19</option>
  <option value="20">20</option>
  <option value="21">21</option>
  <option value="22">22</option>
  <option value="23">23</option>
  <option value="24">24</option>
  <option value="25">25</option>
  <option value="26">26</option>
  <option value="27">27</option>
  <option value="28">28</option>
  <option value="29">29</option>
  <option value="30">30</option>
  <option value="31">31</option>
  <option value="32">32</option>
  <option value="33">33</option>
  <option value="34">34</option>
  <option value="35">35</option>
  <option value="36">36</option>
  <option value="37">37</option>
  <option value="38">38</option>
  <option value="39">39</option>
  <option value="40">40</option>
  <option value="41">41</option>
  <option value="42">42</option>
  <option value="43">43</option>
  <option value="44">44</option>
  <option value="45">45</option>
  <option value="46">46</option>
  <option value="47">47</option>
  <option value="48">48</option>
  <option value="49">49</option>
  <option value="50">50</option>
  <option value="51">51</option>
  <option value="52">52</option>
  <option value="53">53</option>
  <option value="54">54</option>
  <option value="55">55</option>
  <option value="56">56</option>
  <option value="57">57</option>
  <option value="58">58</option>
  <option value="59">59</option>
</select>
<div id="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}UsedServerError" class="TooltipErrorMessage">
    <p>
        This is an error.
    </p>
</div>
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{DateTime}->{Name}Used" for="DynamicField_$DynamicFieldConfigs{DateTime}->{Name}Used">
$DynamicFieldConfigs{DateTime}->{LabelEscaped}:
</label>
EOF

        },
        Success => 1,
    },

    # Dynamic Field Date
    {
        Name   => 'Date: No value / Default',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{Date},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Class              => 'MyClass',
            UseDefaultValue    => 1,
        },
        ExpectedResults => {
            Field => <<"EOF",
<input type="checkbox" name="DynamicField_$DynamicFieldConfigs{Date}->{Name}Used" id="DynamicField_$DynamicFieldConfigs{Date}->{Name}Used" value="1" checked="checked" class="DynamicFieldText MyClass" title="Check to activate this date" />&nbsp;<select class="Validate_DateMonth DynamicFieldText MyClass" id="DynamicField_$DynamicFieldConfigs{Date}->{Name}Month" name="DynamicField_$DynamicFieldConfigs{Date}->{Name}Month" title="Month">
  <option value="1">01</option>
  <option value="2">02</option>
  <option value="3">03</option>
  <option value="4">04</option>
  <option value="5">05</option>
  <option value="6">06</option>
  <option value="7">07</option>
  <option value="8" selected="selected">08</option>
  <option value="9">09</option>
  <option value="10">10</option>
  <option value="11">11</option>
  <option value="12">12</option>
</select>/<select class="Validate_DateDay Validate_DateYear_DynamicField_$DynamicFieldConfigs{Date}->{Name}Year Validate_DateMonth_DynamicField_$DynamicFieldConfigs{Date}->{Name}Month DynamicFieldText MyClass" id="DynamicField_$DynamicFieldConfigs{Date}->{Name}Day" name="DynamicField_$DynamicFieldConfigs{Date}->{Name}Day" title="Day">
  <option value="1">01</option>
  <option value="2">02</option>
  <option value="3">03</option>
  <option value="4">04</option>
  <option value="5">05</option>
  <option value="6">06</option>
  <option value="7">07</option>
  <option value="8">08</option>
  <option value="9">09</option>
  <option value="10">10</option>
  <option value="11">11</option>
  <option value="12">12</option>
  <option value="13">13</option>
  <option value="14">14</option>
  <option value="15">15</option>
  <option value="16">16</option>
  <option value="17">17</option>
  <option value="18">18</option>
  <option value="19">19</option>
  <option value="20">20</option>
  <option value="21" selected="selected">21</option>
  <option value="22">22</option>
  <option value="23">23</option>
  <option value="24">24</option>
  <option value="25">25</option>
  <option value="26">26</option>
  <option value="27">27</option>
  <option value="28">28</option>
  <option value="29">29</option>
  <option value="30">30</option>
  <option value="31">31</option>
</select>/<select class="Validate_DateYear DynamicFieldText MyClass" id="DynamicField_$DynamicFieldConfigs{Date}->{Name}Year" name="DynamicField_$DynamicFieldConfigs{Date}->{Name}Year" title="Year">
  <option value="2008">2008</option>
  <option value="2009">2009</option>
  <option value="2010">2010</option>
  <option value="2011">2011</option>
  <option value="2012">2012</option>
  <option value="2013" selected="selected">2013</option>
  <option value="2014">2014</option>
  <option value="2015">2015</option>
  <option value="2016">2016</option>
  <option value="2017">2017</option>
  <option value="2018">2018</option>
</select>
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{Date}->{Name}Used" for="DynamicField_$DynamicFieldConfigs{Date}->{Name}Used">
$DynamicFieldConfigs{Date}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },
    {
        Name   => 'Date: Value direct',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{Date},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Value              => '2013-12-12 00:00:00',
            Class              => 'MyClass',
            UseDefaultValue    => 0,
        },
        ExpectedResults => {
            Field => <<"EOF",
<input type="checkbox" name="DynamicField_$DynamicFieldConfigs{Date}->{Name}Used" id="DynamicField_$DynamicFieldConfigs{Date}->{Name}Used" value="1" checked="checked" class="DynamicFieldText MyClass" title="Check to activate this date" />&nbsp;<select class="Validate_DateMonth DynamicFieldText MyClass" id="DynamicField_$DynamicFieldConfigs{Date}->{Name}Month" name="DynamicField_$DynamicFieldConfigs{Date}->{Name}Month" title="Month">
  <option value="1">01</option>
  <option value="2">02</option>
  <option value="3">03</option>
  <option value="4">04</option>
  <option value="5">05</option>
  <option value="6">06</option>
  <option value="7">07</option>
  <option value="8">08</option>
  <option value="9">09</option>
  <option value="10">10</option>
  <option value="11">11</option>
  <option value="12" selected="selected">12</option>
</select>/<select class="Validate_DateDay Validate_DateYear_DynamicField_$DynamicFieldConfigs{Date}->{Name}Year Validate_DateMonth_DynamicField_$DynamicFieldConfigs{Date}->{Name}Month DynamicFieldText MyClass" id="DynamicField_$DynamicFieldConfigs{Date}->{Name}Day" name="DynamicField_$DynamicFieldConfigs{Date}->{Name}Day" title="Day">
  <option value="1">01</option>
  <option value="2">02</option>
  <option value="3">03</option>
  <option value="4">04</option>
  <option value="5">05</option>
  <option value="6">06</option>
  <option value="7">07</option>
  <option value="8">08</option>
  <option value="9">09</option>
  <option value="10">10</option>
  <option value="11">11</option>
  <option value="12" selected="selected">12</option>
  <option value="13">13</option>
  <option value="14">14</option>
  <option value="15">15</option>
  <option value="16">16</option>
  <option value="17">17</option>
  <option value="18">18</option>
  <option value="19">19</option>
  <option value="20">20</option>
  <option value="21">21</option>
  <option value="22">22</option>
  <option value="23">23</option>
  <option value="24">24</option>
  <option value="25">25</option>
  <option value="26">26</option>
  <option value="27">27</option>
  <option value="28">28</option>
  <option value="29">29</option>
  <option value="30">30</option>
  <option value="31">31</option>
</select>/<select class="Validate_DateYear DynamicFieldText MyClass" id="DynamicField_$DynamicFieldConfigs{Date}->{Name}Year" name="DynamicField_$DynamicFieldConfigs{Date}->{Name}Year" title="Year">
  <option value="2008">2008</option>
  <option value="2009">2009</option>
  <option value="2010">2010</option>
  <option value="2011">2011</option>
  <option value="2012">2012</option>
  <option value="2013" selected="selected">2013</option>
  <option value="2014">2014</option>
  <option value="2015">2015</option>
  <option value="2016">2016</option>
  <option value="2017">2017</option>
  <option value="2018">2018</option>
</select>
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{Date}->{Name}Used" for="DynamicField_$DynamicFieldConfigs{Date}->{Name}Used">
$DynamicFieldConfigs{Date}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },
    {
        Name   => 'Date: Value web request',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{Date},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Class              => 'MyClass',
            UseDefaultValue    => 0,
            CGIParam           => {
                DynamicField_DateFieldUsed  => 1,
                DynamicField_DateFieldYear  => 2013,
                DynamicField_DateFieldMonth => 12,
                DynamicField_DateFieldDay   => 12,
            },
        },
        ExpectedResults => {
            Field => <<"EOF",
<input type="checkbox" name="DynamicField_$DynamicFieldConfigs{Date}->{Name}Used" id="DynamicField_$DynamicFieldConfigs{Date}->{Name}Used" value="1" checked="checked" class="DynamicFieldText MyClass" title="Check to activate this date" />&nbsp;<select class="Validate_DateMonth DynamicFieldText MyClass" id="DynamicField_$DynamicFieldConfigs{Date}->{Name}Month" name="DynamicField_$DynamicFieldConfigs{Date}->{Name}Month" title="Month">
  <option value="1">01</option>
  <option value="2">02</option>
  <option value="3">03</option>
  <option value="4">04</option>
  <option value="5">05</option>
  <option value="6">06</option>
  <option value="7">07</option>
  <option value="8">08</option>
  <option value="9">09</option>
  <option value="10">10</option>
  <option value="11">11</option>
  <option value="12" selected="selected">12</option>
</select>/<select class="Validate_DateDay Validate_DateYear_DynamicField_$DynamicFieldConfigs{Date}->{Name}Year Validate_DateMonth_DynamicField_$DynamicFieldConfigs{Date}->{Name}Month DynamicFieldText MyClass" id="DynamicField_$DynamicFieldConfigs{Date}->{Name}Day" name="DynamicField_$DynamicFieldConfigs{Date}->{Name}Day" title="Day">
  <option value="1">01</option>
  <option value="2">02</option>
  <option value="3">03</option>
  <option value="4">04</option>
  <option value="5">05</option>
  <option value="6">06</option>
  <option value="7">07</option>
  <option value="8">08</option>
  <option value="9">09</option>
  <option value="10">10</option>
  <option value="11">11</option>
  <option value="12" selected="selected">12</option>
  <option value="13">13</option>
  <option value="14">14</option>
  <option value="15">15</option>
  <option value="16">16</option>
  <option value="17">17</option>
  <option value="18">18</option>
  <option value="19">19</option>
  <option value="20">20</option>
  <option value="21">21</option>
  <option value="22">22</option>
  <option value="23">23</option>
  <option value="24">24</option>
  <option value="25">25</option>
  <option value="26">26</option>
  <option value="27">27</option>
  <option value="28">28</option>
  <option value="29">29</option>
  <option value="30">30</option>
  <option value="31">31</option>
</select>/<select class="Validate_DateYear DynamicFieldText MyClass" id="DynamicField_$DynamicFieldConfigs{Date}->{Name}Year" name="DynamicField_$DynamicFieldConfigs{Date}->{Name}Year" title="Year">
  <option value="2008">2008</option>
  <option value="2009">2009</option>
  <option value="2010">2010</option>
  <option value="2011">2011</option>
  <option value="2012">2012</option>
  <option value="2013" selected="selected">2013</option>
  <option value="2014">2014</option>
  <option value="2015">2015</option>
  <option value="2016">2016</option>
  <option value="2017">2017</option>
  <option value="2018">2018</option>
</select>
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{Date}->{Name}Used" for="DynamicField_$DynamicFieldConfigs{Date}->{Name}Used">
$DynamicFieldConfigs{Date}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },
    {
        Name   => 'Date: Value web request (using default value)',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{Date},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Class              => 'MyClass',
            UseDefaultValue    => 1,
            CGIParam           => {
                DynamicField_DateFieldUsed  => 1,
                DynamicField_DateFieldYear  => 2013,
                DynamicField_DateFieldMonth => 12,
                DynamicField_DateFieldDay   => 12,
            },
        },
        ExpectedResults => {
            Field => <<"EOF",
<input type="checkbox" name="DynamicField_$DynamicFieldConfigs{Date}->{Name}Used" id="DynamicField_$DynamicFieldConfigs{Date}->{Name}Used" value="1" checked="checked" class="DynamicFieldText MyClass" title="Check to activate this date" />&nbsp;<select class="Validate_DateMonth DynamicFieldText MyClass" id="DynamicField_$DynamicFieldConfigs{Date}->{Name}Month" name="DynamicField_$DynamicFieldConfigs{Date}->{Name}Month" title="Month">
  <option value="1">01</option>
  <option value="2">02</option>
  <option value="3">03</option>
  <option value="4">04</option>
  <option value="5">05</option>
  <option value="6">06</option>
  <option value="7">07</option>
  <option value="8">08</option>
  <option value="9">09</option>
  <option value="10">10</option>
  <option value="11">11</option>
  <option value="12" selected="selected">12</option>
</select>/<select class="Validate_DateDay Validate_DateYear_DynamicField_$DynamicFieldConfigs{Date}->{Name}Year Validate_DateMonth_DynamicField_$DynamicFieldConfigs{Date}->{Name}Month DynamicFieldText MyClass" id="DynamicField_$DynamicFieldConfigs{Date}->{Name}Day" name="DynamicField_$DynamicFieldConfigs{Date}->{Name}Day" title="Day">
  <option value="1">01</option>
  <option value="2">02</option>
  <option value="3">03</option>
  <option value="4">04</option>
  <option value="5">05</option>
  <option value="6">06</option>
  <option value="7">07</option>
  <option value="8">08</option>
  <option value="9">09</option>
  <option value="10">10</option>
  <option value="11">11</option>
  <option value="12" selected="selected">12</option>
  <option value="13">13</option>
  <option value="14">14</option>
  <option value="15">15</option>
  <option value="16">16</option>
  <option value="17">17</option>
  <option value="18">18</option>
  <option value="19">19</option>
  <option value="20">20</option>
  <option value="21">21</option>
  <option value="22">22</option>
  <option value="23">23</option>
  <option value="24">24</option>
  <option value="25">25</option>
  <option value="26">26</option>
  <option value="27">27</option>
  <option value="28">28</option>
  <option value="29">29</option>
  <option value="30">30</option>
  <option value="31">31</option>
</select>/<select class="Validate_DateYear DynamicFieldText MyClass" id="DynamicField_$DynamicFieldConfigs{Date}->{Name}Year" name="DynamicField_$DynamicFieldConfigs{Date}->{Name}Year" title="Year">
  <option value="2008">2008</option>
  <option value="2009">2009</option>
  <option value="2010">2010</option>
  <option value="2011">2011</option>
  <option value="2012">2012</option>
  <option value="2013" selected="selected">2013</option>
  <option value="2014">2014</option>
  <option value="2015">2015</option>
  <option value="2016">2016</option>
  <option value="2017">2017</option>
  <option value="2018">2018</option>
</select>
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{Date}->{Name}Used" for="DynamicField_$DynamicFieldConfigs{Date}->{Name}Used">
$DynamicFieldConfigs{Date}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },
    {
        Name   => 'Date: Value template',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{Date},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Class              => 'MyClass',
            UseDefaultValue    => 0,
            Template           => {
                DynamicField_DateFieldUsed   => 1,
                DynamicField_DateFieldYear   => 2013,
                DynamicField_DateFieldMonth  => 12,
                DynamicField_DateFieldDay    => 12,
                DynamicField_DateFieldHour   => 0,
                DynamicField_DateFieldMinute => 0,
            },
        },
        ExpectedResults => {
            Field => <<"EOF",
<input type="checkbox" name="DynamicField_$DynamicFieldConfigs{Date}->{Name}Used" id="DynamicField_$DynamicFieldConfigs{Date}->{Name}Used" value="1" checked="checked" class="DynamicFieldText MyClass" title="Check to activate this date" />&nbsp;<select class="Validate_DateMonth DynamicFieldText MyClass" id="DynamicField_$DynamicFieldConfigs{Date}->{Name}Month" name="DynamicField_$DynamicFieldConfigs{Date}->{Name}Month" title="Month">
  <option value="1">01</option>
  <option value="2">02</option>
  <option value="3">03</option>
  <option value="4">04</option>
  <option value="5">05</option>
  <option value="6">06</option>
  <option value="7">07</option>
  <option value="8">08</option>
  <option value="9">09</option>
  <option value="10">10</option>
  <option value="11">11</option>
  <option value="12" selected="selected">12</option>
</select>/<select class="Validate_DateDay Validate_DateYear_DynamicField_$DynamicFieldConfigs{Date}->{Name}Year Validate_DateMonth_DynamicField_$DynamicFieldConfigs{Date}->{Name}Month DynamicFieldText MyClass" id="DynamicField_$DynamicFieldConfigs{Date}->{Name}Day" name="DynamicField_$DynamicFieldConfigs{Date}->{Name}Day" title="Day">
  <option value="1">01</option>
  <option value="2">02</option>
  <option value="3">03</option>
  <option value="4">04</option>
  <option value="5">05</option>
  <option value="6">06</option>
  <option value="7">07</option>
  <option value="8">08</option>
  <option value="9">09</option>
  <option value="10">10</option>
  <option value="11">11</option>
  <option value="12" selected="selected">12</option>
  <option value="13">13</option>
  <option value="14">14</option>
  <option value="15">15</option>
  <option value="16">16</option>
  <option value="17">17</option>
  <option value="18">18</option>
  <option value="19">19</option>
  <option value="20">20</option>
  <option value="21">21</option>
  <option value="22">22</option>
  <option value="23">23</option>
  <option value="24">24</option>
  <option value="25">25</option>
  <option value="26">26</option>
  <option value="27">27</option>
  <option value="28">28</option>
  <option value="29">29</option>
  <option value="30">30</option>
  <option value="31">31</option>
</select>/<select class="Validate_DateYear DynamicFieldText MyClass" id="DynamicField_$DynamicFieldConfigs{Date}->{Name}Year" name="DynamicField_$DynamicFieldConfigs{Date}->{Name}Year" title="Year">
  <option value="2008">2008</option>
  <option value="2009">2009</option>
  <option value="2010">2010</option>
  <option value="2011">2011</option>
  <option value="2012">2012</option>
  <option value="2013" selected="selected">2013</option>
  <option value="2014">2014</option>
  <option value="2015">2015</option>
  <option value="2016">2016</option>
  <option value="2017">2017</option>
  <option value="2018">2018</option>
</select>
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{Date}->{Name}Used" for="DynamicField_$DynamicFieldConfigs{Date}->{Name}Used">
$DynamicFieldConfigs{Date}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },
    {
        Name   => 'Date: Mandatory',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{Date},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Value              => '2013-12-12 00:00:00',
            Class              => 'MyClass',
            UseDefaultValue    => 0,
            Mandatory          => 1,
        },
        ExpectedResults => {
            Field => <<"EOF",
<input type="checkbox" name="DynamicField_$DynamicFieldConfigs{Date}->{Name}Used" id="DynamicField_$DynamicFieldConfigs{Date}->{Name}Used" value="1" checked="checked" class="DynamicFieldText MyClass Validate_Required" title="Check to activate this date" />&nbsp;<select class="Validate_DateMonth DynamicFieldText MyClass Validate_Required" id="DynamicField_$DynamicFieldConfigs{Date}->{Name}Month" name="DynamicField_$DynamicFieldConfigs{Date}->{Name}Month" title="Month">
  <option value="1">01</option>
  <option value="2">02</option>
  <option value="3">03</option>
  <option value="4">04</option>
  <option value="5">05</option>
  <option value="6">06</option>
  <option value="7">07</option>
  <option value="8">08</option>
  <option value="9">09</option>
  <option value="10">10</option>
  <option value="11">11</option>
  <option value="12" selected="selected">12</option>
</select>/<select class="Validate_DateDay Validate_DateYear_DynamicField_$DynamicFieldConfigs{Date}->{Name}Year Validate_DateMonth_DynamicField_$DynamicFieldConfigs{Date}->{Name}Month DynamicFieldText MyClass Validate_Required" id="DynamicField_$DynamicFieldConfigs{Date}->{Name}Day" name="DynamicField_$DynamicFieldConfigs{Date}->{Name}Day" title="Day">
  <option value="1">01</option>
  <option value="2">02</option>
  <option value="3">03</option>
  <option value="4">04</option>
  <option value="5">05</option>
  <option value="6">06</option>
  <option value="7">07</option>
  <option value="8">08</option>
  <option value="9">09</option>
  <option value="10">10</option>
  <option value="11">11</option>
  <option value="12" selected="selected">12</option>
  <option value="13">13</option>
  <option value="14">14</option>
  <option value="15">15</option>
  <option value="16">16</option>
  <option value="17">17</option>
  <option value="18">18</option>
  <option value="19">19</option>
  <option value="20">20</option>
  <option value="21">21</option>
  <option value="22">22</option>
  <option value="23">23</option>
  <option value="24">24</option>
  <option value="25">25</option>
  <option value="26">26</option>
  <option value="27">27</option>
  <option value="28">28</option>
  <option value="29">29</option>
  <option value="30">30</option>
  <option value="31">31</option>
</select>/<select class="Validate_DateYear DynamicFieldText MyClass Validate_Required" id="DynamicField_$DynamicFieldConfigs{Date}->{Name}Year" name="DynamicField_$DynamicFieldConfigs{Date}->{Name}Year" title="Year">
  <option value="2008">2008</option>
  <option value="2009">2009</option>
  <option value="2010">2010</option>
  <option value="2011">2011</option>
  <option value="2012">2012</option>
  <option value="2013" selected="selected">2013</option>
  <option value="2014">2014</option>
  <option value="2015">2015</option>
  <option value="2016">2016</option>
  <option value="2017">2017</option>
  <option value="2018">2018</option>
</select>
<div id="DynamicField_$DynamicFieldConfigs{Date}->{Name}UsedError" class="TooltipErrorMessage">
    <p>
        This field is required.
    </p>
</div>
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{Date}->{Name}Used" for="DynamicField_$DynamicFieldConfigs{Date}->{Name}Used" class="Mandatory">
    <span class="Marker">*</span>
$DynamicFieldConfigs{Date}->{LabelEscaped}:
</label>
EOF
        },
        Success => 1,
    },
    {
        Name   => 'Date: Server Error',
        Config => {
            DynamicFieldConfig => $DynamicFieldConfigs{Date},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Value              => '2013-12-12 00:00:00',
            Class              => 'MyClass',
            UseDefaultValue    => 0,
            ServerError        => 1,
            ErrorMessage       => 'This is an error.'
        },
        ExpectedResults => {
            Field => <<"EOF",
<input type="checkbox" name="DynamicField_$DynamicFieldConfigs{Date}->{Name}Used" id="DynamicField_$DynamicFieldConfigs{Date}->{Name}Used" value="1" checked="checked" class="DynamicFieldText MyClass ServerError" title="Check to activate this date" />&nbsp;<select class="Validate_DateMonth DynamicFieldText MyClass ServerError" id="DynamicField_$DynamicFieldConfigs{Date}->{Name}Month" name="DynamicField_$DynamicFieldConfigs{Date}->{Name}Month" title="Month">
  <option value="1">01</option>
  <option value="2">02</option>
  <option value="3">03</option>
  <option value="4">04</option>
  <option value="5">05</option>
  <option value="6">06</option>
  <option value="7">07</option>
  <option value="8">08</option>
  <option value="9">09</option>
  <option value="10">10</option>
  <option value="11">11</option>
  <option value="12" selected="selected">12</option>
</select>/<select class="Validate_DateDay Validate_DateYear_DynamicField_$DynamicFieldConfigs{Date}->{Name}Year Validate_DateMonth_DynamicField_$DynamicFieldConfigs{Date}->{Name}Month DynamicFieldText MyClass ServerError" id="DynamicField_$DynamicFieldConfigs{Date}->{Name}Day" name="DynamicField_$DynamicFieldConfigs{Date}->{Name}Day" title="Day">
  <option value="1">01</option>
  <option value="2">02</option>
  <option value="3">03</option>
  <option value="4">04</option>
  <option value="5">05</option>
  <option value="6">06</option>
  <option value="7">07</option>
  <option value="8">08</option>
  <option value="9">09</option>
  <option value="10">10</option>
  <option value="11">11</option>
  <option value="12" selected="selected">12</option>
  <option value="13">13</option>
  <option value="14">14</option>
  <option value="15">15</option>
  <option value="16">16</option>
  <option value="17">17</option>
  <option value="18">18</option>
  <option value="19">19</option>
  <option value="20">20</option>
  <option value="21">21</option>
  <option value="22">22</option>
  <option value="23">23</option>
  <option value="24">24</option>
  <option value="25">25</option>
  <option value="26">26</option>
  <option value="27">27</option>
  <option value="28">28</option>
  <option value="29">29</option>
  <option value="30">30</option>
  <option value="31">31</option>
</select>/<select class="Validate_DateYear DynamicFieldText MyClass ServerError" id="DynamicField_$DynamicFieldConfigs{Date}->{Name}Year" name="DynamicField_$DynamicFieldConfigs{Date}->{Name}Year" title="Year">
  <option value="2008">2008</option>
  <option value="2009">2009</option>
  <option value="2010">2010</option>
  <option value="2011">2011</option>
  <option value="2012">2012</option>
  <option value="2013" selected="selected">2013</option>
  <option value="2014">2014</option>
  <option value="2015">2015</option>
  <option value="2016">2016</option>
  <option value="2017">2017</option>
  <option value="2018">2018</option>
</select>
<div id="DynamicField_$DynamicFieldConfigs{Date}->{Name}UsedServerError" class="TooltipErrorMessage">
    <p>
        This is an error.
    </p>
</div>
EOF
            Label => <<"EOF",
<label id="LabelDynamicField_$DynamicFieldConfigs{Date}->{Name}Used" for="DynamicField_$DynamicFieldConfigs{Date}->{Name}Used">
$DynamicFieldConfigs{Date}->{LabelEscaped}:
</label>
EOF

        },
        Success => 1,
    },
);

# execute tests
for my $Test (@Tests) {

    my $FieldHTML;

    if ( IsHashRefWithData( $Test->{Config} ) ) {
        my %Config = %{ $Test->{Config} };

        if ( IsHashRefWithData( $Test->{Config}->{CGIParam} ) ) {

            # create a new CGI object to simulate a web request
            my $WebRequest = CGI->new( $Test->{Config}->{CGIParam} );

            my $LocalParamObject = Kernel::System::Web::Request->new(
                WebRequest => $WebRequest,
            );

            %Config = (
                %Config,
                ParamObject => $LocalParamObject,
            );
        }
        $FieldHTML = $DFBackendObject->EditFieldRender(%Config);
    }
    else {
        $FieldHTML = $DFBackendObject->EditFieldRender( %{ $Test->{Config} } );
    }
    if ( $Test->{Success} ) {

        # Heredocs always have the newline, even if it is not expected
        if ( $FieldHTML->{Field} !~ m{\n$} ) {
            chomp $Test->{ExpectedResults}->{Field};
        }

        $Self->IsDeeply(
            $FieldHTML,
            $Test->{ExpectedResults},
            "$Test->{Name} | EditFieldRender()",
        );
    }
    else {
        $Self->Is(
            $FieldHTML,
            undef,
            "$Test->{Name} | EditFieldRender() (should be undef)",
        );
    }
}

# we don't need any cleanup

1;
