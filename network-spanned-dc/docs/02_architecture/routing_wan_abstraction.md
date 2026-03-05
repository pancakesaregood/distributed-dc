# Routing and WAN Abstraction

## WAN Abstraction Boundary
The WAN is treated as a vendor-managed L3 handoff. This design specifies required capabilities and expected behavior, not carrier-specific transport implementation.

## Required WAN Capabilities
- IPv6 routing support for site edge peers.
- BGP session support per site for dynamic route exchange.
- Ability to carry each site `/56` summary route.
- SLA visibility for latency, packet loss, and availability.
- Fault notification and maintenance coordination process.

## Routing Model
- Primary: eBGP between each site edge pair and WAN handoff.
- Fallback: static routes with documented activation procedures.
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
- Loss of one edge node: traffic fails over to surviving local edge without manual route changes.
- Loss of one WAN path: BGP convergence reroutes through remaining path.
- Loss of BGP control plane: static fallback procedure restores minimal inter-site reachability.
- Full site failure: failed site routes withdraw; traffic shifts to available sites hosting replicated services.
