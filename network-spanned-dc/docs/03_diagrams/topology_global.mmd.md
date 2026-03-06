# Global Topology

```mermaid
graph LR
  WAN[(Vendor-Managed WAN L3 Cloud)]

  subgraph SA[Site A]
    SAE["Edge Pair<br/>BGP + Policy"]
    SAT[ToR Pair]
    SAC["Compute Cluster<br/>VMs + Podman"]
  end

  subgraph SB[Site B]
    SBE["Edge Pair<br/>BGP + Policy"]
    SBT[ToR Pair]
    SBC["Compute Cluster<br/>VMs + Podman"]
  end

  subgraph SC[Site C]
    SCE["Edge Pair<br/>BGP + Policy"]
    SCT[ToR Pair]
    SCC["Compute Cluster<br/>VMs + Podman"]
  end

  subgraph SD[Site D]
    SDE["Edge Pair<br/>BGP + Policy"]
    SDT[ToR Pair]
    SDC["Compute Cluster<br/>VMs + Podman"]
  end

  SAE --- WAN
  SBE --- WAN
  SCE --- WAN
  SDE --- WAN

  SAE --- SAT --- SAC
  SBE --- SBT --- SBC
  SCE --- SCT --- SCC
  SDE --- SDT --- SDC

  style SA fill:#EAF4FF,stroke:#2E6DA4,stroke-width:2px,color:#111111
  style SB fill:#FFF4DB,stroke:#A56A00,stroke-width:2px,color:#111111
  style SC fill:#EAF8EF,stroke:#2F855A,stroke-width:2px,color:#111111
  style SD fill:#F2EDFF,stroke:#6B46C1,stroke-width:2px,color:#111111
```
