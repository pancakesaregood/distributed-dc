# Client and Service Interactions

Shows how each client type enters the environment, onboards through platform services, passes through the site firewall, and reaches permitted application services. Applies per-site and for VPN-connected remote users.

```mermaid
graph LR

  subgraph CLIENTS[Client Types]
    CU["Internal User<br/>User Segment :0030"]
    CA["Admin User<br/>Mgmt Segment :0000"]
    CR["Remote User<br/>VPN via vpn.example.com"]
    CG["Guest User<br/>Guest Segment :0050"]
    CI["IoT Device<br/>IoT Segment :0040"]
  end

  subgraph ONBOARD[Client Onboarding - Platform Services]
    DHCP["DHCP VM<br/>DHCPv6 Address Lease"]
    DNS["DNS Resolver<br/>Name Resolution"]
    AD["AD Domain Controller<br/>Authentication + Group Policy"]
  end

  FW["Firewall<br/>FW-A / FW-B<br/>Zone Policy Enforcement"]

  subgraph DMZZ[DMZ Zone]
    WAF["WAF<br/>Web Application Firewall"]
    LB["nginx LB<br/>Load Balancer"]
  end

  subgraph APPS[Application and Infrastructure Services]
    WEB["Web Frontend<br/>Tier 1 Stateless"]
    API["Internal API<br/>Tier 1 Stateless"]
    CTR["Container Services<br/>Podman"]
    DB[("Database<br/>Tier 1 Stateful")]
    MGMTS["Management + Monitoring<br/>Admin only"]
  end

  L3OUT["Local Internet<br/>L3 Interface"]
  INT[(Internet)]

  %% Internal user onboarding
  CU -->|1 DHCPv6 lease| DHCP
  CU -->|2 Name resolution| DNS
  CU -->|3 Authenticate| AD
  CU -->|4 User zone| FW

  %% Admin user onboarding
  CA -->|1 DHCPv6 lease| DHCP
  CA -->|2 Name resolution| DNS
  CA -->|3 Authenticate| AD
  CA -->|4 Mgmt zone| FW

  %% Remote user via VPN
  CR -->|vpn.example.com| FW
  FW -->|AD auth + MFA| AD

  %% IoT
  CI -->|IoT zone - telemetry only| FW

  %% Guest - local internet breakout only
  CG -->|Internet only - no WAN backhaul| L3OUT
  L3OUT --> INT

  %% Inbound internet-facing traffic routed through DMZ
  FW -->|HTTPS inbound - DMZ rule| WAF
  WAF -->|Filtered requests| LB
  LB -->|Web backend| WEB
  LB -->|API backend| API

  %% Internal clients permitted directly by firewall zone policy
  FW -->|User + VPN default group| WEB
  FW -->|User + VPN default group| API
  FW -->|Admin + VPN admin group| MGMTS
  FW -->|IoT restricted| API

  %% Service dependencies
  WEB --> DB
  API --> DB
  API --> CTR
  linkStyle default color:#CC5500
```

## Client Access Summary

| Client Type | Entry Point | Onboarding | Permitted Services |
|---|---|---|---|
| Internal User | User segment direct | DHCP, DNS, AD auth | Web frontend, Internal API |
| Admin User | Mgmt segment direct | DHCP, DNS, AD auth | All services including Management |
| Remote User (VPN) | `vpn.example.com` + MFA | AD auth at FW | Web frontend, Internal API (default); Management if admin group |
| Guest User | Guest segment | None | Internet only via local L3 breakout |
| IoT Device | IoT segment | None | Internal API telemetry endpoint only |

## Onboarding Sequence for Internal Clients

1. **DHCP** — Client receives a DHCPv6 address reservation from the site DHCP VM. Address is in the appropriate segment for the client type.
2. **DNS** — Client resolves service FQDNs against the local DNS resolver. Resolver is reachable via anycast or site-local address.
3. **AD Authentication** — Client authenticates against the site AD domain controller. Group membership is evaluated and passed to the firewall for zone policy decisions.
4. **Service Access** — Firewall permits traffic based on zone and AD group. All flows are statefully inspected.

## Inbound Internet Path (DMZ)

Internet-facing requests (e.g., from Remote Users before VPN, or published services accessed externally) follow this path:

1. **Firewall Outside** — Firewall receives inbound HTTPS and applies DMZ zone rule. Non-HTTPS internet traffic is dropped.
2. **WAF** — Request is inspected for OWASP Top 10 threats. Blocked requests are dropped and logged. Permitted requests are forwarded to the nginx LB.
3. **nginx LB** — Terminates TLS and distributes the request to a healthy backend instance in the Servers/VMs zone. Backend health is continuously checked.
4. **Backend Service** — Web frontend or Internal API receives the proxied request from the nginx LB inside address.
