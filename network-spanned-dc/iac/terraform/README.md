# Terraform Scaffold - Dual-Cloud 4-Site Baseline

This scaffold implements the foundational network layer for the dual-cloud proposal:

- Site A (AWS `us-east-1`)
- Site B (AWS `us-west-2`)
- Site C (GCP `us-east4`)
- Site D (GCP `us-west1`)

It is intentionally phased:

- Phase 1 in code now: per-site network boundaries and subnet baselines.
- Phase 2 in code now: AWS<->GCP VPN/BGP links and route policy automation.
- Phase 3 in code now: optional EKS/GKE control-plane baseline.
- Phase 4 in code now: optional worker-capacity onboarding for EKS/GKE.
- Phase 5 in code now: resilience evidence capture and handover tracking flags.

## What This Creates

- AWS:
  - One VPC per site with generated IPv6 CIDR.
  - Ingress/App/Data subnets across two AZs per site (dual-stack).
- GCP:
  - One VPC network per site.
  - Ingress/App/Data subnets per site.
  - IPv6-enabled subnets when `gcp_enable_ipv6 = true`.
- Inter-cloud Phase 2:
  - AWS virtual private gateway per AWS site VPC.
  - Four inter-cloud pair definitions: `A-C`, `A-D`, `B-C`, `B-D`.
  - Per pair: GCP HA VPN gateway + Cloud Router, one AWS customer gateway, one AWS VPN connection, two BGP tunnels.
  - Route preference policy via Cloud Router peer priority:
    - Primary pairs (`A-C`, `B-D`): `100`
    - Cross/failover pairs (`A-D`, `B-C`): `200`
- Platform Phase 3 (when `phase3_enable_platform = true`):
  - AWS Site A/B: one EKS control plane per site in app subnets.
  - GCP Site C/D: one regional GKE cluster per site with default node pool removed.
- Service Onboarding Phase 4 (when `phase4_enable_service_onboarding = true`):
  - AWS Site A/B: one managed EKS node group per site.
  - GCP Site C/D: one managed GKE node pool per site.
- Phase 5 operations pack:
  - Evidence capture script: `scripts/invoke_phase5_evidence_capture.ps1`
  - Generated artifacts: health snapshots, summary markdown, execution record template.

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

## GCP IAM Bootstrap

This repo includes a helper script:

- `network-spanned-dc/iac/terraform/scripts/bootstrap_gcp_permissions.ps1`

Run after installing `gcloud` and authenticating:

```powershell
gcloud auth login
.\scripts\bootstrap_gcp_permissions.ps1 `
  -ProjectId "worldbuilder-413006" `
  -ServiceAccountName "terraform-ddc" `
  -KeyOutputPath "C:\Users\john\.gcp\ddc-sa.json" `
  -EnableGkeRoles
```

Role scope by phase:

- Phase 1 (network baseline):
  - `roles/compute.networkAdmin`
  - `roles/compute.securityAdmin`
- Phase 3 (GKE baseline, optional now):
  - `roles/container.admin`
  - `roles/iam.serviceAccountUser`

Bootstrap user requirements (one-time, human account):

- `roles/serviceusage.serviceUsageAdmin`
- `roles/iam.serviceAccountAdmin`
- `roles/iam.serviceAccountKeyAdmin`
- `roles/resourcemanager.projectIamAdmin`

## Notes

- This baseline does not yet create NAT, internet gateways, firewall policies, published app path resources, or VDI stack resources.
- EKS/GKE control planes are optional and gated by `phase3_enable_platform`.
- Worker capacity is optional and gated by `phase4_enable_service_onboarding` (requires Phase 3).
- Phase 5 deliverable tracking flags are available:
  - `phase5_enable_resilience_validation`
  - `phase5_enable_backup_restore_drills`
  - `phase5_enable_handover_signoff`
- The logical site IPv6 ULA plan from architecture docs is preserved as metadata in variables and can be used by overlay or service-level routing design.
- AWS VPC IPv6 ranges are provider-allocated unless you integrate IPAM/BYOIP.
- For production, set a unique `phase2_secret_seed` or replace deterministic tunnel PSK handling with a managed secret workflow.
- Ensure `container.googleapis.com` is enabled in the GCP project before running Phase 3.
