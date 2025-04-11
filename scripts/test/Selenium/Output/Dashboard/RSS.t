# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));

my $Selenium = $Kernel::OM->Get('Kernel::System::UnitTest::Selenium');

$Selenium->RunTest(
    sub {

        my $HelperObject    = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
        my $ConfigObject    = $Kernel::OM->Get('Kernel::Config');
        my $SysConfigObject = $Kernel::OM->Get('Kernel::System::SysConfig');

        # Disable all dashboard plugins.
        my $Config = $ConfigObject->Get('DashboardBackend');
        $HelperObject->ConfigSettingChange(
            Valid => 0,
            Key   => 'DashboardBackend',
            Value => \%$Config,
        );

        # Get dashboard RSS plugin default sysconfig.
        my %RSSConfig = $SysConfigObject->SettingGet(
            Name    => 'DashboardBackend###0442-RSS',
            Default => 1,
        );

        my $RandomRSSTitle = 'RSS' . $HelperObject->GetRandomID();

        # Set URL config to xml content in order to prevent instability in case cloud services are
        # unavailable at the exact moment of this test run.
        $RSSConfig{DefaultValue}->{URL} = "
            <?xml version=\"1.0\" encoding=\"UTF-8\"?>
            <rss version=\"2.0\"  xmlns:content=\"http://purl.org/rss/1.0/modules/content/\"
              xmlns:wfw=\"http://wellformedweb.org/CommentAPI/\"
              xmlns:dc=\"http://purl.org/dc/elements/1.1/\"
              xmlns:atom=\"http://www.w3.org/2005/Atom\"
              xmlns:sy=\"http://purl.org/rss/1.0/modules/syndication/\"
              xmlns:slash=\"http://purl.org/rss/1.0/modules/slash/\"  >
              <channel>
                  <title>Some news</title>
                  <atom:link href=\"https://www.znuny.com/feed/test\" rel=\"self\" type=\"application/rss+xml\" />
                  <link>https://www.znuny.com</link>
                  <description>Simple service management</description>
                  <lastBuildDate>Fri, 26 Jan 2018 13:37:52 +0000</lastBuildDate>
                  <language>en-EN</language>
                  <sy:updatePeriod>hourly</sy:updatePeriod>
                  <sy:updateFrequency>1</sy:updateFrequency>
                  <generator>https://wordpress.org/?v=4.9.2</generator>
                  <item>
                      <title>$RandomRSSTitle</title>
                      <link>https://www.znuny.com/$RandomRSSTitle</link>
                      <pubDate>Tue, 16 Jan 2018 09:00:07 +0000</pubDate>
                      <dc:creator><![CDATA[Znuny GmbH]]></dc:creator>
                      <category><![CDATA[Release and Security Notes]]></category>
                      <category><![CDATA[Some news]]></category>
                      <guid isPermaLink=\"false\">https://www.znuny.com/?p=61580</guid>
                      <description><![CDATA[&#160; January 16, 2018 — Znuny, test]]></description>
                      <content:encoded><![CDATA[<div class=\"row box-space-md\"> <div class=\"col-lg-12 col-md-12 col-sm-12 column1\"></div> </div>]]></content:encoded>
                  </item>
              </channel>
            </rss>
        ";

        $HelperObject->ConfigSettingChange(
            Valid => 1,
            Key   => 'DashboardBackend###0442-RSS',
            Value => $RSSConfig{EffectiveValue},
        );

        # Avoid SSL errors on old test platforms.
        $HelperObject->ConfigSettingChange(
            Valid => 1,
            Key   => 'WebUserAgent::DisableSSLVerification',
            Value => 1,
        );

        # Create test user and login.
        my $TestUserLogin = $HelperObject->TestUserCreate(
            Groups => [ 'admin', 'users' ],
        ) || die "Did not get test user";

        $Selenium->Login(
            Type     => 'Agent',
            User     => $TestUserLogin,
            Password => $TestUserLogin,
        );

        # Wait for RSS plugin to show up.
        $Selenium->WaitFor( JavaScript => 'return typeof($) === "function" && $("#Dashboard0442-RSS").length' );

        # Test if RSS feed is shown.
        $Self->True(
            $Selenium->execute_script(
                "return \$('#Dashboard0442-RSS tbody a[href*=\"www.znuny.com/$RandomRSSTitle\"]').text().trim() === '$RandomRSSTitle'"
            ),
            "RSS feed '$RandomRSSTitle' - found",
        );

        my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');

        # Make sure cache is correct.
        for my $Cache (qw( Dashboard DashboardQueueOverview )) {
            $CacheObject->CleanUp( Type => $Cache );
        }
    }
);

1;
