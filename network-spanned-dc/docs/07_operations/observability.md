# Observability

## Objectives
- Detect faults quickly at host, network, and service layers.
- Provide evidence for failover and DR effectiveness.
- Support capacity and reliability planning.

Signal types (metrics, logs, traces), tooling, and alert scope are defined in [Logging and Monitoring](../06_security/logging_monitoring.md).

## Standard Dashboards
- Site health and WAN status.
- Routing convergence and prefix visibility.
- VM and Podman workload health.
- Backup success and replication lag.
- Security events and privileged access anomalies.

## Alert Quality
- Every alert must map to a named runbook. An alert without a runbook is not production-ready.
- Suppress duplicate symptoms during known maintenance windows.
- Track false-positive rate and tune quarterly.
