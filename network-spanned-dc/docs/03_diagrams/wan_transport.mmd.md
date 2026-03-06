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

## Mixed-Mode Full-Mesh Example

Sites can run different transport modes simultaneously. All remain in the same IPsec overlay.

```mermaid
graph LR

  subgraph SA[Site A]
    EAA["Edge pair<br/>Private circuit + internet"]
  end

  subgraph SB[Site B]
    EBB["Edge pair<br/>Private circuit + internet"]
  end

  subgraph SC[Site C]
    ECC["Edge pair<br/>Consumer IPv4 only"]
  end

  subgraph SD[Site D]
    EDD["Edge pair<br/>Consumer IPv4 only"]
  end

  EAA <-->|"Mode A<br/>Private circuit"| EBB
  EAA <-->|"Mode B<br/>Consumer IPv4"| ECC
  EAA <-->|"Mode B<br/>Consumer IPv4"| EDD
  EBB <-->|"Mode B<br/>Consumer IPv4"| ECC
  EBB <-->|"Mode B<br/>Consumer IPv4"| EDD
  ECC <-->|"Mode B<br/>Consumer IPv4"| EDD
```

All tunnels above carry IPsec AES-256-GCM with IKEv2 regardless of the underlay. IPv6 ULA routes are reachable from every site through any tunnel mode.

## Key Parameters

| Parameter | Mode A | Mode B |
|---|---|---|
| Outer protocol | IPv6 or IPv4 (provider handoff) | IPv4 (static public address) |
| ESP passthrough | Native | Required (protocol 50 or UDP 4500) |
| NAT-T | Not required | Required if behind NAT or CGN |
| Inner MTU | Provider-confirmed (aim 1400+) | ~1400 bytes (1500 minus IPv4+ESP overhead) |
| Reliability | Carrier SLA | Best-effort |
| Underlay isolation | Private circuit + IPsec | IPsec only |
