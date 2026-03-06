# Segmentation and Allowed Flows

All zone enforcement is performed by FW-A / FW-B. Default deny between all zones.

```mermaid
graph LR
  OUTSIDE["Outside - Edge Router Side"]
  VPN["VPN Zone<br/>Authenticated Sessions"]
  MGMT[Management]
  SRV[Servers and VMs]
  CTR[Containers]
  USR[User]
  IOT[IoT]
  GST[Guest]
  DNS64["DNS64 Resolver<br/>Synthesizes AAAA for IPv4-only hosts"]
  NAT64["NAT64 Gateway<br/>IPv6 ULA to IPv4 translation<br/>WKP 64:ff9b::/96"]
  PAT["IPv4 PAT - Masquerade<br/>Edge internet interface"]
  INT[(Internet)]
  L3OUT["Local L3 Internet<br/>Interface at Edge"]

  subgraph DMZ[DMZ Zone]
    WAF["WAF<br/>Web Application Firewall"]
    LB["nginx LB<br/>Load Balancer"]
    VPNVM["VPN VM<br/>Optional"]
  end

  OUTSIDE -->|VPN handshake - AD auth + MFA| VPN
  OUTSIDE -->|HTTPS inbound - published services| WAF
  VPN -->|Per AD group policy| MGMT
  VPN -->|Per AD group policy| SRV
  VPN -->|Per AD group policy| USR

  WAF -->|Filtered HTTP/HTTPS| LB
  LB -->|Published app ports| SRV
  LB -->|Internal API ports| CTR

  USR -->|Admin + App Access| SRV
  SRV -->|Service Calls| CTR
  MGMT -->|Privileged Admin| SRV
  MGMT -->|Privileged Admin| CTR
  IOT -->|Telemetry Only| SRV
  GST -->|DNS query| DNS64
  DNS64 -->|Synthesized AAAA - 64:ff9b::/96| GST
  GST -->|IPv6 to 64:ff9b::/96| NAT64
  NAT64 -->|Translated IPv4| PAT
  PAT -->|Masqueraded IPv4| L3OUT
  L3OUT --> INT
  SRV -->|Controlled egress - DNS/NTP/packages| L3OUT
  LB -->|Controlled egress| L3OUT

  GST -.Denied.-> SRV
  GST -.Denied.-> MGMT
  GST -.Blocked from WAN tunnels.-> OUTSIDE
  IOT -.Denied.-> MGMT
  USR -.Restricted.-> IOT
  VPN -.Denied without policy.-> MGMT
```
