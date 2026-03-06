# BGP Routing and Prefix Advertisement

```mermaid
graph TD
  WAN[(Vendor-Managed WAN)]

  A["Site A Edge<br/>Advertise fdca:fcaf:e000::/56"]
  B["Site B Edge<br/>Advertise fdca:fcaf:e100::/56"]
  C["Site C Edge<br/>Advertise fdca:fcaf:e200::/56"]
  D["Site D Edge<br/>Advertise fdca:fcaf:e300::/56"]

  ANYA[Site A Anycast /128]
  ANYB[Site B Anycast /128]
  ANYC[Site C Anycast /128]
  ANYD[Site D Anycast /128]

  A <--> WAN
  B <--> WAN
  C <--> WAN
  D <--> WAN

  ANYA --> A
  ANYB --> B
  ANYC --> C
  ANYD --> D

  FALLBACK["Static Route Fallback<br/>Used only during BGP outage"]
  FALLBACK -.-> A
  FALLBACK -.-> B
  FALLBACK -.-> C
  FALLBACK -.-> D

  classDef siteA fill:#EAF4FF,stroke:#2E6DA4,stroke-width:2px,color:#111111;
  classDef siteB fill:#FFF4DB,stroke:#A56A00,stroke-width:2px,color:#111111;
  classDef siteC fill:#EAF8EF,stroke:#2F855A,stroke-width:2px,color:#111111;
  classDef siteD fill:#F2EDFF,stroke:#6B46C1,stroke-width:2px,color:#111111;

  class A,ANYA siteA
  class B,ANYB siteB
  class C,ANYC siteC
  class D,ANYD siteD
  linkStyle default color:#CC5500
```
