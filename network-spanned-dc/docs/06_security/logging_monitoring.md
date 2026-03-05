# Logging and Monitoring

## Logging Scope
- Infrastructure logs: hypervisors, switches, edge routers, firewalls.
- Platform logs: VM orchestration, Podman runtime, automation jobs.
- Security logs: authentication, policy denials, backup admin actions.

## Monitoring Scope
- Availability: host, service, WAN handoff, and route health.
- Performance: latency, loss, CPU, memory, storage IOPS.
- Replication: backup success rates and replication lag.

## Open-Source Tooling Pattern
- Metrics: Prometheus-compatible collectors.
- Visualization: Grafana dashboards.
- Logs: Loki, OpenSearch, or equivalent open-source stack.
- Alerting: Alertmanager-compatible routing and escalation.

## Alert Design
- Route and site health alerts are high priority.
- Backup failure alerts require same-day triage.
- Correlate failover events to user-impact dashboards for incident command clarity.
