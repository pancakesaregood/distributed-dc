# WLC and WAPs

## Purpose
Define the wireless control and access point design for corporate, guest, and device SSIDs across all sites.

## Reference diagram
See [WLC and WAP Topology](../03_diagrams/wlc_waps_topology.mmd.md).

## Scope
- Wireless LAN controller (WLC) architecture and AP join model.
- SSID-to-segment mapping for corporate, guest, and IoT use cases.
- Identity-based access for corporate wireless clients.

## Core components
| Component | Role |
|---|---|
| Wireless LAN controllers | AP control plane, policy, roaming state |
| Wireless access points | Radio edge for client connectivity |
| RADIUS/AAA services | 802.1X and policy decisions |
| DHCP/DNS services | Client addressing and name resolution |
| Firewall and guest egress controls | Segmentation and internet breakout policy |

## Network and security controls
- AP management traffic isolated from client data segments.
- Corporate SSID uses 802.1X with centralized identity policy.
- Guest SSID isolated from internal zones with local internet breakout.
- Device onboarding policy documented for non-802.1X endpoints.
- Rogue AP detection and periodic RF policy review required.

## Availability and failover model
- Controller redundancy model documented per site pair.
- AP fallback controller list configured and tested.
- Client roaming behavior validated during controller failover.
- Guest and corporate SSID continuity tested under link degradation.

## Implementation checklist
1. Define SSID catalog, authentication method, and segment mapping.
2. Build WLC baseline with controller redundancy and AP groups.
3. Configure AP management network, DHCP options, and join policy.
4. Integrate RADIUS/AAA and validate role-based access outcomes.
5. Validate roaming, throughput, and controller failover behavior.
6. Enable alerting for AP down events, auth failures, and RF health.
7. Complete runbooks for wireless operations and incident response.

## Validation evidence
- Authentication success and policy enforcement test results.
- Controller failover and AP rejoin evidence.
- Security validation for guest isolation and admin access controls.
- Coverage and performance survey summary by site.
