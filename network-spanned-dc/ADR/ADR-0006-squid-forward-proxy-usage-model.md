# ADR-0006: Squid Forward Proxy Usage Model for Controlled VDI Browsing

- Status: Accepted
- Date: 2026-03-08
- Deciders: Security + Platform

## Context
Guacamole desktop users required internet browsing with centralized policy control. Direct desktop egress does not provide consistent filtering, source restriction, or auditable policy management.

## Decision
Use a Site A Squid forward proxy as the controlled browsing path for VDI clients:
- listen endpoint: internal proxy URL for desktops,
- source restrictions: only approved VDI CIDR ranges,
- policy controls: domain blocklist/allowlist through Terraform variables,
- infrastructure lifecycle and policy managed in Terraform.

## Consequences
### Positive
- Centralized browsing policy with deterministic enforcement.
- Access restrictions are declarative and auditable in IaC.
- Supports incremental policy tuning without desktop image rebuilds.

### Negative
- Adds proxy dependency for browsing experience.
- Requires proxy health monitoring and lifecycle management.

## Evidence
- `iac/terraform/SESSION_NOTES.md`:
  - "Forward Proxy Bring-up for Guac Client Surf Control (2026-03-08 09:59 America/Toronto)"
