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

        my $HelperObject  = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
        my $ConfigObject  = $Kernel::OM->Get('Kernel::Config');
        my $ProcessObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Process');
        my $CacheObject   = $Kernel::OM->Get('Kernel::System::Cache');

        # Create test user and login.
        my $TestUserLogin = $HelperObject->TestUserCreate(
            Groups => ['admin'],
        ) || die "Did not get test user";

        $Selenium->Login(
            Type     => 'Agent',
            User     => $TestUserLogin,
            Password => $TestUserLogin,
        );

        my $ScriptAlias    = $ConfigObject->Get('ScriptAlias');
        my $ProcessRandom  = 'Process' . $HelperObject->GetRandomID();
        my $ProcessRandom2 = 'Process' . $HelperObject->GetRandomID();

        # Navigate to AdminProcessManagement screen.
        $Selenium->VerifiedGet("${ScriptAlias}index.pl?Action=AdminProcessManagement");

        # Check overview screen.
        $Selenium->find_element( "table",             'css' );
        $Selenium->find_element( "table thead tr th", 'css' );
        $Selenium->find_element( "table tbody tr td", 'css' );
        $Selenium->find_element( "#Filter",           'css' );

        # Check breadcrumb on Overview screen.
        $Self->True(
            $Selenium->find_element( '.BreadCrumb', 'css' ),
            "Breadcrumb is found on Overview screen.",
        );

        # Create new test Process.
        $Selenium->find_element("//a[contains(\@href, \'Subaction=ProcessNew' )]")->VerifiedClick();
        $Selenium->find_element( "#Name",        'css' )->send_keys($ProcessRandom);
        $Selenium->find_element( "#Description", 'css' )->send_keys("Selenium Test Process");
        $Selenium->InputFieldValueSet(
            Element => '#ValidID',
            Value   => 2,
        );
        $Selenium->find_element( "#Submit", 'css' )->VerifiedClick();

        $Selenium->WaitFor( JavaScript => "return typeof(\$) === 'function' && \$('#ProcessDelete').length" );
        my $ProcessID = $Selenium->execute_script('return $("#ProcessDelete").data("id")') || undef;

        $Selenium->find_element( "#Submit", 'css' )->VerifiedClick();

        # Create new test Process.
        $Selenium->find_element("//a[contains(\@href, \'Subaction=ProcessNew' )]")->VerifiedClick();
        $Selenium->find_element( "#Name",        'css' )->send_keys($ProcessRandom2);
        $Selenium->find_element( "#Description", 'css' )->send_keys("Selenium Test Process");
        $Selenium->find_element( "#Submit",      'css' )->VerifiedClick();

        $Selenium->WaitFor( JavaScript => "return typeof(\$) === 'function' && \$('#ProcessDelete').length" );
        my $ProcessID2 = $Selenium->execute_script('return $("#ProcessDelete").data("id")') || undef;

        $Selenium->find_element( "#Submit", 'css' )->VerifiedClick();

        # Checks for AdminValidFilter
        $Self->True(
            $Selenium->find_element( "#ValidFilter", 'css' )->is_displayed(),
            "AdminValidFilter - Button to show or hide invalid table elements is displayed.",
        );
        $Selenium->find_element( "#ValidFilter", 'css' )->click();
        $Self->False(
            $Selenium->find_element( "tr.Invalid", 'css' )->is_displayed(),
            "AdminValidFilter - All invalid entries are not displayed.",
        );
        $Selenium->find_element( "#ValidFilter", 'css' )->click();
        $Self->True(
            $Selenium->find_element( "tr.Invalid", 'css' )->is_displayed(),
            "AdminValidFilter - All invalid entries are displayed again.",
        );

        # Delete test process.
        my $Success = $ProcessObject->ProcessDelete(
            ID     => $ProcessID,
            UserID => 1,
        );
        $Self->True(
            $Success,
            "Process is deleted - $ProcessID",
        );

        # Delete test process.
        $Success = $ProcessObject->ProcessDelete(
            ID     => $ProcessID2,
            UserID => 1,
        );
        $Self->True(
            $Success,
            "Process is deleted - $ProcessID2",
        );

        # Synchronize process after deleting test process.
        $Selenium->find_element("//a[contains(\@href, \'Subaction=ProcessSync' )]")->VerifiedClick();

        # Make sure cache is correct.
        for my $Cache (qw(ProcessManagement_Activity ProcessManagement_Process)) {
            $CacheObject->CleanUp( Type => $Cache );
        }
    }
);

1;
