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
- All inter-site traffic traverses IPsec tunnels (IKEv2, AES-256-GCM, PFS) between site edge pairs. Private WAN circuits provide network-layer isolation in addition. See [Routing and WAN Abstraction](../02_architecture/routing_wan_abstraction.md) for cipher parameters, multi-tunnel redundancy model, and failure behavior.
- Each site has a local internet circuit for direct internet breakout. Internet-facing edge interfaces are treated as untrusted with strict ingress and egress filtering.
- Guest zone traffic exits only via NAT64 and IPv4 PAT at the local site internet interface. It is blocked from inter-site WAN tunnels and all internal zones.
- One designated site has dual ISP circuits on separate edge nodes for redundant internet egress.
- Control-plane route filters prevent unauthorized prefix advertisement.

## Firewall Baseline
- A dedicated vendor-agnostic stateful firewall pair (FW-A / FW-B) is deployed at each site, between the edge routers and the internal ToR switching fabric.
- Firewall operates in zone-based mode with explicit inside, outside, DMZ, VPN, and guest zones.
- Default deny between all zones. All permitted traffic flows require explicit rules.
- Firewall logs all permitted and denied sessions. Logs are shipped to the centralized logging stack.
- HA pair with session synchronization. Loss of one firewall node must not drop active sessions.
- Firewall configuration is version-controlled and deployed via GitOps. No manual changes outside the change process.
- Optional IDS/IPS on the outside interface for threat detection on internet-facing traffic.

## WAF and Load Balancer Baseline
- A WAF VM is deployed in the DMZ zone at each site. All inbound HTTP/HTTPS traffic from the internet or external zones passes through the WAF before reaching the nginx load balancer or any backend service.
- WAF enforces OWASP Top 10 protections: SQL injection, XSS, command injection, path traversal, and protocol anomaly filtering as a minimum baseline.
- WAF operates in blocking mode by default. Exceptions require GitOps change review.
- WAF logs all blocked requests with source IP, request detail, and matched rule. Logs are shipped to the centralized logging stack.
- An nginx load balancer VM is deployed in the DMZ zone at each site, downstream of the WAF. nginx terminates TLS for all published services and distributes requests across backend instances in the Servers/VMs zone.
- nginx health checks remove unhealthy backends from rotation without manual intervention.
- nginx and WAF configurations are version-controlled and deployed via GitOps. No manual changes outside the change process.
- WAF and nginx VMs are classified as Tier 1 stateless. Instances are rebuilt from automation on replacement.

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
