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

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);

my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
my $HelperObject       = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

my $RandomID = $HelperObject->GetRandomNumber();
my $UserID   = 1;

my @Tests = (
    {
        Name               => 'RegEx error message without malicious content.',
        DynamicFieldConfig => {
            Name       => 'RegExErrorMessageSafety1',
            Label      => 'RegExErrorMessageSafety1',
            FieldOrder => 10000,
            FieldType  => 'Text',
            ObjectType => 'Ticket',
            Config     => {
                RegExList => [
                    {
                        Value        => '^\d+$',
                        ErrorMessage => 'Some error message.',
                    },
                    {
                        Value        => '^\d{2}$',
                        ErrorMessage => 'Another error message.',
                    },
                ],
            },
            ValidID => 1,
        },
        ExpectedDynamicFieldConfigRegExList => [
            {
                Value        => '^\d+$',
                ErrorMessage => 'Some error message.',
            },
            {
                Value        => '^\d{2}$',
                ErrorMessage => 'Another error message.',
            },
        ],
    },
    {
        Name               => 'RegEx error message with malicious content.',
        DynamicFieldConfig => {
            Name       => 'RegExErrorMessageSafety2',
            Label      => 'RegExErrorMessageSafety2',
            FieldOrder => 10000,
            FieldType  => 'Text',
            ObjectType => 'Ticket',
            Config     => {
                RegExList => [
                    {
                        Value        => '^\d+$',
                        ErrorMessage => 'Some <script>alert("TEST");</script> error message.',
                    },
                    {
                        Value        => '^\d{2}$',
                        ErrorMessage => 'Another <script>console.log("TEST2");</script>error message.',
                    },
                ],
            },
            ValidID => 1,
        },
        ExpectedDynamicFieldConfigRegExList => [
            {
                Value        => '^\d+$',
                ErrorMessage => 'Some  error message.',
            },
            {
                Value        => '^\d{2}$',
                ErrorMessage => 'Another error message.',
            },
        ],
    },
);

TEST:
for my $Test (@Tests) {
    my $DynamicFieldID = $DynamicFieldObject->DynamicFieldAdd(
        %{ $Test->{DynamicFieldConfig} },
        UserID => $UserID,
    );

    $Self->True(
        $DynamicFieldID,
        "$Test->{Name} - DynamicFieldAdd() must be successful.",
    );

    my $DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
        ID => $DynamicFieldID,
    );

    $Self->IsDeeply(
        $DynamicFieldConfig->{Config}->{RegExList},
        $Test->{ExpectedDynamicFieldConfigRegExList},
        "$Test->{Name} - RegEx config must match expected one.",
    );
}

1;
