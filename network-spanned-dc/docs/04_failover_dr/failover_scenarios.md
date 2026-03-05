# Failover Scenarios

## What Spans and How

| Service Type | Pattern | Notes |
|---|---|---|
| Stateless frontends and internal APIs | Active-active across multiple sites | Prefer DNS or anycast ingress |
| Stateful Tier 1 data services | Active-standby or quorum model | Replication strategy must meet RPO |
| Platform control services | Active-standby across at least two sites | Keep deterministic promotion runbook |
| Site facility services | Local-only | No cross-site failover commitment |

## A) Single Compute Node Failure in One Site
- Trigger: Hypervisor hardware fault, kernel panic, or host isolation.
- Detection: Hypervisor cluster health alerts and workload heartbeat loss.
- Automated response: HA policy restarts affected VMs or containers on remaining nodes in the same site.
- Manual steps: Replace or repair failed node, reintroduce capacity, and validate anti-affinity compliance.
- Expected user impact: Short interruption for workloads pinned to the failed host.
- RTO: 5 to 15 minutes.
- RPO: 0 minutes for replicated stateless services; up to 5 minutes for async stateful replicas.

## B) ToR Switch Failure in One Site
- Trigger: ToR hardware fault or control-plane failure.
- Detection: Link-state alarms and switch telemetry loss.
- Automated response: Traffic reroutes over surviving ToR through bonded host uplinks.
- Manual steps: Replace failed switch, restore config from GitOps source, verify dual-path operation.
- Expected user impact: Brief packet loss during convergence.
- RTO: 10 to 20 minutes.
- RPO: 0 minutes.

## C) Edge Firewall or Router Failure in One Site
- Trigger: Edge node crash, software failure, or planned maintenance fault.
- Detection: HA heartbeat fail and BGP adjacency drop.
- Automated response: Local edge pair failover promotes standby peer; BGP sessions re-establish.
- Manual steps: Repair failed peer, validate route policy and session health.
- Expected user impact: Short inter-site and north-south disruption.
- RTO: 5 to 15 minutes.
- RPO: 0 minutes for resilient services, up to 5 minutes for buffered data pipelines.

## D) WAN Circuit Failure to One Site
- Trigger: Vendor handoff loss or transport outage.
- Detection: BGP down events and WAN SLA alarms.
- Automated response: Traffic shifts to remaining available WAN path if dual-homed; otherwise site isolates.
- Manual steps: Activate static fallback only if BGP control path is unavailable and fallback path exists; coordinate with vendor incident channel.
- Expected user impact: Degraded latency or temporary loss of inter-site services from affected site.
- RTO: 15 to 30 minutes.
- RPO: 5 to 15 minutes for asynchronously replicated services.

## E) Full Site Outage
- Trigger: Power event, facility network failure, or complete site isolation.
- Detection: Site heartbeat and route withdrawal from WAN.
- Automated response: Surviving sites continue serving active-active workloads; failover workflows initiate for active-standby services.
- Manual steps: Promote standby data services, redirect traffic policy, and execute service owner validation.
- Expected user impact: Reduced capacity and potential performance degradation until failed site returns.
- RTO: Tier 1 within 60 to 120 minutes; Tier 2 within 8 hours.
- RPO: Tier 1 up to 15 minutes; Tier 2 up to 24 hours.

## F) Data Corruption or Ransomware-Like Event
- Trigger: Integrity alarms, unusual encryption behavior, or malicious privilege abuse.
- Detection: File integrity monitoring, backup anomaly detection, and security incident alerts.
- Automated response: Quarantine affected systems, suspend replication from suspect datasets, preserve forensic snapshots.
- Manual steps: Declare incident, validate clean restore point, restore to isolated environment, perform integrity checks, then return service.
- Expected user impact: Service read/write restrictions during containment and restore windows.
- RTO: Tier 1 within 4 hours; Tier 2 within 24 hours.
- RPO: Last known clean point, typically 1 hour for Tier 1 data and 24 hours for Tier 2 datasets.
