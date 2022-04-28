# --
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package scripts::Migration::Znuny6_3::ShowITSMUpgradeInstructions;    ## no critic

use strict;
use warnings;

use parent qw(scripts::Migration::Base);

use version;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::System::Package',
);

sub Run {
    my ( $Self, %Param ) = @_;

    my $PackageObject = $Kernel::OM->Get('Kernel::System::Package');

    # Check if ITSM bundle or ITSMCore is installed in version 6.3.1.
    my @Packages = $PackageObject->RepositoryList(
        Result => 'short',
    );

    my $ITSMBundleUpgradeNeeded = grep {
        $_->{Name} eq 'ITSM'
            && $_->{Version} eq '6.3.1'
    } @Packages;

    # Show manual upgrade instructions for ITSM bundle.
    if ($ITSMBundleUpgradeNeeded) {
        print "\n        ITSM has to be upgraded to version 6.3.3 with the following command:\n";
        print
            "        bin/otrs.Console.pl Admin::Package::Upgrade https://download.znuny.org/releases/itsm/bundle6x/:ITSM-6.3.3.opm\n";

        return 1;
    }

    # Show manual upgrade instructions for ITSMCore.
    # Note that ITSMCore is included in the bundle above. So if the bundle is installed, the following check
    # will not be executed.
    my $ITSMCoreUpgradeNeeded = grep {
        $_->{Name} eq 'ITSMCore'
            && $_->{Version} eq '6.3.1'
    } @Packages;

    if ($ITSMCoreUpgradeNeeded) {
        print "\n        ITSMCore has to be upgraded to version 6.3.3 with the following command:\n";
        print
            "        bin/otrs.Console.pl Admin::Package::Upgrade https://download.znuny.org/releases/itsm/packages6x/:ITSMCore-6.3.3.opm\n";

        return 1;
    }

    return 1;
}

1;
