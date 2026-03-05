# Observability

## Objectives
- Detect faults quickly at host, network, and service layers.
- Provide evidence for failover and DR effectiveness.
- Support capacity and reliability planning.

## Signals
- Metrics: resource, latency, error rate, and saturation indicators.
- Logs: structured events for auth, routing, and backup pipelines.
- Traces: service-path latency for Tier 1 distributed applications.

## Standard Dashboards
- Site health and WAN status.
- Routing convergence and prefix visibility.
- VM and Podman workload health.
- Backup success and replication lag.
- Security events and privileged access anomalies.

## Alert Reliability
- Alerts must map to a named runbook.
- Suppress duplicate symptoms during known maintenance windows.
- Track false-positive rate and tune quarterly.
