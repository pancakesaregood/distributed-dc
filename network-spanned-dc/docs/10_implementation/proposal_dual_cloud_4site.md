# Dual-Cloud Four-Site Proposal (AWS + GCP)

## Proposal Status
- Draft version: `0.1`
- Draft date: `2026-03-06`
- Scope: Public cloud extension of the four-site spanned architecture model

## Decision Statement
Implement a four-site, dual-cloud deployment with two AWS regions and two GCP regions, preserving core architecture principles:
- Layer 3 between sites.
- No stretched Layer 2 between sites.
- Explicit failover via routing and service health policy.
- Service spanning through replication and controlled promotion.

## Reference Site Map (Concrete Draft)

| Site | Cloud | Region | Regional Fault Domains | Primary Role |
|---|---|---|---|---|
| Site A | AWS | `us-east-1` | Multi-AZ | East primary application site |
| Site B | AWS | `us-west-2` | Multi-AZ | West AWS peer and DR target |
| Site C | GCP | `us-east4` | Multi-zone | East secondary cloud and failover site |
| Site D | GCP | `us-west1` | Multi-zone | West GCP peer and DR target |

Notes:
- This region set is a US-focused starting point for latency and operations.
- Final region selection must be validated against data residency, compliance, and user latency.

## Per-Site Baseline
- One workload network boundary per site (`VPC` in AWS, dedicated `VPC network` in GCP).
- Three-tier subnet model per site: ingress, application, data/management.
- Kubernetes plus VM support:
  - AWS sites: `EKS` + VM workloads on `EC2`.
  - GCP sites: `GKE` + VM workloads on `Compute Engine`.
- Local internet breakout and local egress controls at each site.

## Connectivity and Routing Model

### Intra-Cloud Site Connectivity
- AWS Site A to Site B:
  - `Transit Gateway` in each AWS region.
  - Inter-region `Transit Gateway peering`.
  - Route tables advertise only approved site summary prefixes.
- GCP Site C to Site D:
  - Dedicated VPC per site.
  - `HA VPN` + `Cloud Router` (BGP) between C and D.
  - Four tunnels (`2x2`) for resilient east-west cloud pathing.

### Inter-Cloud Connectivity (AWS <-> GCP)
- Connect each AWS site to each GCP site (A-C, A-D, B-C, B-D).
- For each AWS-GCP site pair:
  - One BGP VPN set for IPv4 payload routing (2 tunnels).
  - One BGP VPN set for IPv6 payload routing (2 tunnels), where feature parity is available in both ends.
- Target total inter-cloud tunnel count for this draft: `16` tunnels.
- Routing policy:
  - Preferred east path: A-C.
  - Preferred west path: B-D.
  - Cross paths A-D and B-C as policy failover paths with lower preference.

### Prefix Advertisement Policy
- Keep per-site route advertisements summarized.
- IPv6 site summaries:
  - Site A: `fdca:fcaf:e000::/56`
  - Site B: `fdca:fcaf:e100::/56`
  - Site C: `fdca:fcaf:e200::/56`
  - Site D: `fdca:fcaf:e300::/56`
- IPv4 fallback summaries (draft):
  - Site A: `10.10.0.0/20`
  - Site B: `10.20.0.0/20`
  - Site C: `10.30.0.0/20`
  - Site D: `10.40.0.0/20`

## IPv6 Strategy
- Run dual-stack workloads where service support is mature.
- Prefer native IPv6 east-west and north-south traffic paths.
- Keep IPv4 for compatibility paths where managed services are not yet IPv6-complete.
- For internet egress:
  - IPv6-native services egress directly with policy filtering.
  - IPv4-only destinations use NAT policy paths (`NAT Gateway`/`Cloud NAT` and application-level translation as needed).

## Service Placement Model

| Service Class | Placement Pattern | Failover Pattern |
|---|---|---|
| Tier 1 Stateless | Active-active on all four sites | DNS and health-based traffic steering |
| Tier 1 Stateful | Domain-based write primary per geography with cross-cloud replicas | Controlled promotion to designated standby site |
| Tier 2 Platform | Active-standby by cloud pair (A<->C, B<->D) | Manual or runbook-driven promotion |
| Local-Only | Single site only | No cross-site failover requirement |

