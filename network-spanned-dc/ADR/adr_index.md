# Architecture Decision Records (ADR) Index

This index tracks implementation-time architecture decisions captured from runtime build and incident notes.

## ADR Entries
- [ADR-0001: Front-Proxy Branding Injection for Guacamole Login UX](ADR-0001-front-proxy-branding-and-login-customization.md)
- [ADR-0002: Site A Forward Proxy for Controlled VDI Browsing](ADR-0002-site-a-forward-proxy-for-vdi-controlled-browsing.md)
- [ADR-0003: Restrict Ops Application HTTP Access to Internal/Guac-Adjacent CIDRs](ADR-0003-ops-apps-restricted-to-internal-guac-client-networks.md)
- [ADR-0004: Rendered Manifest Path Required for Guacamole Bootstrap Changes](ADR-0004-rendered-manifest-only-for-guacamole-bootstrap.md)
- [ADR-0005: Dual Desktop Reference Targets (Linux and Windows)](ADR-0005-dual-desktop-reference-windows-and-linux.md)
- [ADR-0006: Squid Forward Proxy Usage Model for Controlled VDI Browsing](ADR-0006-squid-forward-proxy-usage-model.md)
- [ADR-0007: NGINX Front-Proxy Pattern for Root Portal and Guacamole UX Injection](ADR-0007-nginx-front-proxy-and-portals.md)
- [ADR-0008: Local-Only (Offline) Admin Panel Operating Model](ADR-0008-local-only-offline-admin-panel.md)

## Source Evidence
- Runtime and remediation record: `iac/terraform/SESSION_NOTES.md`
- Build narrative: [Implementation Build Report](../10_implementation/implementation_build_report.md)
