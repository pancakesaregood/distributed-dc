# Network Admin FAQ

## In simple terms, how do the sites route traffic to each other?
Sites exchange routes using BGP across encrypted IPsec tunnels that run over a vendor-managed Layer 3 WAN abstraction. Think of it as each site having secure "roadways" to every other site, with dynamic signs telling traffic where to go. BGP gives path control and visibility, while IPsec protects data in transit regardless of transport mode underneath. This combination provides operational flexibility without exposing inter-site traffic in plain text.

## Are we building one big Layer 2 network across all sites?
No, and that is a deliberate safety choice. Inter-site connectivity stays Layer 3 only, which keeps broadcast domains local and limits blast radius during faults. Stretching Layer 2 across distance can increase failure complexity and make troubleshooting harder under pressure. Layer 3 boundaries make the design easier to reason about, scale, and recover.

## How are route prefixes announced and controlled?
Routes are advertised primarily as per-site summary prefixes, with policy controls deciding what is accepted and preferred. Anycast can be used where it improves service behavior, but only where it is operationally justified and documented. Summary and policy-based control keep routing tables cleaner and reduce unintended path behavior. In plain language: we advertise intentionally, not everything by default.

## What redundancy should I assume is present?
Each site expects an edge pair, dual top-of-rack paths, and multiple inter-site tunnels with documented failover behavior. Redundancy exists at several layers so one device, one cable path, or one tunnel failure does not automatically become a user-visible outage. This does not eliminate incidents, but it gives the system room to absorb failures while teams respond. The key is that failover behavior is known, tested, and documented ahead of time.

## How is guest internet access handled safely?
Guest traffic breaks out locally at each site and does not get routed into inter-site corporate paths. For IPv6-only guest clients, NAT64 and DNS64 provide practical access to IPv4 destinations without weakening segmentation intent. This keeps guest usage isolated from internal production traffic and simplifies policy enforcement. The model is straightforward: guest access to internet, not guest access to internal WAN transport.
