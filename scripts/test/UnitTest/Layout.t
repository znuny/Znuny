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

my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
my $MainObject   = $Kernel::OM->Get('Kernel::System::Main');

$ConfigObject->{'Frontend::Template::GenerateBlockHooks'}->{'100-ZnunyGenerateBlockHooks'} = {
    'AdminState' => [
        'Overview',
        'ActionList',
        'ActionOverview',
        'ActionAdd',
        'OverviewResult',
        'NoDataFoundMsg',
        'OverviewResultRow',
        'OverviewUpdate',
        'HeaderAdd',
        'HeaderEdit',
    ],
};

$LayoutObject->Block(
    Name => 'Overview',
);
$LayoutObject->Block( Name => 'ActionList' );
$LayoutObject->Block( Name => 'ActionAdd' );

$LayoutObject->Block(
    Name => 'OverviewResult',
);
$LayoutObject->Block(
    Name => 'NoDataFoundMsg',
);

my $Output = $LayoutObject->Output(
    TemplateFile => 'AdminState',
);

my %Param = (
    Data => \$Output,
);
for my $HookName (qw( Overview ActionList ActionAdd OverviewResult NoDataFoundMsg )) {

    my $Exists = $LayoutObject->_OutputFilterHookExists(
        Name => $HookName,
        %Param,
    );

    $Self->True(
        $Exists,
        '_OutputFilterHookExists() - check if hook exists "' . $HookName . '"',
    );
}

my $ActionAddData = $LayoutObject->_OutputFilterHookShift(
    Name => 'ActionAdd',
    %Param,
);

$Self->True(
    $ActionAddData,
    '_OutputFilterHookShift() - shift hook "ActionAdd"',
);

my $Exists = $LayoutObject->_OutputFilterHookExists(
    Name => 'ActionAdd',
    %Param,
);

$Self->False(
    $Exists,
    '_OutputFilterHookExists() - check hook "ActionAdd"',
);

my $Success = $LayoutObject->_OutputFilterHookInsertAfter(
    Name    => 'ActionList',
    Content => $ActionAddData,
    %Param,
);

$Self->True(
    $Success,
    '_OutputFilterHookInsertAfter() - insert after "ActionList"',
);

$Exists = $LayoutObject->_OutputFilterHookExists(
    Name => 'ActionAdd',
    %Param,
);

$Self->True(
    $Exists,
    '_OutputFilterHookExists() - check hook "ActionAdd"',
);

$ActionAddData = $LayoutObject->_OutputFilterHookShift(
    Name => 'ActionAdd',
    %Param,
);

$Self->True(
    $ActionAddData,
    '_OutputFilterHookShift() - shift hook "ActionAdd"',
);

$Success = $LayoutObject->_OutputFilterHookInsertBefore(
    Name    => 'ActionList',
    Content => $ActionAddData,
    %Param,
);

$Self->True(
    $Success,
    '_OutputFilterHookInsertAfter() - insert after "ActionList"',
);

$Exists = $LayoutObject->_OutputFilterHookExists(
    Name => 'ActionAdd',
    %Param,
);

$Self->True(
    $Exists,
    '_OutputFilterHookExists() - check hook "ActionAdd"',
);

$Success = $LayoutObject->_OutputFilterHookReplace(
    Name    => 'ActionAdd',
    Replace => sub {
        my (%Param) = @_;

        my $Content = $Param{Content};

        $Content .= 'blub';

        return $Content;
    },
    %Param,
);

$Self->True(
    $Success,
    '_OutputFilterHookReplace() - replace hook "ActionAdd"',
);

$Self->True(
    ( $Output =~ m{blub}xmsi ? 1 : 0 ),
    '_OutputFilterHookReplace() - check replacement for "ActionAdd"',
);

1;
