# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --
## nofilter(TidyAll::Plugin::Znuny::Perl::Require)
package Kernel::System::Console::Command::Dev::Code::CPANAudit;

use strict;
use warnings;
use Kernel::System::VariableCheck qw(:all);

use File::Basename;
use FindBin qw($Bin);

use parent qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::System::Environment',
    'Kernel::System::Log',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Scan CPAN dependencies in Kernel/cpan-lib and in the system for known vulnerabilities.');

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $EnvironmentObject = $Kernel::OM->Get('Kernel::System::Environment');
    my $LogObject         = $Kernel::OM->Get('Kernel::System::Log');

    my $Version = $EnvironmentObject->ModuleVersionGet( Module => 'CPAN::Audit' );
    if ( !$Version ) {
        $Self->Print("Module CPAN::Audit is not installed.\n");
        return $Self->ExitCodeOk();
    }

    require CPAN::Audit;

    my $Audit = CPAN::Audit->new(
        no_color    => 1,
        no_corelist => 0,
        ascii       => 0,
        verbose     => 0,
        quiet       => 0,
        interactive => 0,
    );

    my @PathsToScan;

    # We need to pass an explicit list of paths to be scanned by CPAN::Audit, otherwise it will fallback to @INC which
    #   includes our complete tree, with article storage, cache, temp files, etc. It can result in a downgraded
    #   performance if this command is run often.
    #   Please see bug#14666 for more information.
    PATH:
    for my $Path (@INC) {
        next PATH if $Path && $Path eq '.';                          # Current folder
        next PATH if $Path && $Path eq dirname($Bin);                # OTRS home folder
        next PATH if $Path && $Path eq dirname($Bin) . '/Custom';    # Custom folder
        push @PathsToScan, $Path;
    }

    # Workaround for CPAN::Audit::Installed. It does not use the passed param(s), but @ARGV instead.
    local @ARGV = @PathsToScan;

    my $Result = $Audit->command('installed');

    if ( IsHashRefWithData($Result) ) {
        my $ModuleCounter;
        my $AdvisoryCounter;
        my $String;
        for my $Module ( sort keys %{ $Result->{dists} } ) {
            $ModuleCounter++;
            my $Count = scalar @{ $Result->{dists}->{$Module}->{advisories} };
            my $Version
                = $Result->{dists}->{$Module}->{version} ? " (version $Result->{dists}->{$Module}->{version})" : '';

            $String .= "$Module$Version has $Count advisories:\n";

            for my $Advisory ( @{ $Result->{dists}->{$Module}->{advisories} } ) {
                $AdvisoryCounter++;
                $String .= "\t* $Advisory->{id}\n\t  $Advisory->{description}";

                $String .= "\n\t  Affected versions: $Advisory->{affected_versions}" if $Advisory->{affected_versions};
                $String .= "\n\t  Fixed versions: $Advisory->{fixed_versions}"       if $Advisory->{fixed_versions};
                $String .= "\n";

                if ( IsArrayRefWithData( $Advisory->{cves} ) ) {
                    my $CVEString = join ' ', @{ $Advisory->{cves} };
                    $String .= "\n\t  CVEs: $CVEString\n";
                }

                $String .= "\n";
            }
        }

        $String .= "\nTotal $AdvisoryCounter advisories found in $ModuleCounter modules.\n";
        $Self->Print($String);
    }

    # return everytime exit code 0
    return $Self->ExitCodeOk();
}

1;
