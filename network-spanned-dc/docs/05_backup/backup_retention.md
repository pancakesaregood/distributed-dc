# Backup Retention

## Retention Policy by Data Class

| Data Class | Short-Term Retention | Medium-Term Retention | Long-Term Retention |
|---|---|---|---|
| Configs and repositories | 30 days | 90 days | 1 year |
| Tier 1 databases | 14 days point-in-time logs | 90 days daily snapshots | 1 year monthly snapshots |
| VM images | 14 daily restore points | 12 weekly restore points | 12 monthly restore points |
| Container registry | 14 days | 90 days | 6 months |

## Immutability Guidance
- Keep at least one retention tier immutable for critical data classes.
- Prevent deletion by production administrators during active incidents.
- Apply legal hold workflow where policy requires extended preservation.

## Retention Governance
- Review retention quarterly with service owners.
- Adjust retention only through approved change control.
- Confirm storage capacity and forecast quarterly.
