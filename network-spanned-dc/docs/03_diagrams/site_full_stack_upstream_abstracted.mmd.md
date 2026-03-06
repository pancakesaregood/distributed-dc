# One-Site Full Stack (Upstream Abstracted)

Single-site deep-dive view of edge, zones, platform services, and data paths.
Upstream dependencies are intentionally abstracted to keep focus on the site architecture.

```mermaid
flowchart LR

  subgraph UPSTREAM[Upstream and External Dependencies - Abstracted]
    WAN[(Vendor-Managed WAN L3 Cloud)]
    PEERS[(Other Sites and Shared Services)]
    INET[(Public Internet)]
    DNSP[(Public DNS or GeoDNS)]
    PKI[(Public CA or ACME Endpoint)]
    OFFBK[(Off-Site Backup Target)]
    OFFOBS[(External Alerting or Ticketing)]
  end

  subgraph SITEA[Site A - Full Stack Detail]
    subgraph EDGE[Edge and Perimeter]
      EA["Edge-A<br/>BGP + IPsec + Internet Uplink"]
      EB["Edge-B<br/>BGP + IPsec + Internet Uplink"]
      FWA["FW-A<br/>Zone Policy + VPN"]
      FWB["FW-B<br/>Zone Policy + VPN"]
    end

    subgraph FABRIC[Local Fabric]
      TORA["ToR-A"]
      TORB["ToR-B"]
    end

    subgraph MGMT[Management Zone - :0000]
      BAST["Bastion / Jump Host"]
      MON["Prometheus + Grafana + Loki"]
      NBOX["NetBox<br/>IPAM + DCIM"]
      GITOPS["GitOps Runner"]
    end

    subgraph DMZ[DMZ Zone - :0060]
      WAF["WAF<br/>OWASP Policy"]
      NLB["nginx LB<br/>TLS Termination"]
      VPNVM["VPN VM Optional"]
    end

    subgraph SERVERS[Servers and VMs Zone - :0010]
      DC1["AD DC-01"]
      DC2["AD DC-02"]
      DHCP["DHCPv6 Server"]
      APP["App and API Services"]
      DB[("Tier 1 Database or Queue")]
      BKP["Backup Proxy or Repo"]
      GUADB[("guacamole-db")]
    end

    subgraph CONTAINERS[Containers Zone - :0020]
      GUAC["guacamole-client"]
      GUACD["guacd"]
      API["Internal Platform APIs"]
    end

    subgraph VDI[VDI Zone - :0070]
      DSK["Desktop VM Pool"]
    end

    subgraph USERS[User Segments]
      USR["User Segment - :0040"]
      IOT["IoT Segment - :0030"]
      GST["Guest Segment - :0050"]
      DNS64["DNS64 Resolver"]
      NAT64["NAT64 Gateway"]
      PAT["IPv4 PAT and Optional NPTv6"]
    end
  end

  WAN <-->|BGP + IPsec Overlay| EA
  WAN <-->|BGP + IPsec Overlay| EB
  WAN <-->|Abstract Inter-Site Paths| PEERS

  INET -->|HTTPS and VPN Ingress| EA
  INET -->|HTTPS and VPN Ingress| EB
  DNSP -->|FQDN Resolves to Site Ingress| INET
  NLB -->|ACME Challenge or Cert Renewal| PKI
  BKP -->|Encrypted Off-Site Copy| OFFBK
  MON -->|Alerts and Events| OFFOBS

  EA -->|Outside| FWA
  EA -->|Outside| FWB
  EB -->|Outside| FWA
  EB -->|Outside| FWB

  FWA -->|Inside| TORA
  FWA -->|Inside| TORB
  FWB -->|Inside| TORA
  FWB -->|Inside| TORB
  TORA --- TORB

  TORA --> BAST
  TORB --> BAST
  TORA --> MON
  TORB --> MON
  TORA --> NBOX
  TORB --> NBOX
  TORA --> GITOPS
  TORB --> GITOPS

  FWA -->|Outside to DMZ TCP 443| WAF
  WAF --> NLB
  NLB --> APP
  NLB --> GUAC

  FWA -->|VPN Termination or DNAT| VPNVM
  VPNVM -->|AD Auth + MFA Policy| DC1
  VPNVM -->|Policy-Allowed Access| APP
  VPNVM -->|Policy-Allowed Access| BAST

  USR -->|App Access| APP
  USR -->|Admin via Bastion| BAST
  IOT -->|Telemetry Only| API

  GUAC -->|Session Metadata| GUADB
  GUAC --> GUACD
  GUAC -->|AD Auth LDAPS| DC1
  GUACD -->|RDP or VNC| DSK
  DSK -->|Domain Join and GPO| DC1
  DSK -->|App Access| APP

  DHCP -->|Reservations + Options| USR
  DHCP -->|Reservations + Options| IOT
  DHCP -->|Reservations + Options| GST
  DC1 <-->|AD Replication| DC2
  APP --> DB
  API --> DB

  GST --> DNS64
  DNS64 -->|Synthesized AAAA| GST
  GST -->|IPv6 to WKP| NAT64
  NAT64 --> PAT
  PAT -->|Internet Egress| EA

  DB -->|Encrypted Replication Abstracted| WAN
  BKP -->|Backup Traffic| WAN
  GITOPS -->|Config Sync| APP
  GITOPS -->|Config Sync| WAF
  GITOPS -->|Config Sync| FWA

  GST -.Denied.-> APP
  GST -.Denied.-> BAST
  IOT -.Denied.-> BAST
```

## Notes

- This diagram is intentionally single-site and exhaustive, while WAN/internet/provider details remain abstracted.
- All east-west and north-south policy enforcement is performed by the site firewall pair.
- Local internet breakout, NAT64, and PAT/NPTv6 behavior are shown as site-local functions.
