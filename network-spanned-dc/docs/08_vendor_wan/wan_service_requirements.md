# WAN Service Requirements

## Required Service Characteristics
- Vendor-managed L3 handoff at each site edge pair.
- IPv6 transport support suitable for ULA-routed inter-site traffic.
- Support for BGP peering and route policy enforcement.
- SLA metrics for latency, jitter, packet loss, and availability.

## Operational Requirements
- Planned maintenance notifications with lead time.
- Incident escalation path with priority handling for site isolation events.
- Near-real-time visibility for link and routing status.

## Design Constraint Reminder
This architecture intentionally avoids assumptions about physical circuit type, underlay provider topology, or carrier-specific routing internals.
