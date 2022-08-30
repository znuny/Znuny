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

# get helper object
$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase  => 1,
        UseTmpArticleDir => 1,
    },
);
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

# get needed objects
my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
my $BackendObject      = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
my $TicketObject       = $Kernel::OM->Get('Kernel::System::Ticket');

# start tests
# always random number with the same number of digits
my $RandomID = $HelperObject->GetRandomNumber();
$RandomID = substr $RandomID, -7, 7;
my @FieldIDs;

# create a dynamic field with short name length (21 characters)
my $FieldID1 = $DynamicFieldObject->DynamicFieldAdd(
    Name       => "TestTextArea$RandomID",
    Label      => 'TestTextAreaShortName',
    FieldOrder => 9991,
    FieldType  => 'TextArea',
    ObjectType => 'Ticket',
    Config     => {
        DefaultValue => 'TestTextAreaShortName',
    },
    ValidID => 1,
    UserID  => 1,
);

if ($FieldID1) {
    push @FieldIDs, $FieldID1;
}

# sanity check
$Self->True(
    $FieldID1,
    "DynamicFieldAdd() successful for Field ID $FieldID1",
);

# create a dynamic field with long name length (166 characters)
my $FieldID2 = $DynamicFieldObject->DynamicFieldAdd(
    Name =>
        "TestTextArea1TestTextArea2TestTextArea3TestTextArea4TestTextArea5TestTextArea6TestTextArea7TestTextArea8TestTextArea9TestTextArea10TestTextArea11TestTextArea$RandomID",
    Label      => 'TestTextArea_long',
    FieldOrder => 9992,
    FieldType  => 'TextArea',
    ObjectType => 'Ticket',
    Config     => {
        DefaultValue => 'TestTextAreaLongName',
    },
    ValidID => 1,
    UserID  => 1,
);

# sanity check
$Self->True(
    $FieldID2,
    "DynamicFieldAdd() successful for Field ID $FieldID2",
);
if ($FieldID2) {
    push @FieldIDs, $FieldID2;
}

# get the Dynamic Fields configuration
my $DynamicFieldsConfig = $Kernel::OM->Get('Kernel::Config')->Get('DynamicFields::Driver');

# sanity check
$Self->Is(
    ref $DynamicFieldsConfig,
    'HASH',
    'Dynamic Field configuration',
);
$Self->IsNotDeeply(
    $DynamicFieldsConfig,
    {},
    'Dynamic Field configuration is not empty',
);

$Self->True(
    $BackendObject,
    'Backend object was created',
);

$Self->Is(
    ref $BackendObject,
    'Kernel::System::DynamicField::Backend',
    'Backend object was created successfully',
);

# check all registered backend delegates
my $FieldType = 'TextArea';
$Self->True(
    $BackendObject->{ 'DynamicField' . $FieldType . 'Object' },
    "Backend delegate for field type $FieldType was created",
);

$Self->Is(
    ref $BackendObject->{ 'DynamicField' . $FieldType . 'Object' },
    $DynamicFieldsConfig->{$FieldType}->{Module},
    "Backend delegate for field type $FieldType was created successfully",
);

# Tests for different length of Dynamic Field name and Value
# short value there is 12 characters
# long value there is 159 characters
# extra-long value there is 318 characters

