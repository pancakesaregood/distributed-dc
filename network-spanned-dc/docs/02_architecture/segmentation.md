# Segmentation Model

## Security Zones
All zone enforcement is performed by the site firewall pair (FW-A / FW-B). The firewall is the single policy enforcement point for all traffic crossing inside and outside boundaries.

- `Outside`: the edge router side. Untrusted. Carries WAN IPsec tunnel traffic and internet traffic.
- `Management`: infrastructure admin and control planes.
- `Servers/VMs`: application VMs and middleware.
- `Containers`: Podman service execution networks.
- `User`: trusted internal user endpoints.
- `IoT`: constrained devices with narrow egress rules.
- `Guest`: isolated internet-only access.
- `DMZ`: reverse proxies, published internal services, and optionally the VPN VM if VPN is not hosted on the firewall appliance.
- `VPN`: authenticated remote access sessions. Clients enter this zone after VPN authentication and MFA. Zone policy then admits traffic to permitted inside zones based on AD group membership.

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

## VPN Zone Policy
- VPN clients authenticate against the site AD domain controller with MFA enforced at the VPN gateway.
- On successful auth, clients are placed in the VPN zone and permitted only to segments allowed by their AD group membership.
- Default VPN group: access to User and Servers/VMs zones on approved ports.
- Admin VPN group: access to Management zone in addition to default permissions.
- No split-tunnel exemptions are permitted without an explicit policy change reviewed in GitOps.

## Implementation Notes
- The firewall pair is vendor-agnostic. Select a platform that supports stateful inspection, zone-based policy, VPN (SSL-VPN or IPsec remote access or WireGuard), AD/LDAP authentication integration, and HA session sync.
- Keep firewall rule sets version-controlled and peer-reviewed through GitOps.
- Validate policy changes using staging simulation before production rollout.
