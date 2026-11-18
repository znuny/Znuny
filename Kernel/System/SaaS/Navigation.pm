# --
# Copyright (C) 2026 Teztarif
# --
package Kernel::System::SaaS::Navigation;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::System::SaaS::Tenant',
    'Kernel::System::SaaS::Permission',
);

sub new {
    my ( $Type, %Param ) = @_;
    return bless {}, $Type;
}

# This map is intentionally small. Unmapped Znuny actions require a separate
# audit and mapping before the system can be declared SaaS-ready.
sub _ModuleForAction {
    my ( $Self, %Param ) = @_;
    my $Action = $Param{Action} // '';
    return 'tickets' if $Action =~ /\AAgentTicket/;
    return 'dashboard' if $Action eq 'AgentDashboard';
    return;
}

sub AllowedAction {
    my ( $Self, %Param ) = @_;
    return if !$Param{UserID};

    my $Tenant = $Kernel::OM->Get('Kernel::System::SaaS::Tenant');
    my $Context = $Tenant->ContextGet();

    # Legacy Znuny remains untouched until authenticated request-context
    # wiring is active. Never use this return as proof of tenant security.
    return 1 if !$Context;
    return if $Context->{UserID} != $Param{UserID};

    my $Module = $Self->_ModuleForAction( Action => $Param{Action} );
    return 1 if !$Module;

    my $Permission = $Kernel::OM->Get('Kernel::System::SaaS::Permission');
    for my $Scope (qw(company department team own)) {
        return 1 if $Permission->Check(
            UserID => $Param{UserID},
            Module => $Module,
            Action => 'view',
            Scope  => $Scope,
        );
    }
    return 0;
}

1;
