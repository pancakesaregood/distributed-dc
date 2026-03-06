# WAN Transport Abstraction Diagram

Shows the two supported transport modes for inter-site IPsec tunnels. The IPsec overlay and all internal architecture are identical in both modes. Only the underlay transport differs.

## Mode Comparison

```mermaid
graph TD

  subgraph OVERLAY[IPsec Overlay - Common to Both Modes]
    direction LR
    EA["Edge-A / Edge-B<br/>Site A"]
    EB["Edge-A / Edge-B<br/>Site B"]
    EA <-->|"IKEv2 - AES-256-GCM - PFS<br/>Full-mesh IPsec tunnel"| EB
  end

  subgraph MODEA[Mode A - Private Circuit]
    direction LR
    PA["Site A Edge<br/>IPv6 or IPv4 handoff"]
    MPLS["Vendor L3 Private Circuit<br/>MPLS or equivalent<br/>Logically isolated path"]
    PB["Site B Edge<br/>IPv6 or IPv4 handoff"]
    PA --- MPLS --- PB
  end

  subgraph MODEB[Mode B - Consumer IPv4 Internet]
    direction LR
    CA["Site A Edge<br/>Static public IPv4"]
    ISP["Public IPv4 Internet<br/>Best-effort path<br/>ESP passthrough required"]
    CB["Site B Edge<br/>Static public IPv4"]
    CA --- ISP --- CB
  end

  MODEA -->|"Underlay carries<br/>IPsec ESP packets"| OVERLAY
  MODEB -->|"Underlay carries<br/>IPsec ESP over IPv4<br/>NAT-T UDP 4500 if behind NAT"| OVERLAY
```

## Protocol Stack per Mode

```mermaid
graph TD

  subgraph STACKA[Mode A - Private Circuit Stack]
    direction TB
    A4["IPv6 ULA payload<br/>Internal traffic"]
    A3["IPsec ESP<br/>AES-256-GCM encrypted"]
    A2["IPv6 or IPv4 outer header<br/>Private circuit handoff addresses"]
    A1["Private L2 circuit<br/>Vendor-managed"]
    A4 --> A3 --> A2 --> A1
  end

  subgraph STACKB[Mode B - Consumer IPv4 Stack]
    direction TB
    B4["IPv6 ULA payload<br/>Internal traffic"]
    B3["IPsec ESP<br/>AES-256-GCM encrypted"]
    B2["IPv4 outer header<br/>Static public IPv4 per edge"]
    B1["Consumer IPv4 internet<br/>Best-effort - ESP or UDP 4500 passthrough"]
    B4 --> B3 --> B2 --> B1
  end
```

## Per-Site-Pair Tunnel Detail

Each site pair maintains four independent IPsec tunnels — two matched-pair and two cross-connect. All four are held established at all times.

```mermaid
graph LR

  subgraph SA[Site A]
    SAA["Edge-A"]
    SAB["Edge-B"]
  end

  subgraph SB[Site B]
    SBA["Edge-A"]
    SBB["Edge-B"]
  end

  SAA <-->|"A-A tunnel - primary<br/>BGP primary session"| SBA
  SAB <-->|"B-B tunnel - secondary<br/>BGP secondary session"| SBB
  SAA <-->|"A-B cross-connect<br/>traffic only"| SBB
  SAB <-->|"B-A cross-connect<br/>traffic only"| SBA
```

With 4 sites (6 site pairs) × 4 tunnels each = **24 tunnels total** in the full fabric.

## Full-Mesh Multi-Tunnel View

All edge nodes shown explicitly. Each line represents one IPsec tunnel.

