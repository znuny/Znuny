# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

## no critic (Modules::RequireExplicitPackage)
use strict;
use warnings;
use utf8;

use vars (qw($Self));

use Cwd qw(abs_path);

my $MainObject = $Kernel::OM->Get('Kernel::System::Main');
$MainObject->Require('Kernel::Modules::AdminProcessManagement');

my $TestModule = Kernel::Modules::AdminProcessManagement->new();
my $Home       = $Kernel::OM->Get('Kernel::Config')->Get('Home');
my $Base       = abs_path("$Home/var/processes/examples");

$Self->True(
    $Base && -d $Base,
    'Examples directory can be resolved',
);

my @ExampleFiles = (
    'Application_for_leave.yml',
);

for my $Filename (@ExampleFiles) {

    my %Location = $TestModule->_ExampleProcessLocationGet(
        Filename => $Filename,
    );

    my ($FileWithoutExtension) = $Filename =~ m{\A(.+)\.yml\z}xms;

    $Self->Is(
        $Location{FileWithoutExtension},
        $FileWithoutExtension,
        "$Filename file name without extension",
    );

    $Self->Is(
        $Location{Location},
        "$Base/$Filename",
        "$Filename stays inside the examples directory",
    );

    for my $Hook (qw(pre post)) {
        my $HookLocation = $TestModule->_ExampleProcessHookLocationGet(
            FileWithoutExtension => $FileWithoutExtension,
            Hook                 => $Hook,
        );

        $Self->Is(
            $HookLocation,
            "$Base/${FileWithoutExtension}_${Hook}.pm",
            "$Filename $Hook hook stays inside the examples directory",
        );
    }
}

my %MissingFile = $TestModule->_ExampleProcessLocationGet(
    Filename => 'No_such_example_process.yml',
);

$Self->Is(
    $MissingFile{Location},
    undef,
    'Missing example file is rejected',
);

my @RejectedFilenames = (
    '',
    '../Application_for_leave.yml',
    '/etc/passwd',
    'Application_for_leave.yml/../../etc/passwd',
    '..\\..\\etc\\passwd',
    '/../../../../../etc/passwd',
    'foo/bar.yml',
);

for my $Filename (@RejectedFilenames) {

    my %Location = $TestModule->_ExampleProcessLocationGet(
        Filename => $Filename,
    );

    my $Label = 'empty name';
    if ( $Filename ne '' ) {
        $Label = $Filename;
    }

    $Self->Is(
        $Location{Location},
        undef,
        "Rejected example file name: $Label",
    );
}

my @RejectedHooks = (
    {
        Name                 => 'parent segments in the file name',
        FileWithoutExtension => '../tmp/evil',
        Hook                 => 'pre',
    },
    {
        Name                 => 'file name is not a plain identifier',
        FileWithoutExtension => 'Application.for.leave',
        Hook                 => 'pre',
    },
    {
        Name                 => 'empty file name',
        FileWithoutExtension => '',
        Hook                 => 'pre',
    },
    {
        Name                 => 'hook is not pre or post',
        FileWithoutExtension => 'Application_for_leave',
        Hook                 => 'init',
    },
);

for my $RejectedHook (@RejectedHooks) {
    my $HookLocation = $TestModule->_ExampleProcessHookLocationGet(
        FileWithoutExtension => $RejectedHook->{FileWithoutExtension},
        Hook                 => $RejectedHook->{Hook},
    );

    $Self->Is(
        $HookLocation,
        undef,
        "Rejected hook: $RejectedHook->{Name}",
    );
}

1;
