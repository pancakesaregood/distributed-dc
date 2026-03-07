# Network Spanned DC Documentation

This project contains a complete, meeting-defendable architecture documentation set for a low-cost, four-site spanned datacenter design.

https://pancakesaregood.github.io/distributed-dc

Core design constraints:
- IPv6 ULA prefix: `fdca:fcaf:e000::/48`
- Four placeholder sites: Site A, Site B, Site C, Site D
- Each site has 1 to 2 racks
- Open-source preference for platform components
- VM-based virtualization and Podman-based container runtime
- Vendor-managed WAN treated as an abstract L3 handoff

## Documentation Navigation
- Start here: [Documentation Home](docs/index.md)
- Scope and acceptance: [01 Scope](docs/01_scope/scope_of_work.md)
- Architecture details: [02 Architecture](docs/02_architecture/overview.md)
- Diagrams: [03 Diagrams](docs/03_diagrams/diagram_index.md)
- Failover and DR: [04 Failover and DR](docs/04_failover_dr/failover_scenarios.md)
- Backup strategy: [05 Backup](docs/05_backup/backup_strategy.md)
- Security baseline: [06 Security](docs/06_security/security_baseline.md)
- Operating model: [07 Operations](docs/07_operations/gitops_operating_model.md)
- WAN abstraction requirements: [08 Vendor WAN](docs/08_vendor_wan/wan_service_requirements.md)
- Clarifications and unknowns: [09 Appendix](docs/09_appendix/abstractions_clarifications_needed.md)

## Local MkDocs Usage
```powershell
cd network-spanned-dc
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install mkdocs
mkdocs serve
```

The site runs locally and reflects the navigation defined in `mkdocs.yml`.

## Cloud Deployment Notes (2026-03-07)
- Terraform cloud deployment phases are implemented through Phase 5 scaffolding in `iac/terraform`.
- Phase 2 inter-cloud VPN/BGP and Phase 3 EKS/GKE control planes are deployed and converged.
- Phase 4 worker-capacity onboarding is now codified behind feature flags and ready to execute.
- Phase 5 resilience-validation evidence capture and handover templates are now codified.
- Detailed operational notes are tracked in `iac/terraform/SESSION_NOTES.md`.
