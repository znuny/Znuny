# --
# Copyright (C) 2026 Teztarif
# --
package Kernel::System::SaaS::Permission;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::System::DB',
    'Kernel::System::SaaS::Tenant',
);

# A read-side authorization service for company-owned SaaS modules. Never
# accept a browser-provided TenantID. User overrides take precedence over
# role grants; explicit denial wins. Each check is license-gated first.
sub new {
    my ( $Type, %Param ) = @_;
    return bless {}, $Type;
}

sub Check {
    my ( $Self, %Param ) = @_;

    for my $Required (qw(UserID Module Action Scope)) {
        return if !defined $Param{$Required} || $Param{$Required} eq '';
    }
    return if $Param{Action} !~ /\A(?:view|create|edit|delete|assign|import|export|approve|manage)\z/;
    return if $Param{Scope} !~ /\A(?:own|team|department|company)\z/;

    my $Tenant = $Kernel::OM->Get('Kernel::System::SaaS::Tenant');
    my $Context = $Tenant->ContextGet();
    return if !$Context || $Context->{UserID} != $Param{UserID};
    return if !$Tenant->ModuleEnabled( Module => $Param{Module} );

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');
    return if !$DBObject->Prepare(
        SQL => <<'SQL',
SELECT access_level
FROM saas_tenant_user
WHERE tenant_id = ? AND user_id = ? AND valid_id = 1
SQL
        Bind  => [ \$Context->{TenantID}, \$Param{UserID} ],
        Limit => 1,
    );
    my @Member = $DBObject->FetchrowArray();
    return if !@Member;

    # Verify explicit user exceptions before any elevated company-admin grant.
    return if !$DBObject->Prepare(
        SQL => <<'SQL',
SELECT up.allowed
FROM saas_user_permission up
INNER JOIN saas_module m ON m.id = up.module_id AND m.valid_id = 1
WHERE up.tenant_id = ? AND up.user_id = ?
    AND m.code = ? AND up.action = ? AND up.scope = ?
SQL
        Bind => [
            \$Context->{TenantID}, \$Param{UserID}, \$Param{Module},
            \$Param{Action}, \$Param{Scope},
        ],
        Limit => 1,
    );
    my @Override = $DBObject->FetchrowArray();
    return $Override[0] ? 1 : 0 if @Override;

    # A Company Admin may manage enabled modules, but never the platform,
    # other tenants, or any module not licensed by Super Admin.
    return 1 if $Member[0] eq 'company_admin';

    return if !$DBObject->Prepare(
        SQL => <<'SQL',
SELECT rp.allowed
FROM saas_user_role ur
INNER JOIN saas_role r ON r.id = ur.role_id
    AND r.tenant_id = ur.tenant_id AND r.valid_id = 1
INNER JOIN saas_role_permission rp ON rp.role_id = r.id
INNER JOIN saas_module m ON m.id = rp.module_id AND m.valid_id = 1
WHERE ur.tenant_id = ? AND ur.user_id = ?
    AND m.code = ? AND rp.action = ? AND rp.scope = ?
SQL
        Bind => [
            \$Context->{TenantID}, \$Param{UserID}, \$Param{Module},
            \$Param{Action}, \$Param{Scope},
        ],
    );

    my $Allowed = 0;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        return 0 if !$Row[0];    # explicit role deny wins over other roles
        $Allowed = 1;
    }
    return $Allowed;
}

# Only return module codes that pass effective authorization. A UI can
# display these, but API handlers MUST also call Check independently.
sub VisibleModules {
    my ( $Self, %Param ) = @_;
    return [] if !$Param{UserID};

    my $Tenant = $Kernel::OM->Get('Kernel::System::SaaS::Tenant');
    my $Context = $Tenant->ContextGet();
    return [] if !$Context || $Context->{UserID} != $Param{UserID};

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');
    return [] if !$DBObject->Prepare(
        SQL => 'SELECT code FROM saas_module WHERE valid_id = 1 ORDER BY code',
    );
    my @Codes;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        push @Codes, $Row[0];
    }

    my @Visible;
    for my $Code (@Codes) {
        push @Visible, $Code if $Self->Check(
            UserID => $Param{UserID},
            Module => $Code,
            Action => 'view',
            Scope  => 'company',
        ) || $Self->Check(
            UserID => $Param{UserID},
            Module => $Code,
            Action => 'view',
            Scope  => 'department',
        ) || $Self->Check(
            UserID => $Param{UserID},
            Module => $Code,
            Action => 'view',
            Scope  => 'team',
        ) || $Self->Check(
            UserID => $Param{UserID},
            Module => $Code,
            Action => 'view',
            Scope  => 'own',
        );
    }
    return \@Visible;
}

1;
