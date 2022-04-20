# --
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package scripts::Migration::Znuny6_3::MigrateDashboardWidgetSystemCommandCalls;    ## no critic

use strict;
use warnings;

use IO::Interactive qw(is_interactive);

use parent qw(scripts::Migration::Base);

use version;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::SysConfig',
);

sub Run {
    my ( $Self, %Param ) = @_;

    my $SysConfigObject = $Kernel::OM->Get('Kernel::System::SysConfig');

    my $UserID = 1;

    my $DashboardBackends = $Self->_GetDashboardConfig();

    my $DashboardWidgetsToRemove = $Self->_GetDashboardBackendsToRemove();
    return 1 if !IsArrayRefWithData($DashboardWidgetsToRemove);

    my @SettingsSetParams;
    for my $DashboardWidget ( sort @{$DashboardWidgetsToRemove} ) {
        push @SettingsSetParams, {
            Name           => "DashboardBackend###$DashboardWidget",
            EffectiveValue => $DashboardBackends->{$DashboardWidget},
            IsValid        => 0,
        };
    }

    $SysConfigObject->SettingsSet(
        UserID   => $UserID,
        Comments => 'Deactivated dashboard widgets that call system commands.',
        Settings => \@SettingsSetParams,
    );

    return 1;
}

sub CheckPreviousRequirement {
    my ( $Self, %Param ) = @_;

    my $DashboardWidgetsToRemove = $Self->_GetDashboardBackendsToRemove();
    return 1 if !IsArrayRefWithData($DashboardWidgetsToRemove);

    print "\n        The following dashboard widgets use system command calls.\n";
    print "        These are not allowed anymore and will be removed.\n";

    for my $DashboardWidget ( sort @{$DashboardWidgetsToRemove} ) {
        print "            $DashboardWidget\n";
    }

    if ( is_interactive() ) {
        print '        Do you want to continue? [Y]es/[N]o: ';

        my $Answer = <>;
        $Answer =~ s{\s}{}g;

        return if $Answer !~ m{\Ay(es)?\z}i;
    }

    return 1;
}

sub _GetDashboardBackendsToRemove {
    my ( $Self, %Param ) = @_;

    my $DashboardBackends = $Self->_GetDashboardConfig();

    my @DashboardWidgetsToRemove
        = grep { $DashboardBackends->{$_}->{Module} eq 'Kernel::Output::HTML::Dashboard::CmdOutput' }
        sort keys %{$DashboardBackends};

    return \@DashboardWidgetsToRemove;
}

sub _GetDashboardConfig {
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    my $DashboardBackends = $ConfigObject->Get('DashboardBackend') // {};
    return $DashboardBackends;
}

1;
