# ADR-0001: Front-Proxy Branding Injection for Guacamole Login UX

- Status: Accepted
- Date: 2026-03-08
- Deciders: Platform + Operations

## Context
The default Guacamole login branding did not match the Slothkko portal experience. We needed a branding override that was:
- fast to roll out,
- reversible,
- independent of rebuilding upstream Guacamole images.

## Decision
Apply branding through the front-proxy layer by injecting:
- `guac-theme.css` (visual overrides),
- `guac-branding.js` (title/favicon and text overrides),
into `/guacamole/` HTML at response time.

Implementation location:
- `iac/k8s/vdi/guacamole-nodeport.yaml`

## Consequences
### Positive
- Branding can be changed without rebuilding Guacamole containers.
- Overrides remain centralized in a single Kubernetes config path.
- Rollback is simple (remove injected assets/sub_filter rules).

### Negative
- Branding depends on response rewriting behavior in the front-proxy.
- CSS selector changes in future Guacamole releases may require updates.

## Evidence
- `iac/terraform/SESSION_NOTES.md` -> "Guacamole Login Branding Override Pass (2026-03-08 15:40 America/Toronto)"
