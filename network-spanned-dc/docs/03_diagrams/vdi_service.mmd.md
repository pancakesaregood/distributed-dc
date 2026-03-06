# VDI Service Architecture

## Full Access Path

Shows how a user browser session reaches a desktop VM through the open-source Guacamole stack, and how desktop VMs interact with backend services and identity.

```mermaid
graph LR

  subgraph CLIENTS[Client Access]
    BRW["Browser<br/>Internal User or VPN User<br/>HTTPS - no client needed"]
  end

  subgraph DMZ[DMZ Zone]
    WAF["WAF<br/>OWASP inspection"]
    LB["nginx LB<br/>TLS termination<br/>Load balances Guacamole"]
  end

  subgraph CTR[Containers Zone]
    GC["guacamole-client<br/>HTML5 session broker<br/>AD + MFA auth"]
    GUACD["guacd<br/>RDP / VNC / SSH proxy"]
  end

  subgraph SRV[Servers and VMs Zone]
    GDB[("guacamole-db<br/>PostgreSQL<br/>Sessions + connections")]
    DC["AD Domain Controller<br/>LDAPS auth + group policy"]
    APP["Application Services<br/>Permitted by AD group"]
  end

  subgraph VDI[VDI Segment - 0070]
    DVM1["Desktop VM<br/>Linux + XRDP or Windows RDP<br/>Persistent or Pooled"]
    DVM2["Desktop VM<br/>Linux + XRDP or Windows RDP<br/>Persistent or Pooled"]
    DVM3["Desktop VM<br/>Linux + XRDP or Windows RDP<br/>Persistent or Pooled"]
  end

  BRW -->|HTTPS| WAF
  WAF -->|Filtered| LB
  LB -->|Proxy to Guacamole| GC
  GC -->|AD LDAPS - MFA| DC
  GC -->|Session config| GDB
  GC -->|Guacamole protocol| GUACD
  GUACD -->|RDP 3389 or VNC 5900| DVM1
  GUACD -->|RDP 3389 or VNC 5900| DVM2
  GUACD -->|RDP 3389 or VNC 5900| DVM3
  DVM1 -->|AD domain join + GPO| DC
  DVM2 -->|AD domain join + GPO| DC
  DVM1 -->|App access per AD group| APP
  DVM2 -->|App access per AD group| APP
  linkStyle default color:#CC5500
```

## Multi-Site Spanning

Each site runs its own Guacamole stack and local desktop VM pool. Session database replicates cross-site for failover.

```mermaid
graph TD

  subgraph SA[Site A]
    GCA["guacamole-client A<br/>guacd A"]
    GDBA[("guacamole-db A<br/>Primary")]
    VDIA["Desktop VM Pool A<br/>fdca:fcaf:e000:0070::/64"]
  end

  subgraph SB[Site B]
    GCB["guacamole-client B<br/>guacd B"]
    GDBB[("guacamole-db B<br/>Replica")]
    VDIB["Desktop VM Pool B<br/>fdca:fcaf:e100:0070::/64"]
  end

  subgraph SC[Site C]
    GCC["guacamole-client C<br/>guacd C"]
    GDBC[("guacamole-db C<br/>Replica")]
    VDIC["Desktop VM Pool C<br/>fdca:fcaf:e200:0070::/64"]
  end

  subgraph SD[Site D]
    GCD["guacamole-client D<br/>guacd D"]
    GDBD[("guacamole-db D<br/>Replica")]
    VDID["Desktop VM Pool D<br/>fdca:fcaf:e300:0070::/64"]
  end

  GDBA <-->|"DB replication - IPsec encrypted WAN tunnel"| GDBB
  GDBA <-->|"DB replication - IPsec encrypted WAN tunnel"| GDBC
  GDBA <-->|"DB replication - IPsec encrypted WAN tunnel"| GDBD

  GCA --> VDIA
  GCB --> VDIB
  GCC --> VDIC
  GCD --> VDID

  style SA fill:#EAF4FF,stroke:#2E6DA4,stroke-width:2px,color:#111111
  style SB fill:#FFF4DB,stroke:#A56A00,stroke-width:2px,color:#111111
  style SC fill:#EAF8EF,stroke:#2F855A,stroke-width:2px,color:#111111
  style SD fill:#F2EDFF,stroke:#6B46C1,stroke-width:2px,color:#111111
  linkStyle default color:#CC5500
```

## Protocol Stack

```mermaid
graph TD
  subgraph USER[User Side]
    BR["Web Browser<br/>Any OS - no agent"]
  end

  subgraph GUA[Guacamole Stack - Containers Zone]
    direction TB
    CL["guacamole-client<br/>HTML5 over WebSocket - HTTPS"]
    GD["guacd<br/>Guacamole protocol to RDP/VNC/SSH"]
  end

  subgraph DESK[VDI Zone]
    direction TB
    XRDP["XRDP or Windows RDP<br/>Desktop VM"]
  end

  BR -->|"HTTPS WebSocket - TLS 1.3"| CL
  CL -->|"Guacamole protocol - internal"| GD
  GD -->|"RDP 3389 or VNC 5900 - VDI segment only"| XRDP
  linkStyle default color:#CC5500
```

## Firewall Zone Policy Summary

```mermaid
graph LR

  LB2["nginx LB<br/>DMZ"]
  GC2["guacamole-client<br/>Containers"]
  GD2["guacd<br/>Containers"]
  VDI2["Desktop VMs<br/>VDI Zone - 0070"]
  SRV2["App Services<br/>Servers and VMs"]
  MGMT2["Management<br/>Denied"]
  DC2["AD DC<br/>Servers and VMs"]

  LB2 -->|443 to Guacamole| GC2
  GC2 -->|Internal| GD2
  GD2 -->|RDP 3389 - VNC 5900| VDI2
  VDI2 -->|App ports per AD group| SRV2
  VDI2 -->|LDAPS 636| DC2
  VDI2 -.Denied.-> MGMT2
  linkStyle default color:#CC5500
```
