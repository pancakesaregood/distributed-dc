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
- All inter-site traffic is encrypted using IPsec tunnel mode with IKEv2. Site edge pairs terminate a full-mesh IPsec overlay across all four sites. The WAN provider carries only encrypted packets.
- Private WAN circuits provide network-layer isolation in addition to the IPsec encryption layer.
- BGP sessions between site edges run inside IPsec tunnels and are additionally protected with TCP-AO or MD5 session authentication.
- IPsec tunnel health is monitored and failures alert at the same priority as WAN path failures.
- Each site has a local internet circuit for direct internet breakout. Internet-facing edge interfaces are treated as untrusted and subject to strict ingress and egress filtering.
- Guest zone traffic exits only through the local site internet interface. Guest traffic is explicitly blocked from entering IPsec inter-site tunnels or reaching any internal zone.
- One designated site has dual ISP circuits terminating on separate edge nodes for redundant internet egress.
- Edge policy restricts inter-site and north-south flows to approved ports.
- Guest and IoT zones isolated from management and server zones.
- Control-plane route filters prevent unauthorized prefix advertisement.

## Security Operations
- Centralized logging and alerting for auth, routing, and backup anomalies.
- Documented incident response and forensic preservation steps.
- Quarterly security review against this baseline.
