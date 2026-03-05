# Per-Site Logical Rack Topology

Standard site template. The designated redundant internet site uses two separate ISP circuits (ISP-1 on Edge-A, ISP-2 on Edge-B) instead of a single shared circuit.

```mermaid
graph TD
  subgraph Site[Single Site Template - 1 to 2 Racks]
    subgraph Rack1[Rack 1]
      E1[Edge-A]
      E2[Edge-B]
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

    WAN[Vendor L3 Handoff\nPrivate Circuit]
    INET[Local Internet\nISP Circuit]
    MGMT[Mgmt Services VMs]
  end

  WAN -->|IPsec inter-site tunnels| E1
  WAN -->|IPsec inter-site tunnels| E2
  INET -->|Local internet breakout| E1
  INET -->|Local internet breakout| E2

  E1 --> T1
  E1 --> T2
  E2 --> T1
  E2 --> T2

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
```
