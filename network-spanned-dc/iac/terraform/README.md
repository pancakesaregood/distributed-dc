# Terraform Scaffold - Dual-Cloud 4-Site Baseline

This scaffold implements the foundational network layer for the dual-cloud proposal:

- Site A (AWS `us-east-1`)
- Site B (AWS `us-west-2`)
- Site C (GCP `us-east4`)
- Site D (GCP `us-west1`)

It is intentionally phased:

- Phase 1 in code now: per-site network boundaries and subnet baselines.
- Phase 2 next: inter-cloud VPN/BGP links and route policy automation.
- Phase 3 next: EKS/GKE platform clusters and service onboarding.

## What This Creates

- AWS:
  - One VPC per site with generated IPv6 CIDR.
  - Ingress/App/Data subnets across two AZs per site (dual-stack).
- GCP:
  - One VPC network per site.
  - Ingress/App/Data subnets per site.
  - IPv6-enabled subnets when `gcp_enable_ipv6 = true`.

## Prerequisites

- Terraform `>= 1.6`
- AWS credentials with permissions for VPC/subnet resources in both target regions
- GCP credentials with permissions for VPC/subnet resources in target project

## Quick Start

```bash
cd network-spanned-dc/iac/terraform
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars
terraform init
terraform plan
```

## Notes

- This baseline does not yet create NAT, internet gateways, firewall policies, EKS/GKE clusters, or VPN/BGP links.
- The logical site IPv6 ULA plan from architecture docs is preserved as metadata in variables and can be used by overlay or service-level routing design.
- AWS VPC IPv6 ranges are provider-allocated unless you integrate IPAM/BYOIP.
