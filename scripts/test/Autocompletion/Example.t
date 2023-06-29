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

my $HelperObject                = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $ConfigObject                = $Kernel::OM->Get('Kernel::Config');
my $QueueObject                 = $Kernel::OM->Get('Kernel::System::Queue');
my $AutocompletionExampleObject = $Kernel::OM->Get('Kernel::System::Autocompletion::Example');

for my $Queue (qw(Postmaster Raw Junk Misc)) {
    my $QueueID = $QueueObject->QueueLookup( Queue => $Queue );

    my $AutocompletionData = $AutocompletionExampleObject->GetData(
        SearchString => $Queue,
        UserID       => 1,
    );

    my $ExpectedAutocompletionData = [
        {
            'selection_list_title' => $Queue,
            'inserted_value'       => "$Queue ($QueueID)",
            'id'                   => $QueueID,
        },
    ];

    $Self->IsDeeply(
        $AutocompletionData,
        $ExpectedAutocompletionData,
        'GetData() returned expected autocompletion data.',
    );
}

1;
