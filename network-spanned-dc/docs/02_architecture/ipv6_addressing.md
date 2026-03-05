# IPv6 Addressing Plan

## ULA Root Prefix
- Global internal prefix: `fdca:fcaf:e000::/48`

## Site Allocation (/56 per Site)
- Site A: `fdca:fcaf:e000::/56`
- Site B: `fdca:fcaf:e100::/56`
- Site C: `fdca:fcaf:e200::/56`
- Site D: `fdca:fcaf:e300::/56`

## Standard /64 Segment Suffixes per Site
The same suffix map is used at every site for operational consistency.

| Suffix | Segment | Purpose |
|---|---|---|
| `:0000` | Management | Hypervisor, switch, and platform management |
| `:0010` | Servers/VMs | VM workloads and infrastructure VMs |
| `:0020` | Containers | Podman hosts and service networks |
| `:0030` | User | Internal user and admin jump hosts |
| `:0040` | IoT | Sensors and non-user embedded devices |
| `:0050` | Guest | Isolated guest and contractor access |
| `:0060` | DMZ | Exposed internal services behind policy controls |
| `:00f0` | Loopbacks | Router and service loopback /128 addresses |
| `:00ff` | Transit | Point-to-point routed links |

## Examples by Site

### Site A (`fdca:fcaf:e000::/56`)
- Management: `fdca:fcaf:e000:0000::/64`
- Servers/VMs: `fdca:fcaf:e000:0010::/64`
- Containers: `fdca:fcaf:e000:0020::/64`
- Loopbacks: `fdca:fcaf:e000:00f0::/64`
- Transit: `fdca:fcaf:e000:00ff::/64`

### Site B (`fdca:fcaf:e100::/56`)
- Management: `fdca:fcaf:e100:0000::/64`
- Servers/VMs: `fdca:fcaf:e100:0010::/64`
- Containers: `fdca:fcaf:e100:0020::/64`
- Loopbacks: `fdca:fcaf:e100:00f0::/64`
- Transit: `fdca:fcaf:e100:00ff::/64`

### Site C (`fdca:fcaf:e200::/56`)
- Management: `fdca:fcaf:e200:0000::/64`
- Servers/VMs: `fdca:fcaf:e200:0010::/64`
- Containers: `fdca:fcaf:e200:0020::/64`
- Loopbacks: `fdca:fcaf:e200:00f0::/64`
- Transit: `fdca:fcaf:e200:00ff::/64`

### Site D (`fdca:fcaf:e300::/56`)
- Management: `fdca:fcaf:e300:0000::/64`
- Servers/VMs: `fdca:fcaf:e300:0010::/64`
- Containers: `fdca:fcaf:e300:0020::/64`
- Loopbacks: `fdca:fcaf:e300:00f0::/64`
- Transit: `fdca:fcaf:e300:00ff::/64`

## Why /64 per Segment
- IPv6 Neighbor Discovery and host behavior are standardized around `/64` subnets.
- Using `/64` avoids interoperability edge cases in network tools and operating systems.
- Consistent `/64` segmentation simplifies automation templates and validation checks.

## Address Assignment Guidance
- Do not use SLAAC for servers, hypervisors, network appliances, or platform control services.
- Use static assignments or DHCPv6 reservations for infrastructure workloads.

### Simple Static Convention
Format: `fdca:fcaf:<site>:<segment>::RRHH`
- `RR` = rack number in hex (`01` or `02`)
- `HH` = host index in hex (`01` to `FE`)

Examples:
- Site A rack 1 hypervisor 10 in servers segment: `fdca:fcaf:e000:0010::010A`
- Site C rack 2 storage node 3 in servers segment: `fdca:fcaf:e200:0010::0203`
- Site B edge loopback 1: `fdca:fcaf:e100:00f0::0001/128`
