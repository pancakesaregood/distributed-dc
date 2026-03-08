# ADR-0005: Dual Desktop Reference Targets (Linux and Windows)

- Status: Accepted
- Date: 2026-03-08
- Deciders: Platform + EUC Operations

## Context
Guacamole needed practical desktop targets for users:
- a Linux option for lightweight browser-based VNC sessions,
- a Windows option for RDP-based workflows.

User context and support workflows required both paths to exist in the same access portal and permission model.

## Decision
Adopt a dual-target desktop reference pattern:
- Linux desktop:
  - Kubernetes-hosted VNC target (`vdi-desktop.vdi.svc.cluster.local:5900`).
- Windows desktop:
  - Site A EC2 Windows Server instance exposed on `3389` to internal VPC sources for Guacamole RDP.
- Guacamole DB seeding includes both connection objects and per-user permissions (`READ/UPDATE/DELETE/ADMINISTER`) for operational users.

## Consequences
### Positive
- Supports mixed workload needs (Linux and Windows) from one control plane.
- Lowers troubleshooting complexity by keeping a known reference desktop per protocol.
- Enables user access verification independent of application onboarding.

### Negative
- Increases operational surface (two desktop stacks/protocols).
- Windows RDP stability and credential drift require ongoing runbook support.

## Evidence
- `iac/terraform/SESSION_NOTES.md`:
  - "Sample VDI Session Bootstrap Pass (2026-03-08 04:57 America/Toronto)"
  - "Guacamole Login Branding Override Pass (2026-03-08 15:40 America/Toronto)"
