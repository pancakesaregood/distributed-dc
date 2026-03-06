# Identity

## Purpose
Identity defines who can access platform resources and under what governance model.

## Identity Model
- Primary identity source: Active Directory.
- Unique named identities for all administrators and operators.
- Role-based access control mapped to operational responsibilities.

## Identity Classes
- Human identities: user and admin accounts with role-based privileges.
- Service identities: scoped accounts for platform-to-platform integration.
- Emergency identities: break-glass paths with strict control and audit.

## Lifecycle Controls
- Provisioning: role-justified request and approval.
- Modification: change ticket and least-privilege review.
- Deprovisioning: immediate disablement on role exit.

## Governance Requirements
- Monthly privileged access review.
- Quarterly entitlement recertification by service owners.
- Immutable audit trail for identity changes.

## Security Baseline
- No shared privileged accounts.
- No unmanaged static credentials for production integrations.
- Strong secret handling and rotation process for service identities.

## Operational References
- Identity and access policy baseline: `06_security/identity_access.md`.
- Runbook mapping and alert dependencies: `07_operations/observability.md`.
