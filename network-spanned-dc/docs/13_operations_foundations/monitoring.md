# Monitoring

## Purpose
Monitoring provides near-real-time health detection for infrastructure, network, security controls, and service tiers.

## Monitoring Scope
- Site infrastructure: edge, firewall, ToR, hypervisors, storage nodes.
- Platform services: DNS, AD, VPN, load balancers, backup services.
- Workload services: Tier 1 stateless, Tier 1 stateful, Tier 2 services.
- WAN and routing: tunnel status, BGP session state, route reachability.

## Monitoring Model
- Black-box checks: endpoint reachability and user-path health.
- White-box checks: component metrics from hosts and services.
- Dependency checks: identity, storage, routing, and backup dependency status.

## Required Signal Categories
- Availability: up/down, quorum, role state, HA state.
- Performance: latency, packet loss, CPU, memory, IOPS, queue depth.
- Reliability: error rate, restart rate, failed job count.
- Replication and data safety: lag, backup success, restore validation status.

## Alert Severity Framework
- Sev 1: site loss, critical service outage, authentication control outage.
- Sev 2: degraded Tier 1 service, replication at risk, sustained packet loss.
- Sev 3: component warning and threshold drift without active user impact.

## Alert Quality Rules
- Every production alert maps to a runbook.
- Every Sev 1 and Sev 2 alert has an owner and escalation chain.
- Maintenance windows suppress non-actionable alert storms.

## Operational Cadence
- Daily: review overnight failures and unresolved alerts.
- Weekly: tune thresholds and remove duplicate/noisy alerts.
- Monthly: validate monitor coverage against architecture changes.
