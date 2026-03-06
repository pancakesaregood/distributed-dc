# Telephony

## Purpose
Define a resilient telephony pattern for IP phones, softphones, call routing, and PSTN connectivity across all sites.

## Reference diagram
See [Telephony Service Flow](../03_diagrams/telephony_flow.mmd.md).

## Scope
- Enterprise voice for users at all sites.
- Inbound and outbound PSTN calling through controlled SIP trunks.
- Emergency calling behavior and site-aware call routing.

## Core components
| Component | Role |
|---|---|
| IP phones and softphones | User endpoints for voice calls |
| Voice VLAN and access policy | Isolates voice endpoints from data clients |
| Call control cluster | Registration, routing, policy, and failover |
| Session border controller (SBC) | SIP demarcation, security, and trunk control |
| SIP trunk provider | External PSTN connectivity |
| Voicemail and call recording | Message and compliance retention where required |

## Network and security controls
- Dedicated voice VLAN per site with explicit ACL policy.
- QoS marking and trust model enforced at access and uplink layers.
- SIP signaling and RTP media flows limited to documented ports and peers.
- Management interfaces placed in admin segments, not user voice segments.
- Admin access protected by MFA and role-based access policy.

## Availability and failover model
- Per-site call handling for local survivability when WAN paths are impaired.
- Inter-site peer routing for overflow and failover when primary services fail.
- SIP trunk failover policy documented and tested with the carrier.
- Emergency dialing must keep working during inter-site WAN failure.

## Implementation checklist
1. Define dialing plan, extension ranges, and site-based routing rules.
2. Build call control nodes and SBC policy with backup paths.
3. Configure voice VLAN, QoS class mapping, and ACL enforcement.
4. Register pilot phones and validate call quality under load.
5. Test PSTN, inter-site failover, and emergency dialing scenarios.
6. Document runbooks, alerts, and ownership before production handoff.

## Validation evidence
- Baseline call quality metrics under normal and degraded conditions.
- Successful failover test records for call control and SIP trunks.
- Security review for signaling/media paths and admin access controls.
- Runbook sign-off by network, platform, and operations owners.
