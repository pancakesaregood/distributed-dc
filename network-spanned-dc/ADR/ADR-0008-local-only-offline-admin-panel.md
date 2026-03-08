# ADR-0008: Local-Only (Offline) Admin Panel Operating Model

- Status: Accepted
- Date: 2026-03-08
- Deciders: Operations + Security

## Context
The VDI operations admin panel is a high-privilege troubleshooting interface. Publishing it through ALB/Cloudflare would increase external exposure and operational risk.

## Decision
Run the admin panel as a local-only tool by default:
- bind to loopback (`127.0.0.1`) on operator workstation,
- require explicit admin credentials,
- do not publish by default through public edge paths (ALB/Cloudflare),
- use temporary tunnel/reverse-proxy only when explicitly required and approved.

## Consequences
### Positive
- Minimizes attack surface for privileged operations interface.
- Reduces accidental public exposure risk.
- Aligns with break-glass operational usage pattern.

### Negative
- Remote/shared access requires additional controlled access steps.
- Operational convenience is lower than always-public dashboards.

## Evidence
- `iac/terraform/SESSION_NOTES.md`:
  - "Admin DNS + Console Exposure Clarification (2026-03-08 06:02 America/Toronto)"
  - "Admin Panel Runtime Check (2026-03-08 06:29 America/Toronto)"
