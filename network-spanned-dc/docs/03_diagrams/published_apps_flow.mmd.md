# Published Application Diagrams

## Single-Site Traffic Flow

Inbound internet request reaching a published app at one site, traversing the full DMZ stack.

```mermaid
graph TD

  INET["Internet Client<br/>External user or bot"]
  DNS["Public DNS<br/>app.example.com → site edge IP"]

  subgraph SITE[Site - Single Publishing Site]
    EDGE["Edge Router<br/>Internet interface<br/>Public IP"]

    subgraph FW[Firewall Pair - FW-A and FW-B]
      FWDMZ["DMZ Rule<br/>Outside → DMZ - TCP 443 only"]
    end

    subgraph DMZ[DMZ Zone]
      WAF["WAF<br/>OWASP Top 10 + app rules<br/>Blocking mode"]
      LB["nginx LB<br/>TLS termination<br/>Upstream pool + health checks"]
    end

    subgraph SRV[Servers and VMs Zone]
      APP1["App Backend 1<br/>Stateless"]
      APP2["App Backend 2<br/>Stateless"]
      DB[("Database<br/>Stateful - if required")]
    end
  end

  INET -->|1 DNS lookup| DNS
  DNS -->|2 Resolves to edge IP| INET
  INET -->|3 HTTPS TCP 443| EDGE
  EDGE -->|4 Forwarded to FW outside| FWDMZ
  FWDMZ -->|5 DMZ rule permits 443| WAF
  WAF -->|6 Inspected - OWASP passed| LB
  LB -->|7 TLS terminated - proxied to backend| APP1
  LB -->|7 or load balanced to| APP2
  APP1 -->|8 DB read/write if needed| DB
  APP2 -->|8 DB read/write if needed| DB
  linkStyle default color:#CC5500
```

## Multi-Site Anycast Flow

Stateless app published at multiple sites behind a shared anycast ingress VIP. BGP selects the nearest site.

```mermaid
graph LR

  INET["Internet Client"]
  ANYDNS["Public DNS<br/>app.example.com → anycast VIP /128"]
  ANYING["Anycast VIP /128<br/>BGP-advertised from all active sites"]

  subgraph SA[Site A]
    EA["Edge-A or Edge-B<br/>Advertises anycast VIP"]
    subgraph DMZA[DMZ - Site A]
      WAFA["WAF A"]
      LBA["nginx LB A<br/>upstream-app pool"]
    end
    APPA["App Backend A<br/>Stateless"]
  end

  subgraph SB[Site B]
    EB["Edge-A or Edge-B<br/>Advertises anycast VIP"]
    subgraph DMZB[DMZ - Site B]
      WAFB["WAF B"]
      LBB["nginx LB B<br/>upstream-app pool"]
    end
    APPB["App Backend B<br/>Stateless"]
  end

  HEALTHA["Health daemon - Site A<br/>Withdraws VIP if backends down"]
  HEALTHB["Health daemon - Site B<br/>Withdraws VIP if backends down"]

  INET -->|DNS lookup| ANYDNS
  ANYDNS -->|Returns anycast VIP| INET
  INET -->|HTTPS to anycast VIP| ANYING
  ANYING -->|BGP nearest path| EA
  ANYING -->|BGP nearest path| EB

  EA --> WAFA --> LBA --> APPA
  EB --> WAFB --> LBB --> APPB

  HEALTHA -->|Health gate| EA
  HEALTHB -->|Health gate| EB

  style SA fill:#EAF4FF,stroke:#2E6DA4,stroke-width:2px,color:#111111
  style DMZA fill:#EAF4FF,stroke:#2E6DA4,stroke-width:2px,color:#111111
  style SB fill:#FFF4DB,stroke:#A56A00,stroke-width:2px,color:#111111
  style DMZB fill:#FFF4DB,stroke:#A56A00,stroke-width:2px,color:#111111
  linkStyle default color:#CC5500
```

## Multi-Site GeoDNS Flow

Alternative to anycast. DNS provider returns the nearest site's IP based on client geography.

