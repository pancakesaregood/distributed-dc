# Identity and Access

## Identity Principles
- Centralized identity provider for administrators and service operators.
- Role-based access control mapped to operational responsibilities.
- Unique named accounts for all privileged access.

## MFA and Session Controls
- MFA required for all privileged and remote access.
- Session recording for high-risk administration paths.
- Time-bound elevation for emergency or break-glass operations.

## Service Account Governance
- Separate service identities for production and backup systems.
- No shared static credentials across environments.
- Periodic credential rotation with auditable change records.

## Access Review
- Monthly privileged access review.
- Quarterly entitlement recertification with service owners.
- Immediate deprovisioning for role changes and terminations.
