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
- Guest zone traffic is policy-routed to the local site internet L3 interface.
- Guest traffic is explicitly blocked from entering the IPsec inter-site WAN tunnels.
- Guest traffic must not reach any internal segment; the only permitted destination is the internet via the local edge.
- If the local internet circuit is unavailable, guest service is suspended at that site. Guest traffic is not rerouted over the WAN to another site's internet path by default.

### VPN Inbound Routing
- Remote access VPN connections arrive from the internet at the edge router's internet-facing interface.
- The edge router forwards VPN traffic to the firewall outside interface. The firewall handles VPN termination.
- VPN can terminate on the firewall appliance itself (preferred for simplicity) or via DNAT to a dedicated VPN VM in the DMZ zone.
- Authenticated VPN sessions are placed in the VPN zone on the firewall. Zone policy then permits traffic to inside zones based on group membership.
- The public FQDN `vpn.example.com` resolves to the VPN endpoint IP at each site. DNS can be managed as per-site records or via GeoDNS for automatic client routing to the nearest site.
