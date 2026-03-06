# Routing and WAN Abstraction

## WAN Abstraction Boundary
The WAN is treated as a vendor-managed L3 handoff. This design specifies required capabilities and expected behavior, not carrier-specific transport implementation. The WAN is assumed to be a private circuit service (such as an MPLS VPN or equivalent dedicated L3 service) that isolates inter-site traffic at the network layer. In addition, the customer edge terminates IPsec tunnels between all site pairs to provide encryption that is fully under customer control, independent of WAN provider trust assumptions.

## Encryption Model
- All inter-site traffic traverses IPsec tunnels terminated on the site edge pair.
- IPsec mode: tunnel mode with IKEv2 key exchange.
- Cipher suite: AES-256-GCM for encryption, SHA-256 or stronger for integrity, Perfect Forward Secrecy enabled.
- IPsec tunnels are established between every pair of sites, forming a full-mesh encrypted overlay.
- BGP sessions run inside the IPsec tunnels; BGP TCP-AO session authentication is applied as an additional control-plane hardening measure.
- IPsec session keys are rotated on a defined schedule and on any security incident involving edge credentials.

## Multi-Tunnel Redundancy Model

Each site operates an edge pair (Edge-A and Edge-B). Each edge node establishes independent IPsec tunnels to **each** edge node at every remote site. This produces four tunnels per site pair rather than one:

| Tunnel | Local | Remote | Role |
|---|---|---|---|
| A–A | Edge-A | Remote Edge-A | Primary — matched pair, preferred path |
| B–B | Edge-B | Remote Edge-B | Secondary — matched pair, failover path |
| A–B | Edge-A | Remote Edge-B | Cross-connect — available if remote Edge-A fails |
| B–A | Edge-B | Remote Edge-A | Cross-connect — available if local Edge-A fails |

With 4 sites and 6 site pairs, the fabric carries 24 IPsec tunnels in total.

**Redundancy properties:**
- Loss of one local edge node: 2 of 4 tunnels to each remote site remain active. Traffic reroutes automatically over the surviving edge.
- Loss of one remote edge node: same — 2 tunnels per affected site pair remain.
- Loss of one WAN path for a single edge: that edge's tunnels reroute or re-establish over its surviving path. The other edge's tunnels are unaffected.
- Simultaneous loss of a local edge AND the primary path on the remaining edge: the B–A or A–B cross-connect tunnel carries traffic on the surviving path until the failed components recover.

**BGP session assignment:**
- Primary BGP sessions run on A–A tunnels (Edge-A to remote Edge-A for each site pair).
- Secondary BGP sessions run on B–B tunnels (Edge-B to remote Edge-B for each site pair).
- Cross-connect tunnels (A–B, B–A) carry forwarded traffic under routing policy but do not carry additional BGP sessions by default. Add cross-connect BGP sessions if stricter convergence guarantees are required.
- Each edge node therefore maintains `(n-1) × 2` BGP sessions where n is the number of sites (6 sessions per edge, 12 per site across both edges).

## Required WAN Capabilities
- Private circuit or VPN service providing logically isolated inter-site L3 connectivity.
- IPv6 routing support for site edge peers.
- BGP session support per site for dynamic route exchange.
- Ability to carry each site `/56` summary route and IPsec-encapsulated inter-site traffic.
- SLA visibility for latency, packet loss, and availability.
- Fault notification and maintenance coordination process.

## Routing Model
- Primary: eBGP between each site edge pair and WAN handoff, carried over IPsec-encrypted inter-site tunnels.
- Fallback: static routes with documented activation procedures. Static fallback traffic also routes through the IPsec overlay.
- Local preference and AS-path policy to prefer healthy primary paths.
- Prefix filtering to accept and advertise only approved route sets.

## Route Advertisement Policy
Each site advertises only its site summary:
- Site A advertises `fdca:fcaf:e000::/56`
- Site B advertises `fdca:fcaf:e100::/56`
- Site C advertises `fdca:fcaf:e200::/56`
- Site D advertises `fdca:fcaf:e300::/56`

