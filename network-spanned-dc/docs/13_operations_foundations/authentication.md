# Authentication

## Purpose
Authentication verifies identity before access is granted to services, infrastructure, and operations tooling.

## Authentication Baseline
- MFA required for privileged and remote access.
- Central directory-backed authentication for platform services.
- Encrypted auth transports (for example, LDAPS, TLS-backed auth endpoints).

## Authentication Paths
- Admin access: directory auth + MFA + role enforcement.
- VPN access: directory auth + MFA + policy-based zone admission.
- Service access: non-interactive service credentials with scoped privileges.
- VDI access (Guacamole): OIDC federation to Keycloak with FIDO2/WebAuthn passwordless enrollment.

## FIDO2 VDI Pattern
- Identity provider: Keycloak exposed at `/idp` behind the same edge entry point as Guacamole.
- User auth path: user selects OIDC login, taps FIDO2 key, and completes local key verification (PIN/biometric).
- Enrollment control: bootstrap users are required to register a passwordless WebAuthn credential.
- Guacamole trust model: Guacamole trusts OIDC assertions (`preferred_username`) and maps identity to existing connection permissions.
- Fallback control: local Guacamole admin remains for break-glass only; normal user access is expected through OIDC.

## Session Controls
- Time-bound elevation for high-risk operations.
- Session logging for privileged workflows.
- Explicit timeout and re-authentication requirements for sensitive actions.

## Service-to-Service Authentication
- Distinct service identity per integration path.
- Credential rotation on defined cadence.
- Revocation process tested for incident response.

## Failure and Fallback Handling
- Local-first authentication path with cross-site resilience.
- Break-glass flow only under incident conditions, fully audited.

## Control Validation
- Failed-auth anomaly alerts monitored continuously.
- Quarterly authentication flow test for VPN, admin, and service paths.
