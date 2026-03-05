# RTO and RPO Targets

## Target Table

| Service Tier | Example Workloads | Target RTO | Target RPO |
|---|---|---|---|
| Tier 1 Stateless | Internal APIs, ingress, service directory | 15 minutes | 0 to 5 minutes |
| Tier 1 Stateful | Databases, queue brokers, identity stores | 60 to 120 minutes | 15 minutes |
| Tier 2 Platform | Build workers, artifact cache, analytics jobs | 8 hours | 24 hours |
| Local-Only Services | Site-specific systems | Business-defined | Business-defined |

## Target Governance
- Targets are design commitments for architecture validation.
- Service owners can request stricter targets with additional cost and complexity justification.
- DR test results must be reviewed quarterly against these targets.
