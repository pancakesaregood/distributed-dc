# Spanned Datacenter Documentation Home

This documentation defines a defendable architecture for a low-cost, four-site spanned datacenter using open-source components where practical.

## Design Snapshot
- IPv6 ULA plan anchored on `fdca:fcaf:e000::/48`
- Four sites connected through a vendor-managed L3 WAN abstraction
- All inter-site traffic traverses private WAN circuits and is additionally protected by IPsec tunnels between site edge pairs
- Site-level failure domains with no stretched Layer 2 between sites
- VM-first compute with Podman for containerized workloads
- Service spanning through replication and routing, not shared L2 domains

## Start Here
- [Scope of Work](01_scope/scope_of_work.md)
- [Architecture Overview](02_architecture/overview.md)
- [IPv6 Addressing](02_architecture/ipv6_addressing.md)
- [Routing and WAN Abstraction](02_architecture/routing_wan_abstraction.md)
- [Failover Scenarios](04_failover_dr/failover_scenarios.md)
- [Backup Strategy](05_backup/backup_strategy.md)
- [Abstractions and Clarifications Needed](09_appendix/abstractions_clarifications_needed.md)

## Reading Path for Design Reviews
1. Review scope and acceptance criteria.
2. Review architecture principles and addressing strategy.
3. Review routing, segmentation, and service spanning model.
4. Review failover, backup, and DR runbooks.
5. Confirm unresolved clarifications before implementation.
