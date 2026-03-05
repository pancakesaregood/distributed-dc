# ADR 0001: Record Architecture Decisions

- Status: Accepted
- Date: 2026-03-05

## Context
A low-cost, four-site spanned datacenter architecture is required with clear failure domains, defendable routing strategy, and open-source preference.

## Decisions
1. Use IPv6 ULA root prefix `fdca:fcaf:e000::/48` with `/56` per site and standardized `/64` segment suffixes.
2. Keep inter-site design Layer 3 only; do not stretch Layer 2 between sites.
3. Treat WAN as vendor-managed L3 abstraction and define capability requirements, not circuit specifics.
4. Use BGP as primary route exchange and static routing as controlled fallback.
5. Use VM-first compute with Podman for containerized workloads.
6. Use replication-based service spanning patterns instead of shared broadcast domains.
7. Use 3-2-1 aligned backup strategy with credential separation and optional immutable archive tier.

## Consequences
- Improves fault isolation and reduces cross-site broadcast risk.
- Keeps architecture portable across WAN providers.
- Requires mature service replication and explicit failover runbooks.
- Enables low recurring licensing footprint when open-source options are selected.
