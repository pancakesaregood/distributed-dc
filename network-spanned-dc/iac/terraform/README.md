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
  - Ingress/App/Data/VDI subnets across two AZs per site (dual-stack).
- GCP:
  - One VPC network per site.
  - Ingress/App/Data/VDI subnets per site.
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
- Published App Path Phase 4 extension (when `phase4_enable_published_app_path = true`):
  - AWS Site A/B: internet-facing ALB + AWS WAFv2 baseline with managed rules.
  - Health-gated target groups with optional backend IP target registration.
- VDI Reference Stack Phase 4 extension (when `phase4_enable_vdi_reference_stack = true`):
  - AWS Site A/B: VDI broker and desktop security-group policy boundaries, broker IAM role/profile, and dedicated EKS VDI node groups.
  - GCP Site C/D: VDI firewall policy controls, broker service-account IAM bindings, and dedicated GKE VDI node pools.
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

## Dev Session Lifecycle Scripts

Use these PowerShell helpers to reduce costs between dev sessions:

- Bring environment up: `scripts/invoke_dev_environment_up.ps1`
- Bring environment down: `scripts/invoke_dev_environment_down.ps1`
- Enable and verify VDI stack: `scripts/invoke_phase4_vdi_enablement.ps1`

Examples:

```powershell
cd network-spanned-dc\iac\terraform

# Start core platform (Phase 3 + Phase 4 service onboarding).
.\scripts\invoke_dev_environment_up.ps1 `
  -AwsProfile "ddc" `
  -GcpCredentialsPath "C:\Users\john\.gcp\ddc-sa.json"

# Start with published app path and VDI reference stack.
.\scripts\invoke_dev_environment_up.ps1 `
  -AwsProfile "ddc" `
  -GcpCredentialsPath "C:\Users\john\.gcp\ddc-sa.json" `
  -EnablePublishedAppPath `
  -EnableVdiReferenceStack

# Enable Phase 4 VDI stack and run worker health checks (EKS/GKE).
.\scripts\invoke_phase4_vdi_enablement.ps1 `
  -AwsProfile "ddc" `
  -GcpCredentialsPath "C:\Users\john\.gcp\ddc-sa.json" `
  -GcpProjectId "worldbuilder-413006" `
  -AutoApprove

# Stop expensive platform resources (keeps Phase 1/2 foundation and networking).
.\scripts\invoke_dev_environment_down.ps1 `
  -AwsProfile "ddc" `
  -GcpCredentialsPath "C:\Users\john\.gcp\ddc-sa.json"

# Stop platform resources and suspend Phase 2 inter-cloud VPN/BGP links.
.\scripts\invoke_dev_environment_down.ps1 `
  -AwsProfile "ddc" `
  -GcpCredentialsPath "C:\Users\john\.gcp\ddc-sa.json" `
  -SuspendIntercloud

# Maximum savings: destroy everything managed by Terraform.
.\scripts\invoke_dev_environment_down.ps1 `
  -AwsProfile "ddc" `
  -GcpCredentialsPath "C:\Users\john\.gcp\ddc-sa.json" `
  -DestroyAll
```

Notes:
- `-PlanOnly` previews changes without applying.
- Interactive confirmation is used by default; add `-AutoApprove` for non-interactive runs.
- Default "down" mode disables Phase 3/4/5 resources; base networking (Phase 1/2) remains and can still incur cost.
- Add `-SuspendIntercloud` to disable Phase 2 (`phase2_enable_intercloud=false`) and remove AWS/GCP VPN/BGP resources between sessions.
- `invoke_phase4_vdi_enablement.ps1` runs post-apply worker health checks unless `-SkipHealthChecks` is set.

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

- This baseline does not yet create NAT, internet gateways, or full site firewall policy resources.
- EKS/GKE control planes are optional and gated by `phase3_enable_platform`.
- Worker capacity is optional and gated by `phase4_enable_service_onboarding` (requires Phase 3).
- Phase 4 worker hardening controls:
  - `phase4_aws_enable_ssm_managed_instance_core` (defaults to `false`)
  - `phase4_aws_enable_private_service_endpoints` (defaults to `true`; creates EC2/EKS/STS/ECR/S3 private endpoints)
  - `phase4_gcp_node_oauth_scopes` (defaults to logging/monitoring/storage-read scopes)
  - `phase4_gcp_node_disable_legacy_metadata_endpoints` (defaults to `true`)
  - `phase4_gcp_node_enable_secure_boot` (defaults to `true`)
  - `phase4_gcp_node_enable_integrity_monitoring` (defaults to `true`)
  - `phase4_gcp_node_workload_metadata_mode` (defaults to `GCE_METADATA`; use `GKE_METADATA` only when Workload Identity is enabled)
- Phase 4 published app path controls:
  - `phase4_enable_published_app_path` (defaults to `false`; requires `phase4_enable_service_onboarding=true`)
  - `phase4_published_app_listener_port` (defaults to `80`)
  - `phase4_published_app_allowed_ingress_ipv4_cidrs` / `phase4_published_app_allowed_ingress_ipv6_cidrs`
  - `phase4_published_app_health_check_path` and `phase4_published_app_backend_port`
  - `phase4_site_a_published_app_backend_ipv4_targets` / `phase4_site_b_published_app_backend_ipv4_targets`
  - `phase4_published_app_waf_rate_limit`
- Phase 4 VDI reference stack controls:
  - `phase4_enable_vdi_reference_stack` (defaults to `false`; requires `phase4_enable_service_onboarding=true`)
  - `phase4_vdi_aws_node_*` and `phase4_vdi_gcp_node_*` controls for dedicated VDI worker pools
  - `phase4_vdi_identity_ssm_parameter_arn_patterns` and `phase4_vdi_identity_secret_arn_patterns` for AWS broker identity policy scope
  - `phase4_vdi_aws_desktop_controlled_egress_ipv4_cidrs` / `phase4_vdi_aws_desktop_controlled_egress_ipv6_cidrs`
  - `phase4_vdi_gcp_desktop_controlled_egress_ipv4_cidrs`
- Phase 3 API hardening controls:
  - `phase3_aws_endpoint_private_access`
  - `phase3_aws_public_access_cidrs`
  - `phase3_gcp_master_authorized_networks`
- Phase 5 deliverable tracking flags are available:
  - `phase5_enable_resilience_validation`
  - `phase5_enable_backup_restore_drills`
  - `phase5_enable_handover_signoff`
- The logical site IPv6 ULA plan from architecture docs is preserved as metadata in variables and can be used by overlay or service-level routing design.
- AWS VPC IPv6 ranges are provider-allocated unless you integrate IPAM/BYOIP.
- Phase 2 inter-cloud links are controlled by `phase2_enable_intercloud` (defaults to `true`).
- For production, set a unique `phase2_secret_seed` or replace deterministic tunnel PSK handling with a managed secret workflow.
- Ensure `container.googleapis.com` is enabled in the GCP project before running Phase 3.
