# Logical Network

## Logical Domains
- Management domain for infrastructure administration.
- Server and VM domain for traditional workloads.
- Container domain for Podman-hosted services.
- User and endpoint domain for internal clients.
- IoT and guest domains with restricted access.
- DMZ domain for externally exposed internal services.
- Loopback and transit domains for routing control.

## Inter-Site Connectivity Model
- Sites exchange summarized routes over vendor-managed L3 handoff.
- East-west traffic between sites is routed through edge policy controls.
- No VLAN or broadcast domain is extended across sites.

## Control Plane Expectations
- BGP preferred for dynamic route exchange.
- Static route fallback available when BGP is unavailable.
- Prefix filters prevent accidental route leaks.

## Data Plane Expectations
- Service traffic uses IPv6 ULA internally.
- Security zones are enforced at site edge and internal policy points.
- Cross-site traffic for stateful services is replication-oriented, not chatty transaction-by-transaction, unless latency permits.
