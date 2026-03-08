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
  - AWS Site A/B ingress subnets are promoted to public edge (IGW + public route table associations) when `phase4_aws_enable_ingress_internet_edge = true`.
  - AWS Site A/B: internet-facing ALB + AWS WAFv2 baseline with managed rules.
  - Health-gated target groups with optional backend IP target registration.
- Cloudflare DNS Phase 4 extension (when `phase4_enable_cloudflare_edge = true`):
  - Cloudflare CNAME records targeting Site A/B published app ALBs.
  - DNS-only by default (`proxied=false`), with optional Cloudflare proxy enablement.
  - Managed DNS record updates through Terraform (`allow_overwrite=true`).
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
- Cloudflare API token with Zone DNS edit permission (and Zone read if using `phase4_cloudflare_zone_name`) (only if Cloudflare edge is enabled)

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
- Mirror VDI images into private ECR: `scripts/invoke_phase4_vdi_ecr_image_mirror.ps1`
- Bootstrap Guacamole service on EKS VDI pools: `scripts/invoke_phase4_vdi_service_bootstrap.ps1`
- Launch admin-only VDI reactor console: `scripts/invoke_vdi_ops_console.ps1`
- Discover and cut over published app backends: `scripts/invoke_phase4_published_app_cutover.ps1`
- Discover EKS VDI node targets and cut over published app path: `scripts/invoke_phase4_vdi_eks_backend_cutover.ps1`

Examples:

```powershell
cd network-spanned-dc\iac\terraform

# Start core platform (Phase 3 + Phase 4 service onboarding).
.\scripts\invoke_dev_environment_up.ps1 `
  -AwsProfile "ddc" `
  -GcpCredentialsPath "C:\Users\<user>\.gcp\ddc-sa.json"

# Start with published app path and VDI reference stack.
.\scripts\invoke_dev_environment_up.ps1 `
  -AwsProfile "ddc" `
  -GcpCredentialsPath "C:\Users\<user>\.gcp\ddc-sa.json" `
  -EnablePublishedAppPath `
  -EnableVdiReferenceStack

# Start with published app path + Cloudflare DNS automation (DNS-only mode).
$env:CLOUDFLARE_API_TOKEN = "<cloudflare-api-token>"
.\scripts\invoke_dev_environment_up.ps1 `
  -AwsProfile "ddc" `
  -GcpCredentialsPath "C:\Users\<user>\.gcp\ddc-sa.json" `
  -EnablePublishedAppPath `
  -EnableCloudflareEdge `
  -CloudflareZoneName "slothkko.com" `
  -CloudflareSiteARecordName "app-a" `
  -CloudflareSiteBRecordName "app-b"

# Enable Phase 4 VDI stack and run worker health checks (EKS/GKE).
.\scripts\invoke_phase4_vdi_enablement.ps1 `
  -AwsProfile "ddc" `
  -GcpCredentialsPath "C:\Users\<user>\.gcp\ddc-sa.json" `
  -GcpProjectId "worldbuilder-413006" `
  -DisableGcpBrokerIdentity `
  -PreflightOnly

# Apply Phase 4 VDI stack after preflight passes.
.\scripts\invoke_phase4_vdi_enablement.ps1 `
  -AwsProfile "ddc" `
  -GcpCredentialsPath "C:\Users\<user>\.gcp\ddc-sa.json" `
  -GcpProjectId "worldbuilder-413006" `
  -DisableGcpBrokerIdentity `
  -AutoApprove

# Mirror required VDI images to private ECR in both AWS regions.
.\scripts\invoke_phase4_vdi_ecr_image_mirror.ps1 `
  -AwsProfile "ddc"

# Mirror the optional sample desktop image as well.
.\scripts\invoke_phase4_vdi_ecr_image_mirror.ps1 `
  -AwsProfile "ddc" `
  -MirrorDesktopImage

# Bootstrap Guacamole service on EKS VDI worker pools using regional private ECR images.
.\scripts\invoke_phase4_vdi_service_bootstrap.ps1 `
  -AwsProfile "ddc" `
  -UseRegionalEcrImages `
  -EcrAccountId "<AWS_ACCOUNT_ID>"

# Bootstrap sample desktop target + Guacamole connection.
.\scripts\invoke_phase4_vdi_service_bootstrap.ps1 `
  -AwsProfile "ddc" `
  -UseRegionalEcrImages `
  -UseRegionalEcrDesktopImage `
  -EnableSampleVdiDesktop `
  -DesktopConnectionName "VDI Desktop" `
  -EcrAccountId "<AWS_ACCOUNT_ID>"

