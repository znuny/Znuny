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

use Kernel::System::VariableCheck qw(IsHashRefWithData);

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);

my $MainObject = $Kernel::OM->Get('Kernel::System::Main');

$Kernel::OM->Get('Kernel::System::UnitTest::Helper');

$MainObject->Require('Kernel::Modules::AdminOAuth2TokenManagement');

my $ModuleObject = Kernel::Modules::AdminOAuth2TokenManagement->new();

my @Tests = (
    {
        Name         => 'Known template',
        Filename     => 'GoogleMail',
        Success      => 1,
        TemplateName => 'Google Mail',
    },
    {
        Name          => 'Parent directory',
        Filename      => '../oauth2_token_config_example',
        Success       => 0,
        ForbiddenName => 'Microsoft Outlook auth code flow (example@outlook.com)',
    },
    {
        Name     => 'Slash in filename',
        Filename => 'GoogleMail/Secret',
        Success  => 0,
    },
    {
        Name     => 'Unknown template',
        Filename => 'DoesNotExist',
        Success  => 0,
    },
);

TEST:
for my $Test (@Tests) {
    my $TokenConfigTemplate = $ModuleObject->_GetTokenConfigTemplate(
        TokenConfigTemplateFilename => $Test->{Filename},
    );

    if ( $Test->{Success} ) {
        $Self->True(
            IsHashRefWithData($TokenConfigTemplate),
            $Test->{Name} . ' - template was read.',
        );
        $Self->Is(
            $TokenConfigTemplate->{Name},
            $Test->{TemplateName},
            $Test->{Name} . ' - template name.',
        );
        next TEST;
    }

    my $TemplateWasRead = IsHashRefWithData($TokenConfigTemplate) ? 1 : 0;
    $Self->False(
        $TemplateWasRead,
        $Test->{Name} . ' - template was not read.',
    );

    next TEST if !$Test->{ForbiddenName};

    my $TemplateName = '';
    if ($TemplateWasRead) {
        $TemplateName = $TokenConfigTemplate->{Name} // '';
    }

    $Self->IsNot(
        $TemplateName,
        $Test->{ForbiddenName},
        $Test->{Name} . ' - outside template content was not returned.',
    );
}

1;
