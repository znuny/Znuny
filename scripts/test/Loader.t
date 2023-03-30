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

# get needed objects
my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
my $LoaderObject = $Kernel::OM->Get('Kernel::System::Loader');
my $MainObject   = $Kernel::OM->Get('Kernel::System::Main');

# get helper object
$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

my $Home = $ConfigObject->Get('Home');

{
    my $CSS = $MainObject->FileRead(
        Location => $Home . '/scripts/test/sample/Loader/OTRS.Reset.css',
    );

    $CSS = ${$CSS};

    my $ExpectedMinifiedFilename = 'OTRS.Reset.min_for_css_minifier.css';
    if ( $LoaderObject->IsCSSMinifierXSAvailable() ) {
        $ExpectedMinifiedFilename = 'OTRS.Reset.min_for_css_minifier_xs.css';
    }

    my $ExpectedCSS = $MainObject->FileRead(
        Location => "$Home/scripts/test/sample/Loader/$ExpectedMinifiedFilename",
    );

    $ExpectedCSS = ${$ExpectedCSS};
    chomp $ExpectedCSS;

    my $MinifiedCSS = $LoaderObject->MinifyCSS( Code => $CSS );

    $Self->Is(
        $MinifiedCSS || '',
        $ExpectedCSS,
        'MinifyCSS()',
    );

    # empty cache
    $Kernel::OM->Get('Kernel::System::Cache')->CleanUp(
        Type => 'Loader',
    );

    my $MinifiedCSSFile = $LoaderObject->GetMinifiedFile(
        Location => $Home . '/scripts/test/sample/Loader/OTRS.Reset.css',
        Type     => 'CSS',
    );

    my $MinifiedCSSFileCached = $LoaderObject->GetMinifiedFile(
        Location => $Home . '/scripts/test/sample/Loader/OTRS.Reset.css',
        Type     => 'CSS',
    );

    $Self->Is(
        $MinifiedCSSFile,
        $ExpectedCSS,
        'GetMinifiedFile() for CSS, no cache',
    );

    $Self->Is(
        $MinifiedCSSFile,
        $ExpectedCSS,
        'GetMinifiedFile() for CSS, with cache',
    );
}

{
    my $JavaScript = $MainObject->FileRead(
        Location => $Home . '/scripts/test/sample/Loader/OTRS.Agent.App.Login.js',
    );
    $JavaScript = ${$JavaScript};

    # make sure line endings are standardized
    $JavaScript =~ s{\r\n}{\n}xmsg;

    my $MinifiedJS = $LoaderObject->MinifyJavaScript( Code => $JavaScript );

    # Remove any trailing new lines (also from last line, therefore no chomp)
    $MinifiedJS =~ s{\n+\z}{}ms;

    my $ExpectedMinifiedFilename = 'OTRS.Agent.App.Login.min_for_javascript_minifier.js';
    if ( $LoaderObject->IsJavaScriptMinifierXSAvailable() ) {
        $ExpectedMinifiedFilename = 'OTRS.Agent.App.Login.min_for_javascript_minifier_xs.js';
    }

    my $ExpectedJS = $MainObject->FileRead(
        Location => "$Home/scripts/test/sample/Loader/$ExpectedMinifiedFilename",
    );
    $ExpectedJS = ${$ExpectedJS};
    $ExpectedJS =~ s{\r\n}{\n}xmsg;

    # Remove any trailing new lines (also from last line, therefore no chomp)
    $ExpectedJS =~ s{\n+\z}{}ms;

    $Self->Is(
        $MinifiedJS || '',
        $ExpectedJS,
        'MinifyJavaScript()',
    );
}

{
    my $MinifiedJSFilename = $LoaderObject->MinifyFiles(
        List => [
            $Home . '/scripts/test/sample/Loader/OTRS.Agent.App.Login.js',
            $Home . '/scripts/test/sample/Loader/OTRS.Agent.App.Dashboard.js',
        ],
        Type            => 'JavaScript',
        TargetDirectory => $ConfigObject->Get('TempDir'),
    );

    $Self->True(
        $MinifiedJSFilename,
        'MinifyFiles() - no cache',
    );

    my $MinifiedJSFilename2 = $LoaderObject->MinifyFiles(
        List => [
            $Home . '/scripts/test/sample/Loader/OTRS.Agent.App.Login.js',
            $Home . '/scripts/test/sample/Loader/OTRS.Agent.App.Dashboard.js',
        ],
        Type            => 'JavaScript',
        TargetDirectory => $ConfigObject->Get('TempDir'),
    );

    $Self->True(
        $MinifiedJSFilename2,
        'MinifyFiles() - with cache',
    );

    $Self->Is(
        $MinifiedJSFilename,
        $MinifiedJSFilename2,
        'MinifyFiles() - compare cache and no cache',
    );

    my $MinifiedJS = $MainObject->FileRead(
        Location => $ConfigObject->Get('TempDir') . "/$MinifiedJSFilename",
    );

    $MinifiedJS = ${$MinifiedJS};
    $MinifiedJS =~ s{\r\n}{\n}xmsg;

    # Remove any trailing new lines (also from last line, therefore no chomp)
    $MinifiedJS =~ s{\n+\z}{}ms;

    my $ExpectedMinifiedFilename = 'CombinedJavaScript.min_for_javascript_minifier.js';
    if ( $LoaderObject->IsJavaScriptMinifierXSAvailable() ) {
        $ExpectedMinifiedFilename = 'CombinedJavaScript.min_for_javascript_minifier_xs.js';
    }

    my $Expected = $MainObject->FileRead(
        Location => "$Home/scripts/test/sample/Loader/$ExpectedMinifiedFilename",
    );
    $Expected = ${$Expected};
    $Expected =~ s{\r\n}{\n}xmsg;

    # Remove any trailing new lines (also from last line, therefore no chomp)
    $Expected =~ s{\n+\z}{}ms;

    $Self->Is(
        $MinifiedJS,
        $Expected,
        'MinifyFiles() result content',
    );

    $MainObject->FileDelete(
        Location => $ConfigObject->Get('TempDir') . "/$MinifiedJSFilename",
    );
}

my @JSTests = (

    # this next test shows a case where the minification currently only works with
    # parents around the regular expression. Without them, CSS::Minifier (currently 1.05) will die.
    {
        Source => 'function test(s) { return (/\d{1,2}/).test(s); }',
        Result => 'function test(s){return(/\d{1,2}/).test(s);}',
        Name   => 'Regexp minification',
    }
);

for my $Test (@JSTests) {
    my $Result = $LoaderObject->MinifyJavaScript(
        Code => $Test->{Source},
    );
    $Self->Is(
        $Result,
        $Test->{Result},
        $Test->{Name},
    );
}

# cleanup cache is done by RestoreDatabase

1;
