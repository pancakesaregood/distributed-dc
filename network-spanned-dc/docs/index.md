# Spanned Datacenter Documentation Home

<div class="hero-panel">
  <p class="hero-kicker">Four-Site Architecture Blueprint</p>
  <p class="hero-lead">Build for failure. Operate with clarity. Recover with evidence.</p>
  <p class="hero-copy">
    This documentation set is built to move from architecture intent to implementable operations.
    Use it as a working playbook for design review, implementation planning, and day-2 ownership.
  </p>
  <div class="hero-actions">
    <a class="hero-chip" href="01_scope/scope_of_work/">Start with Scope</a>
    <a class="hero-chip" href="03_diagrams/diagram_index/">Open Diagram Set</a>
    <a class="hero-chip" href="10_implementation/readme/">View Implementation Plan</a>
  </div>
</div>

## Fast Paths

<div class="home-grid">
  <a class="home-card" href="01_scope/scope_of_work/">
    <h3>Scope and Gates</h3>
    <p>Objectives, boundaries, assumptions, and acceptance criteria.</p>
  </a>
  <a class="home-card" href="02_architecture/overview/">
    <h3>Architecture Core</h3>
    <p>Executive overview, topology model, and design constraints.</p>
  </a>
  <a class="home-card" href="03_diagrams/diagram_index/">
    <h3>Visual Design Pack</h3>
    <p>Logical, physical, routing, service, and recovery diagrams.</p>
  </a>
  <a class="home-card" href="04_failover_dr/failover_scenarios/">
    <h3>Failover and DR</h3>
    <p>Scenario matrix, RTO/RPO targets, runbooks, and test plans.</p>
  </a>
  <a class="home-card" href="06_security/security_baseline/">
    <h3>Security Baseline</h3>
    <p>Segmentation, identity controls, telemetry, and response guardrails.</p>
  </a>
  <a class="home-card" href="07_operations/gitops_operating_model/">
    <h3>Operations Model</h3>
    <p>GitOps workflow, lifecycle management, and observability alignment.</p>
  </a>
  <a class="home-card" href="10_implementation/readme/">
    <h3>Implementation Proposal</h3>
    <p>Phased rollout plan, ownership model, risks, and success criteria.</p>
  </a>
  <a class="home-card" href="11_FAQ/readme/">
    <h3>Role-Based FAQs</h3>
    <p>Team, executive, operations, security, and support focused FAQs.</p>
  </a>
  <a class="home-card" href="12_business_cases/readme/">
    <h3>Business Cases</h3>
    <p>Decision-ready cases for resilience, security, automation, and DR.</p>
  </a>
</div>

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
- [Business Cases Home](12_business_cases/readme.md)
- [Operations Foundations](13_operations_foundations/readme.md)

## Reading Path for Design Reviews
1. Review scope, assumptions, and acceptance criteria.
2. Review architecture overview, physical layout, and addressing strategy.
3. Review routing, segmentation, service spanning, and WAN abstraction.
4. Review diagrams for logical and physical implementation views.
5. Review failover, backup, security, and operations controls.
6. Close or explicitly accept remaining open decisions.
