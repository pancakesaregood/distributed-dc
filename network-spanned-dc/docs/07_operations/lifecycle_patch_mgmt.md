# Lifecycle and Patch Management

## Patch Cadence
- Monthly standard patch window for hypervisors, guest OS, and network software.
- Emergency patch process for critical vulnerabilities.
- Rolling patch by site to preserve multi-site service availability.

## Upgrade Strategy
- Validate upgrades in non-production environment first.
- Upgrade one site at a time with hold points.
- Verify backup integrity before major version upgrades.

## End-of-Life Management
- Track hardware and software lifecycle dates in asset inventory.
- Plan replacement or migration at least two quarters before end-of-support.
- Require risk sign-off for any temporary extension beyond support windows.

## Patch Governance
- Document approved baselines and exceptions.
- Capture patch outcomes and regressions in operations log.
- Review patch KPIs quarterly.
