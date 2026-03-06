# Logical Network

## Logical Domains
- Management domain for infrastructure administration.
- Server and VM domain for traditional workloads.
- Container domain for Podman-hosted services.
- User and endpoint domain for internal clients.
- IoT and guest domains with restricted access.
- DMZ domain for externally exposed internal services.
- VPN domain: terminated remote access sessions before they are admitted to any inside zone. Traffic in this domain has been authenticated but not yet permitted to a specific inside zone.
- Loopback and transit domains for routing control.
- Internet domain: local ISP circuit on the site edge pair, used for direct internet breakout. Separate from the inter-site WAN domain.

## Inter-Site Connectivity Model
- Sites exchange summarized routes over vendor-managed L3 handoff delivered as a private circuit service.
- All inter-site traffic is carried inside IPsec tunnels terminated on site edge pairs. The WAN provider carries encrypted packets; it has no visibility into payload content.
- East-west traffic between sites passes through the site firewall pair before reaching the edge router and entering the IPsec overlay.
- No VLAN or broadcast domain is extended across sites.

## Site Traffic Path
Inbound: `Edge pair (outside) → Firewall outside interface → Firewall zone policy → Firewall inside interface → ToR → Internal segment`

Outbound: `Internal segment → ToR → Firewall inside interface → Firewall zone policy → Firewall outside interface → Edge pair → WAN or Internet`

VPN inbound: `Internet → Edge pair → Firewall outside interface → VPN termination (on-box or VPN VM via DMZ) → Firewall zone policy → Firewall inside interface → ToR → Permitted internal segment`

## Control Plane Expectations
- BGP preferred for dynamic route exchange. BGP sessions run over the IPsec inter-site tunnels and are additionally hardened with TCP-AO or MD5 session authentication.
- Static route fallback available when BGP is unavailable. Static fallback traffic also transits the IPsec overlay.
- Prefix filters prevent accidental route leaks.

## Data Plane Expectations
- Service traffic uses IPv6 ULA internally.
- Security zones are enforced at site edge and internal policy points.
- All data-plane traffic leaving a site edge toward other sites is encrypted by the IPsec inter-site tunnel before reaching the WAN handoff.
- Internet-destined traffic exits through the local site internet interface, not the WAN. Guest traffic uses local internet breakout only and is blocked from the WAN. Guest devices receive a DNS64 resolver via DHCP; NAT64 translates IPv6 ULA traffic to IPv4 for IPv4-only internet destinations using the Well-Known Prefix `64:ff9b::/96`. IPv4 PAT is applied at the edge internet interface. NPTv6 handles IPv6-native internet destinations where the ISP provides a public IPv6 prefix.
- Cross-site traffic for stateful services is replication-oriented, not chatty transaction-by-transaction, unless latency permits. Replication streams are encrypted end-to-end by the IPsec overlay; application-layer encryption is additional and optional.
