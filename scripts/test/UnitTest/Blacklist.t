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

my $HelperObject  = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $CommandObject = $Kernel::OM->Get('Kernel::System::Console::Command::Dev::UnitTest::Run');
my $ConfigObject  = $Kernel::OM->Get('Kernel::Config');
my $EncodeObject  = $Kernel::OM->Get('Kernel::System::Encode');

my $Home      = $ConfigObject->Get('Home');
my $Directory = "$Home/scripts/test";
my $RandomID  = $HelperObject->GetRandomID();

my @Tests = (
    {
        Name   => "UnitTest 'Signature.t' (blacklisted)",
        Test   => 'scripts/test/Signature.t',
        Config => {
            Valid => 1,
            Key   => 'UnitTest::Blacklist###1000-UnitTest' . $RandomID,
            Value => [ $Directory . '/Signature.t' ],
        },
        TestExecuted => 0,
    },
    {
        Name   => "UnitTest 'Signature.t' (whitelisted)",
        Test   => 'scripts/test/Signature.t',
        Config => {
            Valid => 1,
            Key   => 'UnitTest::Blacklist###1000-UnitTest' . $RandomID,
            Value => [],
        },
        TestExecuted => 1,
    },
);

for my $Test (@Tests) {

    $HelperObject->ConfigSettingChange(
        %{ $Test->{Config} },
    );

    my $Result;
    my $ExitCode;

    {
        local *STDOUT;
        open STDOUT, '>:encoding(UTF-8)', \$Result;

        $ExitCode = $CommandObject->Execute( '--test', $Test->{Test} );
        $EncodeObject->EncodeInput( \$Result );
    }

    chomp $Result;

    # Check for executed tests message.
    my $Success = $Result =~ m{ No \s+ tests \s+ executed\. }xms;

    if ( $Test->{TestExecuted} ) {

        $Self->False(
            $Success,
            $Test->{Name} . ' - executed successfully.',
        );
    }
    else {

        $Self->True(
            $Success,
            $Test->{Name} . ' - not executed.',
        );
    }
}

1;
