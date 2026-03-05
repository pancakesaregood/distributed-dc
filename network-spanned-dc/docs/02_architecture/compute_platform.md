# Compute Platform

## Design Goals
- Support VM workloads for broad compatibility.
- Support containerized services via Podman.
- Minimize recurring licensing costs.
- Keep failure domains aligned to site boundaries.

## Recommended Baseline
- Hypervisor: KVM-based platform (for example, Proxmox VE community model or equivalent open-source KVM stack).
- Container runtime: Podman with systemd-managed units or Quadlet definitions.
- Image and package pipeline: Git-backed build definitions with signed artifacts.

## Per-Site Topology
- Minimum two hypervisor nodes per site.
- Shared management VMs for orchestration, monitoring, and backup agents.
- Storage presented locally with cross-site replication for critical datasets.

## Scheduling and Placement
- Place Tier 1 services across at least two sites.
- Keep Tier 2 services local-first with backup and restore capability.
- Anti-affinity policies prevent all replicas from sharing one host.

## Operational Controls
- Use immutable templates for VM and container host provisioning.
- Keep host configuration in version control.
- Enforce maintenance windows and staged patch rollout by site.
