# Per-Site Logical Rack Topology

Standard site template. The designated redundant internet site uses two separate ISP circuits (ISP-1 on Edge-A, ISP-2 on Edge-B) instead of a single shared circuit. VPN can terminate on FW-A/FW-B directly or via DNAT to a VPN VM in a DMZ segment.

```mermaid
graph TD
  subgraph Site[Single Site Template - 1 to 2 Racks]
    subgraph Rack1[Rack 1]
      E1["Edge-A<br/>L3 Router"]
      E2["Edge-B<br/>L3 Router"]
      F1["FW-A<br/>Firewall"]
      F2["FW-B<br/>Firewall"]
      T1[ToR-A]
      T2[ToR-B]
      H1[HV-01]
      H2[HV-02]
    end

    subgraph Rack2[Rack 2 Optional]
      H3[HV-03]
      H4[HV-04]
      S1[Storage-01]
      S2[Storage-02]
    end

    WAN["Vendor L3 Handoff<br/>Private Circuit"]
    INET["Local Internet / ISP Circuit<br/>vpn.example.com"]
    MGMT[Mgmt Services VMs]
  end

  WAN -->|IPsec inter-site tunnels| E1
  WAN -->|IPsec inter-site tunnels| E2
  INET -->|Internet + VPN inbound| E1
  INET -->|Internet + VPN inbound| E2

  E1 -->|Outside interface| F1
  E1 -->|Outside interface| F2
  E2 -->|Outside interface| F1
  E2 -->|Outside interface| F2

  F1 -->|Inside interface| T1
  F1 -->|Inside interface| T2
  F2 -->|Inside interface| T1
  F2 -->|Inside interface| T2

  T1 --> H1
  T2 --> H1
  T1 --> H2
  T2 --> H2
  T1 --> H3
  T2 --> H3
  T1 --> H4
  T2 --> H4
  T1 --> S1
  T2 --> S1
  T1 --> S2
  T2 --> S2

  H1 --> MGMT
  H2 --> MGMT
  linkStyle default color:#CC5500
```
