# Backup Strategy

## 3-2-1 Alignment Across Four Sites
- 3 copies of critical data: production + local backup + cross-site backup.
- 2 media or storage types where practical: primary storage and backup repository/object storage.
- 1 off-domain or immutable copy: optional archive tier with immutability controls.

## Backup Topology
- Local fast-restore target at each site for short RTO recoveries.
- Cross-site replication to at least one alternate site. All cross-site replication traffic transits the IPsec-encrypted inter-site tunnels between edge pairs; no additional transport-layer encryption is required, though application-layer encryption of backup streams is permitted for defense-in-depth.
- Optional immutable archive tier for ransomware-resilient retention.

## Credential Separation
- Backup system credentials are separate from production admin credentials.
- Backup service accounts are least-privileged and non-interactive.
- MFA is required for backup control-plane administration.

## Backup Frequency Tiers

| Tier | Data Class | Frequency | Method |
|---|---|---|---|
| Tier 1 | Configs and repositories | Every 15 minutes sync + daily full snapshot | Git mirror plus snapshot backup |
| Tier 1 | Databases | Continuous log shipping + hourly snapshots | Native DB replication and backup tooling |
| Tier 2 | VM images | Daily incremental + weekly synthetic full | Hypervisor-aware image backups |
| Tier 2 | Container registry | Every 4 hours metadata sync + daily blob backup | Registry replication and object snapshot |

## Restore Test Schedule
- Monthly sample restore.
- Quarterly site-failover tabletop.
- Semiannual partial DR execution.

## Design Guardrails
- No backup credentials stored on application hosts in plaintext.
- Backups are encrypted at rest and in transit. In-transit encryption for cross-site flows is provided by the IPsec inter-site tunnel layer.
- Replication lag and backup failures generate actionable alerts.
