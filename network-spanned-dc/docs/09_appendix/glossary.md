# Glossary

## Networking and Routing

- **BGP (Border Gateway Protocol)**: Dynamic routing protocol used for inter-site route exchange.
- **eBGP**: BGP sessions between routers in different autonomous systems.
- **TCP-AO (TCP Authentication Option)**: Cryptographic authentication for BGP TCP sessions.
- **TCP MD5**: Legacy BGP session authentication mechanism used only where TCP-AO is not supported.
- **Anycast**: The same IP address advertised from multiple sites so routing selects the nearest healthy path.
- **GeoDNS**: DNS steering method that returns site-specific records by client geography or policy.
- **ECMP (Equal-Cost Multi-Path)**: Routing behavior that load-shares across equal-cost paths.
- **L3OUT**: Local Layer 3 internet egress interface at each site edge.
- **ToR (Top of Rack)**: Rack-level switch pair that aggregates host uplinks.
- **Edge pair**: Two site edge nodes that terminate WAN handoffs and IPsec tunnels.

## WAN and Tunnel Transport

- **Mode A (Private Circuit)**: Vendor-managed private WAN transport underlay.
- **Mode B (Consumer IPv4 Internet)**: Public internet underlay carrying IPv6-over-IPv4 IPsec tunnels.
- **MPLS (Multiprotocol Label Switching)**: Common private WAN transport technology used by carriers.
- **CGNAT (Carrier-Grade NAT)**: ISP NAT layer that can force NAT-T usage for IPsec tunnels.
- **IPsec**: Protocol suite for authenticated and encrypted IP transport between sites.
- **IKEv2**: Negotiation protocol used to establish and maintain IPsec security associations.
- **ESP (Encapsulating Security Payload)**: IPsec data-plane protocol used for encrypted tunnel payloads.
- **NAT-T (NAT Traversal)**: Encapsulation of ESP in UDP 4500 to traverse NAT devices.
- **MTU (Maximum Transmission Unit)**: Largest packet size allowed on a link without fragmentation.
- **Inner MTU**: Effective payload MTU available inside the IPsec tunnel after encapsulation overhead.
- **PMTUD (Path MTU Discovery)**: Mechanism that discovers end-to-end MTU and avoids blackholing large packets.

## IPv6 Addressing and Translation

- **ULA (Unique Local Address)**: Private IPv6 address space (`fc00::/7`) used for internal traffic.
- **GUA (Global Unicast Address)**: Publicly routable IPv6 address.
- **/48**: Organization-level IPv6 allocation for the full environment.
- **/56**: Site-level allocation carved from the /48.
- **/64**: Standard IPv6 subnet size for a segment.
- **/128**: Single IPv6 host address, commonly used for loopbacks and VIPs.
- **SLAAC (Stateless Address Autoconfiguration)**: Automatic IPv6 host addressing from router advertisements.
- **DHCPv6**: IPv6 DHCP service used for reserved assignment and option delivery.
- **NAT64**: Stateful IPv6-to-IPv4 translation for IPv6-only clients reaching IPv4-only destinations.
- **DNS64**: DNS synthesis of AAAA records from A records for NAT64 traversal.
- **WKP (Well-Known Prefix)**: NAT64 prefix `64:ff9b::/96`.
- **NPTv6**: Stateless IPv6 prefix translation (ULA to GUA) when public IPv6 is available.
- **PAT / NAPT**: Many-to-one IPv4 translation using source port remapping.

## Segmentation and Security Controls

- **FW-A / FW-B**: High-availability firewall pair at each site.
- **Zone-based firewall**: Policy model that permits or denies traffic between named security zones.
- **DMZ (Demilitarized Zone)**: Zone for internet-facing services such as WAF, load balancer, and optional VPN VM.
- **Outside zone**: Untrusted zone facing WAN and internet ingress.
- **Servers/VMs zone**: Internal zone for application and platform servers.
- **Guest zone**: Internet-only user zone isolated from internal systems.
- **VPN zone**: Zone where authenticated remote-access sessions are placed.
- **VDI zone**: Zone containing virtual desktop workloads and brokered access paths.
- **Default deny**: Security posture that blocks all traffic unless explicitly allowed.
- **Stateful inspection**: Firewall behavior that tracks session state and permits return traffic for established sessions.
- **WAF (Web Application Firewall)**: Layer 7 control that inspects and blocks malicious web traffic.
- **OWASP Top 10**: Baseline list of common web application security risks used for WAF policy.
- **TLS (Transport Layer Security)**: Encryption protocol for application traffic.
- **HSTS (HTTP Strict Transport Security)**: Browser policy that enforces HTTPS-only access.
- **LDAPS**: LDAP over TLS, used for secure directory authentication queries.
- **RBAC (Role-Based Access Control)**: Authorization model based on role membership.
- **Break-glass access**: Time-bound emergency access path used during incidents.

## Published Apps and Remote Access

- **Ingress VIP**: Site or anycast virtual IP that receives inbound application traffic.
- **nginx load balancer**: Reverse proxy and TLS termination layer in front of backends.
- **VDI (Virtual Desktop Infrastructure)**: Remote desktop service delivered from centrally hosted VMs.
- **Apache Guacamole**: Clientless HTML5 gateway for RDP, VNC, and SSH sessions.
- **guacamole-client**: Web application component serving user sessions.
- **guacd**: Proxy daemon translating Guacamole protocol to backend desktop protocols.
- **RDP (Remote Desktop Protocol)**: Remote desktop protocol used for Windows and compatible Linux access.
- **XRDP**: Linux service that enables RDP connectivity.
- **VPN (Virtual Private Network)**: Encrypted remote-access tunnel into site networks.
- **MFA (Multi-Factor Authentication)**: Authentication requiring at least two independent factors.
- **TOTP (Time-based One-Time Password)**: Short-lived numeric code used as an MFA factor.
- **Split tunnel**: VPN mode where only selected traffic traverses the tunnel.

## Operations and Reliability

- **GitOps**: Operating model where configuration changes are made through version-controlled pull requests and automated deployment.
- **SDN (Software-Defined Networking)**: Network control through software abstractions and policy-driven automation.
- **EVPN (Ethernet VPN)**: BGP-based control plane for overlay reachability.
- **VXLAN (Virtual eXtensible LAN)**: Overlay encapsulation carrying Layer 2 segments over IP.
- **IPAM (IP Address Management)**: Source-of-truth system for subnet and address allocation.
- **DCIM (Data Center Infrastructure Management)**: Source-of-truth system for physical inventory and rack placement.
- **RTO (Recovery Time Objective)**: Maximum acceptable restoration time after an outage.
- **RPO (Recovery Point Objective)**: Maximum acceptable data loss measured in time.
- **HA (High Availability)**: Redundancy design that keeps services available through component failure.
- **SLO (Service Level Objective)**: Internal reliability target used to measure service performance.
- **3-2-1 backup**: Backup strategy with 3 data copies, 2 media types, and 1 off-domain or immutable copy.
