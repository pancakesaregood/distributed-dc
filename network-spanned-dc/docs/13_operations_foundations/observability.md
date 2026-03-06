# Observability

## Purpose
Observability explains why a system is failing or degrading by correlating metrics, logs, traces, and events across sites.

## Core Pillars
- Metrics: time-series health and performance indicators.
- Logs: structured event records for workflows and failures.
- Traces: request and call-path timing across service boundaries.
- Events: change actions and topology state transitions.

## Telemetry Architecture
- Per-site collectors gather metrics and logs from local components.
- Central aggregation layer stores and correlates multi-site telemetry.
- Dashboards present service, dependency, and business-impact views.

## Standard Dashboards
- Site health: edge, firewall, ToR, host, storage status.
- Service health: API latency, error budget burn, response times.
- Routing health: BGP adjacency, tunnel state, failover events.
- Data safety: replication lag, backup outcomes, restore evidence.
- Security posture: auth failures, denied flows, privilege anomalies.

## Instrumentation Requirements
- All Tier 1 services expose standard availability and latency metrics.
- Critical workflows include request identifiers for log correlation.
- Change events are stamped with actor, time, and scope.

## SLO and Error Budget Alignment
- Observability dashboards must expose SLI/SLO trends by service tier.
- Error budget burn alerts trigger operational review before SLO breach.

## Review Cadence
- Weekly service-level telemetry review.
- Monthly reliability review with SLO trend and incident root causes.
- Quarterly instrumentation gap analysis.
