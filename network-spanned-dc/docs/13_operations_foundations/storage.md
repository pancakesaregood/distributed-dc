# Storage

## Purpose
Storage provides durable and recoverable data services for platform components and business workloads.

## Storage Design Principles
- Keep primary data local to the site for low-latency operation.
- Use replication according to service tier and write profile.
- Align storage policy with RTO/RPO targets and backup controls.

## Storage Classes
- Tier 1 stateful data: high-priority transactional systems.
- Platform state: identity stores, configuration databases, service metadata.
- Tier 2 data: non-critical datasets and rebuildable caches.

## Data Protection Model
- Local snapshots for fast operational restore.
- Cross-site replication for continuity.
- Backup copies aligned to 3-2-1 guidance.

## Operational Controls
- Capacity headroom targets by class.
- IOPS and latency alerting for critical volumes.
- Documented recovery workflow for corruption and ransomware scenarios.

## Replication Guidance
- Prefer service-aware replication where available.
- Validate failover behavior before production promotion.
- Track and alert on replication lag against thresholds.

## Storage Health Metrics
- Volume utilization and growth rate.
- Read/write latency and queue depth.
- Replication lag and sync status.
- Snapshot and backup completion status.
