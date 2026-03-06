# Physical Layout

## Site Template
Each site uses a compact design suitable for 1 to 2 racks:

- Rack 1: edge pair, firewall pair, ToR pair, management services, and at least two hypervisor nodes.
- Rack 2 (optional): additional hypervisors, storage nodes, and service expansion capacity.

## Standard Components per Site
- `Edge-A` and `Edge-B`: L3 router pair. Handles WAN private circuit termination, IPsec inter-site tunnel endpoints, local internet ISP termination, and BGP routing. Each edge node has dedicated interfaces for the WAN handoff and the internet circuit. Does not perform stateful zone inspection — that function belongs to the firewall pair.
- `FW-A` and `FW-B`: dedicated vendor-agnostic stateful firewall pair. Outside interface faces the edge pair; inside interface(s) connect to the internal ToR switching fabric. Enforces all inter-zone policy and performs stateful inspection of all traffic crossing the inside/outside boundary. VPN terminates here (on-box) or traffic is forwarded to a dedicated VPN VM via a DMZ interface. Deployed as an HA pair with session synchronization.
- `ToR-A` and `ToR-B`: redundant top-of-rack switching. Connects to the firewall inside interfaces and distributes to hypervisors and storage.
- `HV-01..n`: VM hypervisor nodes.
- `Storage-01..n`: local storage and replication endpoints.
- `Mgmt-VMs`: DNS caching, monitoring collectors, and automation agents.
- `VPN-VM` (optional): dedicated VPN server VM if VPN is not hosted on the firewall appliance. Placed in a VPN segment accessible from the firewall DMZ interface.
- `WAF-VM`: Web Application Firewall VM deployed in the DMZ zone. Inspects all inbound HTTP/HTTPS traffic before it reaches the load balancer. Runs as a single VM per site; add a second instance for HA at sites where internet-facing service uptime is critical.
- `LB-VM`: nginx load balancer VM deployed in the DMZ zone. Terminates TLS for published services and distributes traffic across backend instances in the Servers/VMs zone. Add a second instance for HA at internet-facing or high-traffic sites.

## Internet Circuit Model
- Standard site: one ISP circuit presented to both Edge-A and Edge-B. Edge nodes share the circuit via active-standby or ECMP.
- Designated redundant internet site: Edge-A connects to ISP-1 and Edge-B connects to ISP-2. Full edge and ISP redundancy for internet egress. Designate one site at implementation; Site A is recommended given its primary service role.

## Physical Redundancy Pattern
- Dual power paths for all critical nodes.
- Dual uplinks from each hypervisor to both ToR switches.
- Dual uplinks from each ToR to both firewall inside interfaces.
- Dual uplinks from each firewall outside interface to both edge routers.
- Out-of-band management network physically separated where feasible.

## Capacity Guidance
- Minimum per site: 2 hypervisors, 2 ToRs, 2 edge nodes.
- Recommended growth threshold: add Rack 2 when sustained compute utilization exceeds 65 percent.
- Keep spare capacity for one host failure without violating Tier 1 service SLOs.
