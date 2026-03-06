# Identity and Access

## Purpose
Define identity, access, and privilege governance for operators, administrators, and service identities.

## Identity Principles
- One authoritative identity source for human administrators and operators.
- Role-based authorization aligned to operational responsibility.
- Unique named accounts for all privileged actions.
- Full auditability for identity lifecycle and privilege changes.

## Authentication Baseline
- MFA required for:
  - Privileged platform access
  - Remote access (VPN and equivalent flows)
  - High-risk administrative actions
- Directory-backed authentication for platform control paths.
- Encrypted authentication protocols only (for example, LDAPS or TLS-backed services).

## Authorization Model
- Authorization is role-based and least-privilege by default.
- Zone and service access is granted by group membership and policy mapping.
- Deny-by-default policy for undefined or unapproved role paths.
- Temporary privilege elevation requires ticketed approval and expiry.

## Privileged Access Controls
- Administrative access uses hardened jump paths and controlled endpoints.
- Session activity for high-risk operations is logged and reviewable.
- Break-glass access is time-bounded and requires retrospective review.
- Privileged credential use is prohibited outside approved tooling paths.

## Service Identity Governance
- Separate service accounts by environment and function.
- No shared static service credentials across production domains.
- Credential rotation on a defined cadence with change traceability.
- Immediate revocation workflow for compromised service identities.

## Lifecycle and Review Controls
- Joiner/mover/leaver flows must include immediate deprovisioning on role exit.
- Monthly review of privileged identities and emergency access usage.
- Quarterly entitlement recertification with service owners.
- Control evidence retained for audit and incident investigations.

## Operational Integration
- Identity failures and abnormal auth patterns generate actionable alerts.
- Access model changes are version-controlled and peer-reviewed.
- Incident runbooks include identity containment and recovery procedures.

## Related Documents
- [Security Baseline](security_baseline.md)
- [Authentication Foundations](../13_operations_foundations/authentication.md)
- [Identity Foundations](../13_operations_foundations/identity.md)
