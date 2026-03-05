# Acceptance Criteria

## Scope and Documentation
- All required files exist in the defined repository structure.
- Architecture language is consistent and review-ready.
- No secrets or credentials appear in any document.

## Architecture
- Inter-site model is explicitly Layer 3 only.
- No stretched Layer 2 between sites is documented.
- Per-site failure domains are clearly defined.
- Spanning services rely on replication and routing policy.

## Addressing and Routing
- IPv6 ULA prefix is `fdca:fcaf:e000::/48`.
- Site `/56` allocations and standard `/64` segments are documented.
- BGP primary and static fallback routing are defined.
- Route advertisement policy includes per-site `/56` summaries.

## Resilience and DR
- Required failover scenarios are documented with trigger, detection, automated and manual responses, user impact, RTO, and RPO.
- Backup strategy is 3-2-1 aligned and includes credential isolation.
- Restore test schedule includes monthly, quarterly, and semiannual activities.

## Operational Readiness
- GitOps model, observability baseline, and patch lifecycle are defined.
- Vendor WAN requirements and handoff expectations are documented.
- Unknowns are captured in [Abstractions and Clarifications Needed](../09_appendix/abstractions_clarifications_needed.md).
