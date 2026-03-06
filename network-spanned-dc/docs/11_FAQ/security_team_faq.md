# Security Team FAQ

## What are the baseline controls?
- Zone-based segmentation, default deny, MFA for privileged and remote access, and centralized logging/monitoring.

## How is inter-site traffic protected?
- Encrypted with IPsec (IKEv2, AES-256-GCM, PFS) regardless of transport mode.

## Where is internet ingress policy enforced?
- Through site firewall policy and DMZ controls, including WAF and load balancer tiers.

## How are identity and access managed?
- AD-backed authentication with RBAC policy and LDAPS integrations for services.

## What telemetry is expected for security operations?
- Centralized logs, authentication events, firewall/WAF events, and alert-to-runbook mapping for response.
