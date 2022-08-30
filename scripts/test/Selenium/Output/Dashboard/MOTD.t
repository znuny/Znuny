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

# get selenium object
my $Selenium = $Kernel::OM->Get('Kernel::System::UnitTest::Selenium');

$Selenium->RunTest(
    sub {

        # get helper object
        my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

        # get dashboard MOTD plugin default sysconfig
        my %MOTDConfig = $Kernel::OM->Get('Kernel::System::SysConfig')->SettingGet(
            Name    => 'DashboardBackend###0210-MOTD',
            Default => 1,
        );

        $HelperObject->ConfigSettingChange(
            Valid => 1,
            Key   => 'DashboardBackend###0210-MOTD',
            Value => $MOTDConfig{EffectiveValue},
        );

        # # create test user and login
        my $TestUserLogin = $HelperObject->TestUserCreate(
            Groups => [ 'admin', 'users' ],
        ) || die "Did not get test user";

        $Selenium->Login(
            Type     => 'Agent',
            User     => $TestUserLogin,
            Password => $TestUserLogin,
        );

        # test if MOTD plugin shows correct message
        my $DefaultMOTD
            = "This is the message of the day. You can edit this in Kernel/Output/HTML/Templates/Standard/Motd.tt.";
        $Self->True(
            index( $Selenium->get_page_source(), $DefaultMOTD ) > -1,
            "MOTD dashboard plugin message - found",
        );
    }
);

1;