Stateful guidance:
- Avoid global synchronous writes across all four sites.
- Use asynchronous cross-region and cross-cloud replication unless measured latency justifies synchronous pairing for a specific service.

## Ingress and Traffic Steering
- Public ingress:
  - Global DNS with health checks and policy routing (`latency` + `failover`).
  - Regional L7 load balancers per site (AWS ALB/NLB, GCP Global/Regional LB as needed).
- Internal ingress:
  - Per-cloud internal load balancing.
  - Service discovery synchronized via GitOps-managed records and health policies.

## Failure Behavior (Target)

| Failure Event | Expected Behavior | Manual Action |
|---|---|---|
| Single AZ/zone failure in a site | Workloads reschedule within region | None |
| Full site failure (A, B, C, or D) | Route withdrawal plus DNS weight shift to surviving sites | Optional capacity tuning |
| East inter-cloud link failure (A-C) | Cross-path A-D/B-C takes traffic | None |
| Full AWS control-plane outage in one region | Workloads continue on other AWS region and GCP pair | Data-service promotion if needed |
| Full cloud-provider regional outage | Surviving provider and remaining regions continue service based on tier policy | Runbook-based stateful promotion |

## Security and Operations Baseline
- End-to-end encryption in transit (`IPsec` for inter-cloud links, `TLS` for service traffic).
- Cloud-native KMS in each provider with key ownership policy and rotation.
- Identity federation for admin and CI/CD access with MFA.
- Centralized logs/metrics/traces with provider-local buffering and cross-cloud export.
- GitOps-managed infrastructure and application manifests with peer review.

## Delivery Plan (Draft)

### Phase 0 - Architecture Decisions (2 weeks)
- Confirm region list, compliance boundaries, and service tier mapping.
- Confirm DNS authority and certificate management model.

### Phase 1 - Per-Cloud Foundations (4-6 weeks)
- Build Site A/B on AWS and Site C/D on GCP.
- Deploy baseline EKS/GKE clusters and VM landing zones.

### Phase 2 - Cross-Site Networking (3-4 weeks)
- Bring up AWS TGW peering and GCP HA VPN pair.
- Bring up AWS-GCP VPN/BGP connections with route filters.
- Validate IPv6 and IPv4 route propagation and failover.

### Phase 3 - Service Onboarding (4-8 weeks)
- Onboard tiered reference workloads.
- Implement runbook-driven stateful failover and restoration.

### Phase 4 - Resilience Certification (3-4 weeks)
- Execute game-day tests for site, path, and provider failure scenarios.
- Record evidence against RTO/RPO targets and close gaps.

## Implementation Artifacts in This Repository
- Terraform root: `network-spanned-dc/iac/terraform`
- AWS site module: `network-spanned-dc/iac/terraform/modules/aws_site`
- GCP site module: `network-spanned-dc/iac/terraform/modules/gcp_site`
- Example variable file: `network-spanned-dc/iac/terraform/terraform.tfvars.example`

Current build scope:
- Phase 1 baseline network resources for all four sites.
- Dual-stack network intent (IPv6 where provider features permit).
- Inter-cloud path policy matrix captured as Terraform outputs for next-phase VPN/BGP implementation.

## Acceptance Criteria for This Use Case
- All four sites are active with tested connectivity and policy controls.
- Tier 1 stateless services pass active-active failover tests across both clouds.
- Tier 1 stateful services pass controlled promotion tests across cloud boundaries.
- IPv6 data paths are validated for selected services; IPv4 fallback paths are validated where IPv6 is not yet available.
- DR test evidence is attached to the implementation record.

## Open Decisions
- Authoritative DNS operating model (single-provider vs dual-provider).
- Cross-cloud data replication tooling per stateful service.
- Cost guardrails for inter-cloud egress and replication traffic.
- Final selection of services that must be IPv6-first at go-live.

## Related Diagram
- [Dual-Cloud 4-Site Topology](../03_diagrams/dual_cloud_4site_topology.mmd.md)
