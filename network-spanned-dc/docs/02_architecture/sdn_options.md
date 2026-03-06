# SDN Options

## Objective
Apply software-defined networking only where it reduces operational effort without introducing disproportionate complexity or hardware risk.

## Option 1: EVPN-VXLAN on Network Fabric
- Control plane: EVPN.
- Data plane: VXLAN overlay.
- Best fit: sites with validated switch/NOS support and strong network operations maturity.
- Benefit: cleaner multi-tenant segmentation and scalable policy distribution.
- Risk: higher implementation complexity and stronger dependency on network platform features.

## Option 2: Host-Based Overlay (Open vSwitch + FRR)
- Overlay logic implemented at hypervisor or host layer.
- Best fit: environments where switching hardware is limited but host automation is mature.
- Benefit: reduced dependency on advanced physical switching features.
- Risk: increased host complexity, harder troubleshooting boundaries, and larger blast radius for host misconfiguration.

## Option 3: Routed Access with Minimal Overlay
- Traditional routed VLAN-per-zone model with explicit policy boundaries.
- Best fit: budget-sensitive and mixed-hardware sites.
- Benefit: lowest complexity and fastest operational onboarding.
- Risk: fewer mobility abstractions and less centralized network automation behavior.

## Decision Framework

| Criterion | Option 1 | Option 2 | Option 3 |
| --- | --- | --- | --- |
| Hardware feature dependency | High | Low | Low |
| Operational complexity | Medium-high | High | Low |
| Time to deploy | Medium | Medium | Fast |
| Troubleshooting simplicity | Medium | Low | High |
| Fit for initial baseline | Conditional | Conditional | Strong |

## Recommended Path
- Use Option 3 as the default deployment baseline for all sites.
- Introduce Option 1 selectively where EVPN-VXLAN capability is validated in hardware and team operations.
- Use Option 2 only where Option 1 is not feasible and host overlay operations are well supported.
- Keep every option expressed as code-backed intent to preserve migration flexibility.

## Adoption Gates
- Confirm platform support matrix for required protocols and telemetry.
- Validate failure behavior in lab or staging before production use.
- Confirm runbooks and team readiness for day-2 operations.
- Update observability dashboards and alert mappings before go-live.

## Tooling Candidates
- FRRouting for route policy and dynamic routing integration.
- Open vSwitch for host-side switching and optional overlay support.
- NetBox as source of truth for IPAM/DCIM and intent metadata.
- Ansible (or equivalent) for repeatable network and host configuration rollout.
