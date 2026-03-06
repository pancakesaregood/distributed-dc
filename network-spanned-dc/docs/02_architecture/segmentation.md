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
- `DMZ`: reverse proxies, WAF (Web Application Firewall), nginx load balancers, published internal services, and optionally the VPN VM if VPN is not hosted on the firewall appliance. All inbound internet-facing HTTP/HTTPS traffic passes through the WAF before reaching any backend service. The nginx load balancer distributes traffic across stateless application and API backend instances.
- `VPN`: authenticated remote access sessions. Clients enter this zone after VPN authentication and MFA. Zone policy then admits traffic to permitted inside zones based on AD group membership.
- `VDI`: virtual desktop VM pool. Desktop VMs provisioned for enterprise VDI users. Isolated from Management and Guest zones. Access to application services is permitted per AD group. Reachable only from guacd (Containers zone) on RDP/VNC ports; no direct user access to this zone.

## High-Level Policy Intent
- Default deny between zones unless explicitly required.
- Management access only from approved admin endpoints.
- Guest to internal networks denied. Guest traffic is permitted only to the local internet via the site's local L3 internet interface. Guest traffic is explicitly blocked from entering the IPsec inter-site WAN tunnels.
- IoT to management denied except telemetry collectors.
- DMZ to backend services only on approved application ports.
- VDI zone to Management denied. VDI zone to Guest denied. VDI desktop VMs access application services in the Servers/VMs and Containers zones only, on permitted ports, per AD group.
- All inbound HTTP/HTTPS from the Outside zone passes through the WAF in the DMZ before the nginx LB forwards to the Servers/VMs zone.
- WAF inspects and filters requests before they reach any application backend; blocked requests are dropped at the WAF and never forwarded.

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

## DMZ Service Components
- **WAF**: Deployed as a VM in the DMZ zone. Inspects all inbound HTTP/HTTPS traffic for OWASP Top 10 threats, injection attacks, and protocol anomalies. Default deny on unknown patterns. Logs all blocked and permitted requests. Configuration version-controlled in GitOps.
- **nginx Load Balancer**: Deployed as a VM (or HA pair) in the DMZ zone. Terminates TLS for published services and distributes requests across backend instances in the Servers/VMs zone. Provides health checking and removes unhealthy backends automatically. Also used for internal API load balancing where multiple container or VM instances exist.
- Inbound path for published services: `Outside → FW DMZ rule → WAF → nginx LB → backend (Servers/VMs zone)`.
- WAF and nginx LB VMs are Tier 1 stateless components; configuration is ephemeral and rebuilt from GitOps on replacement.

## Implementation Notes
- The firewall pair is vendor-agnostic. Select a platform that supports stateful inspection, zone-based policy, VPN (SSL-VPN or IPsec remote access or WireGuard), AD/LDAP authentication integration, and HA session sync.
- Keep firewall rule sets version-controlled and peer-reviewed through GitOps.
- Validate policy changes using staging simulation before production rollout.
