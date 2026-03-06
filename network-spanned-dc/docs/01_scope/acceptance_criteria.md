# Acceptance Criteria

The scope package is accepted when all criteria below are met.

## Documentation Completeness
- All core sections exist and are linked from `docs/index.md` and `mkdocs.yml`.
- Scope, assumptions, exclusions, and acceptance criteria are mutually consistent.
- No credentials, tokens, private keys, or production secrets appear in documentation.
- Architecture statements use consistent terminology across docs and diagrams.

## Architecture Baseline
- The inter-site model is explicitly Layer 3 only with no stretched Layer 2 between sites.
- IPv6 ULA root prefix is `fdca:fcaf:e000::/48` with per-site `/56` and standard `/64` segments documented.
- Site topology includes edge pair, firewall pair, ToR pair, and minimum hypervisor baseline.
- Service classification and spanning behavior are documented for stateless and stateful tiers.

## Routing, Security, and Segmentation
- WAN abstraction, IPsec overlay expectations, and route advertisement policy are documented.
- BGP policy intent includes site summary advertisements and failover behavior.
- Segmentation policy includes default deny and explicit zone intent.
- Internet publication path includes WAF and load balancer controls.
- Identity and MFA expectations are documented for privileged and remote access.

## Resilience and Recovery
- Failover scenarios include trigger, detection, automated response, manual actions, impact, RTO, and RPO.
- DR runbooks and test cadence are documented and linked.
- Backup strategy, retention, and restore procedures are documented and aligned.
- Open risks and unresolved design decisions are tracked in the appendix decision register.

## Physical and Operational Readiness
- One-rack and two-rack physical guidance is documented, including RU placement and heavy-device positioning.
- Cable routing guidance separates power and data paths with dual-path resilience intent.
- Airflow direction, spacing expectations, and quality targets are documented.
- GitOps workflow, observability baseline, and lifecycle management model are defined.

## Review and Build Quality
- Markdown renders cleanly in repository viewers and MkDocs output.
- Mermaid diagrams in scope-related references do not contain parse errors.
- Cross-document links used by scope files resolve correctly in MkDocs build.
