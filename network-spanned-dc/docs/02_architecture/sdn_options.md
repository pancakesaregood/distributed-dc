# SDN Options

## Objective
Use SDN where practical to reduce operational overhead while respecting low-cost constraints and heterogeneous site hardware realities.

## Option 1: EVPN-VXLAN on Network Fabric
- Uses EVPN control plane and VXLAN overlay.
- Best for flexible multi-tenant segmentation and simplified mobility.
- Requires switch and NOS support for EVPN-VXLAN.

## Option 2: Host-Based Overlay with Open vSwitch and FRR
- Overlay built at hypervisor/container host layer.
- Reduces dependence on advanced switching features.
- Increases host operational complexity and troubleshooting burden.

## Option 3: Routed Access with Minimal Overlay
- Traditional routed VLAN per zone at each site.
- Lowest complexity and broad hardware compatibility.
- Fewer SDN automation benefits for workload mobility.

## Recommended Path
- Baseline with Option 3 for predictable delivery.
- Introduce Option 1 selectively where switch capability and team skills are validated.
- Keep configuration modeled as code to permit gradual migration.

## Open-Source Tooling Candidates
- FRRouting for dynamic routing.
- Open vSwitch for overlay and virtual switching.
- NetBox for source-of-truth inventory and addressing metadata.
- Ansible for repeatable network and host configuration deployment.