my @Tests = (
    {
        Name               => 'short Value for short field name',
        DynamicFieldConfig => {
            ID         => $FieldID1,
            Name       => "TestTextArea$RandomID",
            ObjectType => 'Ticket',
            FieldType  => 'TextArea',
            Config     => {
                DefaultValue => 'TestTextArea',
            },
        },
        Value      => 'TestTextArea',
        UserID     => 1,
        Success    => 1,
        ShouldGet  => 1,
        FirstValue => 'TestTextArea_FirstValue',
        ExpectedData =>
            "%%FieldName%%TestTextArea$RandomID%%Value%%TestTextArea%%OldValue%%TestTextArea_FirstValue",
        ExpectedDataWitoutOld =>
            "%%FieldName%%TestTextArea$RandomID%%Value%%TestTextArea_FirstValue%%OldValue%%",
    },
    {
        Name               => 'long Value for short field name',
        DynamicFieldConfig => {
            ID         => $FieldID1,
            Name       => "TestTextArea$RandomID",
            ObjectType => 'Ticket',
            FieldType  => 'TextArea',
            Config     => {
                DefaultValue => 'TestTextArea',
            },
        },
        Value =>
            'TestTextArea1TestTextArea2TestTextArea3TestTextArea4TestTextArea5TestTextArea6TestTextArea7TestTextArea8TestTextArea9TestTextArea10TestTextArea11TestTextArea',
        UserID     => 1,
        Success    => 1,
        ShouldGet  => 1,
        FirstValue => 'TestTextArea_FirstValue',
        ExpectedData =>
            "%%FieldName%%TestTextArea$RandomID%%Value%%TestTextArea1TestTextArea2TestTextArea3TestTextArea4TestTextArea5TestTextArea6TestTextArea7TestTextArea8TestTextArea9Te[...]%%OldValue%%TestTextArea_FirstValue",
        ExpectedDataWitoutOld =>
            "%%FieldName%%TestTextArea$RandomID%%Value%%TestTextArea_FirstValue%%OldValue%%",
    },

    {
        Name               => 'extra long Value for short field name',
        DynamicFieldConfig => {
            ID         => $FieldID1,
            Name       => "TestTextArea$RandomID",
            ObjectType => 'Ticket',
            FieldType  => 'TextArea',
            Config     => {
                DefaultValue => 'TestTextArea',
            },
        },

        Value =>
            'TestTextArea1TestTextArea2TestTextArea3TestTextArea4TestTextArea5TestTextArea6TestTextArea7TestTextArea8TestTextArea9TestTextArea10TestTextArea11TestTextArea12TestTextArea1TestTextArea2TestTextArea3TestTextArea4TestTextArea5TestTextArea6TestTextArea7TestTextArea8TestTextArea9TestTextArea10TestTextArea11TestTextArea12',
        UserID     => 1,
        Success    => 1,
        ShouldGet  => 1,
        FirstValue => 'TestTextArea_FirstValue',
        ExpectedData =>
            "%%FieldName%%TestTextArea$RandomID%%Value%%TestTextArea1TestTextArea2TestTextArea3TestTextArea4TestTextArea5TestTextArea6TestTextArea7TestTextArea8TestTextArea9Te[...]%%OldValue%%TestTextArea_FirstValue",
        ExpectedDataWitoutOld =>
            "%%FieldName%%TestTextArea$RandomID%%Value%%TestTextArea_FirstValue%%OldValue%%",
    },
    {
        Name               => 'short Value for long field name',
        DynamicFieldConfig => {
            ID => $FieldID2,
            Name =>
                "TestTextArea1TestTextArea2TestTextArea3TestTextArea4TestTextArea5TestTextArea6TestTextArea7TestTextArea8TestTextArea9TestTextArea10TestTextArea11TestTextArea$RandomID",
            ObjectType => 'Ticket',
            FieldType  => 'TextArea',
            Config     => {
                DefaultValue => 'TestTextArea',
            },
        },

        Value      => 'TestTextArea',
        UserID     => 1,
        Success    => 1,
        ShouldGet  => 1,
        FirstValue => 'TestTextArea_FirstValue',
        ExpectedData =>
            "%%FieldName%%TestTextArea1TestTextArea2TestTextArea3TestTextArea4TestTextArea5TestTextArea6TestTextArea7TestTextArea8TestTextArea9TestTextA[...]%%Value%%TestTextArea%%OldValue%%TestTextArea_FirstValue",
        ExpectedDataWitoutOld =>
            "%%FieldName%%TestTextArea1TestTextArea2TestTextArea3TestTextArea4TestTextArea5TestTextArea6TestTextArea7TestTextArea8TestTextArea9TestTextArea10TestTex[...]%%Value%%TestTextArea_FirstValue%%OldValue%%",
    },
    {
        Name               => 'long Value for long field name',
        DynamicFieldConfig => {
            ID => $FieldID2,
            Name =>
                "TestTextArea1TestTextArea2TestTextArea3TestTextArea4TestTextArea5TestTextArea6TestTextArea7TestTextArea8TestTextArea9TestTextArea10TestTextArea11TestTextArea$RandomID",
            ObjectType => 'Ticket',
            FieldType  => 'TextArea',
            Config     => {
                DefaultValue => 'TestTextArea',
            },
        },

        Value =>
            'TestTextArea1TestTextArea2TestTextArea3TestTextArea4TestTextArea5TestTextArea6TestTextArea7TestTextArea8TestTextArea9TestTextArea10TestTextArea11TestTextArea12',
        UserID     => 1,
        Success    => 1,
        ShouldGet  => 1,
        FirstValue => 'TestTextArea_FirstValue',
        ExpectedData =>
            "%%FieldName%%TestTextArea1TestTextArea2TestTextArea3TestTextArea4TestTextArea5T[...]%%Value%%TestTextArea1TestTextArea2TestTextArea3TestTextArea4TestTextArea5T[...]%%OldValue%%TestTextArea_FirstValue",
        ExpectedDataWitoutOld =>
            "%%FieldName%%TestTextArea1TestTextArea2TestTextArea3TestTextArea4TestTextArea5TestTextArea6TestTextArea7TestTextArea8TestTextArea9TestTextArea10TestTex[...]%%Value%%TestTextArea_FirstValue%%OldValue%%",
    },
    {
        Name               => 'extra-long Value for long field name',
        DynamicFieldConfig => {
            ID => $FieldID2,
            Name =>
                "TestTextArea1TestTextArea2TestTextArea3TestTextArea4TestTextArea5TestTextArea6TestTextArea7TestTextArea8TestTextArea9TestTextArea10TestTextArea11TestTextArea$RandomID",
            ObjectType => 'Ticket',
            FieldType  => 'TextArea',
            Config     => {
                DefaultValue => 'TestTextArea',
            },
        },

        Value =>
            'TestTextArea1TestTextArea2TestTextArea3TestTextArea4TestTextArea5TestTextArea6TestTextArea7TestTextArea8TestTextArea9TestTextArea10TestTextArea11TestTextArea12TestTextArea1TestTextArea2TestTextArea3TestTextArea4TestTextArea5TestTextArea6TestTextArea7TestTextArea8TestTextArea9TestTextArea10TestTextArea11TestTextArea12',
        UserID     => 1,
        Success    => 1,
        ShouldGet  => 1,
        FirstValue => 'TestTextArea_FirstValue',
        ExpectedData =>
            "%%FieldName%%TestTextArea1TestTextArea2TestTextArea3TestTextArea4TestTextArea5T[...]%%Value%%TestTextArea1TestTextArea2TestTextArea3TestTextArea4TestTextArea5T[...]%%OldValue%%TestTextArea_FirstValue",
        ExpectedDataWitoutOld =>
            "%%FieldName%%TestTextArea1TestTextArea2TestTextArea3TestTextArea4TestTextArea5TestTextArea6TestTextArea7TestTextArea8TestTextArea9TestTextArea10TestTex[...]%%Value%%TestTextArea_FirstValue%%OldValue%%",
    },
    {
        Name               => 'extra-long Value for long field name  and short FirstValue',
        DynamicFieldConfig => {
            ID => $FieldID2,
            Name =>
                "TestTextArea1TestTextArea2TestTextArea3TestTextArea4TestTextArea5TestTextArea6TestTextArea7TestTextArea8TestTextArea9TestTextArea10TestTextArea11TestTextArea$RandomID",
            ObjectType => 'Ticket',
            FieldType  => 'TextArea',
            Config     => {
                DefaultValue => 'TestTextArea',
            },
        },

        Value =>
            'TestTextArea1TestTextArea2TestTextArea3TestTextArea4TestTextArea5TestTextArea6TestTextArea7TestTextArea8TestTextArea9TestTextArea10TestTextArea11TestTextArea12TestTextArea1TestTextArea2TestTextArea3TestTextArea4TestTextArea5TestTextArea6TestTextArea7TestTextArea8TestTextArea9TestTextArea10TestTextArea11TestTextArea12',
        UserID     => 1,
        Success    => 1,
        ShouldGet  => 1,
        FirstValue => 'TestTextArea_FirstValue_Short',
        ExpectedData =>
            "%%FieldName%%TestTextArea1TestTextArea2TestTextArea3TestTextArea4TestTextAre[...]%%Value%%TestTextArea1TestTextArea2TestTextArea3TestTextArea4TestTextAre[...]%%OldValue%%TestTextArea_FirstValue_Short",
        ExpectedDataWitoutOld =>
            "%%FieldName%%TestTextArea1TestTextArea2TestTextArea3TestTextArea4TestTextArea5TestTextArea6TestTextArea7TestTextArea8TestTextArea9TestTextArea10T[...]%%Value%%TestTextArea_FirstValue_Short%%OldValue%%",
    },
    {
        Name               => 'extra-long Value for long field name and long FirstValue',
        DynamicFieldConfig => {
            ID => $FieldID2,
            Name =>
                "TestTextArea1TestTextArea2TestTextArea3TestTextArea4TestTextArea5TestTextArea6TestTextArea7TestTextArea8TestTextArea9TestTextArea10TestTextArea11TestTextArea$RandomID",
            ObjectType => 'Ticket',
            FieldType  => 'TextArea',
            Config     => {
                DefaultValue => 'TestTextArea',
            },
        },

        Value =>
            'TestTextArea1TestTextArea2TestTextArea3TestTextArea4TestTextArea5TestTextArea6TestTextArea7TestTextArea8TestTextArea9TestTextArea10TestTextArea11TestTextArea12TestTextArea1TestTextArea2TestTextArea3TestTextArea4TestTextArea5TestTextArea6TestTextArea7TestTextArea8TestTextArea9TestTextArea10TestTextArea11TestTextArea12',
        UserID    => 1,
        Success   => 1,
        ShouldGet => 1,
        FirstValue =>
            'TestTextArea1TestTextArea2TestTextArea3TestTextArea4TestTextArea5TestTextArea6_FirstValue_Long',
        ExpectedData =>
            "%%FieldName%%TestTextArea1TestTextArea2TestTextArea3TestTextAre[...]%%Value%%TestTextArea1TestTextArea2TestTextArea3TestTextAre[...]%%OldValue%%TestTextArea1TestTextArea2TestTextArea3TestTextAre[...]",
        ExpectedDataWitoutOld =>
            "%%FieldName%%TestTextArea1TestTextArea2TestTextArea3TestTextArea4TestTextArea5TestTextArea6[...]%%Value%%TestTextArea1TestTextArea2TestTextArea3TestTextArea4TestTextArea5TestTextArea6[...]%%OldValue%%",
    },

    {
        Name               => 'empty Value and long FirstValue',
        DynamicFieldConfig => {
            ID => $FieldID2,
            Name =>
                "TestTextArea$RandomID",
            ObjectType => 'Ticket',
            FieldType  => 'TextArea',
            Config     => {
                DefaultValue => 'TestTextArea',
            },
        },

        Value     => '',
        UserID    => 1,
        Success   => 1,
        ShouldGet => 1,
        FirstValue =>
            'TestTextArea1TestTextArea2TestTextArea3TestTextArea4TestTextArea5TestTextArea6TextArea7TextArea8TextArea9TextArea10TextArea11TextArea12TextArea13TextArea14TextArea15_FirstValue_Long',
        ExpectedData =>
            "%%FieldName%%TestTextArea$RandomID%%Value%%%%OldValue%%TestTextArea1TestTextArea2TestTextArea3TestTextAre[...]",
        ExpectedDataWitoutOld =>
            "%%FieldName%%TestTextArea$RandomID%%Value%%TestTextArea1TestTextArea2TestTextArea3TestTextArea4TestTextArea5TestTextArea6TextArea7TextArea8TextArea9TextArea10TextArea11TextArea12TextAre[...]%%OldValue%%",
    },
    {
        Name               => 'long Value and empty FirstValue',
        DynamicFieldConfig => {
            ID         => $FieldID2,
            Name       => "TestTextArea$RandomID",
            ObjectType => 'Ticket',
            FieldType  => 'TextArea',
            Config     => {
                DefaultValue => 'TestTextArea',
            },
        },

        Value =>
            'TestTextArea1TestTextArea2TestTextArea3TestTextArea4TestTextArea5TestTextArea6TestTextArea7TestTextArea8TestTextArea9TestTextArea10TestTextArea11TestTextArea12TestTextArea1TestTextArea2TestTextArea3TestTextArea4TestTextArea5TestTextArea6TestTextArea7TestTextArea8TestTextArea9TestTextArea10TestTextArea11TestTextArea12',
        UserID     => 1,
        Success    => 1,
        ShouldGet  => 1,
        FirstValue => '',
        ExpectedData =>
            "%%FieldName%%TestTextArea1TestTextArea2TestTextArea3TestTextAre[...]%%Value%%TestTextArea1TestTextArea2TestTextArea3TestTextArea4TestTextArea5TestTextArea6TestTextArea7TestTextArea8Te[...]%%OldValue%%",
        ExpectedDataWitoutOld =>
            "%%FieldName%%TestTextArea$RandomID%%Value%%TestTextArea1TestTextArea2TestTextArea3TestTextArea4TestTextArea5TestTextArea6TestTextArea7TestTextArea8TestTextArea9TestTextArea10TestTextAre[...]%%OldValue%%",
    },
);

