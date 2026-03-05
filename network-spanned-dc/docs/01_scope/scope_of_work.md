# Scope of Work

## Objective
Design and document a low-cost, four-site spanned datacenter architecture with defendable technical decisions, clear failure behavior, and practical operating procedures.

## In Scope
- Four placeholder sites (Site A, Site B, Site C, Site D), each with 1 to 2 racks.
- IPv6 ULA addressing plan using `fdca:fcaf:e000::/48`.
- L3 inter-site design over vendor-managed WAN L3 handoff.
- VM-based compute platform and Podman container model.
- SDN options with open-source preference.
- Segmentation, failover scenarios, and DR strategy.
- Backup strategy aligned to 3-2-1 principles.
- Security baseline, operations model, and naming standards.

## Not in Scope
- Detailed hardware bill of materials.
- Vendor circuit engineering details.
- Application-specific migration plans.
- Production credential creation.
- Compliance certification activities.

See [Out of Scope](out_of_scope.md) for explicit exclusions.

## Delivery Phases
### Phase 0: Discovery
- Validate assumptions, site constraints, and WAN capabilities.
- Confirm virtualization and storage replication options.
- Capture unresolved decisions in the clarifications appendix.

### Phase 1: Site Build
- Build per-site edge, ToR, and compute baseline.
- Implement IPv6 segmentation and local routing controls.
- Establish management, logging, and identity foundations.

### Phase 2: Service Spanning
- Enable inter-site routing advertisements and policy controls.
- Deploy replicated services according to spanning model.
- Validate backup replication and cross-site restores.

### Phase 3: DR Test
- Execute defined failover and recovery scenarios.
- Measure achieved RTO/RPO against targets.
- Produce lessons learned and remediation actions.

## Deliverables
- Architecture documents in `docs/`.
- Mermaid diagrams for topology, routing, segmentation, services, backup, and failover.
- Failover and DR runbooks and test plan.
- Backup and retention strategy.
- ADR and changelog for traceability.

## Acceptance Criteria Pointers
- [Acceptance Criteria](acceptance_criteria.md)
- [Failover Scenarios](../04_failover_dr/failover_scenarios.md)
- [Test Plan](../04_failover_dr/test_plan.md)
- [Backup Strategy](../05_backup/backup_strategy.md)
