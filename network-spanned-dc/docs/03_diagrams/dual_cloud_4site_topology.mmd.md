# Dual-Cloud 4-Site Topology

```mermaid
flowchart LR
    subgraph AWS["AWS"]
        A["Site A\nus-east-1\n(EKS + EC2)"]
        B["Site B\nus-west-2\n(EKS + EC2)"]
        ATGW["Transit Gateway A"]
        BTGW["Transit Gateway B"]
        A --- ATGW
        B --- BTGW
        ATGW <-. Inter-region Peering .-> BTGW
    end

    subgraph GCP["GCP"]
        C["Site C\nus-east4\n(GKE + Compute Engine)"]
        D["Site D\nus-west1\n(GKE + Compute Engine)"]
        CR1["Cloud Router C + HA VPN"]
        CR2["Cloud Router D + HA VPN"]
        C --- CR1
        D --- CR2
        CR1 <-. BGP over HA VPN .-> CR2
    end

    ATGW <-. A-C VPN/BGP .-> CR1
    ATGW <-. A-D VPN/BGP .-> CR2
    BTGW <-. B-C VPN/BGP .-> CR1
    BTGW <-. B-D VPN/BGP .-> CR2

    DNS["Global DNS + Health Checks"]
    DNS --> A
    DNS --> B
    DNS --> C
    DNS --> D

    classDef site fill:#f7f7f7,stroke:#333,stroke-width:1px;
    class A,B,C,D site;
```

## Routing Intent
- East preferred path: Site A <-> Site C.
- West preferred path: Site B <-> Site D.
- Cross-paths (A-D, B-C) remain ready for policy-driven failover.
- Advertise only summarized site prefixes for both IPv6 and IPv4 families.
