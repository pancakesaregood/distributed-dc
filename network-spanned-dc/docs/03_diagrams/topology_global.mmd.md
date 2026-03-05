# Global Topology

```mermaid
graph LR
  WAN[(Vendor-Managed WAN L3 Cloud)]

  subgraph SA[Site A]
    SAE[Edge Pair]\nBGP + Policy
    SAT[ToR Pair]
    SAC[Compute Cluster]\nVMs + Podman
  end

  subgraph SB[Site B]
    SBE[Edge Pair]\nBGP + Policy
    SBT[ToR Pair]
    SBC[Compute Cluster]\nVMs + Podman
  end

  subgraph SC[Site C]
    SCE[Edge Pair]\nBGP + Policy
    SCT[ToR Pair]
    SCC[Compute Cluster]\nVMs + Podman
  end

  subgraph SD[Site D]
    SDE[Edge Pair]\nBGP + Policy
    SDT[ToR Pair]
    SDC[Compute Cluster]\nVMs + Podman
  end

  SAE --- WAN
  SBE --- WAN
  SCE --- WAN
  SDE --- WAN

  SAE --- SAT --- SAC
  SBE --- SBT --- SBC
  SCE --- SCT --- SCC
  SDE --- SDT --- SDC
```
