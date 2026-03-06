# Spanned Datacenter Documentation Home

This documentation defines a defendable architecture for a low-cost, four-site spanned datacenter using open-source components where practical.

See [Architecture Overview](02_architecture/overview.md) for the executive summary, design principles, and constraints.

## Start Here
- [Scope of Work](01_scope/scope_of_work.md)
- [Assumptions](01_scope/assumptions.md)
- [Acceptance Criteria](01_scope/acceptance_criteria.md)
- [Architecture Overview](02_architecture/overview.md)
- [IPv6 Addressing](02_architecture/ipv6_addressing.md)
- [Routing and WAN Abstraction](02_architecture/routing_wan_abstraction.md)
- [Physical Layout](02_architecture/physical_layout.md)
- [Diagram Index](03_diagrams/diagram_index.md)
- [Physical Rack Topology (Two-Rack Site)](03_diagrams/physical_rack_topology_2rack.mmd.md)
- [One-Site Full Stack (Upstream Abstracted)](03_diagrams/site_full_stack_upstream_abstracted.mmd.md)
- [Failover Scenarios](04_failover_dr/failover_scenarios.md)
- [Backup Strategy](05_backup/backup_strategy.md)
- [Security Baseline](06_security/security_baseline.md)
- [GitOps Operating Model](07_operations/gitops_operating_model.md)
- [WAN Service Requirements](08_vendor_wan/wan_service_requirements.md)
- [Abstractions and Clarifications Needed](09_appendix/abstractions_clarifications_needed.md)
- [Implementation Proposal](10_implementation/readme.md)
- [FAQ Home](11_FAQ/readme.md)

## Reading Path for Design Reviews
1. Review scope and acceptance criteria.
2. Review architecture overview, physical layout, and addressing strategy.
3. Review routing, segmentation, and service spanning model.
4. Review diagram set (logical, physical, and service flow views).
5. Review failover, backup, security, and operations controls.
6. Confirm unresolved clarifications before implementation.
