# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::Console::Command::Dev::Tools::RPMSpecGenerate;
## nofilter(TidyAll::Plugin::Znuny::Perl::LayoutObject)

use strict;
use warnings;

use parent qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::Output::HTML::Layout',
    'Kernel::System::DateTime',
    'Kernel::System::Main',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Generate RPM spec files.');

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    $Self->Print("<yellow>Starting...</yellow>\n\n");

    my $Home = $Kernel::OM->Get('Kernel::Config')->Get('Home');

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # Call Output() once so that the TT objects are created.
    $LayoutObject->Output( Template => '' );
    $LayoutObject->{TemplateProviderObject}->include_path(
        ["$Home/scripts/auto_build/spec/templates"]
    );

    my @SpecFileTemplates = $Kernel::OM->Get('Kernel::System::Main')->DirectoryRead(
        Directory => "$Home/scripts/auto_build/spec/templates",
        Filter    => "*.spec.tt",
    );

    my $DateTimeObject = $Kernel::OM->Create('Kernel::System::DateTime');
    my $CurrentYear    = $DateTimeObject->Format( Format => '%Y' );

    for my $SpecFileTemplate (@SpecFileTemplates) {
        my $SpecFileName = $SpecFileTemplate;
        $SpecFileName =~ s{^.*/spec/templates/}{};
        $SpecFileName = substr( $SpecFileName, 0, -3 );    # cut off .tt

        my $Output = $Kernel::OM->Get('Kernel::Output::HTML::Layout')->Output(
            TemplateFile => $SpecFileName,
            Data         => {
                CurrentYear => $CurrentYear,
            },
        );
        my $TargetPath = "$Home/scripts/auto_build/spec/$SpecFileName";
        my $Written    = $Kernel::OM->Get('Kernel::System::Main')->FileWrite(
            Location => $TargetPath,
            Mode     => 'utf8',
            Content  => \$Output,
        );
        if ( !$Written ) {
            $Self->PrintError("Could not write $TargetPath.");
            return $Self->ExitCodeError();
        }
        $Self->Print("  <yellow>$SpecFileTemplate -> $TargetPath</yellow>\n");
    }

    $Self->Print("\n<green>Done.</green>\n");

    return $Self->ExitCodeOk();
}

1;
