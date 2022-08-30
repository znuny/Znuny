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

use Kernel::System::VariableCheck qw(:all);

# get needed objects
my $HelperObject     = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $ValidationObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::TransitionValidation::ValidateDemo');

# sanity check
$Self->Is(
    ref $ValidationObject,
    'Kernel::System::ProcessManagement::TransitionValidation::ValidateDemo',
    "ValidationObject created successfully",
);

my @Tests = (
    {
        Name    => '1 - No Params',
        Config  => undef,
        Success => 0,
    },
    {
        Name   => '2 - No Data',
        Config => {
            Data => undef,
        },
        Success => 0,
    },
    {
        Name   => '3 - No Queue',
        Config => {
            Data => {
                Queue => undef,
            },
        },
        Success => 0,
    },
    {
        Name   => '4 - Wrong Data Format',
        Config => {
            Data => 'Data',
        },
        Success => 0,
    },
    {
        Name   => '5 - Wrong Queue format',
        Config => {
            Data => {
                Queue => {
                    Name => 'Raw'
                },
            },
        },
        Success => 0,
    },
    {
        Name   => '6 - Empty Queue',
        Config => {
            Data => {
                Queue => '',
            },
        },
        Success => 0,
    },
    {
        Name   => '7 - Wrong Queue (Misc)',
        Config => {
            Data => {
                Queue => 'Misc',
            },
        },
        Success => 0,
    },
    {
        Name   => '8 - Correct Queue (Raw)',
        Config => {
            Data => {
                Queue => 'Raw',
            },
        },
        Success => 1,
    },
);

for my $Test (@Tests) {

    my $ValidateResult = $ValidationObject->Validate( %{ $Test->{Config} } );

    if ( $Test->{Success} ) {
        $Self->Is(
            $ValidateResult,
            1,
            "Validate() ValidationDemo for test $Test->{Name} should return 1",
        );
    }
    else {
        $Self->IsNot(
            $ValidateResult,
            1,
            "Validate() ValidationDemo for test $Test->{Name} should not return 1",
        );
    }
}

1;
