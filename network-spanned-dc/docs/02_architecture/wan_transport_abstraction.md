# WAN Transport Abstraction

## Design Principle

The inter-site IPsec overlay is transport-agnostic. The overlay operates identically regardless of what carries the outer packets between site edges. This is a deliberate design constraint: all architecture, addressing, routing, and security decisions are made at the IPsec overlay level and above. The physical transport beneath the tunnels is swappable without changing any internal design.

Two transport modes are supported. Both terminate on the same site edge pair with the same IPsec parameters. Both carry IPv6 ULA as the inner protocol. Internal architecture, segmentation, BGP topology, and service design are unchanged between modes.

---

## Transport Mode A — Private Circuit

The preferred transport. A vendor-managed private L3 circuit (MPLS VPN or equivalent dedicated service) connects site edge pairs. The WAN provider offers logically isolated inter-site paths and an IPv6-capable L3 handoff.

**Stack:**
```
[IPv6 ULA inner traffic]
    encapsulated in IPsec tunnel mode (IKEv2 / AES-256-GCM)
        carried over IPv6 or IPv4 private circuit underlay
```

- Edge pair addresses on the WAN handoff can be IPv6 or IPv4 depending on the provider's handoff model.
- IPsec outer headers match the handoff address family.
- Private circuit provides network-layer isolation in addition to IPsec encryption; both layers are active simultaneously and are complementary controls.
- MTU: WAN provider must support at least 1400-byte inner MTU after IPsec overhead. Prefer 1500+ byte L2 MTU on the handoff.

---

## Transport Mode B — Consumer IPv4 Internet (IPv6-over-IPv4 IPsec)

The fallback transport for sites where a private circuit is not available or cost-prohibitive. Consumer-grade IPv4 internet connections (broadband, business DSL, cable, fixed wireless) carry the IPsec tunnels. IPv6 ULA runs as the overlay inside the IPv4 IPsec tunnels.

**Stack:**
```
[IPv6 ULA inner traffic]
    encapsulated in IPsec tunnel mode (IKEv2 / AES-256-GCM)
        encapsulated in IPv4 outer headers (ESP protocol 50)
            carried over consumer IPv4 internet
```

This is a 6-in-4 arrangement via IPsec tunnel mode. The edge routers see IPv4 on the WAN-facing interface; all internal addressing and routing remain IPv6 ULA without modification.

### Requirements for Mode B

- **Static public IPv4 per edge node** — each edge node requires a static, routable public IPv4 address. Dynamic addressing is not recommended; if unavoidable, use a stable FQDN via dynamic DNS and configure IKEv2 to use FQDN-based peer identity. A static IP is strongly preferred.
- **NAT traversal (NAT-T)** — if the edge is behind CGN or a site NAT device, IKEv2 NAT-T must be enabled (UDP port 4500 for ESP encapsulation). Prefer direct public IPv4 on the edge interface to avoid double-NAT complications.
- **ISP passthrough** — the ISP must pass ESP (IP protocol 50) or UDP 4500 (NAT-T) without blocking, stripping, or deep-packet inspection that breaks IKEv2 negotiation.
- **IKEv2 DPD (Dead Peer Detection)** — enable DPD with a conservative timeout. Consumer paths have variable quality; DPD detects silent tunnel failures and triggers rekeying automatically.
- **Sufficient bandwidth** — IPsec adds approximately 60–80 bytes of overhead per packet on an IPv4 transport (IPv4 outer 20 + ESP header ~8 + IV 8 + ICV 16 + padding). Account for this in bandwidth planning. Effective inner MTU is approximately 1380 bytes on a 1500-byte-MTU consumer connection.

### MTU Handling for Mode B

| Layer | Header Size |
|---|---|
| Consumer IPv4 MTU | 1500 bytes |
| IPv4 outer header | 20 bytes |
| ESP header + IV + ICV | ~40 bytes |
| **Available inner MTU** | **~1440 bytes** |
| IPv6 inner header | 40 bytes |
| **Available for inner payload** | **~1400 bytes** |

Set the edge tunnel interface MTU to 1400 bytes (inner) to avoid fragmentation. Enable PMTUD on the edge and ensure the firewall does not block ICMPv6 Packet Too Big messages needed for path MTU discovery inside the tunnel.

---

## Common IPsec Parameters (Both Modes)

These parameters apply regardless of transport mode:

| Parameter | Value |
|---|---|
| IKE version | IKEv2 |
| Encryption | AES-256-GCM |
| Integrity | SHA-256 or stronger (implicit in GCM; explicit for IKE SA) |
| Key exchange | Diffie-Hellman Group 14 or higher (Group 19/20 preferred) |
| PFS | Required |
| Authentication | Certificate-based preferred; PSK acceptable with strong key management |
| SA lifetime (IKE) | 24 hours |
| SA lifetime (IPsec) | 1 hour |
| DPD | Enabled, 30-second probe interval |
| NAT-T | Enabled (required for Mode B; harmless for Mode A) |

---

## Topology Implications

- Each site operates two edge nodes (Edge-A and Edge-B). Each edge node establishes independent IPsec tunnels to each edge node at every other site.
- Per site pair, four tunnels are maintained: Edge-A to remote Edge-A (A–A), Edge-A to remote Edge-B (A–B), Edge-B to remote Edge-A (B–A), and Edge-B to remote Edge-B (B–B). With four sites and six site pairs, the fabric carries 24 tunnels in total.
- All four tunnels per site pair are held established at all times. Cross-connect tunnels are not brought up on demand; they must be immediately ready to carry traffic without a new IKEv2 negotiation cycle.
- Sites can run different transport modes simultaneously. For example, Site A and Site B may have private circuits (Mode A) while Site C and Site D use consumer internet (Mode B). All four sites remain in the same full-mesh IPsec overlay with the same 4-tunnel-per-pair model.
- BGP primary sessions run on A–A matched-pair tunnels. BGP secondary sessions run on B–B matched-pair tunnels. Cross-connect tunnels (A–B, B–A) forward traffic under routing policy without additional BGP sessions by default.
- Route advertisement, prefix policy, and anycast behavior are identical on both transports and across all tunnel roles.

---

## Operational Differences Between Modes

| Concern | Mode A (Private Circuit) | Mode B (Consumer IPv4) |
|---|---|---|
| Underlay reliability | Carrier SLA, dedicated path | Best-effort, shared internet |
| Latency predictability | High | Variable |
| Tunnel endpoint type | IPv6 or IPv4 private handoff | Static public IPv4 required |
| NAT traversal | Typically not needed | Required if behind NAT/CGN |
| MTU | Provider-confirmed, generally 1500+ | ~1400 inner MTU after overhead |
| Monitoring | WAN SLA + IPsec tunnel state | IPsec tunnel state only (no SLA) |
| Failure detection | WAN alarm + DPD | DPD only |
| Cost | Higher | Low |
| Privacy | Private circuit isolation + IPsec | IPsec only |

---

## Upgrade Path

Sites may transition from Mode B to Mode A without any change to internal addressing, routing, or security policy. The only change required is:

1. Provision a private circuit handoff at the site edge pair.
2. Reconfigure the IPsec peer addresses on both ends to use the new private circuit addresses.
3. Validate tunnel establishment and BGP convergence.
4. Decommission the consumer internet tunnel for that site pair.

All other configuration, including BGP policy, prefix advertisement, firewall rules, and internal segments, is unaffected.
