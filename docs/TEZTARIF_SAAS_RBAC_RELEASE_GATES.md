# Teztarif SaaS Access Control: implementation and release gate

## Hierarchy
- Platform Super Admin: independent platform role, not an ordinary tenant member. Its secure authentication, company provisioning, auditing and entitlement writes are **not yet implemented**.
- Company Admin: belongs to exactly one tenant; has full control only over licensed company modules unless explicitly restricted.
- Department Admin / Team / Technician: permissions are explicitly assigned via company-local roles and per-user overrides.
- Customer access remains separate and needs per-ticket authorization.

## What this branch implements
- Database definitions: `saas_role`, `saas_user_role`, `saas_role_permission`, `saas_user_permission`.
- Read-side effective authorization: active tenant context, live subscription/module license, active membership, explicit per-user exceptions, roles and deny precedence.
- `VisibleModules` from the authorization service; can power future company sidebar.
- Basic ticket and dashboard navigation filters and backend route checks using the same action mapper, when a tenant context has been established.
- Negative tests for missing tenant context, unsupported scopes and missing authentication.

## Blocking release work
1. PR #1 -> PR #2 -> PR #3 and this PR must be reviewed in order; current default `dev` does not have this SaaS architecture.
2. Generate and commit database SQL for all supported engines via Znuny schema generator, plan upgrades and backfills; run migration/rollback tests.
3. Establish authenticated request-scoped tenant context **before** routing. Without context, legacy Znuny mode is deliberately unchanged. This is NOT safe for SaaS tenancy.
4. Audit every Znuny action, ticket article, attachment, search, export, mail intake, scheduled job, API, report and cache for tenant isolation; map remaining actions. Unmapped actions currently follow legacy behavior.
5. Implement platform provisioning, company/department/team CRUD and audited permission delegation with privilege-escalation protection. Current branch has read-side permission evaluation only.
6. Extend authorization to resource scopes: OWN/TEAM/DEPARTMENT/COMPANY must be checked against the actual requested ticket/department. A module's view permission alone is insufficient.
7. Add explicit 403 / forbidden handling for API clients, session revocation, navigation browser tests, billing lifecycle tests, audit logs, negative cross-tenant tests and load tests.
8. CI must pass; do not merge or advertise production-ready before all gates pass.

## Permission semantics
Access = authenticated tenant context AND active membership AND active subscription AND licensed module AND allowed action/scope.
User exceptions take precedence over roles. An explicit deny from any assigned role wins over other role grants. Company Admin is allowed licensed modules unless a per-user exception denies the exact permission.

### Important safety caveat
Role module permissions **do not yet enforce record ownership**. A department-scope role must not be trusted to read arbitrary ticket IDs just because it can open the Ticket screen.
