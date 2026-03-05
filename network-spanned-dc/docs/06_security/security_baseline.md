# Security Baseline

## Baseline Controls
- Least privilege access for infrastructure and platform roles.
- MFA for privileged control-plane access.
- Segmentation with default-deny inter-zone policy.
- Encrypted management protocols only.
- Encrypted backups and replication channels.

## Platform Hardening
- Standard hardened images for hypervisors and VM templates.
- CIS-aligned configuration where practical.
- Controlled package sources and signed update artifacts.
- Endpoint protection for management and critical service VMs.

## Network Security
- Edge policy restricts inter-site and north-south flows to approved ports.
- Guest and IoT zones isolated from management and server zones.
- Control-plane route filters prevent unauthorized prefix advertisement.

## Security Operations
- Centralized logging and alerting for auth, routing, and backup anomalies.
- Documented incident response and forensic preservation steps.
- Quarterly security review against this baseline.
