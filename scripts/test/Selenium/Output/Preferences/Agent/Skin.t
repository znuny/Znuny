# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

## no critic (Modules::RequireExplicitPackage)
use strict;
use warnings;
use utf8;

use vars (qw($Self));

# get selenium object
my $Selenium = $Kernel::OM->Get('Kernel::System::UnitTest::Selenium');

$Selenium->RunTest(
    sub {

        my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
        my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

        my $TestUserLogin = $HelperObject->TestUserCreate(
            Groups => ['admin'],
        ) || die "Did not get test user";

        $Selenium->Login(
            Type     => 'Agent',
            User     => $TestUserLogin,
            Password => $TestUserLogin,
        );

        my $ScriptAlias = $ConfigObject->Get('ScriptAlias');

        # go to agent preferences
        $Selenium->VerifiedGet("${ScriptAlias}index.pl?Action=AgentPreferences;Subaction=Group;Group=Miscellaneous");

        # Available agent skins are "default" and "dark" (Loader::Agent::Skin).
        # Saving the skin sets NeedsReload, which reloads the page and removes the
        # success icon before it can be observed.
        $Selenium->InputFieldValueSet(
            Element => '#UserSkin',
            Value   => 'dark',
        );
        $Selenium->execute_script('window.SeleniumSkinUpdated = 1;');
        $Selenium->WaitForjQueryEventBound(
            CSSSelector => "form:has(input[type=hidden][name=Group][value=Skin]) .WidgetSimple .SettingUpdateBox button.Update",
        );
        $Selenium->execute_script(
            "\$('#UserSkin').closest('.WidgetSimple').find('.SettingUpdateBox').find('button.Update').trigger('click');"
        );
        $Selenium->WaitFor(
            JavaScript =>
                "return !window.SeleniumSkinUpdated && typeof(\$) === 'function' && \$('#UserSkin').val() === 'dark';"
        );
    }
);

1;
