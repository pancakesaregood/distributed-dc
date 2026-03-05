# DR Runbooks

## Runbook Framework
Each runbook follows a consistent structure:
1. Preconditions and declaration criteria.
2. Roles and communication channels.
3. Step-by-step execution.
4. Validation checkpoints.
5. Exit criteria and post-incident review actions.

## Runbook Set
- Compute host failure recovery.
- Network path and ToR recovery.
- Edge routing failover and BGP recovery.
- Site outage service promotion.
- Data corruption containment and clean restore.

## Standard Manual Validation Checks
- Confirm control-plane health (routing, DNS, identity).
- Confirm data-plane reachability from user and service networks.
- Confirm backup integrity and replication status.
- Confirm alert noise returns to baseline.

## Documentation Discipline
- Keep runbooks in Git with change history.
- Require peer review for any runbook change.
- Record timestamps during execution to prove measured RTO/RPO.
