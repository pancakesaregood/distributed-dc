# ADR-0002: Site A Forward Proxy for Controlled VDI Browsing

- Status: Accepted
- Date: 2026-03-08
- Deciders: Platform + Security

## Context
Guacamole VDI clients required web browsing capability with enforceable controls. Direct unrestricted egress from desktops did not meet control expectations.

## Decision
Deploy a dedicated Site A Squid forward proxy, managed by Terraform, with:
- source CIDR restrictions to VDI client ranges,
- explicit domain block list controls,
- controlled listening endpoint for desktop proxy configuration.

Implementation location:
- `iac/terraform/phase4_forward_proxy.tf`
- variables `phase4_enable_forward_proxy_site_a` and `phase4_forward_proxy_site_a_*`

## Consequences
### Positive
- Policy enforcement is centralized and auditable.
- Browsing control can be changed via Terraform variables.
- Guacamole desktop traffic can be routed through a deterministic control point.

### Negative
- Adds an additional runtime component to operate and monitor.
- Proxy becomes a dependency for web browsing from controlled clients.

## Evidence
- `iac/terraform/SESSION_NOTES.md` -> "Forward Proxy Bring-up for Guac Client Surf Control (2026-03-08 09:59 America/Toronto)"
