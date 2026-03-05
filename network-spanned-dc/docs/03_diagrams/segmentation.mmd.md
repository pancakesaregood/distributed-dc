# Segmentation and Allowed Flows

```mermaid
graph LR
  MGMT[Management]
  SRV[Servers and VMs]
  CTR[Containers]
  USR[User]
  IOT[IoT]
  GST[Guest]
  DMZ[DMZ]
  INT[(Internet or External Services)]
  L3OUT[Local L3 Internet\nInterface at Edge]

  USR -->|Admin + App Access| SRV
  SRV -->|Service Calls| CTR
  DMZ -->|Published App Ports| SRV
  MGMT -->|Privileged Admin| SRV
  MGMT -->|Privileged Admin| CTR
  IOT -->|Telemetry Only| SRV
  GST -->|Local breakout only\nno WAN backhaul| L3OUT
  L3OUT --> INT
  SRV -->|Controlled egress\nDNS NTP packages| L3OUT
  DMZ -->|Controlled egress| L3OUT

  GST -.Denied.-> SRV
  GST -.Denied.-> MGMT
  GST -.Blocked from WAN tunnels.-> SRV
  IOT -.Denied.-> MGMT
  USR -.Restricted.-> IOT
```
