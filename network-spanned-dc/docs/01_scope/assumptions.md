# Assumptions

## Site and Facility Assumptions
- Four active sites are available and identified as Site A through Site D.
- Each site can host at least one 42U rack, with a second rack available for growth.
- Redundant power feeds (A/B) and adequate cooling are available at each site.
- Cold aisle and hot aisle orientation can be maintained for front-to-back airflow equipment.
- Required front and rear service clearances are available for safe maintenance.

## Network and WAN Assumptions
- WAN service is presented as a vendor-managed Layer 3 handoff at each site.
- WAN path supports IKEv2 and IPsec transport requirements.
- WAN provider can share SLA metrics for latency, packet loss, and availability.
- Local internet breakout is available per site for controlled egress and published ingress.
- Public DNS or GeoDNS services are available for internet-facing records.

## Platform Assumptions
- Hypervisor hardware supports virtualization extensions and current Linux kernel baselines.
- VM-centric platform operation is acceptable, with Podman used for containerized services.
- Storage and database replication models can be selected per service tier.
- Source-of-truth systems (IPAM/DCIM and configuration repository) are available to operations teams.

## Security and Access Assumptions
- Active Directory-backed identity is available for operator and user authentication flows.
- MFA is enforceable for privileged access and remote access paths.
- Firewall platform can enforce zone-based policy with default deny posture.
- Logging and metrics telemetry can be collected centrally for alerting and forensics.

## Operational Assumptions
- A shared change-control process exists for network, platform, and security updates.
- Teams can operate Git-based workflows and follow runbook-driven incident response.
- Planned DR exercises are approved by service owners and operational leadership.
- Backup windows and restore test windows are available on a recurring schedule.
- Open decisions and constraints are tracked and reviewed before production rollout.
