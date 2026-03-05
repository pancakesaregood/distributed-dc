# Assumptions

## Environment Assumptions
- Four active sites are available and can be labeled Site A through Site D.
- Each site has 1 to 2 racks with redundant power and cooling.
- WAN service is provided as vendor-managed L3 handoff at each site.
- WAN provider can support route exchange and SLA reporting.

## Technical Assumptions
- IPv6 ULA is acceptable for internal east-west communications.
- Open-source tools are preferred when operationally supportable.
- Hypervisor hosts support hardware virtualization extensions.
- Platform teams can operate Linux-based tooling and Git workflows.
- Time synchronization and DNS forwarding can be centralized.

## Operational Assumptions
- A shared change process exists for network and platform changes.
- Incident response staffing can execute manual DR runbooks.
- Backup data transfer windows are available during off-peak periods.
- Periodic DR exercises are approved by service owners.
