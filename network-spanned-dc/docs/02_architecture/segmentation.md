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
- Guest to internal networks denied.
- IoT to management denied except telemetry collectors.
- DMZ to backend services only on approved application ports.

## East-West and North-South Controls
- East-west policies are enforced per site to preserve local blast-radius boundaries.
- Cross-site flows are routed and filtered at edge policy points.
- North-south egress controls include DNS, NTP, package repositories, and explicit internet-bound service paths.

## Implementation Notes
- Use open-source firewalls and policy engines where practical.
- Keep policy sets version-controlled and peer-reviewed through GitOps.
- Validate policy changes using staging simulation before production rollout.