```mermaid
graph LR

  subgraph SA[Site A]
    SAED_A["Edge-A"]
    SAED_B["Edge-B"]
  end

  subgraph SB[Site B]
    SBED_A["Edge-A"]
    SBED_B["Edge-B"]
  end

  subgraph SC[Site C]
    SCED_A["Edge-A"]
    SCED_B["Edge-B"]
  end

  subgraph SD[Site D]
    SDED_A["Edge-A"]
    SDED_B["Edge-B"]
  end

  SAED_A <--> SBED_A
  SAED_A <--> SBED_B
  SAED_B <--> SBED_A
  SAED_B <--> SBED_B

  SAED_A <--> SCED_A
  SAED_A <--> SCED_B
  SAED_B <--> SCED_A
  SAED_B <--> SCED_B

  SAED_A <--> SDED_A
  SAED_A <--> SDED_B
  SAED_B <--> SDED_A
  SAED_B <--> SDED_B

  SBED_A <--> SCED_A
  SBED_A <--> SCED_B
  SBED_B <--> SCED_A
  SBED_B <--> SCED_B

  SBED_A <--> SDED_A
  SBED_A <--> SDED_B
  SBED_B <--> SDED_A
  SBED_B <--> SDED_B

  SCED_A <--> SDED_A
  SCED_A <--> SDED_B
  SCED_B <--> SDED_A
  SCED_B <--> SDED_B
```

## Mixed-Mode Full-Mesh Example

Sites can run different transport modes simultaneously. The 4-tunnel-per-pair model applies regardless of transport mode.

```mermaid
graph LR

  subgraph SA[Site A - Mode A]
    MA_A["Edge-A<br/>Private circuit"]
    MA_B["Edge-B<br/>Private circuit"]
  end

  subgraph SB[Site B - Mode A]
    MB_A["Edge-A<br/>Private circuit"]
    MB_B["Edge-B<br/>Private circuit"]
  end

  subgraph SC[Site C - Mode B]
    MC_A["Edge-A<br/>Static public IPv4"]
    MC_B["Edge-B<br/>Static public IPv4"]
  end

  subgraph SD[Site D - Mode B]
    MD_A["Edge-A<br/>Static public IPv4"]
    MD_B["Edge-B<br/>Static public IPv4"]
  end

  MA_A <-->|"Mode A - 4 tunnels"| MB_A
  MA_A <-->|"Mode A"| MB_B
  MA_B <-->|"Mode A"| MB_A
  MA_B <-->|"Mode A"| MB_B

  MA_A <-->|"Mode B - 4 tunnels"| MC_A
  MA_A <-->|"Mode B"| MC_B
  MA_B <-->|"Mode B"| MC_A
  MA_B <-->|"Mode B"| MC_B

  MA_A <-->|"Mode B - 4 tunnels"| MD_A
  MA_A <-->|"Mode B"| MD_B
  MA_B <-->|"Mode B"| MD_A
  MA_B <-->|"Mode B"| MD_B

  MB_A <-->|"Mode B - 4 tunnels"| MC_A
  MB_A <-->|"Mode B"| MC_B
  MB_B <-->|"Mode B"| MC_A
  MB_B <-->|"Mode B"| MC_B

  MB_A <-->|"Mode B - 4 tunnels"| MD_A
  MB_A <-->|"Mode B"| MD_B
  MB_B <-->|"Mode B"| MD_A
  MB_B <-->|"Mode B"| MD_B

  MC_A <-->|"Mode B - 4 tunnels"| MD_A
  MC_A <-->|"Mode B"| MD_B
  MC_B <-->|"Mode B"| MD_A
  MC_B <-->|"Mode B"| MD_B
```

All tunnels carry IPsec AES-256-GCM with IKEv2 regardless of the underlay. IPv6 ULA routes are reachable from every site through any tunnel mode.

## Key Parameters

| Parameter | Mode A | Mode B |
|---|---|---|
| Outer protocol | IPv6 or IPv4 (provider handoff) | IPv4 (static public address) |
| ESP passthrough | Native | Required (protocol 50 or UDP 4500) |
| NAT-T | Not required | Required if behind NAT or CGN |
| Inner MTU | Provider-confirmed (aim 1400+) | ~1400 bytes (1500 minus IPv4+ESP overhead) |
| Reliability | Carrier SLA | Best-effort |
| Underlay isolation | Private circuit + IPsec | IPsec only |
