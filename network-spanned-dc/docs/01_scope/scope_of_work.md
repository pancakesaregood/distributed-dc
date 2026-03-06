# Scope of Work

## Objective
Deliver a documentation-first architecture package for a low-cost, four-site spanned datacenter design that is technically defendable and implementation-ready.

## Scope Boundary
This project defines architecture, topology, policy intent, and operating procedures.
It does not perform production deployment, migration execution, or procurement.

## In Scope
- Four placeholder sites (Site A, Site B, Site C, Site D), each with 1 to 2 racks.
- IPv6 ULA addressing plan using `fdca:fcaf:e000::/48`, with per-site `/56` and standard segment `/64` allocations.
- Inter-site Layer 3 routing model over vendor-managed WAN handoff, with IPsec tunnel overlay and BGP route exchange.
- Per-site segmentation model including DMZ, user, servers/VMs, containers, VDI, guest, and management zones.
- Compute and service baseline using VM-based virtualization and Podman container runtime.
- Service publication model including WAF, load balancing, GeoDNS or anycast options, and health gating.
- Resilience design including failover scenarios, DR runbooks, RTO/RPO targets, and test cadence.
- Backup and retention strategy aligned to 3-2-1 principles with restore validation.
- Security baseline, identity model, logging/monitoring pattern, and GitOps operations model.
- Physical site guidance for one-rack and two-rack layouts, including RU placement, cable lanes, and airflow quality controls.
- Open decisions tracked in the appendix decision register.

## Not in Scope
- Final hardware bill of materials, quote requests, or vendor pricing.
- Carrier selection, circuit procurement, and contract negotiation.
- Site construction, facilities engineering, or physical security construction.
- Application migration execution, data cutover planning, or app refactoring.
- Production secret material generation or credential rotation implementation.
- Compliance audit execution, legal attestation, or certification submission.

See [Out of Scope](out_of_scope.md) for full exclusions.

## Workstreams

### Workstream 1: Foundation
- Confirm assumptions and constraints.
- Define architecture principles and service-tier model.
- Lock addressing, naming, and governance baselines.

### Workstream 2: Network and Security
- Define WAN abstraction, route policy, and tunnel model.
- Define segmentation, zone policy intent, and internet breakout.
- Define identity, access, and baseline security controls.

### Workstream 3: Platform and Services
- Define compute and container platform assumptions.
- Define published app and VDI service architectures.
- Define physical topology guidance and two-rack reference pattern.

### Workstream 4: Resilience and Operations
- Define failover scenarios, DR runbooks, and test plan.
- Define backup, retention, restore procedures, and observability.
- Define GitOps lifecycle and patch management expectations.

## Delivery Phases and Exit Gates

### Phase 0: Discovery and Baseline
- Exit gate: assumptions reviewed, unresolved decisions logged in appendix, and architecture boundaries accepted.

### Phase 1: Per-Site Blueprint
- Exit gate: site topology, segmentation intent, and physical rack model documented and peer reviewed.

### Phase 2: Multi-Site Behavior
- Exit gate: routing policy, service spanning model, and failover behavior documented with measurable targets.

### Phase 3: Recovery Readiness
- Exit gate: DR, backup, and restore procedures documented with evidence requirements and test cadence.

## Deliverables
- Architecture documentation set in `docs/`.
- Mermaid diagrams for logical topology, physical topology, segmentation, routing, service flows, and recovery scenarios.
- Scope, assumptions, exclusions, and acceptance criteria documentation.
- Failover and DR runbooks, test plan, and RTO/RPO targets.
- Backup, security, and operations documentation baseline.
- ADR and changelog records for traceability.

## Definition of Done
- All criteria in [Acceptance Criteria](acceptance_criteria.md) are satisfied.
- Open issues are captured in [Abstractions and Clarifications Needed](../09_appendix/abstractions_clarifications_needed.md).
- Core operational references are linked from [Documentation Home](../index.md).