```mermaid
graph LR

  INET["Internet Client"]
  GEODNS["GeoDNS Provider<br/>app.example.com<br/>Returns nearest site IP<br/>Health-gated per site"]

  subgraph SA[Site A - Region 1]
    IPA["Edge public IP - Site A"]
    subgraph DMZGA[DMZ - Site A]
      WAFGA["WAF A"]
      LBGA["nginx LB A"]
    end
    APPGA["App Backend A"]
  end

  subgraph SB[Site B - Region 2]
    IPB["Edge public IP - Site B"]
    subgraph DMZGB[DMZ - Site B]
      WAFGB["WAF B"]
      LBGB["nginx LB B"]
    end
    APPGB["App Backend B"]
  end

  INET -->|DNS lookup| GEODNS
  GEODNS -->|Returns site A IP if nearest and healthy| INET
  INET -->|HTTPS| IPA
  IPA --> WAFGA --> LBGA --> APPGA

  GEODNS -->|Returns site B IP for region 2 clients| INET
  INET -->|HTTPS| IPB
  IPB --> WAFGB --> LBGB --> APPGB

  style SA fill:#EAF4FF,stroke:#2E6DA4,stroke-width:2px,color:#111111
  style DMZGA fill:#EAF4FF,stroke:#2E6DA4,stroke-width:2px,color:#111111
  style SB fill:#FFF4DB,stroke:#A56A00,stroke-width:2px,color:#111111
  style DMZGB fill:#FFF4DB,stroke:#A56A00,stroke-width:2px,color:#111111
  linkStyle default color:#CC5500
```

## App Publish Workflow

Steps from request to live service. All configuration changes flow through GitOps — no manual changes on production systems.

```mermaid
flowchart TD

  REQ["App Publish Request<br/>FQDN - backend IPs - port<br/>TLS cert source - WAF exceptions"]
  REVIEW["Architecture Review<br/>Confirm tier - spanning model<br/>DNS strategy - site assignment"]

  subgraph GITOPS[GitOps PRs - all in parallel]
    PR1["nginx upstream + server block<br/>TLS cert reference"]
    PR2["WAF profile<br/>Base OWASP + app rules"]
    PR3["Firewall DMZ rule<br/>Outside to DMZ TCP 443<br/>DMZ to backend app port"]
    PR4["TLS certificate<br/>Provisioned via certbot or CA<br/>Stored in secrets manager"]
  end

  MERGE["All PRs reviewed and merged<br/>Automation applies to staging"]
  STAGING["Staging Validation<br/>HTTPS reachable + correct cert<br/>HSTS header present<br/>WAF blocks test injection payload<br/>nginx upstream health green<br/>FW denies non-443 ports"]

  STAGING_PASS{Pass?}

  DNS["Public DNS Cutover<br/>Low TTL during cutover<br/>Point FQDN to edge IP or anycast VIP"]
  SMOKE["Production Smoke Test<br/>External HTTPS check<br/>Cert valid - app responds<br/>WAF event log active"]
  MONITOR["Monitoring Active<br/>nginx access log flowing<br/>WAF event log flowing<br/>Error rate and latency alerts set"]

  FAIL["Fix and re-validate<br/>Update GitOps PR<br/>Re-run staging"]

  REQ --> REVIEW
  REVIEW --> GITOPS
  PR1 & PR2 & PR3 & PR4 --> MERGE
  MERGE --> STAGING
  STAGING --> STAGING_PASS
  STAGING_PASS -->|Yes| DNS
  STAGING_PASS -->|No| FAIL
  FAIL --> GITOPS
  DNS --> SMOKE
  SMOKE --> MONITOR
  linkStyle default color:#CC5500
```

## Full-Stack App with Stateful DB

Stateless frontend published externally, write DB single-site, read replicas at secondary sites.

```mermaid
graph LR

  INET2["Internet Client"]

  subgraph SA2[Site A - Primary]
    subgraph DMZSA2[DMZ]
      WAFP["WAF"]
      LBP["nginx LB"]
    end
    APPP["App Frontend<br/>Stateless"]
    DBP[("DB Primary<br/>Accepts writes")]
  end

  subgraph SB2[Site B - Secondary]
    subgraph DMZSB2[DMZ]
      WAFR["WAF"]
      LBR["nginx LB"]
    end
    APPR["App Frontend<br/>Stateless"]
    DBR[("DB Replica<br/>Read only")]
  end

  INET2 -->|HTTPS - nearest site| WAFP
  WAFP --> LBP --> APPP
  APPP -->|Writes| DBP

  INET2 -->|HTTPS - nearest site| WAFR
  WAFR --> LBR --> APPR
  APPR -->|Reads from replica| DBR

  DBP <-->|"Replication - IPsec encrypted WAN tunnel"| DBR

  style SA2 fill:#EAF4FF,stroke:#2E6DA4,stroke-width:2px,color:#111111
  style DMZSA2 fill:#EAF4FF,stroke:#2E6DA4,stroke-width:2px,color:#111111
  style SB2 fill:#FFF4DB,stroke:#A56A00,stroke-width:2px,color:#111111
  style DMZSB2 fill:#FFF4DB,stroke:#A56A00,stroke-width:2px,color:#111111
  linkStyle default color:#CC5500
```
