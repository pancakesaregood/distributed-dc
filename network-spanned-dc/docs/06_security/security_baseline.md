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
- Control-plane route filters prevent unauthorized prefix advertisement.

## Firewall Baseline
- A dedicated vendor-agnostic stateful firewall pair (FW-A / FW-B) is deployed at each site, between the edge routers and the internal ToR switching fabric.
- Firewall operates in zone-based mode with explicit inside, outside, DMZ, VPN, and guest zones.
- Default deny between all zones. All permitted traffic flows require explicit rules.
- Firewall logs all permitted and denied sessions. Logs are shipped to the centralized logging stack.
- HA pair with session synchronization. Loss of one firewall node must not drop active sessions.
- Firewall configuration is version-controlled and deployed via GitOps. No manual changes outside the change process.
- Optional IDS/IPS on the outside interface for threat detection on internet-facing traffic.

## VPN Baseline
- Remote access VPN terminates on the site firewall appliance or a dedicated VPN VM in the DMZ zone.
- VPN is reachable via the public FQDN `vpn.example.com`, which resolves to the VPN endpoint IP at each site.
- MFA is required for all VPN connections. Authentication integrates with the site AD domain controller.
- VPN clients are placed in a restricted VPN zone on the firewall. Access to inside zones is governed by AD group membership and explicit firewall policy.
- All VPN sessions are logged with client identity, source IP, session duration, and accessed resources.
- Split tunnelling is disabled by default. All client traffic routes through the VPN tunnel.
- VPN session certificates or credentials are rotated on a defined schedule and immediately on compromise.

## Security Operations
- Centralized logging and alerting for auth, routing, and backup anomalies.
- Documented incident response and forensic preservation steps.
- Quarterly security review against this baseline.
