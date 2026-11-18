# Teztarif ticket assistance rollout

This branch introduces a zero-cost, deterministic triage helper, **not a trained AI model**. It is not yet wired to the ticket creation UI or API.

## Useful AI/ML integrations, after tenant security tests pass
1. Authorized knowledge-base retrieval from the current tenant's verified solutions. Require citations and user confirmation.
2. Duplicate ticket suggestions restricted to accessible tickets in the authenticated tenant.
3. Technician routing recommendations based on expertise, availability and assigned workload (human confirmation).
4. SLA breach-risk scoring trained from tenant-consented historical data, with measured precision and a deterministic deadline alert fallback.

## Safety, cost and product guardrails
- Enforce tenant context and record-level permission checks in backend *before* retrieving context or constructing prompts.
- Never query across companies or treat customer-company records as tenancy.
- Redact secrets and unnecessary personal data. Do not train on customer tickets by default.
- Use model calls only for new/meaningfully changed tickets and explicit technician requests; cache repeated results per tenant, ticket version and model version.
- Persist decision provenance, feedback, consent and cost. Cap tokens and requests by company.
- No automatic ticket closure, account changes, technician dispatch or customer-facing AI replies without approval.
- Evaluate on real anonymized tickets against baseline handling time and false assignment rates before rollout.

## Current status
- The TicketAssist Perl module provides rule-based *advisory* categorization only.
- Real LLM/ML, retrieval indexes, provider credentials, UI and event wiring are **not implemented in this PR**.
- The SaaS tenant foundation remains pending integration and comprehensive denial testing.