# Launch the admin-only VDI reactor console (restart hung sessions, inspect processes/sessions, live map/health lights).
.\scripts\invoke_vdi_ops_console.ps1 `
  -AdminUsername "ops-admin" `
  -AdminPassword "<strong-password>" `
  -OpenBrowser

# Quota-safe apply (AWS workers only, keep GCP VDI controls but skip GCP VDI worker pools).
.\scripts\invoke_phase4_vdi_enablement.ps1 `
  -AwsProfile "ddc" `
  -GcpCredentialsPath "C:\Users\<user>\.gcp\ddc-sa.json" `
  -GcpProjectId "worldbuilder-413006" `
  -DisableGcpBrokerIdentity `
  -DisableGcpWorkerPools `
  -AutoApprove

# Enable VDI plus published app path with Cloudflare edge records.
$env:CLOUDFLARE_API_TOKEN = "<cloudflare-api-token>"
.\scripts\invoke_phase4_vdi_enablement.ps1 `
  -AwsProfile "ddc" `
  -GcpCredentialsPath "C:\Users\<user>\.gcp\ddc-sa.json" `
  -GcpProjectId "worldbuilder-413006" `
  -EnablePublishedAppPath `
  -EnablePublishedAppTls `
  -EnableCloudflareEdge `
  -CloudflareZoneName "slothkko.com" `
  -CloudflareSiteARecordName "app-a" `
  -CloudflareSiteBRecordName "app-b" `
  -CloudflareRecordProxied `
  -CloudflareRecordTtl 1 `
  -AutoApprove

# Optional: revise zone hostnames (for example admin + apex + www) in terraform.tfvars:
# phase4_cloudflare_additional_records = {
#   "admin" = "site_a"
#   "@"     = "site_a"
#   "www"   = "site_a"
# }
# phase4_site_a_published_app_tls_subject_alternative_names = ["admin", "@", "www"]

# Switch published app path from fixed-response to forward mode using explicit backend IP targets.
.\scripts\invoke_phase4_vdi_enablement.ps1 `
  -AwsProfile "ddc" `
  -GcpCredentialsPath "C:\Users\<user>\.gcp\ddc-sa.json" `
  -GcpProjectId "worldbuilder-413006" `
  -EnablePublishedAppPath `
  -SiteAPublishedAppBackendTargets @("10.10.2.45", "10.10.2.46") `
  -SiteBPublishedAppBackendTargets @("10.20.2.45", "10.20.2.46") `
  -PublishedAppBackendPort 80 `
  -PublishedAppHealthCheckPath "/healthz" `
  -PlanOnly

# Auto-discover backend targets from AWS app/data subnets and run cutover preflight.
.\scripts\invoke_phase4_published_app_cutover.ps1 `
  -AwsProfile "ddc" `
  -GcpCredentialsPath "C:\Users\<user>\.gcp\ddc-sa.json" `
  -GcpProjectId "worldbuilder-413006" `
  -PreflightOnly

# Apply auto-discovered forward-mode cutover.
.\scripts\invoke_phase4_published_app_cutover.ps1 `
  -AwsProfile "ddc" `
  -GcpCredentialsPath "C:\Users\<user>\.gcp\ddc-sa.json" `
  -GcpProjectId "worldbuilder-413006" `
  -AutoApprove

# Discover targets from EKS VDI nodegroups and run VDI-oriented preflight
# (backend_port 30080, health_path /guacamole/).
.\scripts\invoke_phase4_vdi_eks_backend_cutover.ps1 `
  -AwsProfile "ddc" `
  -GcpCredentialsPath "C:\Users\<user>\.gcp\ddc-sa.json" `
  -GcpProjectId "worldbuilder-413006" `
  -DisableGcpBrokerIdentity `
  -PreflightOnly

# Apply EKS-targeted cutover.
.\scripts\invoke_phase4_vdi_eks_backend_cutover.ps1 `
  -AwsProfile "ddc" `
  -GcpCredentialsPath "C:\Users\<user>\.gcp\ddc-sa.json" `
  -GcpProjectId "worldbuilder-413006" `
  -DisableGcpBrokerIdentity `
  -EnablePublishedAppTls `
  -EnableCloudflareEdge `
  -CloudflareZoneName "slothkko.com" `
  -CloudflareSiteARecordName "app-a" `
  -CloudflareSiteBRecordName "app-b" `
  -CloudflareRecordProxied `
  -CloudflareRecordTtl 1 `
  -AutoApprove

# Stop expensive platform resources (keeps Phase 1/2 foundation and networking).
.\scripts\invoke_dev_environment_down.ps1 `
  -AwsProfile "ddc" `
  -GcpCredentialsPath "C:\Users\<user>\.gcp\ddc-sa.json"

# Stop platform resources and suspend Phase 2 inter-cloud VPN/BGP links.
.\scripts\invoke_dev_environment_down.ps1 `
  -AwsProfile "ddc" `
  -GcpCredentialsPath "C:\Users\<user>\.gcp\ddc-sa.json" `
  -SuspendIntercloud

