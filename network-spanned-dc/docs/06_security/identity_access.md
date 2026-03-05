# Identity and Access

## Identity Principles
- Centralized identity provider for administrators and service operators.
- Role-based access control mapped to operational responsibilities.
- Unique named accounts for all privileged access.

## MFA and Session Controls
- MFA required for all privileged and remote access, including all VPN connections.
- VPN authentication integrates with the site AD domain controller. AD group membership determines which firewall zones are accessible after tunnel establishment.
- Session recording for high-risk administration paths.
- Time-bound elevation for emergency or break-glass operations.
- VPN sessions are logged with user identity, source IP, connection duration, and destination zones accessed. Logs are shipped to the centralized logging stack.

## Service Account Governance
- Separate service identities for production and backup systems.
- No shared static credentials across environments.
- Periodic credential rotation with auditable change records.

## Access Review
- Monthly privileged access review.
- Quarterly entitlement recertification with service owners.
- Immediate deprovisioning for role changes and terminations.
