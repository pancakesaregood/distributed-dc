# DHCP and Active Directory Services

AD Domain Controllers run as dedicated VMs on the hypervisor cluster at each site.
DHCP VMs serve DHCPv6 reservations to infrastructure clients within each site.
Clients and servers authenticate against the local DC first; cross-site DC access is available over IPsec-encrypted WAN tunnels for resilience.

```mermaid
graph TD

  subgraph SA[Site A]
    subgraph ADSA[AD VMs - Servers Segment fdca:fcaf:e000:0010::/64]
      DCA1["DC-A-01<br/>Domain Controller<br/>PDC Emulator"]
      DCA2["DC-A-02<br/>Domain Controller"]
    end
    DHCPA["DHCP-A VM<br/>Servers Segment"]
    CLTA["Clients and Servers<br/>Site A"]
  end

  subgraph SB[Site B]
    subgraph ADSB[AD VMs - Servers Segment fdca:fcaf:e100:0010::/64]
      DCB1["DC-B-01<br/>Domain Controller"]
    end
    DHCPB["DHCP-B VM<br/>Servers Segment"]
    CLTB["Clients and Servers<br/>Site B"]
  end

  subgraph SC[Site C]
    subgraph ADSC[AD VMs - Servers Segment fdca:fcaf:e200:0010::/64]
      DCC1["DC-C-01<br/>Domain Controller"]
    end
    DHCPC["DHCP-C VM<br/>Servers Segment"]
    CLTC["Clients and Servers<br/>Site C"]
  end

  subgraph SD[Site D]
    subgraph ADSD[AD VMs - Servers Segment fdca:fcaf:e300:0010::/64]
      DCD1["DC-D-01<br/>Domain Controller"]
    end
    DHCPD["DHCP-D VM<br/>Servers Segment"]
    CLTD["Clients and Servers<br/>Site D"]
  end

  DCA1 <-->|AD Replication over IPsec-encrypted WAN tunnel| DCB1
  DCA1 <-->|AD Replication over IPsec-encrypted WAN tunnel| DCC1
  DCA1 <-->|AD Replication over IPsec-encrypted WAN tunnel| DCD1
  DCB1 <-->|AD Replication over IPsec-encrypted WAN tunnel| DCC1
  DCB1 <-->|AD Replication over IPsec-encrypted WAN tunnel| DCD1
  DCC1 <-->|AD Replication over IPsec-encrypted WAN tunnel| DCD1

  DHCPA -->|DHCPv6 Lease| CLTA
  DHCPB -->|DHCPv6 Lease| CLTB
  DHCPC -->|DHCPv6 Lease| CLTC
  DHCPD -->|DHCPv6 Lease| CLTD

  CLTA -->|Auth + Group Policy - Local-first| DCA1
  CLTB -->|Auth + Group Policy - Local-first| DCB1
  CLTC -->|Auth + Group Policy - Local-first| DCC1
  CLTD -->|Auth + Group Policy - Local-first| DCD1
```

## Design Notes

- Site A runs two AD DCs for quorum and FSMO role resilience (PDC Emulator on DC-A-01).
- Sites B, C, and D each run one DC; add a second DC per site to match Site A redundancy if capacity allows.
- All DC VMs are placed in the Servers/VMs segment (`:0010`) at each site, consistent with the IPv6 addressing plan.
- DHCP VMs issue DHCPv6 reservations rather than dynamic SLAAC, per the addressing plan guidance.
- AD replication topology is full-mesh across all four sites. All replication traffic is encrypted inside IPsec tunnels between site edge pairs; it does not traverse the WAN in plaintext.
- Local DC is the preferred authentication target; cross-site DC fallback is available if the local DC is unreachable.
- AD VMs are classified as Tier 1 Stateful services under the services spanning model.