This limits control-plane churn and avoids leaking internal `/64` detail externally.

## Optional Anycast for Shared Services
Anycast is optional for:
- Internal DNS resolver VIP
- Internal ingress VIP

Approach:
- Advertise identical `/128` loopback anycast addresses from multiple sites.
- Use health checks to withdraw advertisements when local service is unhealthy.
- Keep stateful backends non-anycast unless replication semantics are proven safe.

## Failure Behavior Expectations
- Loss of one edge node: the surviving local edge retains 2 of 4 tunnels to each remote site (B–B and B–A if Edge-B survives, or A–A and A–B if Edge-A survives). BGP withdraws routes learned via the failed edge. No manual intervention required.
- Loss of one WAN path on a single edge: IPsec tunnels from that edge re-establish over its surviving internet path (for Mode B) or fail if the only WAN path is gone. The paired edge and its tunnels are unaffected.
- Loss of both tunnels to a remote site from one local edge: cross-connect tunnels from the other local edge carry traffic to that remote site. BGP routes are still available via the secondary BGP session.
- Loss of BGP control plane: static fallback procedure restores minimal inter-site reachability. IPsec tunnels must remain operational for any static fallback traffic to be encrypted.
- Full site failure: all 8 tunnels from the failed site tear down on IKEv2 dead-peer detection timeout. Failed site routes withdraw from all remaining sites via BGP. Traffic shifts to available sites hosting replicated services.
- IPsec tunnel failure without WAN failure: BGP withdraws routes using that tunnel. Remaining tunnels carry the load. Investigate and re-establish the failed tunnel without traffic impact.

## IPsec Operational Requirements
- Each site edge pair shares an IPsec configuration sourced from version control. Tunnel definitions are templated per edge role (Edge-A or Edge-B) and applied consistently across all sites.
- IKEv2 pre-shared keys or certificate-based authentication; certificate-based preferred for rotation and audit.
- All 24 tunnel states are monitored individually. Any single tunnel failure generates a high-priority alert. Loss of both tunnels in a matched pair (A–A and A–B, or B–B and B–A) generates a critical alert.
- IPsec SA lifetime and rekeying parameters are documented and consistent across all sites and all tunnel roles.
- Cross-connect tunnels (A–B, B–A) are held in a ready-established state at all times, not brought up on demand. This ensures they are immediately available for traffic without an IKEv2 negotiation delay at the moment they are needed.

## Internet Breakout Model
Each site has an independent local internet connection terminating on the site edge pair. Internet traffic exits directly at the local site and is never backhauled over the inter-site WAN.

### Standard Sites
- A single ISP circuit connects to both Edge-A and Edge-B at the site.
- Edge nodes share the ISP circuit via active-standby or ECMP depending on ISP handoff capability.
- Loss of one edge node: internet traffic fails over to the surviving edge node automatically.
- Loss of the ISP circuit: site loses internet egress; inter-site WAN and private services remain unaffected.

### Designated Redundant Internet Site
One site is designated to have full internet edge redundancy:
- Edge-A connects to ISP-1 (primary internet circuit).
- Edge-B connects to ISP-2 (secondary internet circuit from a different provider).
- BGP or policy-based routing selects the preferred internet path; failover is automatic on path loss.
- This site can optionally provide internet fallback egress for other sites during a local ISP outage, via the inter-site WAN, if explicitly enabled in policy. This path must be approved in design governance before activation.

### Guest Internet Routing
- Guest zone traffic is policy-routed to the local site internet L3 interface. All guest internet egress exits at the closest site L3OUT — no WAN backhaul.
- Guest traffic is explicitly blocked from entering the IPsec inter-site WAN tunnels.
- Guest traffic must not reach any internal segment; the only permitted destination is the internet via the local edge.
- If the local internet circuit is unavailable, guest service is suspended at that site. Guest traffic is not rerouted over the WAN to another site's internet path by default.

