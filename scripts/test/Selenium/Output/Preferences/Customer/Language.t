# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
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

        my $TestUserLogin = $HelperObject->TestCustomerUserCreate(
            Groups => ['admin'],
        ) || die "Did not get test user";

        $Selenium->Login(
            Type     => 'Customer',
            User     => $TestUserLogin,
            Password => $TestUserLogin,
        );

        my $ScriptAlias = $Kernel::OM->Get('Kernel::Config')->Get('ScriptAlias');

        # go to customer preferences
        $Selenium->VerifiedGet("${ScriptAlias}customer.pl?Action=CustomerPreferences");

        my $Language = 'de';

        # change test user language preference to Deutsch
        $Selenium->InputFieldValueSet(
            Element => '#UserLanguage',
            Value   => $Language,
        );
        $Selenium->find_element( "#UserLanguageUpdate", 'css' )->VerifiedClick();

        # check for update preference message on screen
        my $LanguageObject = Kernel::Language->new(
            UserLanguage => $Language,
        );
        my $UpdateMessage = $LanguageObject->Translate('Preferences updated successfully!');
        $Self->True(
            index( $Selenium->get_page_source(), $UpdateMessage ) > -1,
            'Customer preference language - updated'
        );
    }
);

1;
