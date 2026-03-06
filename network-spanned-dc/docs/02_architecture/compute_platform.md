# Compute Platform

## Design Goals
- Support mixed workloads (VM-first with containerized services where appropriate).
- Keep platform operations predictable and low-overhead.
- Preserve site-level fault isolation and clear recovery behavior.
- Avoid lock-in to proprietary control planes where equivalent open options exist.

## Recommended Baseline
- Hypervisor stack: KVM-based platform with cluster-aware management.
- Container runtime: Podman with systemd or Quadlet for service lifecycle control.
- Image pipeline: versioned templates, signed artifacts, and reproducible build inputs.
- Configuration model: Git-backed host profiles and environment-specific overlays.

## Per-Site Capacity Baseline
- Minimum two hypervisor nodes per site for baseline resilience.
- Add third and fourth hosts when sustained compute utilization exceeds operational threshold.
- Keep management and platform control services pinned to resilient placement groups.
- Keep local backup proxy or repository capability at each site for fast restore.

## Placement and Resilience Policy
- Tier 1 stateless services: spread across at least two sites.
- Tier 1 stateful services: active-standby or quorum model per service latency profile.
- Tier 2 services: local-first with tested backup and restore paths.
- Enforce anti-affinity for replicas so no critical pair lands on one host.
- During planned maintenance, keep one-host-failure tolerance for Tier 1 services.

## Rack and Connectivity Considerations
- Dual-home every hypervisor to ToR-A and ToR-B.
- Separate uplink paths by A/B cable lanes and switches.
- Maintain front-to-back airflow and avoid mixed side-flow hosts in shared racks.
- Two-rack physical placement guidance is defined in [Physical Rack Topology (Two-Rack Site)](../03_diagrams/physical_rack_topology_2rack.mmd.md).

## Operational Controls
- Immutable base templates for host and VM provisioning.
- Staged patch rollout by site and workload tier.
- Pre-change health checks and post-change validation runbooks.
- Capacity and thermal telemetry integrated into standard observability dashboards.
- Recovery drills include host loss, datastore loss, and cross-site service restore.

## Decision Dependencies
Final implementation choices for management stack and replication models are tracked in [Abstractions and Clarifications Needed](../09_appendix/abstractions_clarifications_needed.md).
