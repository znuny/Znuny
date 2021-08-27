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
my $UnitTestHelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

my @Filters = (
    {
        'Match' => {
            'Auto-Submitted' => '123'
        },
        'Name' => 'filter 1',
        'Not'  => {
            'Auto-Submitted' => undef
        },
        'Set' => {
            'X-OTRS-DynamicField-blub' => '123'
        },
        'StopAfterMatch' => '0'
    },
    {
        'Match' => {
            'Auto-Submitted' => '123'
        },
        'Name' => 'fitler 2',
        'Not'  => {
            'Auto-Submitted' => undef
        },
        'Set' => {
            'X-OTRS-DynamicField-blub' => '123'
        },
        'StopAfterMatch' => '0'
    },
);
my $Result = $ZnunyHelperObject->_PostMasterFilterCreate(@Filters);

$Self->True(
    $Result,
    '_PostMasterFilterCreate()',
);

my $Configs = $ZnunyHelperObject->_PostMasterFilterConfigExport(
    Format => 'perl',
);

FILTER:
for my $Filter (@Filters) {
    my $Match = $Configs =~ m{\Q$Filter->{Name}\E}xmsi ? 1 : 0;
    $Self->True(
        $Match,
        'Export contains name of the post master filter "' . $Filter->{Name} . '"',
    );
}

1;
