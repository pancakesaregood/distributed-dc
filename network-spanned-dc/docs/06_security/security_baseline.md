# Security Baseline

## Purpose
Define minimum mandatory controls for the spanned datacenter platform so security posture is consistent across all four sites.

## Baseline Objectives
- Enforce least privilege for all human and service identities.
- Constrain blast radius with zone segmentation and default deny policy.
- Encrypt sensitive traffic paths in transit and protect data at rest.
- Maintain audit-quality telemetry for detection, response, and review.
- Keep security controls reproducible through Git-backed change workflows.

## Control Domains

### Identity and Access
- Centralized identity source for operators and service administrators.
- MFA required for privileged access and remote access.
- Unique named privileged accounts only; no shared admin accounts.
- Time-bounded elevation for break-glass and high-risk tasks.

### Network and Segmentation
- Inter-site traffic traverses IPsec overlay tunnels (IKEv2, AES-256-GCM, PFS).
- Layer 3 between sites only; no stretched Layer 2 trust boundary.
- Guest zone is internet-only and blocked from internal zones and WAN tunnels.
- Route filtering prevents unauthorized prefix advertisement.

### Perimeter and Application Exposure
- Dedicated firewall pair at each site with explicit zone policy.
- Default deny between zones; allow rules must be explicit and justified.
- Inbound HTTP/HTTPS paths must traverse WAF before load balancer or backend.
- Internet ingress and VPN entry points treated as untrusted edges.

### Platform and Host Hardening
- Hardened base images for hypervisors and critical service VMs.
- Encrypted management protocols only.
- Signed package sources and controlled update channels.
- Endpoint protection and vulnerability remediation cadence for critical hosts.

### Data Protection
- Backup and replication channels encrypted in transit.
- Backup model aligned to 3-2-1 with immutable or off-domain copy.
- Credential separation between production and backup control planes.
- Restore workflows tested on a recurring schedule.

### Detection and Response
- Centralized collection of firewall, WAF, auth, host, and backup signals.
- Alert severity model with runbook mapping for Sev 1 and Sev 2 events.
- Forensic logging retention aligned to incident response requirements.
- Quarterly security baseline review and control exception review.

## Firewall Baseline Requirements
- FW-A/FW-B deployed per site between edge and internal fabric.
- HA pair with state/session synchronization.
- Firewall policy and object definitions managed through GitOps.
- All permit and deny events logged to centralized telemetry.
- Manual emergency changes require post-incident normalization through code.

## WAF and Load Balancer Baseline Requirements
- WAF deployed in DMZ and operating in blocking mode by default.
- OWASP-focused baseline ruleset required for all published apps.
- Exception requests require review, approval, and expiry date.
- Load balancer performs TLS termination and backend health checks.
- WAF/LB configurations are version-controlled and reproducible.

## VPN and Remote Access Baseline Requirements
- VPN terminates on firewall or dedicated VPN VM in DMZ.
- VPN authentication requires directory-backed identity + MFA.
- Post-auth zone access determined by role and explicit policy.
- Split tunneling disabled by default unless formally approved.
- VPN sessions logged with identity, source, duration, and target zone.

## Governance and Assurance
- Security controls must be mapped to runbooks and monitored signals.
- Exceptions must include owner, reason, risk statement, and expiry.
- Baseline drift is reviewed monthly and corrected through change process.

## Related Documents
- [Identity and Access](identity_access.md)
- [Logging and Monitoring](logging_monitoring.md)
- [Monitoring Foundations](../13_operations_foundations/monitoring.md)
- [Observability Foundations](../13_operations_foundations/observability.md)
- [Authentication Foundations](../13_operations_foundations/authentication.md)
