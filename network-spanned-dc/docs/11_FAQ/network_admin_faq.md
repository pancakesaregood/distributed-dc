# Network Admin FAQ

## What is the inter-site routing model?
- BGP over IPsec tunnels across a vendor-managed Layer 3 WAN abstraction.

## Are we stretching Layer 2 between sites?
- No. Inter-site design is Layer 3 only.

## How are prefixes advertised?
- Per-site summary prefixes with policy controls and optional anycast advertisements where appropriate.

## What redundancy is expected?
- Edge pair per site, dual ToR paths, and multi-tunnel inter-site model with documented failover behavior.

## How is guest internet handled?
- Local breakout only, with NAT64/DNS64 for IPv6-only guest clients and no guest access to inter-site WAN paths.
