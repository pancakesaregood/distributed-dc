# Routing and WAN Abstraction

## WAN Abstraction Boundary
The WAN is treated as a vendor-managed L3 handoff. This design specifies required capabilities and expected behavior, not carrier-specific transport implementation. The WAN is assumed to be a private circuit service (such as an MPLS VPN or equivalent dedicated L3 service) that isolates inter-site traffic at the network layer. In addition, the customer edge terminates IPsec tunnels between all site pairs to provide encryption that is fully under customer control, independent of WAN provider trust assumptions.

## Encryption Model
- All inter-site traffic traverses IPsec tunnels terminated on the site edge pair.
- IPsec mode: tunnel mode with IKEv2 key exchange.
- Cipher suite: AES-256-GCM for encryption, SHA-256 or stronger for integrity, Perfect Forward Secrecy enabled.
- IPsec tunnels are established between every pair of sites, forming a full-mesh encrypted overlay.
- BGP sessions run inside the IPsec tunnel; BGP MD5 or TCP-AO session authentication is applied as an additional control-plane hardening measure.
- IPsec session keys are rotated on a defined schedule and on any security incident involving edge credentials.

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
- Loss of one edge node: traffic fails over to surviving local edge without manual route changes. The surviving edge continues terminating IPsec tunnels.
- Loss of one WAN path: BGP convergence reroutes through remaining path. IPsec tunnels re-establish over the surviving path.
- Loss of BGP control plane: static fallback procedure restores minimal inter-site reachability. IPsec tunnels must remain operational for any static fallback traffic to be encrypted.
- Full site failure: failed site routes withdraw; traffic shifts to available sites hosting replicated services. IPsec tunnels from failed site tear down on IKEv2 dead-peer detection timeout.
- IPsec tunnel failure without WAN failure: treat as equivalent to edge node loss; route traffic through surviving local edge and its tunnel set while investigating the tunnel failure.

## IPsec Operational Requirements
- Each site edge pair shares an IPsec configuration sourced from version control.
- IKEv2 pre-shared keys or certificate-based authentication; certificate-based preferred for rotation and audit.
- Tunnel state is monitored and failures generate high-priority alerts equivalent to WAN path loss alerts.
- IPsec SA lifetime and rekeying parameters are documented and consistent across all sites.

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
