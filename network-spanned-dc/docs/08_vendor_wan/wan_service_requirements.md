# WAN Service Requirements

## Required Service Characteristics
- Private circuit L3 service providing logically isolated inter-site connectivity. The WAN must not route inter-site traffic over shared public internet paths unless an explicit exception is approved and IPsec encryption is confirmed continuously active.
- Vendor-managed L3 handoff at each site edge pair.
- IPv6 transport support for ULA-routed inter-site traffic including IPsec-encapsulated packets. The WAN must pass ESP (IP protocol 50) and IKEv2 (UDP 500 and UDP 4500) without blocking or deep-packet inspection that breaks IKEv2 negotiation.
- Support for BGP peering and route policy enforcement.
- SLA metrics for latency, jitter, packet loss, and availability. Baseline SLA measurements should account for the MTU overhead introduced by IPsec encapsulation.

## Operational Requirements
- Planned maintenance notifications with lead time.
- Incident escalation path with priority handling for site isolation events.
- Near-real-time visibility for link and routing status.

## Design Constraint Reminder
This architecture intentionally avoids assumptions about physical circuit type, underlay provider topology, or carrier-specific routing internals. Regardless of the WAN service model selected, customer-controlled IPsec tunnels between site edge pairs are mandatory. Private WAN isolation and IPsec encryption are complementary layered controls, not alternatives to each other.