#### NAT64 and DNS64 for Guest Internet

The internal network is IPv6-only (ULA). Guest devices need to reach both IPv6-native and IPv4-only internet destinations. Two translation functions are deployed at each site for the guest path:

**NAT64 (RFC 6146)**
- Translates outbound IPv6 packets from guest devices into IPv4 packets at the local internet L3 interface.
- Uses the Well-Known Prefix `64:ff9b::/96` as the NAT64 destination range. Packets from guests addressed to `64:ff9b::<ipv4>` are translated to the corresponding IPv4 destination.
- NAT64 is implemented on the site firewall pair where the platform supports it (e.g., VyOS, OPNsense with Jool). If the firewall does not support NAT64 natively, a dedicated NAT64 gateway VM (`site-<x>-nat64-01`) is deployed in the Guest zone and traffic is steered to it via firewall policy.
- All NAT64 state is local to the site. Cross-site NAT64 failover is not provided; guest internet access is site-local.

**DNS64 (RFC 6147)**
- A DNS64 resolver is provided to the guest segment as the authoritative DNS for guest clients. DHCP for guests delivers the DNS64 resolver address.
- The DNS64 resolver synthesizes AAAA records for IPv4-only internet hosts by prepending the NAT64 Well-Known Prefix to the host's A record address. Guest devices then connect to the synthesized IPv6 address, which NAT64 translates to IPv4.
- For hosts with native AAAA records, DNS64 returns the real AAAA record unchanged. NAT64 is not involved for IPv6-native destinations.
- DNS64 runs as a lightweight VM or container (`site-<x>-dns64-01`) in the Guest zone, or as a separate resolver view on the site DNS resolver with guest-facing DNSSEC validation adjusted for synthesis.

**IPv4 PAT (Masquerade)**
- NAT64-translated IPv4 packets exit the site through the edge internet interface with IPv4 PAT (NAPT/masquerade). The edge masquerades all outbound IPv4 behind the ISP-assigned public IPv4 address(es).
- This is standard IPv4 NAT at the edge internet interface, applied to all IPv4 traffic destined for the internet regardless of origin (NAT64-translated guest traffic or any other IPv4 egress path).
- On the designated redundant internet site with dual ISP circuits, PAT is applied per-edge to the respective ISP address.

**NPTv6 (Optional)**
- If the ISP provides a public IPv6 prefix (GUA), NPTv6 (Network Prefix Translation, RFC 6296) at the edge translates the ULA guest source address to a GUA address for IPv6-native internet destinations. This eliminates the NAT64/DNS64 path for IPv6-capable sites and provides a direct IPv6 path.
- NPTv6 is stateless and has no session table overhead. Enable it if the ISP provides a stable IPv6 prefix.

**Guest translation path summary:**

| Destination type | Guest source | Path |
|---|---|---|
| IPv4-only internet | ULA guest | DNS64 synthesis → NAT64 → IPv4 PAT → ISP IPv4 |
| IPv6-native internet | ULA guest | NPTv6 (ULA→GUA) → ISP IPv6 (if available) or NAT64 fallback |
| Any internal segment | ULA guest | Denied by firewall — guest zone isolation |

### VPN Inbound Routing
- Remote access VPN connections arrive from the internet at the edge router's internet-facing interface.
- The edge router forwards VPN traffic to the firewall outside interface. The firewall handles VPN termination.
- VPN can terminate on the firewall appliance itself (preferred for simplicity) or via DNAT to a dedicated VPN VM in the DMZ zone.
- Authenticated VPN sessions are placed in the VPN zone on the firewall. Zone policy then permits traffic to inside zones based on group membership.
- The public FQDN `vpn.example.com` resolves to the VPN endpoint IP at each site. DNS can be managed as per-site records or via GeoDNS for automatic client routing to the nearest site.