for my $Test (@Tests) {

    # create a ticket for test DynamicField Value
    my $TicketID = $TicketObject->TicketCreate(
        Title        => 'Some Ticket Title',
        Queue        => 'Raw',
        Lock         => 'unlock',
        Priority     => '3 normal',
        State        => 'new',
        CustomerID   => 'unittest' . $RandomID,
        CustomerUser => 'customer@example.com',
        OwnerID      => 1,
        UserID       => 1,
    );

    # sanity check
    $Self->True(
        $TicketID,
        "$Test->{Name} - TicketCreate() successful for Ticket ID $TicketID",
    );

    #  set value of dynamic field, OldValue is not set on TicketCreate
    my $Success = $BackendObject->ValueSet(
        DynamicFieldConfig => $Test->{DynamicFieldConfig},
        ObjectID           => $TicketID,
        Value              => $Test->{FirstValue},
        UserID             => $Test->{UserID},
    );

    #  update value of dynamic field for ticket history to set OldValue
    $Success = $BackendObject->ValueSet(
        DynamicFieldConfig => $Test->{DynamicFieldConfig},
        ObjectID           => $TicketID,
        Value              => $Test->{Value},
        UserID             => $Test->{UserID},
    );

    if ( !$Test->{Success} ) {
        $Self->False(
            $Success,
            "$Test->{Name} - ValueSet() - Test ($Test->{Name}) - with False",
        );

        # Try to get the value with ValueGet()
        my $Value = $BackendObject->ValueGet(
            DynamicFieldConfig => $Test->{DynamicFieldConfig},
            ObjectID           => $TicketID,
        );

        # fix Value if it's an array ref
        if ( defined $Value && ref $Value eq 'ARRAY' ) {
            $Value = join ',', @{$Value};
        }

        # compare data
        if ( $Test->{ShouldGet} ) {

            $Self->IsNot(
                $Value,
                $Test->{Value},
                "$Test->{Name} - ValueGet() after unsuccessful ValueSet() - (Test $Test->{Name}) - Value",
            );
        }
        else {
            $Self->Is(
                $Value,
                undef,
                "$Test->{Name} - ValueGet() after unsuccessful ValueSet() - (Test $Test->{Name}) - Value undef",
            );
        }

    }
    else {
        $Self->True(
            $Success,
            "$Test->{Name} - ValueSet() - Test ($Test->{Name}) - with True",
        );

        # get the value with ValueGet()
        my $Value = $BackendObject->ValueGet(
            DynamicFieldConfig => $Test->{DynamicFieldConfig},
            ObjectID           => $TicketID,
        );

        # workaround for oracle
        # oracle databases can't determine the difference between NULL and ''
        if ( !defined $Value || $Value eq '' ) {

            # test falseness
            $Self->False(
                $Value,
                "$Test->{Name} - ValueGet() after successful ValueSet() - (Test $Test->{Name}) - "
                    . "Value (Special case for '')"
            );
        }
        else {
            if ( ref $Value eq 'ARRAY' ) {

                # compare data
                $Self->IsDeeply(
                    $Value,
                    $Test->{Value},
                    "$Test->{Name} - ValueGet() after successful ValueSet() - (Test $Test->{Name}) - Value",
                );

            }
            else {

                # compare data
                $Self->Is(
                    $Value,
                    $Test->{Value},
                    "$Test->{Name} - ValueGet() after successful ValueSet() - (Test $Test->{Name}) - Value",
                );
            }
        }

        my @HistoryGet = $TicketObject->HistoryGet(
            UserID   => 1,
            TicketID => $TicketID,
        );

        my $NoHistoryField = scalar @HistoryGet;
        my $ResultEntry    = 'HistoryType';
        for my $ResultCount ( 0 .. ( $NoHistoryField - 1 ) ) {

            if ( $HistoryGet[$ResultCount]->{$ResultEntry} eq 'TicketDynamicFieldUpdate' ) {

                my $ResultEntryDynamicField = 'Name';

                #check if there is OldValue
                ( my $CheckOldValue ) = $HistoryGet[$ResultCount]->{$ResultEntryDynamicField}
                    =~ /\%\%OldValue\%\%(?:(.+?))?$/;
                if ($CheckOldValue) {
                    $Self->Is(
                        $HistoryGet[$ResultCount]->{$ResultEntryDynamicField},
                        $Test->{ExpectedData},
                        "$Test->{Name} for Ticket DynamicField Update - History Name for ticket $TicketID"
                    );
                }
                else {
                    $Self->Is(
                        $HistoryGet[$ResultCount]->{$ResultEntryDynamicField},
                        $Test->{ExpectedDataWitoutOld},
                        "$Test->{Name} for TicketCreate - History Name for ticket $TicketID"
                    );
                }
            }
        }
    }
}

# cleanup is done by RestoreDatabase

1;
