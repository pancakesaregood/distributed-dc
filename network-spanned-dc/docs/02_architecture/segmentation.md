# Segmentation Model

## Security Zones
- `Management`: infrastructure admin and control planes.
- `Servers/VMs`: application VMs and middleware.
- `Containers`: Podman service execution networks.
- `User`: trusted internal user endpoints.
- `IoT`: constrained devices with narrow egress rules.
- `Guest`: isolated internet-only access.
- `DMZ`: reverse proxies and published internal services.

## High-Level Policy Intent
- Default deny between zones unless explicitly required.
- Management access only from approved admin endpoints.
- Guest to internal networks denied. Guest traffic is permitted only to the local internet via the site's local L3 internet interface. Guest traffic is explicitly blocked from entering the IPsec inter-site WAN tunnels.
- IoT to management denied except telemetry collectors.
- DMZ to backend services only on approved application ports.

## East-West and North-South Controls
- East-west policies are enforced per site to preserve local blast-radius boundaries.
- Cross-site flows are routed and filtered at edge policy points and transit only the IPsec-encrypted inter-site WAN tunnels.
- North-south internet egress is local at each site. Each site edge pair provides a local L3 internet interface. Traffic destined for the internet exits at the local site without traversing the WAN.
- Guest north-south: Guest traffic routes only to the local internet L3 interface. No WAN backhaul for guest egress. Guest internet is suspended at a site if the local ISP circuit is down.
- Controlled north-south paths for infrastructure include DNS, NTP, package repositories, and approved internet-bound service paths, all through the local edge internet interface.

## Implementation Notes
- Use open-source firewalls and policy engines where practical.
- Keep policy sets version-controlled and peer-reviewed through GitOps.
- Validate policy changes using staging simulation before production rollout.
