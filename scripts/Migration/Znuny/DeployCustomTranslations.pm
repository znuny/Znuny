# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package scripts::Migration::Znuny::DeployCustomTranslations;    ## no critic

use strict;
use warnings;
use utf8;

use parent qw(scripts::Migration::Base);

our @ObjectDependencies = (
    'Kernel::System::Translation',
);

=head1 SYNOPSIS

Deploys custom translations.

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    $Self->_Deployment(%Param);

    return 1;
}

sub _Deployment {
    my ( $Self, %Param ) = @_;

    my $TranslationObject = $Kernel::OM->Get('Kernel::System::Translation');

    my $Success = $TranslationObject->DataDeployment(
        UserID => 1,
    );

    if ( !$Success ) {
        print "        Failed to deploy translations.\n";
        return;
    }

    print "        Successfully deployed translations.\n";
    return 1;
}

1;
