# Server Team FAQ

## What is the server platform baseline?
- KVM-based virtualization with Podman for containerized services where appropriate.

## How many hosts are required per site?
- Minimum two hypervisor nodes per site, expanding to additional hosts by capacity and resilience targets.

## How should hosts connect to the network?
- Dual-homed to ToR-A and ToR-B with A/B cable path separation.

## How are workloads placed?
- Tier 1 services are spread across hosts and sites; anti-affinity prevents critical replicas on the same host.

## What are the patching expectations?
- Staged maintenance by site and tier, with pre-checks, rollback plans, and post-change validation.
