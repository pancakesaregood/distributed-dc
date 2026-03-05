# Naming Standards

## Site and Rack Naming
- Sites: `site-a`, `site-b`, `site-c`, `site-d`.
- Racks: `r01`, `r02` per site.

## Device Naming
- Edge: `site-a-edge-a`, `site-a-edge-b`.
- ToR: `site-a-tor-a`, `site-a-tor-b`.
- Hypervisor: `site-a-r01-hv01`.
- Storage: `site-a-r02-st01`.

## Service Naming
- Tier 1 stateless apps: `svc-<name>-aa`.
- Tier 1 stateful services: `svc-<name>-as`.
- Local-only services: `svc-<name>-local`.

## Addressing Labels
- Prefix objects include site and segment suffix.
- Loopback object names include role and numeric ID.
- Transit links include both endpoint IDs for traceability.

Consistent names reduce troubleshooting time and improve automation reliability.
