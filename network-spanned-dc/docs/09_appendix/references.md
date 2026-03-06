# References

This appendix lists the standards and primary technology references used across the architecture documentation set.

## Standards and Protocols

### IPv6 Addressing and Translation

- RFC 4193 - Unique Local IPv6 Unicast Addresses (ULA): https://www.rfc-editor.org/rfc/rfc4193
- RFC 4291 - IPv6 Addressing Architecture: https://www.rfc-editor.org/rfc/rfc4291
- RFC 8415 - Dynamic Host Configuration Protocol for IPv6 (DHCPv6): https://www.rfc-editor.org/rfc/rfc8415
- RFC 6052 - IPv6 Addressing of IPv4/IPv6 Translators (`64:ff9b::/96` WKP): https://www.rfc-editor.org/rfc/rfc6052
- RFC 6146 - Stateful NAT64: https://www.rfc-editor.org/rfc/rfc6146
- RFC 6147 - DNS64: https://www.rfc-editor.org/rfc/rfc6147
- RFC 6296 - IPv6-to-IPv6 Network Prefix Translation (NPTv6): https://www.rfc-editor.org/rfc/rfc6296
- RFC 8201 - Path MTU Discovery for IPv6: https://www.rfc-editor.org/rfc/rfc8201
- RFC 4443 - ICMPv6 (includes Packet Too Big signaling for PMTUD): https://www.rfc-editor.org/rfc/rfc4443

### Routing and Overlay Networking

- RFC 4271 - Border Gateway Protocol 4 (BGP-4): https://www.rfc-editor.org/rfc/rfc4271
- RFC 5925 - TCP Authentication Option (TCP-AO): https://www.rfc-editor.org/rfc/rfc5925
- RFC 2385 - TCP MD5 Signature Option (legacy BGP hardening): https://www.rfc-editor.org/rfc/rfc2385
- RFC 7432 - BGP MPLS-Based Ethernet VPN (EVPN): https://www.rfc-editor.org/rfc/rfc7432
- RFC 7348 - Virtual eXtensible Local Area Network (VXLAN): https://www.rfc-editor.org/rfc/rfc7348

### IPsec and IKEv2

- RFC 4301 - Security Architecture for IPsec: https://www.rfc-editor.org/rfc/rfc4301
- RFC 4303 - IP Encapsulating Security Payload (ESP): https://www.rfc-editor.org/rfc/rfc4303
- RFC 7296 - Internet Key Exchange Protocol Version 2 (IKEv2): https://www.rfc-editor.org/rfc/rfc7296
- RFC 3947 - Negotiation of NAT Traversal in IKE: https://www.rfc-editor.org/rfc/rfc3947
- RFC 3948 - UDP Encapsulation of IPsec ESP Packets: https://www.rfc-editor.org/rfc/rfc3948

### TLS and HTTP Security

- RFC 8446 - TLS 1.3: https://www.rfc-editor.org/rfc/rfc8446
- RFC 6797 - HTTP Strict Transport Security (HSTS): https://www.rfc-editor.org/rfc/rfc6797

## Open Source Project References

### Routing, Overlay, and Translation

- FRRouting: https://frrouting.org
- Open vSwitch: https://www.openvswitch.org
- strongSwan: https://www.strongswan.org
- Jool NAT64/DNS64: https://nicmx.github.io/Jool

### Firewall and VPN Platform Candidates

- OPNsense: https://opnsense.org
- pfSense CE: https://www.pfsense.org
- VyOS: https://vyos.io
- WireGuard: https://www.wireguard.com
- OpenVPN: https://openvpn.net

### Published Application Components

- NGINX: https://nginx.org
- ModSecurity: https://modsecurity.org
- OWASP Core Rule Set: https://coreruleset.org
- Let's Encrypt: https://letsencrypt.org
- Certbot: https://certbot.eff.org

### VDI and Remote Access

- Apache Guacamole: https://guacamole.apache.org
- XRDP: https://www.xrdp.org

### Compute and Platform Services

- Linux KVM: https://linux-kvm.org
- libvirt: https://libvirt.org
- Podman: https://podman.io
- PostgreSQL: https://www.postgresql.org

### Observability and Source of Truth

- Prometheus: https://prometheus.io
- Grafana: https://grafana.com
- Loki: https://grafana.com/oss/loki
- OpenSearch: https://opensearch.org
- NetBox: https://netbox.dev
- MkDocs: https://www.mkdocs.org
