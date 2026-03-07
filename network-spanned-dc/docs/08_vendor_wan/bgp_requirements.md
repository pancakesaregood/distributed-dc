# BGP Requirements

## Session Model
- eBGP between each site edge node and WAN handoff, hardened with TCP-AO authentication.
- All inter-site BGP sessions run inside IPsec tunnels. The full tunnel redundancy model is defined in [Routing and WAN Abstraction — Multi-Tunnel Redundancy Model](../02_architecture/routing_wan_abstraction.md).

## BGP Session Assignment per Tunnel

Each site pair maintains four IPsec tunnels. BGP sessions are assigned as follows:

| Tunnel | BGP Session | Purpose |
|---|---|---|
| A–A (Edge-A to remote Edge-A) | Yes — primary | Preferred path; carries primary routing table |
| B–B (Edge-B to remote Edge-B) | Yes — secondary | Failover path; active session, lower local preference |
| A–B (Edge-A to remote Edge-B) | No — traffic only | Cross-connect; forwards traffic by routing policy, no BGP |
| B–A (Edge-B to remote Edge-A) | No — traffic only | Cross-connect; forwards traffic by routing policy, no BGP |

Each edge node therefore maintains `(n-1) × 2` BGP sessions where n is the number of sites. With four sites: 6 BGP sessions per edge node, 12 per site across both edge nodes.

Cross-connect BGP sessions may be added if faster convergence is required during a matched-pair tunnel failure. This increases session count to `(n-1) × 4` per site but eliminates the routing policy failover delay.

## Prefix Policy
- Advertise only site summary `/56` prefixes.
- Accept only approved internal and required service prefixes.
- Block default route unless explicitly approved in design governance.

## Convergence and Stability
- Use conservative timer settings aligned with WAN SLA and failover objectives.
- Apply route dampening carefully to avoid masking true failures.
- Monitor flap events and tie to incident review workflow.

## Anycast Support
- Optional `/128` anycast advertisements allowed for internal DNS and ingress VIPs.
- Anycast advertisements must be health-gated to avoid blackholing traffic.
