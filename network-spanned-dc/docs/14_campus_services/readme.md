# Campus and Edge Services

This section adds service-specific guidance for user-facing campus and edge services that sit on top of the multi-site architecture.

## Included sections
- [Telephony](telephony.md)
- [Printing](printing.md)
- [WLC and WAPs](wlc_waps.md)
- [Campus Networks](campus_networks.md)

## Shared baseline for all four services
- Layer 3 only between sites.
- Per-site failure domains with local survivability where possible.
- Segmentation and default-deny controls enforced at zone boundaries.
- Git-backed change control and documented rollback plans.
- Monitoring and runbook mapping required before production handoff.

## Related diagrams
- [Telephony Service Flow](../03_diagrams/telephony_flow.mmd.md)
- [Printing Service Flow](../03_diagrams/printing_flow.mmd.md)
- [WLC and WAP Topology](../03_diagrams/wlc_waps_topology.mmd.md)
- [Campus Network Topology](../03_diagrams/campus_networks_topology.mmd.md)
