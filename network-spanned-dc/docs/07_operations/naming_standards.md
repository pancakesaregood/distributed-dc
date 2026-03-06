# Naming Standards

## Site and Rack Naming
- Sites: `site-a`, `site-b`, `site-c`, `site-d`.
- Racks: `r01`, `r02` per site.

## Device Naming
- Edge router: `site-a-edge-a`, `site-a-edge-b`.
- Firewall: `site-a-fw-a`, `site-a-fw-b`.
- ToR: `site-a-tor-a`, `site-a-tor-b`.
- Hypervisor: `site-a-r01-hv01`.
- Storage: `site-a-r02-st01`.
- VPN VM (if not on-box on firewall): `site-a-vpn-01`.
- WAF VM: `site-a-waf-01`, `site-a-waf-02` (if HA pair).
- nginx Load Balancer VM: `site-a-lb-01`, `site-a-lb-02` (if HA pair).
- Guacamole DB VM: `site-a-guac-db-01` (primary at site), `site-a-guac-db-02` (replica).
- VDI desktop VM (persistent): `site-a-vdi-<username>`.
- VDI desktop VM (pooled): `site-a-vdi-pool-<index>` (e.g., `site-a-vdi-pool-01`).
- NAT64 gateway VM (if not on firewall): `site-a-nat64-01`.
- DNS64 resolver VM: `site-a-dns64-01`.

## Service Naming
- Tier 1 stateless apps: `svc-<name>-aa`.
- Tier 1 stateful services: `svc-<name>-as`.
- Local-only services: `svc-<name>-local`.

## Addressing Labels
- Prefix objects include site and segment suffix.
- Loopback object names include role and numeric ID.
- Transit links include both endpoint IDs for traceability.

Consistent names reduce troubleshooting time and improve automation reliability.