# Maximum savings: destroy everything managed by Terraform.
.\scripts\invoke_dev_environment_down.ps1 `
  -AwsProfile "ddc" `
  -GcpCredentialsPath "C:\Users\<user>\.gcp\ddc-sa.json" `
  -DestroyAll
```

Notes:
- `-PlanOnly` previews changes without applying.
- `-PreflightOnly` runs fail-fast checks (Terraform validate, AWS free-tier eligibility, orphan/in-flight VDI nodegroup checks) without plan/apply.
- Interactive confirmation is used by default; add `-AutoApprove` for non-interactive runs.
- Default "down" mode disables Phase 3/4/5 resources; base networking (Phase 1/2) remains and can still incur cost.
- Add `-SuspendIntercloud` to disable Phase 2 (`phase2_enable_intercloud=false`) and remove AWS/GCP VPN/BGP resources between sessions.
- `invoke_phase4_vdi_enablement.ps1` runs post-apply worker health checks unless `-SkipHealthChecks` is set.
- `invoke_phase4_vdi_enablement.ps1 -EnablePublishedAppPath` now also sets `phase4_aws_enable_ingress_internet_edge=true` and runs AWS ingress-route preflight checks.
- Use `-EnablePublishedAppTls` with Cloudflare edge to provision per-site ACM certs (DNS-validated via Cloudflare) and HTTPS listeners on the published app ALBs.
- Use `-SiteAPublishedAppBackendTargets` and `-SiteBPublishedAppBackendTargets` to override published app backend IP lists for a single pass.
- Optional overrides: `-PublishedAppBackendPort` and `-PublishedAppHealthCheckPath`.
- Cloudflare DNS controls in helper scripts:
  - `-CloudflareRecordProxied` enables orange-cloud proxy mode.
  - `-CloudflareRecordTtl` sets record TTL (`1` for automatic/proxied, or `>=60`).
- `invoke_vdi_ops_console.ps1` serves the ops panel locally (default `127.0.0.1`) and does not publish it through ALB/Cloudflare by itself.
- `invoke_phase4_vdi_ecr_image_mirror.ps1` mirrors `postgres`, `guacamole/guacd`, and `guacamole/guacamole` into regional private ECR repos for private-node pulls.
- add `-MirrorDesktopImage` to also mirror a sample VNC desktop image into `ddc-vdi-desktop`.
- `invoke_phase4_vdi_service_bootstrap.ps1` applies `iac/k8s/vdi/guacamole-nodeport.yaml` to each EKS cluster, can inject regional ECR image URIs with `-UseRegionalEcrImages`, and can rotate seed admin credentials with `-GuacAdminPassword` (or `GUACADMIN_PASSWORD` env var).
- `invoke_phase4_vdi_service_bootstrap.ps1 -EnableSampleVdiDesktop` applies `iac/k8s/vdi/vdi-desktop-vnc.yaml`, deploys `vdi-desktop` in each target cluster, and seeds a Guacamole VNC connection (`VDI Desktop` by default).
- `invoke_phase4_published_app_cutover.ps1` discovers private ENI IPs in AWS app subnets (and data subnets by default), then invokes `invoke_phase4_vdi_enablement.ps1` with discovered target lists.
- Use `-IncludeIngressSubnets:$true` if your backend ENIs live in ingress subnets.
- Use `-AllowEmptyTargets` only if you intentionally want fixed-response fallback (`503`) on one or both sites.
- `invoke_phase4_vdi_eks_backend_cutover.ps1` discovers backend targets from EKS nodegroup instances (`-NodegroupSuffix vdi` by default) and invokes `invoke_phase4_vdi_enablement.ps1` with VDI-oriented defaults (`backend_port=30080`, `health_path=/guacamole/`).
- After cutover, ALB target health can take ~30-120 seconds to transition from `unhealthy` to `healthy` while NodePort checks converge.
- Override nodegroup names with `-SiteANodegroupName` and `-SiteBNodegroupName` when naming diverges from standard suffix conventions.
- Published app preflight now validates backend target IPv4 format, detects duplicates, and warns when targets are not attached to ENIs in the site VPC.
- If no backend targets are configured, listener mode remains fixed-response (`503`) by design.
- VDI health checks are bounded by `-HealthCheckTimeoutMinutes` and polled by `-HealthCheckPollSeconds`.
- Add `-DisableGcpBrokerIdentity` when the active GCP identity cannot create service accounts.
- Use `-DisableGcpWorkerPools` (or tfvars `phase4_vdi_enable_gcp_worker_pools=false`) for quota-safe AWS-only worker rollout.
- Use `-DisableAwsWorkerPools` (or tfvars `phase4_vdi_enable_aws_worker_pools=false`) to disable AWS VDI workers in a given pass.
- Use `-SkipAwsFreeTierChecks` or `-SkipAwsExistingNodegroupChecks` only for emergency/manual workflows.
- Use `-SkipGcpQuotaChecks` only for emergency/manual workflows; preflight now checks `CPUS_ALL_REGIONS` against configured VDI GKE node pool sizing.
- Failure diagnostics are written to `evidence/phase4-vdi-diagnostics/` unless `-CollectDiagnosticsOnFailure:$false` is set.
- For Cloudflare DNS mode, export `CLOUDFLARE_API_TOKEN` before running plan/apply.
- Cloudflare DNS-only mode (`proxied=false`) with the current ALB listener (`80`) serves `http://` endpoints; `https://` is expected to time out until TLS is added.
- Cloudflare WAF is not provisioned by this Terraform layer; this integration only manages DNS records.

