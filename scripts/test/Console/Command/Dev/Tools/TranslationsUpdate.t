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
use File::Path();

use Kernel::System::VariableCheck qw(:all);

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);

my $CommandObject = $Kernel::OM->Get('Kernel::System::Console::Command::Dev::Tools::TranslationsUpdate');
my $EncodeObject  = $Kernel::OM->Get('Kernel::System::Encode');
my $ConfigObject  = $Kernel::OM->Get('Kernel::Config');
my $MainObject    = $Kernel::OM->Get('Kernel::System::Main');

my $TempDir     = $ConfigObject->Get('TempDir');
my $ModuleDir   = "$TempDir/TranslationsUpdate";
my $I18nDir     = "$TempDir/TranslationsUpdate/i18n/TranslationsUpdate";
my $LanguageDir = "$TempDir/TranslationsUpdate/Kernel/Language";

my @Tests = (
    {
        Name      => "Run without Parameter.",
        Parameter => [],
        ExitCode  => 0,
        STDOUT    => 'Starting...',
        STDERR    => undef,
    },
    {
        Name      => "Run for language de with generate-po.",
        Parameter => [ '--language=de', '--generate-po' ],
        ExitCode  => 0,
        STDOUT    => 'Starting...',
        STDERR    => undef,
    },
    {
        Name      => "Run module-directory without value",
        Parameter => [ '--language=de', '--generate-po', '--module-directory' ],
        ExitCode  => 1,
        STDOUT    => undef,
        STDERR    => "Error: the following options have an unexpected or missing value: --module-directory.",
    },
    {
        Name      => "Run for language de and module-directory with generate-po.",
        Parameter => [ '--language=de', '--generate-po', '--module-directory', $ModuleDir ],
        Data      => {
            TemplateFile => '<h1>[% Translate("TranslationsUpdate") | html %]</h1>',
            POTFile      => ' ',
        },
        ExitCode => 0,
        STDOUT   => 'Starting...',
        STDERR   => undef
    },
);

for my $Test (@Tests) {

    if ( $Test->{Data} ) {

        if ( !-d $ModuleDir ) {
            File::Path::make_path( $ModuleDir, { chmod => 0770 } );    ## no critic
        }
        if ( !-d $I18nDir ) {
            File::Path::make_path( $I18nDir, { chmod => 0770 } );      ## no critic
        }
        if ( !-d $LanguageDir ) {
            File::Path::make_path( $LanguageDir, { chmod => 0770 } );    ## no critic
        }

        if ( $Test->{Data}->{TemplateFile} ) {
            my $TemplateLocation = $MainObject->FileWrite(
                Directory  => $ModuleDir,
                Filename   => 'Template.tt',
                Content    => \$Test->{Data}->{TemplateFile},
                Permission => '644',
            );
        }

        if ( $Test->{Data}->{POTFile} ) {
            my $PotLocation = $MainObject->FileWrite(
                Directory  => $I18nDir,
                Filename   => 'TranslationsUpdate.pot',
                Content    => \$Test->{Data}->{POTFile} || '',
                Permission => '644',
            );
        }
        if ( $Test->{Data}->{LanguageFile} ) {
            my $PotLocation = $MainObject->FileWrite(
                Directory  => $I18nDir,
                Filename   => 'de_TranslationsUpdate.pm',
                Content    => \$Test->{Data}->{LanguageFile} || '',
                Permission => '644',
            );
        }
    }

    my %Result;
    {
        local *STDOUT;
        local *STDERR;
        open STDOUT, '>:encoding(UTF-8)', \$Result{STDOUT};
        open STDERR, '>:encoding(UTF-8)', \$Result{STDERR};

        $Result{ExitCode} = $CommandObject->Execute( @{ $Test->{Parameter} } );

        $EncodeObject->EncodeInput( \$Result{STDOUT} );
        $EncodeObject->EncodeInput( \$Result{STDERR} );
    }

    $Self->True(
        scalar %Result,
        "ConsoleCommand returns a HashRef with data ($Test->{Name})",
    ) || return 1;

    $Self->Is(
        $Result{ExitCode},
        $Test->{ExitCode},
        "Expected ExitCode ($Test->{Name})",
    );

    STD:
    for my $STD (qw(STDOUT STDERR)) {

        next STD if !IsStringWithData( $Test->{$STD} );

        $Self->True(
            index( $Result{$STD}, $Test->{$STD} ) > -1,
            "$STD contains '$Test->{ $STD }' ($Test->{Name})",
        );
    }

    if ( $Test->{Data} ) {

        my $TemplateContent = $MainObject->FileRead(
            Directory => $ModuleDir,
            Filename  => 'Template.tt',
        );
        my $POTContent = $MainObject->FileRead(
            Directory => $I18nDir,
            Filename  => 'TranslationsUpdate.pot',
        );
        my $LanguageContent = $MainObject->FileRead(
            Directory => $LanguageDir,
            Filename  => 'de_TranslationsUpdate.pm',
        );

        $Self->True(
            $TemplateContent,
            "$ModuleDir/Template.tt exists",
        );

        $Self->True(
            $POTContent,
            "$I18nDir/TranslationsUpdate.pot exists",
        );

        $Self->True(
            $LanguageContent,
            "$LanguageDir/de_TranslationsUpdate.pm exists",
        );

    }
}

1;
