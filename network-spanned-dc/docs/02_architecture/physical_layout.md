# Physical Layout

## Site Template
Each site uses a compact design suitable for 1 to 2 racks:

- Rack 1: edge pair, ToR pair, management services, and at least two hypervisor nodes.
- Rack 2 (optional): additional hypervisors, storage nodes, and service expansion capacity.

## Standard Components per Site
- `Edge-A` and `Edge-B`: firewall/router pair for WAN handoff, local internet breakout, and policy enforcement. Each edge node has a dedicated interface for the internet circuit in addition to the WAN handoff interface.
- `ToR-A` and `ToR-B`: redundant top-of-rack switching.
- `HV-01..n`: VM hypervisor nodes.
- `Storage-01..n`: local storage and replication endpoints.
- `Mgmt-VMs`: DNS caching, monitoring collectors, and automation agents.

## Internet Circuit Model
- Standard site: one ISP circuit presented to both Edge-A and Edge-B. Edge nodes share the circuit via active-standby or ECMP.
- Designated redundant internet site: Edge-A connects to ISP-1 and Edge-B connects to ISP-2. Full edge and ISP redundancy for internet egress. Designate one site at implementation; Site A is recommended given its primary service role.

## Physical Redundancy Pattern
- Dual power paths for all critical nodes.
- Dual uplinks from each hypervisor to both ToR switches.
- Dual uplinks from each ToR to both edge devices.
- Out-of-band management network physically separated where feasible.

## Capacity Guidance
- Minimum per site: 2 hypervisors, 2 ToRs, 2 edge nodes.
- Recommended growth threshold: add Rack 2 when sustained compute utilization exceeds 65 percent.
- Keep spare capacity for one host failure without violating Tier 1 service SLOs.
