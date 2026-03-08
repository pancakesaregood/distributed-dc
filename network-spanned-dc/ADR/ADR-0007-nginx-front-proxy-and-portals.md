# ADR-0007: NGINX Front-Proxy Pattern for Root Portal and Guacamole UX Injection

- Status: Accepted
- Date: 2026-03-08
- Deciders: Platform + Operations

## Context
We needed a unified root entrypoint experience (`/`) and the ability to customize Guacamole login UX without modifying upstream Guacamole application images.

## Decision
Use an NGINX sidecar/front-proxy in the Guacamole deployment to:
- serve Slothkko portal assets on `/` and `/portal/*`,
- reverse proxy Guacamole on `/guacamole/`,
- inject UI customization assets (`guac-theme.css`, `guac-branding.js`) into Guacamole HTML responses using `sub_filter`.

## Consequences
### Positive
- Decouples UX/branding and portal behavior from upstream Guacamole builds.
- Enables fast UI updates through configmap-based asset changes.
- Keeps a single, consistent user-facing entrypoint for portal and login.

### Negative
- Adds response-rewrite coupling to HTML structure.
- Requires careful rollout process when modifying templated manifest content.

## Evidence
- `iac/terraform/SESSION_NOTES.md`:
  - "Slothkko Root Portal + Guac Theme Activation Pass (2026-03-08 08:14 America/Toronto)"
  - "Guacamole Login Branding Override Pass (2026-03-08 15:40 America/Toronto)"
