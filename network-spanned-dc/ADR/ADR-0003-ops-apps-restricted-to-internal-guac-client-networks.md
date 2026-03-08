# ADR-0003: Restrict Ops Application HTTP Access to Internal/Guac-Adjacent CIDRs

- Status: Accepted
- Date: 2026-03-08
- Deciders: Security + Operations

## Context
OpenProject and Git server UIs were initially reachable from public internet addresses. Requirement changed to keep these application surfaces reachable only from Guacamole-side/internal site networks.

## Decision
Set default HTTP ingress policy for ops apps to internal site CIDRs (plus optional trusted admin CIDRs), and avoid broad public `0.0.0.0/0` exposure for application UIs.

Implementation location:
- `iac/terraform/phase4_ops_servers.tf`
- variables:
  - `phase4_ops_openproject_http_allowed_ipv4_cidrs`
  - `phase4_ops_git_http_allowed_ipv4_cidrs`
  - `phase4_ops_trusted_ipv4_cidrs`

## Consequences
### Positive
- Reduced external attack surface for operational tools.
- Access model aligns with Guacamole-mediated administration intent.
- Policy remains configurable per environment through Terraform.

### Negative
- Direct public troubleshooting access is constrained by design.
- Emergency break-glass access requires explicit CIDR policy changes.

## Evidence
- `iac/terraform/SESSION_NOTES.md` -> "Ops Server Baseline + Guac Access Pass (2026-03-08 07:36 America/Toronto)"
