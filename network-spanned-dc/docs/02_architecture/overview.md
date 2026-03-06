# Architecture Overview

## Executive Summary
This design proposes a low-cost, four-site distributed datacenter built to improve resilience and operational flexibility. Each site operates as an independent failure domain with its own compute capacity, security boundary, and internet access, ensuring that the loss of any single location does not interrupt critical services.

The sites are interconnected through a vendor-managed Layer 3 network, allowing workloads and traffic to shift between locations without relying on fragile Layer 2 extensions. Service continuity is maintained through routing and data replication, rather than stretched networks, which simplifies operations and reduces the risk of cascading failures.

This architecture prioritizes predictable failure behavior, gradual scaling, and practical operations, allowing capacity to grow incrementally while maintaining service availability across all locations.

## Core Design Principles
- Layer 3 between sites.
- No stretched Layer 2 between sites.
- Inter-site traffic encrypted in transit with an IPsec overlay.
- Per-site failure domains with local control and local internet breakout.
- Service spanning via replication and policy-based routing, not shared broadcast domains.
- Open-source-first tooling where operationally supportable.
- Git-backed, reviewable, automation-driven change control.

## Constraints
- Budget-sensitive architecture with low recurring licensing overhead.
- WAN transport abstracted as vendor-managed Layer 3 connectivity.
- Site footprint constrained to 1 to 2 racks per location.
- Mixed workload support required: VMs plus Podman-managed containers.
- Operations model must remain supportable by a small infrastructure team.

## High-Level Architecture
- Per site: edge pair, firewall pair, ToR pair, compute cluster, local backup services, and local internet handoff.
- Inbound path: internet or WAN edge -> firewall policy boundary -> internal segments.
- Inter-site routing: BGP over IPsec tunnel mesh with documented fallback behavior.
- Remote access: VPN terminates on firewall or dedicated VPN VM with AD + MFA controls.
- Guest internet: local site egress only, with NAT64/DNS64 and policy isolation from WAN.
- Service publication: DMZ WAF + load balancer stack, with GeoDNS or anycast selection by service type.

## Physical Form Factor
- Baseline supports one-rack sites and two-rack expansion sites.
- Two-rack RU placement, cable pathing, vent direction, and airflow quality controls are defined in [Physical Rack Topology (Two-Rack Site)](../03_diagrams/physical_rack_topology_2rack.mmd.md).

## Design Governance
- Architecture acceptance criteria are defined in [01 Scope - Acceptance Criteria](../01_scope/acceptance_criteria.md).
- Open design decisions are tracked in [Abstractions and Clarifications Needed](../09_appendix/abstractions_clarifications_needed.md).

## Design Outcome
The resulting architecture can scale to additional sites without redesigning core policy, because addressing, segmentation, routing intent, and service classes are standardized and transport-agnostic.
