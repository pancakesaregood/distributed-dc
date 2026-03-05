# Architecture Overview

## Executive Summary
This design defines a low-cost, four-site spanned datacenter architecture that prioritizes fault isolation, operational simplicity, and open-source tooling. Each site is an independent failure domain with local compute and network control planes. Sites are interconnected over a vendor-managed Layer 3 WAN handoff, and service continuity across sites is achieved through routing and data replication rather than Layer 2 extension.

## Core Design Principles
- Layer 3 between sites.
- No stretched Layer 2 between sites.
- Failure domains are bounded per site.
- Spanning services use replication and deterministic failover.
- Open-source platforms are preferred when they meet support and operational requirements.
- Automation and Git-backed change control are default practices.

## Constraints
- Budget-sensitive architecture with low recurring licensing overhead.
- WAN transport is abstracted as a vendor-managed L3 service.
- Site design assumes 1 to 2 racks per location.
- Compute platform must support VMs and Podman containers.

## High-Level Architecture
- Per site: edge pair, ToR pair, compute cluster, and local backup target.
- Inter-site: prefix-based routing with BGP as primary exchange method.
- Data resiliency: local fast restore plus cross-site replicated copies.
- Optional global anycast for DNS and internal ingress endpoints.

## Design Outcome
The resulting architecture is scalable from four to additional sites with minimal redesign, because routing policies, addressing, and service classes are standardized and independent of specific WAN circuit implementations.
