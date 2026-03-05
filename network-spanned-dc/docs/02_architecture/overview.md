# Architecture Overview

## Executive Summary
This design defines a low-cost, four-site spanned datacenter architecture that prioritizes fault isolation, operational simplicity, and open-source tooling. Each site is an independent failure domain with local compute and network control planes. Sites are interconnected over a vendor-managed Layer 3 WAN handoff, and service continuity across sites is achieved through routing and data replication rather than Layer 2 extension. Each site includes a dedicated vendor-agnostic stateful firewall pair that enforces zone policy and terminates remote access VPN, providing a clear inside/outside security boundary between the routed edge and internal segments.

## Core Design Principles
- Layer 3 between sites.
- No stretched Layer 2 between sites.
- All inter-site traffic is encrypted in transit. Site edge pairs terminate IPsec tunnels over the WAN; private WAN circuits provide network-layer isolation, and the IPsec overlay provides defense-in-depth encryption regardless of WAN provider trust assumptions.
- Failure domains are bounded per site.
- Spanning services use replication and deterministic failover.
- Open-source platforms are preferred when they meet support and operational requirements.
- Automation and Git-backed change control are default practices.

## Constraints
- Budget-sensitive architecture with low recurring licensing overhead.
- WAN transport is abstracted as a vendor-managed L3 service.
- Each site has an independent local internet connection. Internet traffic breaks out locally and is never backhauled over the inter-site WAN.
- One designated site has a redundant internet edge: dual ISP circuits, each terminating on a separate edge node, providing full edge and ISP redundancy for internet egress. All other sites use a single ISP circuit presented across both edge nodes.
- Site design assumes 1 to 2 racks per location.
- Compute platform must support VMs and Podman containers.

## High-Level Architecture
- Per site: edge pair (L3 router), firewall pair (FW-A / FW-B), ToR pair, compute cluster, local backup target, and independent internet connection.
- Traffic path inbound: edge pair → firewall outside interface → firewall inside interface → ToR → internal segments.
- Inter-site: prefix-based routing with BGP as primary exchange method. BGP sessions and all data-plane traffic run over IPsec-encrypted tunnels between site edge pairs.
- Remote access VPN: inbound VPN connections arrive at the edge, are forwarded to the firewall outside interface, and terminate on the firewall appliance or a dedicated VPN VM. Authenticated clients are granted access to internal zones per group policy. Reachable via `vpn.example.com`.
- Internet egress: each site breaks out internet traffic locally through the site edge pair. Guest traffic is policy-routed to the local internet L3 interface and is blocked from entering the inter-site WAN.
- Data resiliency: local fast restore plus cross-site replicated copies. All cross-site replication traffic is encrypted via the IPsec inter-site tunnels.
- Optional global anycast for DNS and internal ingress endpoints.

## Design Outcome
The resulting architecture is scalable from four to additional sites with minimal redesign, because routing policies, addressing, and service classes are standardized and independent of specific WAN circuit implementations.
