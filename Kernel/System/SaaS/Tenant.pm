# --
# Copyright (C) 2026 Teztarif
# --

package Kernel::System::SaaS::Tenant;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::System::DB',
    'Kernel::System::Log',
);

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless $Self, $Type;

    return $Self;
}

=head1 NAME

Kernel::System::SaaS::Tenant - fail-closed tenant context and ownership checks

=head1 PUBLIC INTERFACE

=head2 ContextSet()

Set the tenant context once for the current request. The user must have an
active membership in an active or trial tenant. A context cannot be switched
after it has been set.

=cut

sub ContextSet {
    my ( $Self, %Param ) = @_;

    for my $Needed (qw(TenantID UserID)) {
        return $Self->_Error("Need $Needed!") if !$Param{$Needed};
    }

    if ( $Self->{TenantID} ) {
        return 1 if $Self->{TenantID} == $Param{TenantID} && $Self->{UserID} == $Param{UserID};
        return $Self->_Error('Tenant context is immutable for the current request.');
    }

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');
    return if !$DBObject->Prepare(
        SQL => <<'SQL',
SELECT tu.access_level
FROM saas_tenant_user tu
INNER JOIN saas_tenant t ON t.id = tu.tenant_id
WHERE tu.tenant_id = ?
    AND tu.user_id = ?
    AND tu.valid_id = 1
    AND t.status IN ('active', 'trial')
SQL
        Bind => [ \$Param{TenantID}, \$Param{UserID} ],
        Limit => 1,
    );

    my @Row = $DBObject->FetchrowArray();
    return $Self->_Error('User has no active membership for this tenant.') if !@Row;

    $Self->{TenantID}    = $Param{TenantID};
    $Self->{UserID}      = $Param{UserID};
    $Self->{AccessLevel} = $Row[0];

    return 1;
}

sub ContextGet {
    my ( $Self, %Param ) = @_;

    return if !$Self->{TenantID};

    return {
        TenantID    => $Self->{TenantID},
        UserID      => $Self->{UserID},
        AccessLevel => $Self->{AccessLevel},
    };
}

=head2 ObjectTenantSet()

Assign a domain object to the current tenant. Existing ownership can never be
changed by this method.

=cut

sub ObjectTenantSet {
    my ( $Self, %Param ) = @_;

    return $Self->_ContextRequired() if !$Self->{TenantID};
    for my $Needed (qw(ObjectType ObjectID)) {
        return $Self->_Error("Need $Needed!") if !defined $Param{$Needed} || $Param{$Needed} eq '';
    }

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');
    my $ObjectID = "$Param{ObjectID}";
    return if !$DBObject->Prepare(
        SQL => <<'SQL',
SELECT tenant_id
FROM saas_object_tenant
WHERE object_type = ? AND object_id = ?
SQL
        Bind  => [ \$Param{ObjectType}, \$ObjectID ],
        Limit => 1,
    );

    my @Row = $DBObject->FetchrowArray();
    if (@Row) {
        return 1 if $Row[0] == $Self->{TenantID};
        return $Self->_Error('Cross-tenant ownership reassignment denied.');
    }

    return $DBObject->Do(
        SQL => <<'SQL',
INSERT INTO saas_object_tenant
    (tenant_id, object_type, object_id, create_time, create_by)
VALUES (?, ?, ?, current_timestamp, ?)
SQL
        Bind => [ \$Self->{TenantID}, \$Param{ObjectType}, \$ObjectID, \$Self->{UserID} ],
    );
}

=head2 ObjectAccessCheck()

Return true only when the object is explicitly owned by the current tenant.
Unassigned objects fail closed.

=cut

sub ObjectAccessCheck {
    my ( $Self, %Param ) = @_;

    return if !$Self->{TenantID};
    return if !defined $Param{ObjectType} || !defined $Param{ObjectID};

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');
    my $ObjectID = "$Param{ObjectID}";
    return if !$DBObject->Prepare(
        SQL => <<'SQL',
SELECT 1
FROM saas_object_tenant
WHERE tenant_id = ? AND object_type = ? AND object_id = ?
SQL
        Bind  => [ \$Self->{TenantID}, \$Param{ObjectType}, \$ObjectID ],
        Limit => 1,
    );

    my @Row = $DBObject->FetchrowArray();
    return @Row ? 1 : 0;
}

=head2 ModuleEnabled()

Resolve effective module licensing. A tenant override wins over the active
subscription plan. Missing or expired subscriptions fail closed.

=cut

sub ModuleEnabled {
    my ( $Self, %Param ) = @_;

    return if !$Self->{TenantID};
    return if !$Param{Module};

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');
     # Module overrides cannot bypass expiry or cancellation. Check the
    # subscription first, regardless of the requested module.
    return if !$DBObject->Prepare(
        SQL => <<'SQL',
SELECT id
FROM saas_subscription
WHERE tenant_id = ?
    AND status IN ('active', 'trial')
    AND start_time <= current_timestamp
    AND (end_time IS NULL OR end_time > current_timestamp)
ORDER BY id DESC
SQL
        Bind  => [ \$Self->{TenantID} ],
        Limit => 1,
    );
    my @ActiveSubscription = $DBObject->FetchrowArray();
    return 0 if !@ActiveSubscription;

   return if !$DBObject->Prepare(
        SQL => <<'SQL',
SELECT tm.enabled
FROM saas_tenant_module tm
INNER JOIN saas_module m ON m.id = tm.module_id
WHERE tm.tenant_id = ? AND m.code = ? AND m.valid_id = 1
SQL
        Bind  => [ \$Self->{TenantID}, \$Param{Module} ],
        Limit => 1,
    );
    my @Override = $DBObject->FetchrowArray();
    return $Override[0] ? 1 : 0 if @Override;

    return if !$DBObject->Prepare(
        SQL => <<'SQL',
SELECT pm.enabled
FROM saas_subscription s
INNER JOIN saas_plan_module pm ON pm.plan_id = s.plan_id
INNER JOIN saas_module m ON m.id = pm.module_id
WHERE s.id = ?
    AND m.code = ?
    AND m.valid_id = 1
ORDER BY s.id DESC
SQL
        Bind  => [ \$ActiveSubscription[0], \$Param{Module} ],
        Limit => 1,
    );
    my @Plan = $DBObject->FetchrowArray();

    return @Plan && $Plan[0] ? 1 : 0;
}

sub _ContextRequired {
    my ( $Self, %Param ) = @_;
    return $Self->_Error('Tenant context is required.');
}

sub _Error {
    my ( $Self, $Message ) = @_;

    $Kernel::OM->Get('Kernel::System::Log')->Log(
        Priority => 'error',
        Message  => $Message,
    );
    return;
}

1;
