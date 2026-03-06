# Segmentation Model

## Security Zones
All zone enforcement is performed by the site firewall pair (FW-A / FW-B). The firewall is the single policy enforcement point for all traffic crossing inside and outside boundaries.

- `Outside`: the edge router side. Untrusted. Carries WAN IPsec tunnel traffic and internet traffic.
- `Management`: infrastructure admin and control planes.
- `Servers/VMs`: application VMs and middleware.
- `Containers`: Podman service execution networks.
- `User`: trusted internal user endpoints.
- `IoT`: constrained devices with narrow egress rules.
- `Guest`: isolated internet-only access. Guest devices receive addresses from the Guest segment (`:0050`) and a DNS64 resolver address via DHCP. Outbound internet access is provided via NAT64 (IPv4-only destinations) and NPTv6 (IPv6-native destinations). IPv4 PAT is applied at the edge internet interface. Guest devices cannot reach any internal zone; all internal destinations are denied.
- `DMZ`: reverse proxies, WAF (Web Application Firewall), nginx load balancers, published internal services, and optionally the VPN VM if VPN is not hosted on the firewall appliance. All inbound internet-facing HTTP/HTTPS traffic passes through the WAF before reaching any backend service. The nginx load balancer distributes traffic across stateless application and API backend instances.
- `VPN`: authenticated remote access sessions. Clients enter this zone after VPN authentication and MFA. Zone policy then admits traffic to permitted inside zones based on AD group membership.
- `VDI`: virtual desktop VM pool. Desktop VMs provisioned for enterprise VDI users. Isolated from Management and Guest zones. Access to application services is permitted per AD group. Reachable only from guacd (Containers zone) on RDP/VNC ports; no direct user access to this zone.

## High-Level Policy Intent
- Default deny between zones unless explicitly required.
- Management access only from approved admin endpoints.
- Guest to internal networks denied. Guest traffic exits only through NAT64 → IPv4 PAT at the local site internet L3 interface. Guest traffic is explicitly blocked from entering the IPsec inter-site WAN tunnels. DNS64 is served to guest clients to enable NAT64 operation for IPv4-only internet destinations.
- IoT to management denied except telemetry collectors.
- DMZ to backend services only on approved application ports.
- VDI zone to Management denied. VDI zone to Guest denied. VDI desktop VMs access application services in the Servers/VMs and Containers zones only, on permitted ports, per AD group.
- All inbound HTTP/HTTPS from the Outside zone passes through the WAF in the DMZ before the nginx LB forwards to the Servers/VMs zone.
- WAF inspects and filters requests before they reach any application backend; blocked requests are dropped at the WAF and never forwarded.

## East-West and North-South Controls
- East-west policies are enforced per site to preserve local blast-radius boundaries.
- Cross-site flows are routed and filtered at edge policy points and transit only the IPsec-encrypted inter-site WAN tunnels.
- North-south internet egress is local at each site. Each site edge pair provides a local L3 internet interface. Traffic destined for the internet exits at the local site without traversing the WAN.
- Guest north-south: Guest traffic routes only to the local internet L3 interface via NAT64 and IPv4 PAT. No WAN backhaul for guest egress. DNS64 is served to guest clients for IPv4-only destination reachability. Guest internet is suspended at a site if the local ISP circuit is down.
- Controlled north-south paths for infrastructure include DNS, NTP, package repositories, and approved internet-bound service paths, all through the local edge internet interface.

## VPN Zone Policy
- Clients enter the VPN zone after AD authentication and MFA. They are not admitted directly to any inside zone.
- Default group: access to User and Servers/VMs zones on approved ports.
- Admin group: access to Management zone in addition to default permissions.
- No split-tunnel exemptions without a GitOps-reviewed policy change.
- Authentication requirements, session logging, and certificate rotation are defined in [Security Baseline — VPN](../06_security/security_baseline.md).

## DMZ Service Components
- **WAF**: inspects inbound HTTP/HTTPS at the DMZ boundary before traffic reaches the load balancer or any backend.
- **nginx Load Balancer**: terminates TLS and distributes requests across backend instances in the Servers/VMs zone. Removes unhealthy backends automatically.
- Inbound path: `Outside → FW DMZ rule → WAF → nginx LB → backend (Servers/VMs zone)`.
- Both are Tier 1 stateless. Security controls, OWASP baseline, and operational requirements are in [Security Baseline — WAF and Load Balancer](../06_security/security_baseline.md).

## Implementation Notes
- The firewall pair is vendor-agnostic. Select a platform that supports stateful inspection, zone-based policy, VPN (SSL-VPN or IPsec remote access or WireGuard), AD/LDAP authentication integration, and HA session sync.
- Keep firewall rule sets version-controlled and peer-reviewed through GitOps.
- Validate policy changes using staging simulation before production rollout.
