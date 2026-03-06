# Campus Networks

## Purpose
Define a repeatable campus access network pattern per site that aligns with segmentation, security, and operations standards.

## Reference diagram
See [Campus Network Topology](../03_diagrams/campus_networks_topology.mmd.md).

## Scope
- Wired campus access for users, devices, and local edge services.
- Site-local distribution and uplink policy to datacenter services.
- Guest and IoT segmentation with controlled egress paths.

## Design baseline
- Dual access switch paths for critical wiring closets.
- Explicit VLAN or VRF boundaries for user, voice, guest, IoT, and management.
- Dynamic routing from site distribution to core/firewall boundaries.
- Standardized DHCP relay, DNS policy, and NTP reachability.

## Security and policy controls
- Default-deny inter-segment policy with explicit allow rules.
- NAC or identity-aware policy for device onboarding where required.
- Port security baseline for unused ports and unauthorized devices.
- Dedicated management plane for switch and network device administration.

## Availability and failover model
- Redundant uplinks from access to site distribution or ToR layers.
- Documented first-hop redundancy behavior for critical user segments.
- Site-local service continuity for campus authentication dependencies.
- Clear degraded-mode behavior when WAN or central services fail.

## Implementation checklist
1. Define segment catalog and per-segment policy intent.
2. Apply standard switch templates and naming conventions.
3. Configure uplink redundancy and routing adjacencies.
4. Enforce ACL and firewall policy at zone boundaries.
5. Validate endpoint onboarding for corporate, guest, and IoT segments.
6. Execute failover tests for uplinks and first-hop gateways.
7. Complete diagrams, runbooks, and support escalation paths.

## Validation evidence
- Segment reachability matrix with expected allow and deny outcomes.
- Uplink and gateway failover test logs.
- Security review for management plane and access control posture.
- Operations handoff confirmation for network support teams.
