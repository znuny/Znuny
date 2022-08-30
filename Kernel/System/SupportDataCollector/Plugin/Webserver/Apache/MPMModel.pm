# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::SupportDataCollector::Plugin::Webserver::Apache::MPMModel;

use strict;
use warnings;

use parent qw(Kernel::System::SupportDataCollector::PluginBase);

use Kernel::Language qw(Translatable);

our @ObjectDependencies = ();

sub GetDisplayPath {
    return Translatable('Webserver');
}

sub Run {
    my $Self = shift;

    my %Environment = %ENV;

    # No web request or no apache webserver with mod_perl, skip this check.
    if ( !$ENV{GATEWAY_INTERFACE} || !$ENV{SERVER_SOFTWARE} || $ENV{SERVER_SOFTWARE} !~ m{apache}i || !$ENV{MOD_PERL} )
    {
        return $Self->GetResults();
    }

    my $MPMModel;
    my %KnownModels = (
        'worker.c'  => 1,
        'prefork.c' => 1,
        'event.c'   => 1,
    );

    MODULE:
    for ( my $Module = Apache2::Module::top_module(); $Module; $Module = $Module->next() ) {
        if ( $KnownModels{ $Module->name() } ) {
            $MPMModel = $Module->name();
        }
    }

    if ( $MPMModel eq 'prefork.c' ) {
        $Self->AddResultOk(
            Identifier => 'MPMModel',
            Label      => Translatable('MPM model'),
            Value      => $MPMModel,
        );
    }
    else {
        $Self->AddResultProblem(
            Identifier => 'MPMModel',
            Label      => Translatable('MPM model'),
            Value      => $MPMModel,
            Message    => Translatable("OTRS requires apache to be run with the 'prefork' MPM model."),
        );
    }

    return $Self->GetResults();
}

1;