## GCP IAM Bootstrap

This repo includes a helper script:

- `network-spanned-dc/iac/terraform/scripts/bootstrap_gcp_permissions.ps1`

Run after installing `gcloud` and authenticating:

```powershell
gcloud auth login
.\scripts\bootstrap_gcp_permissions.ps1 `
  -ProjectId "worldbuilder-413006" `
  -ServiceAccountName "terraform-ddc" `
  -KeyOutputPath "C:\Users\<user>\.gcp\ddc-sa.json" `
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

- This baseline does not create NAT gateways; internet gateway/public ingress routing is only created when `phase4_aws_enable_ingress_internet_edge=true`.
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
  - `phase4_enable_published_app_tls` (defaults to `false`; requires Cloudflare edge for DNS validation automation)
  - `phase4_aws_enable_ingress_internet_edge` (defaults to `false`; required when `phase4_enable_published_app_path=true`)
  - `phase4_published_app_listener_port` (defaults to `80`)
  - `phase4_published_app_https_port` (defaults to `443`)
  - `phase4_published_app_tls_ssl_policy` (defaults to `ELBSecurityPolicy-TLS13-1-2-2021-06`)
  - `phase4_site_a_published_app_tls_subject_alternative_names` / `phase4_site_b_published_app_tls_subject_alternative_names`
  - `phase4_published_app_allowed_ingress_ipv4_cidrs` / `phase4_published_app_allowed_ingress_ipv6_cidrs`
  - `phase4_published_app_health_check_path`, `phase4_published_app_root_redirect_path`, and `phase4_published_app_backend_port`
  - `phase4_site_a_published_app_backend_ipv4_targets` / `phase4_site_b_published_app_backend_ipv4_targets`
  - `phase4_published_app_waf_rate_limit`
- Phase 4 Cloudflare edge controls:
  - `phase4_enable_cloudflare_edge` (defaults to `false`; requires `phase4_enable_published_app_path=true`)
  - `phase4_cloudflare_zone_id` or `phase4_cloudflare_zone_name`
  - `phase4_cloudflare_site_a_record_name` / `phase4_cloudflare_site_b_record_name`
  - `phase4_cloudflare_additional_records` (map of extra hostnames to `site_a` or `site_b`; example keys: `admin`, `www`, `@`)
  - `phase4_cloudflare_record_proxied` (defaults to `false` for DNS-only mode)
  - `phase4_cloudflare_record_ttl` (defaults to `300`; use `1` for automatic TTL when proxied)
- Phase 4 VDI reference stack controls:
  - `phase4_enable_vdi_reference_stack` (defaults to `false`; requires `phase4_enable_service_onboarding=true`)
  - `phase4_vdi_enable_aws_worker_pools` / `phase4_vdi_enable_gcp_worker_pools` for provider-scoped worker rollout
  - `phase4_vdi_aws_node_*` and `phase4_vdi_gcp_node_*` controls for dedicated VDI worker pools
  - `phase4_vdi_identity_ssm_parameter_arn_patterns` and `phase4_vdi_identity_secret_arn_patterns` for AWS broker identity policy scope
  - `phase4_vdi_aws_desktop_controlled_egress_ipv4_cidrs` / `phase4_vdi_aws_desktop_controlled_egress_ipv6_cidrs`
  - `phase4_vdi_gcp_desktop_controlled_egress_ipv4_cidrs`
  - `phase4_vdi_gcp_manage_broker_identity` (defaults to `true`; set `false` if the current GCP identity cannot create service accounts)
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
