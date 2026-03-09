# Session Notes - Resume Guide

## Current State (2026-03-07)
- Docs are building and published to GitHub Pages.
- Terraform Phase 1, Phase 2, Phase 3, and Phase 4 service onboarding are applied and converged.
- Phase 2 inter-cloud resources are now toggleable with `phase2_enable_intercloud` (default `true`).
- Terraform Phase 4 worker hardening is active:
  - AWS private service endpoints (`ec2`, `eks`, `sts`, `ecr.api`, `ecr.dkr`, `s3`) are deployed in Site A and Site B VPCs.
  - GKE node metadata mode is pinned to `GCE_METADATA` for non-Workload-Identity clusters.
- Terraform Phase 4 published app path scaffold is now in code (gated, not applied):
  - AWS Site A/B ALB + WAF baseline with health-gated target groups.
  - Dry-run check: `terraform plan -var "phase4_enable_published_app_path=true"` succeeds and proposes `12` creates.
- Terraform Phase 4 VDI reference stack scaffold is now in code (gated, not applied):
  - Dedicated VDI subnet tier exists per site (AWS and GCP).
  - AWS Site A/B VDI policy controls: broker/desktop security groups and broker IAM instance profile.
  - GCP Site C/D VDI policy controls: broker/desktop firewall controls and broker service-account IAM bindings.
  - Dedicated VDI worker pools are defined for both providers (EKS node groups and GKE node pools).
  - Dry-run check: `terraform plan -var "phase4_enable_vdi_reference_stack=true"` proposes `70` adds and `2` in-place updates.
- Terraform Phase 5 resilience-validation pack is in code and evidence capture has been executed.
- Phase 3 API access hardening iteration is applied:
  - EKS API endpoints: `endpoint_private_access=true`, public CIDRs restricted to `<REDACTED_PUBLIC_CIDR>`.
  - GKE control planes: `master_authorized_networks` enabled with `<REDACTED_PUBLIC_CIDR>` (`operator-workstation`).
- Drift check:
  - `terraform plan` returns `No changes`.
- Local service account key is valid:
  - `C:\Users\<user>\.gcp\ddc-sa.json` length is greater than `0`.

## Deployed Network IDs
- AWS Site A VPC: `vpc-08fb1c45a4dcd2e37`
- AWS Site B VPC: `vpc-09195c6c0e649d508`
- AWS Site A VPN gateway: `vgw-01eff2094d8281d4d`
- AWS Site B VPN gateway: `vgw-0967b88e3cb390241`
- GCP Site C network: `ddc-proposal-site-c-vpc`
- GCP Site D network: `ddc-proposal-site-d-vpc`

## Phase 2 Result
- Inter-cloud pairs deployed:
  - `A-C` priority `100`
  - `B-D` priority `100`
  - `A-D` priority `200`
  - `B-C` priority `200`
- GCP tunnel status:
  - `8` tunnels total
  - all `ESTABLISHED`

## Important Quota Note
- Project quota `VPN_TUNNELS` is currently `10` globally.
- Terraform design was adjusted to `2 tunnels per pair` (total `8`) to stay within quota.
- If you need `4 tunnels per pair` (total `16`), request a quota increase before reworking the module.

## Phase 3 Result
- AWS EKS control planes:
  - Site A: `ddc-proposal-site-a-eks` (`ACTIVE`, version `1.35`)
  - Site B: `ddc-proposal-site-b-eks` (`ACTIVE`, version `1.35`)
- EKS API access posture:
  - Site A and Site B private endpoint access enabled.
  - Site A and Site B public API CIDRs restricted to `<REDACTED_PUBLIC_CIDR>`.
- GCP GKE clusters:
  - Site C: `ddc-proposal-site-c-gke` (`RUNNING`, version `1.34.3-gke.1444000`)
  - Site D: `ddc-proposal-site-d-gke` (`RUNNING`, version `1.34.3-gke.1444000`)
- GKE API access posture:
  - Site C and Site D master authorized networks enabled with `<REDACTED_PUBLIC_CIDR>`.
- Design intent:
  - control planes deployed and hardened
  - Phase 3 remains optional via `phase3_enable_platform`

## Important API Note
- `container.googleapis.com` must be enabled in project `worldbuilder-413006`.
- Do not manage that API with `google_project_service` under the current service account:
  - it can apply, but later refresh/plan can fail if `cloudresourcemanager.googleapis.com` is unavailable to that identity.
- Keep API enablement as a one-time bootstrap/admin step.

## Quick Health Check Commands
Run in a fresh PowerShell:

```powershell
gcloud version
aws --version
terraform version
```

Validate identity and tunnel health:

```powershell
gcloud auth list --format="table(account,status)"
aws sts get-caller-identity --profile ddc
gcloud compute vpn-tunnels list --project worldbuilder-413006 --format="table(name,region,status)"
```

Validate Kubernetes control planes:

```powershell
aws eks describe-cluster --name ddc-proposal-site-a-eks --region us-east-1 --profile ddc --query "cluster.{name:name,status:status,version:version}" --output table
aws eks describe-cluster --name ddc-proposal-site-b-eks --region us-west-2 --profile ddc --query "cluster.{name:name,status:status,version:version}" --output table
gcloud container clusters list --project worldbuilder-413006 --format="table(name,location,status,currentMasterVersion)"
```

## Terraform Re-Run Sequence
```powershell
cd e:\distributed-dc\network-spanned-dc\iac\terraform
$env:GOOGLE_APPLICATION_CREDENTIALS="C:\Users\<user>\.gcp\ddc-sa.json"
$env:AWS_PROFILE="ddc"
terraform init
terraform plan -var "phase3_enable_platform=true"
```

Expected now: no pending changes.

## Phase 4 Result
- EKS worker nodegroups:
  - Site A: `ddc-proposal-site-a-ng-general` (`ACTIVE`)
  - Site B: `ddc-proposal-site-b-ng-general` (`ACTIVE`)
- GKE node pools:
  - Site C: `ddc-proposal-site-c-pool-general` (`RUNNING`, autoscaling `1..2`)
  - Site D: `ddc-proposal-site-d-pool-general` (`RUNNING`, autoscaling `1..2`)
- Source-material Phase 4 flags:
  - `phase4_enable_service_onboarding = true`
  - `phase4_enable_published_app_path = false`
  - `phase4_enable_vdi_reference_stack = false`

## Phase 5 Runtime Status
- Evidence capture script:
  - `scripts/invoke_phase5_evidence_capture.ps1`
- Latest artifact pointer:
  - `evidence/phase5-latest.txt`
- Latest evidence run:
  - `evidence/phase5-20260307-021747`
  - Metrics snapshot:
    - AWS VPN `available`: `4/4`
    - GCP VPN `ESTABLISHED`: `8/8`
    - EKS `ACTIVE`: `2/2`
    - GKE `RUNNING`: `2/2`

## Undone / Blocked (2026-03-07)
- VDI apply is paused and **not converged** on AWS worker nodegroups.
- Root cause (observed in AWS Auto Scaling activity logs):
  - EKS VDI worker launches failed with `InvalidParameterCombination: specified instance type is not eligible for Free Tier`.
  - Prior run attempted `t3.large` for VDI nodegroups.
- Current mitigation already committed in local config:
  - `phase4_vdi_aws_node_instance_types` changed to free-tier-eligible `["t3.small"]`.
- Remaining cleanup before retry:
  - existing AWS VDI nodegroups `ddc-proposal-site-a-ng-vdi` and `ddc-proposal-site-b-ng-vdi` are in `DELETING` and must finish.
- Resume commands once deletion completes:
  - `.\scripts\invoke_phase4_vdi_enablement.ps1 -AwsProfile "ddc" -GcpCredentialsPath "C:\Users\<user>\.gcp\ddc-sa.json" -GcpProjectId "worldbuilder-413006" -DisableGcpBrokerIdentity -PreflightOnly`
  - `.\scripts\invoke_phase4_vdi_enablement.ps1 -AwsProfile "ddc" -GcpCredentialsPath "C:\Users\<user>\.gcp\ddc-sa.json" -GcpProjectId "worldbuilder-413006" -DisableGcpBrokerIdentity -AutoApprove`
  - verify:
    - `aws eks describe-nodegroup --cluster-name ddc-proposal-site-a-eks --nodegroup-name ddc-proposal-site-a-ng-vdi --region us-east-1 --profile ddc --query "nodegroup.status" --output text`
    - `aws eks describe-nodegroup --cluster-name ddc-proposal-site-b-eks --nodegroup-name ddc-proposal-site-b-ng-vdi --region us-west-2 --profile ddc --query "nodegroup.status" --output text`
- Resilient pass structure now implemented in `scripts/invoke_phase4_vdi_enablement.ps1`:
  - preflight gate (`-PreflightOnly`) for fail-fast blockers
  - AWS free-tier eligibility validation for worker instance types
  - GCP `CPUS_ALL_REGIONS` quota validation against configured VDI nodepool machine type and initial count
  - orphan/in-flight VDI nodegroup detection before apply
  - bounded post-apply worker polling (`-HealthCheckTimeoutMinutes`, `-HealthCheckPollSeconds`)
  - diagnostic artifacts on failure in `evidence/phase4-vdi-diagnostics/`
- Latest pass outcome (2026-03-07 16:14 America/Toronto):
  - AWS VDI nodegroups now converge (`ddc-proposal-site-a-ng-vdi`, `ddc-proposal-site-b-ng-vdi` are `ACTIVE`).
  - GCP VDI nodepools blocked by project CPU quota:
    - `CPUS_ALL_REGIONS` limit `32`, usage `24`, available `8`.
    - current VDI sizing requires `48` CPUs total (`24` per regional pool at `e2-standard-8` with 3 zones and initial count `1`).
  - Preflight now catches this before apply and exits fast with diagnostics.
  - New rollout toggles are available:
    - `phase4_vdi_enable_aws_worker_pools`
    - `phase4_vdi_enable_gcp_worker_pools`
  - Local quota-safe setting currently in `terraform.tfvars`:
    - `phase4_vdi_enable_gcp_worker_pools = false`
  - Quota-safe convergence pass (2026-03-07 16:22 America/Toronto):
    - `invoke_phase4_vdi_enablement.ps1` completed successfully with AWS VDI workers `ACTIVE`.
    - `phase4_vdi_reference_stacks` now reports:
      - AWS worker summaries populated (`site-a`, `site-b`)
      - GCP worker summaries `null` (`site-c`, `site-d`) while VDI control-plane firewall/policy baseline remains applied.

## Next Build Step
- Apply and validate published app path when ready:
  - set `phase4_enable_published_app_path=true`
  - set backend targets:
    - `phase4_site_a_published_app_backend_ipv4_targets`
    - `phase4_site_b_published_app_backend_ipv4_targets`
- optional Cloudflare DNS automation:
    - set `phase4_enable_cloudflare_edge=true`
    - set `phase4_cloudflare_zone_name` (or `phase4_cloudflare_zone_id`)
    - set `phase4_cloudflare_site_a_record_name` and/or `phase4_cloudflare_site_b_record_name`
    - keep `phase4_cloudflare_record_proxied=false` for DNS-only mode
    - export `CLOUDFLARE_API_TOKEN` before apply/plan
- Published app path pre-flight:
  - Current dry-run with `phase4_enable_published_app_path=true` proposes `12` creates (ALB/SG/TG/listener/WAF x2 sites).
  - If backend target lists are empty, listener mode is `fixed-response` (`503`), which is safe for edge bring-up.
  - To forward live traffic, provide reachable backend IPs in app/data tiers and rerun plan.
- Suggested next-pass commands:
  - `terraform plan -var "phase4_enable_published_app_path=true"`
  - `terraform apply -var "phase4_enable_published_app_path=true" -auto-approve`
  - `terraform plan -var "phase4_enable_published_app_path=true" -var "phase4_enable_cloudflare_edge=true" -var "phase4_cloudflare_zone_name=slothkko.com" -var "phase4_cloudflare_site_a_record_name=app-a" -var "phase4_cloudflare_site_b_record_name=app-b" -var "phase4_cloudflare_record_proxied=false"`
  - `terraform apply -var "phase4_enable_published_app_path=true" -var "phase4_enable_cloudflare_edge=true" -var "phase4_cloudflare_zone_name=slothkko.com" -var "phase4_cloudflare_site_a_record_name=app-a" -var "phase4_cloudflare_site_b_record_name=app-b" -var "phase4_cloudflare_record_proxied=false" -auto-approve`
- Apply and validate VDI reference stack when ready:
  - set `phase4_enable_vdi_reference_stack=true`
  - keep `phase4_enable_service_onboarding=true` and `phase3_enable_platform=true`
  - review VDI sizing controls:
    - `phase4_vdi_aws_node_*`
    - `phase4_vdi_gcp_node_*`
  - if GCP identity lacks `iam.serviceAccounts.create`, set `phase4_vdi_gcp_manage_broker_identity=false`
  - run (recommended helper):
    - `.\scripts\invoke_phase4_vdi_enablement.ps1 -AwsProfile "ddc" -GcpCredentialsPath "C:\Users\<user>\.gcp\ddc-sa.json" -GcpProjectId "worldbuilder-413006" -PlanOnly`
    - `.\scripts\invoke_phase4_vdi_enablement.ps1 -AwsProfile "ddc" -GcpCredentialsPath "C:\Users\<user>\.gcp\ddc-sa.json" -GcpProjectId "worldbuilder-413006" -AutoApprove`
- Execute failover scenarios and backup/restore drills; record outcomes in latest `execution_record.md`.

## Published App Unblock Pass (2026-03-07 16:43 America/Toronto)
- Root cause from prior failed apply was confirmed and fixed:
  - AWS ingress subnets had no internet gateway/public route, so ALB creation failed with `InvalidSubnet: VPC ... has no internet gateway`.
- Implemented structural fix in Terraform:
  - New root variable `phase4_aws_enable_ingress_internet_edge` (required when `phase4_enable_published_app_path=true`).
  - `modules/aws_site` now supports `enable_ingress_internet_edge` and creates:
    - `aws_internet_gateway`
    - ingress public `aws_route_table` (`<REDACTED_PRIVATE_CIDR>` and `::/0` to IGW)
    - `aws_route_table_association` for ingress subnets
  - Published app modules now include `depends_on = [module.aws_site_a]` / `[module.aws_site_b]` to avoid route/ALB timing races.
  - `invoke_dev_environment_up.ps1` and `invoke_phase4_vdi_enablement.ps1` now set `phase4_aws_enable_ingress_internet_edge=true` automatically when `-EnablePublishedAppPath` is used.
  - `invoke_phase4_vdi_enablement.ps1` preflight now checks AWS ingress route readiness and reports when edge will be created in the same apply.
- Validation and execution:
  - `terraform validate` passed.
  - Preflight command passed with expected warning (edge missing but will be created).
  - Full apply command succeeded:
    - `.\scripts\invoke_phase4_vdi_enablement.ps1 -AwsProfile "ddc" -GcpCredentialsPath "C:\Users\<user>\.gcp\ddc-sa.json" -GcpProjectId "worldbuilder-413006" -EnablePublishedAppPath -DisableGcpBrokerIdentity -AutoApprove`
  - Apply result: `14 added, 0 changed, 0 destroyed`.
  - Published app path now active in both AWS sites with fixed-response listeners and WAF associations.
  - New outputs show ingress edge enabled:
    - Site A IGW: `igw-0cecfd70e398bd37f`
    - Site B IGW: `igw-0c0ae8dfb0f73e467`
  - Published app DNS endpoints:
    - Site A ALB: `<REDACTED_AWS_ALB_DNS>`
    - Site B ALB: `<REDACTED_AWS_ALB_DNS>`

## Next Build Step (Updated)
- Cloudflare DNS automation pass:
  - enable `phase4_enable_cloudflare_edge=true`
  - use zone `slothkko.com`
  - map `app-a` and `app-b` records to the published app ALB DNS names
  - keep `phase4_cloudflare_record_proxied=false` (DNS-only) for now.
- Optional traffic-forwarding pass:
  - populate backend IP targets:
    - `phase4_site_a_published_app_backend_ipv4_targets`
    - `phase4_site_b_published_app_backend_ipv4_targets`
  - rerun apply to switch listener behavior from fixed `503` to forward mode.

## Cloudflare DNS Pass (2026-03-08 01:58 America/Toronto)
- Executed Cloudflare edge enablement with published app path:
  - `.\scripts\invoke_phase4_vdi_enablement.ps1 -AwsProfile "ddc" -GcpCredentialsPath "C:\Users\<user>\.gcp\ddc-sa.json" -GcpProjectId "worldbuilder-413006" -EnablePublishedAppPath -EnableCloudflareEdge -CloudflareZoneName "slothkko.com" -CloudflareSiteARecordName "app-a" -CloudflareSiteBRecordName "app-b" -DisableGcpBrokerIdentity -AutoApprove`
- Preflight/validate passed.
- Apply result:
  - `2 added, 2 changed, 0 destroyed`
  - Added Cloudflare DNS records:
    - `app-a.slothkko.com` -> `<REDACTED_AWS_ALB_DNS>` (`proxied=false`, TTL `300`)
    - `app-b.slothkko.com` -> `<REDACTED_AWS_ALB_DNS>` (`proxied=false`, TTL `300`)
  - Reconciled AWS S3 gateway endpoint route-table attachments for new ingress-public route tables.
- Verification:
  - `phase4_cloudflare_edge_records` output populated for both sites.
  - DNS check against `<REDACTED_PUBLIC_IP>` resolves both hostnames to the expected ALB aliases.

## Phase 5 Evidence Pass (2026-03-08 03:03 America/Toronto)
- Enhanced `scripts/invoke_phase5_evidence_capture.ps1` to capture:
  - published app endpoint probe states (`published_app_endpoint_states.json`)
  - Cloudflare DNS resolution/target-match states (`cloudflare_dns_states.json`)
  - new summary metrics for:
    - published app endpoint health
    - Cloudflare DNS resolving/target alignment
- Executed:
  - `.\scripts\invoke_phase5_evidence_capture.ps1 -ProjectId "worldbuilder-413006" -AwsProfile "ddc"`
- Latest evidence directory:
  - `evidence/phase5-20260308-030306`
- Result snapshot:
  - AWS VPN `available`: `4/4`
  - GCP VPN `ESTABLISHED`: `8/8`
  - EKS `ACTIVE`: `2/2`
  - GKE `RUNNING`: `2/2`
  - Published app endpoints healthy (expected status mode): `2/2`
  - Cloudflare DNS records resolving: `2/2`
  - Cloudflare DNS target match: `2/2`

## Published App Targeting Pass (2026-03-08 03:11 America/Toronto)
- Enhanced `scripts/invoke_phase4_vdi_enablement.ps1` to support explicit published-app backend overrides:
  - `-SiteAPublishedAppBackendTargets`
  - `-SiteBPublishedAppBackendTargets`
  - `-PublishedAppBackendPort`
  - `-PublishedAppHealthCheckPath`
- Added published-app preflight validation:
  - validates backend target IPv4 format
  - flags duplicate backend target IPs as preflight errors
  - warns when backend IPs are not currently attached to ENIs in the site VPC
  - explicitly reports fixed-response mode when target lists are empty
- Validation runs:
  - baseline published app preflight (`-PreflightOnly`) passed with empty-target warnings for both sites
  - intentional invalid target test (`-SiteAPublishedAppBackendTargets "<REDACTED_INVALID_IP>"`) correctly failed in preflight before apply

## Published App Auto-Discovery Cutover Pass (2026-03-08 03:19 America/Toronto)
- Added helper script:
  - `scripts/invoke_phase4_published_app_cutover.ps1`
- What it does:
  - resolves AWS site network outputs from Terraform
  - discovers private ENI IPv4 targets per site from app subnets (plus data subnets by default)
  - limits discovered targets with `-MaxTargetsPerSite` (default `4`)
  - passes discovered targets into `invoke_phase4_vdi_enablement.ps1` with `-EnablePublishedAppPath`
  - supports optional Cloudflare pass-through flags and trims accidental quote characters around `CLOUDFLARE_API_TOKEN`
- Operational controls:
  - `-IncludeDataSubnets` (default `true`)
  - `-IncludeIngressSubnets` (default `false`)
  - `-AllowEmptyTargets` (otherwise requires at least one discovered target per site)
  - pass-through for `-PreflightOnly`, `-PlanOnly`, `-AutoApprove`, and worker-pool toggles
- Validation:
  - script parsed successfully with PowerShell parser
  - preflight execution succeeded:
    - `.\scripts\invoke_phase4_published_app_cutover.ps1 -AwsProfile "ddc" -GcpCredentialsPath "C:\Users\<user>\.gcp\ddc-sa.json" -GcpProjectId "worldbuilder-413006" -DisableGcpBrokerIdentity -PreflightOnly`
    - discovered site-a targets (limited to `4`): `<REDACTED_PRIVATE_IP>`, `<REDACTED_PRIVATE_IP>`, `<REDACTED_PRIVATE_IP>`, `<REDACTED_PRIVATE_IP>`
    - discovered site-b targets (limited to `4`): `<REDACTED_PRIVATE_IP>`, `<REDACTED_PRIVATE_IP>`, `<REDACTED_PRIVATE_IP>`, `<REDACTED_PRIVATE_IP>`
    - delegated preflight in `invoke_phase4_vdi_enablement.ps1` passed all checks and skipped apply as expected

## VDI EKS Targeted Cutover Pass (2026-03-08 03:31 America/Toronto)
- Source-doc alignment reviewed:
  - `docs/10_implementation/readme.md` Phase 4 requirement includes VDI reference stack onboarding.
  - `docs/02_architecture/vdi_service.md` expects browser-path VDI access with Guacamole; this pass improves deterministic backend targeting for that path.
- Added helper script:
  - `scripts/invoke_phase4_vdi_eks_backend_cutover.ps1`
- What it does:
  - resolves AWS site clusters from Terraform output (`phase3_aws_eks_clusters`)
  - resolves nodegroup names using suffix convention (`-NodegroupSuffix "vdi"` by default) or explicit names
  - discovers private IP targets from EKS nodegroup backing instances (via EKS -> ASG -> EC2 lookups)
  - invokes `invoke_phase4_vdi_enablement.ps1` with discovered targets and VDI-oriented defaults:
    - `PublishedAppBackendPort = 30080`
    - `PublishedAppHealthCheckPath = "/guacamole/"`
  - supports Cloudflare pass-through and trims accidental quote characters around `CLOUDFLARE_API_TOKEN`
- Validation:
  - preflight execution succeeded:
    - `.\scripts\invoke_phase4_vdi_eks_backend_cutover.ps1 -AwsProfile "ddc" -GcpCredentialsPath "C:\Users\<user>\.gcp\ddc-sa.json" -GcpProjectId "worldbuilder-413006" -DisableGcpBrokerIdentity -PreflightOnly`
    - discovered site-a EKS VDI targets: `<REDACTED_PRIVATE_IP>`
    - discovered site-b EKS VDI targets: `<REDACTED_PRIVATE_IP>`
    - delegated preflight in `invoke_phase4_vdi_enablement.ps1` passed with `backend_port=30080` and `health_path=/guacamole/`

## Dev Session Cost-Saver Scripts
- Up script:
  - `scripts/invoke_dev_environment_up.ps1`
- Down script:
  - `scripts/invoke_dev_environment_down.ps1`
- VDI enablement + health check script:
  - `scripts/invoke_phase4_vdi_enablement.ps1`
- Typical use:
  - start core platform:
    - `.\scripts\invoke_dev_environment_up.ps1 -AwsProfile "ddc" -GcpCredentialsPath "C:\Users\<user>\.gcp\ddc-sa.json"`
  - stop platform between sessions:
    - `.\scripts\invoke_dev_environment_down.ps1 -AwsProfile "ddc" -GcpCredentialsPath "C:\Users\<user>\.gcp\ddc-sa.json"`
  - stop platform and suspend inter-cloud VPN/BGP to save more:
    - `.\scripts\invoke_dev_environment_down.ps1 -AwsProfile "ddc" -GcpCredentialsPath "C:\Users\<user>\.gcp\ddc-sa.json" -SuspendIntercloud`
  - maximum savings (full destroy):
    - `.\scripts\invoke_dev_environment_down.ps1 -AwsProfile "ddc" -GcpCredentialsPath "C:\Users\<user>\.gcp\ddc-sa.json" -DestroyAll`

## Phase 5 Execution Starter
```powershell
cd e:\distributed-dc\network-spanned-dc\iac\terraform
$env:GOOGLE_APPLICATION_CREDENTIALS="C:\Users\<user>\.gcp\ddc-sa.json"
$env:AWS_PROFILE="ddc"
.\scripts\invoke_phase5_evidence_capture.ps1 -ProjectId "worldbuilder-413006"
```

## Cloudflare TLS Origin Pass (2026-03-08 04:28 America/Toronto)
- Observed after enabling Cloudflare proxy mode:
  - browser returned `522` (`Host Error`) for:
    - `app-a.slothkko.com/guacamole`
    - `app-b.slothkko.com/guacamole`
  - Cloudflare edge and browser were healthy; origin was not accepting TLS on `443`.
- Root cause:
  - published-app ALBs were HTTP-only (`80`) and did not have HTTPS listeners/certificates.
- Implemented fix:
  - Added published-app TLS controls and resources:
    - `phase4_enable_published_app_tls`
    - `phase4_published_app_https_port`
    - `phase4_published_app_tls_ssl_policy`
  - Added new Terraform file:
    - `phase4_published_app_tls.tf`
      - per-site ACM certificates (`us-east-1`, `us-west-2`)
      - Cloudflare DNS validation records
      - ACM certificate validation resources
      - ALB HTTPS listeners on `443`
  - Updated published-app module security group to allow optional HTTPS ingress.
  - Extended helper scripts:
    - `invoke_phase4_vdi_enablement.ps1`
      - `-EnablePublishedAppTls`
      - `-CloudflareRecordProxied`
      - `-CloudflareRecordTtl`
    - `invoke_phase4_vdi_eks_backend_cutover.ps1`
      - pass-through for the same TLS/proxy flags
- Executed:
  - `.\scripts\invoke_phase4_vdi_eks_backend_cutover.ps1 -AwsProfile "ddc" -GcpCredentialsPath "C:\Users\<user>\.gcp\ddc-sa.json" -GcpProjectId "worldbuilder-413006" -DisableGcpBrokerIdentity -EnablePublishedAppTls -EnableCloudflareEdge -CloudflareZoneName "slothkko.com" -CloudflareSiteARecordName "app-a" -CloudflareSiteBRecordName "app-b" -CloudflareRecordProxied -CloudflareRecordTtl 1 -AutoApprove`
- Apply result:
  - `8 added, 2 changed, 0 destroyed`
  - Cloudflare records stayed proxied (`true`) with automatic TTL (`1`).
  - New outputs now include:
    - `phase4_deliverable_flags.published_app_tls = true`
    - per-site `https_listener_arn`, `https_listener_port`, and `tls_certificate_arn` in `phase4_published_app_paths`
- Verification:
  - `https://app-a.slothkko.com/guacamole/` -> `200`
  - `https://app-b.slothkko.com/guacamole/` -> `200`
  - `http://app-a.slothkko.com/guacamole/` -> `301`
  - `http://app-b.slothkko.com/guacamole/` -> `301`
  - ALBs now expose both `80` and `443` listeners with ACM certificates in-region.

## VDI Service Bootstrap + ECR Mirror Pass (2026-03-08 03:58 America/Toronto)
- Added EKS VDI service bootstrap artifacts:
  - `iac/k8s/vdi/guacamole-nodeport.yaml`
  - `iac/k8s/vdi/guacamole-postgresql-init.sql`
  - `scripts/invoke_phase4_vdi_service_bootstrap.ps1`
- Added image mirror helper:
  - `scripts/invoke_phase4_vdi_ecr_image_mirror.ps1`
- Executed ECR mirror in both regions:
  - `.\scripts\invoke_phase4_vdi_ecr_image_mirror.ps1 -AwsProfile "ddc"`
  - account: `<AWS_ACCOUNT_ID>`
  - repos:
    - `ddc-vdi-postgres`
    - `ddc-vdi-guacd`
    - `ddc-vdi-guacamole`
- Executed bootstrap with private regional images:
  - `.\scripts\invoke_phase4_vdi_service_bootstrap.ps1 -AwsProfile "ddc" -UseRegionalEcrImages -EcrAccountId <AWS_ACCOUNT_ID> -SiteAOnly`
  - `.\scripts\invoke_phase4_vdi_service_bootstrap.ps1 -AwsProfile "ddc" -UseRegionalEcrImages -EcrAccountId <AWS_ACCOUNT_ID> -SiteBOnly`
- Kubernetes verification:
  - `vdi` namespace present on both clusters.
  - `guacamole-db` and `guacamole` deployments `Running`.
  - `guacamole-nodeport` service active on `80:30080/TCP`.

## Published App NodePort Recovery Pass (2026-03-08 04:12 America/Toronto)
- Initial symptom after VDI cutover:
  - ALB and Cloudflare `/guacamole/` probes returned `504`.
  - target-group health for both sites reported `Target.Timeout`.
- Root cause:
  - EKS node ENIs only had cluster SGs (`sg-096cda992d63a8273`, `sg-0b9dec32addf36b1c`) and lacked ingress from published-app ALB SGs on NodePort `30080`.
- Terraform fix:
  - `phase4_published_app_path.tf`
  - added:
    - `aws_vpc_security_group_ingress_rule.phase4_site_a_published_app_to_vdi_eks_nodeport`
    - `aws_vpc_security_group_ingress_rule.phase4_site_b_published_app_to_vdi_eks_nodeport`
  - both rules allow `tcp/30080` from site ALB SG to site EKS cluster SG.
- Applied safely through existing helper (explicit Phase 4 enable flags):
  - `.\scripts\invoke_phase4_vdi_eks_backend_cutover.ps1 -AwsProfile "ddc" -GcpCredentialsPath "C:\Users\<user>\.gcp\ddc-sa.json" -GcpProjectId "worldbuilder-413006" -DisableGcpBrokerIdentity -EnableCloudflareEdge -CloudflareZoneName "slothkko.com" -CloudflareSiteARecordName "app-a" -CloudflareSiteBRecordName "app-b" -AutoApprove`
  - apply result: `2 added, 0 changed, 0 destroyed`
- Post-fix verification:
  - target health:
    - site-a `<REDACTED_PRIVATE_IP>` -> `healthy`
    - site-b `<REDACTED_PRIVATE_IP>` -> `healthy`
  - endpoint probes:
    - `http://app-a.slothkko.com/guacamole/` -> `200`
    - `http://app-b.slothkko.com/guacamole/` -> `200`
    - direct ALB `/guacamole/` endpoints -> `200`
  - cluster-side checks:
    - local container and nodeport curls inside each cluster returned `200`.
  - expected current behavior (at that time, before TLS origin pass):
    - `https://app-a.slothkko.com/guacamole/` and `https://app-b.slothkko.com/guacamole/` time out because Cloudflare was DNS-only and ALB listener was HTTP/80 only.

## Guacadmin Rotation + Root Redirect Pass (2026-03-08 04:41 America/Toronto)
- User-facing issues:
  - `guacadmin` default credential still accepted.
  - bare host (`https://app-a.slothkko.com/`) showed Tomcat `404` because Guacamole is served at `/guacamole/`.
- Immediate runtime remediation:
  - rotated `guacadmin` password directly in both EKS site databases via `kubectl exec ... psql` update against `guacamole_user`.
  - updated `guacamole-db-init` ConfigMap in both clusters with the same non-default admin password seed (hash/salt) so DB pod re-initialization does not revert to `<default-admin-credential>`.
  - verified old credential rejected and new credential accepted on both:
    - `app-a`: old `403`, new `200`
    - `app-b`: old `403`, new `200`
- Terraform changes for host-root UX:
  - module updates:
    - `modules/aws_published_app_path/variables.tf`
    - `modules/aws_published_app_path/main.tf`
  - root wiring:
    - `phase4_published_app_path.tf`
    - `phase4_published_app_tls.tf`
    - `variables.tf`
    - `terraform.tfvars.example`
  - behavior:
    - adds listener rules on HTTP/HTTPS to redirect path `/` to `phase4_published_app_root_redirect_path` (default `/guacamole/`).
- Applied through standard cutover helper:
  - `.\scripts\invoke_phase4_vdi_eks_backend_cutover.ps1 -AwsProfile "ddc" -GcpCredentialsPath "C:\Users\<user>\.gcp\ddc-sa.json" -GcpProjectId "worldbuilder-413006" -DisableGcpBrokerIdentity -EnablePublishedAppTls -EnableCloudflareEdge -CloudflareZoneName "slothkko.com" -CloudflareSiteARecordName "app-a" -CloudflareSiteBRecordName "app-b" -CloudflareRecordProxied -CloudflareRecordTtl 1 -AutoApprove`
  - apply result: `4 added, 0 changed, 0 destroyed` (listener redirect rules only).
- Post-apply verification:
  - `https://app-a.slothkko.com/` -> `302` to `/guacamole/`
  - `https://app-b.slothkko.com/` -> `302` to `/guacamole/`
  - `https://app-a.slothkko.com/guacamole/` -> `200`
  - `https://app-b.slothkko.com/guacamole/` -> `200`
- Follow-up hardening:
  - `scripts/invoke_phase4_vdi_service_bootstrap.ps1` now supports non-default admin seeding:
    - new `-GuacAdminPassword` (or `GUACADMIN_PASSWORD` env var)
    - DB init SQL configmap is rendered with generated hash/salt
    - post-bootstrap DB rotation step enforces the provided admin password in running DB
    - warns when default `guacadmin` is used

## Sample VDI Session Bootstrap Pass (2026-03-08 04:57 America/Toronto)
- Goal:
  - move from “Guacamole UI reachable” to “first connectable session target” in both AWS sites.
- Added:
  - `iac/k8s/vdi/vdi-desktop-vnc.yaml`
    - deploys `vdi-desktop` (VNC server) in `vdi` namespace
    - creates `vdi-desktop-auth` secret and `vdi-desktop` ClusterIP service (`5900/TCP`)
- Script enhancements:
  - `scripts/invoke_phase4_vdi_ecr_image_mirror.ps1`
    - new `-MirrorDesktopImage`
    - new desktop repo/image params (`ddc-vdi-desktop`, `dorowu/ubuntu-desktop-lxde-vnc:latest`)
  - `scripts/invoke_phase4_vdi_service_bootstrap.ps1`
    - `-EnableSampleVdiDesktop`
    - `-UseRegionalEcrDesktopImage`
    - `-DesktopImage`, `-DesktopConnectionName`, `-DesktopVncPort`, `-DesktopVncPassword`
    - deploys desktop manifest per site and seeds Guacamole DB connection/permissions for `guacadmin`
- Executed:
  - `.\scripts\invoke_phase4_vdi_ecr_image_mirror.ps1 -AwsProfile "ddc" -MirrorDesktopImage`
  - `.\scripts\invoke_phase4_vdi_service_bootstrap.ps1 -AwsProfile "ddc" -UseRegionalEcrImages -UseRegionalEcrDesktopImage -EnableSampleVdiDesktop -EcrAccountId "<AWS_ACCOUNT_ID>" -GuacAdminPassword "<existing>" -DesktopVncPassword "<set>"`
- Verification:
  - both clusters:
    - `deployment/vdi-desktop` rolled out successfully
    - `service/vdi-desktop` present on `5900/TCP`
  - both published endpoints:
    - Guacamole API lists connection `VDI Desktop` (protocol `vnc`)
    - connection parameters resolve to `<REDACTED_INTERNAL_DNS>:5900`

## Review Pass (2026-03-08 05:51 America/Toronto)
- Scope:
  - reviewed the current working-tree "last pass" across Terraform modules, root stacks, helper scripts, and VDI ops console assets.
- Validation run:
  - `terraform fmt -check -recursive` (no formatting violations)
  - `terraform validate` (`Success! The configuration is valid.`)
  - PowerShell parser checks across changed scripts (all parse successfully)
  - `python -m py_compile iac/terraform/tools/vdi_ops_console/server.py` (syntax OK)
- Admin panel run:
  - initial wrapper launch failed with:
    - `Cannot overwrite variable Host because it is read-only or constant.`
  - fix applied:
    - `scripts/invoke_vdi_ops_console.ps1` renamed launcher param from `Host` to `BindHost` to avoid collision with PowerShell automatic `$Host`.
  - rerun through wrapper:
    - `.\scripts\invoke_vdi_ops_console.ps1 -AdminUsername "ops-admin" -AdminPassword "<test>" -Port 8099`
    - health probe result: `ADMIN_PANEL_OK_WRAPPER state=green green=10/10`
- Review note for cleanup before commit:
  - untracked directory `tools/cloudflare-python/` is a full external checkout (including nested `.git` and local virtualenv folders) and is very large (`17867` files, `210326841` bytes). Confirm this is intentionally vendored before staging/committing.

## Admin DNS + Console Exposure Clarification (2026-03-08 06:02 America/Toronto)
- Ops console runtime behavior clarified:
  - `scripts/invoke_vdi_ops_console.ps1` hosts the panel on the local workstation by default (`<REDACTED_PRIVATE_ENDPOINT>`).
  - it is not published through ALB/Cloudflare by default, so Guacamole clients and remote browsers cannot reach it unless an explicit tunnel/reverse-proxy path is added.
- Script fix applied:
  - `invoke_vdi_ops_console.ps1` parameter renamed from `Host` to `BindHost` to avoid PowerShell automatic variable collision (`$Host` is read-only).
  - wrapper launch and authenticated `/api/health` verification succeeded after fix.
- Cloudflare/zone revision support added in Terraform:
  - new variable `phase4_cloudflare_additional_records` (map of hostname -> `site_a`/`site_b`) for hostnames like `admin`, `www`, or `@`.
  - TLS SAN support added via:
    - `phase4_site_a_published_app_tls_subject_alternative_names`
    - `phase4_site_b_published_app_tls_subject_alternative_names`
  - `phase4_published_app_tls.tf` now supports `@` apex handling for primary hostname and SAN entries.
  - `phase4_cloudflare_edge_records` output now includes `additional` records.
- Validation:
  - `terraform fmt -recursive` completed.
  - `terraform validate` returned `Success! The configuration is valid.`

## Admin DNS Resolution + TLS Restore Pass (2026-03-08 06:20 America/Toronto)
- Primary user-facing incident:
  - `admin.slothkko.com` did not resolve.
  - after initial DNS add, `admin/www/@` returned Cloudflare `526` while `app-a` stayed healthy.
- Terraform blocker fixed:
  - `outputs.tf`
    - `output "phase4_cloudflare_edge_records"` false branch changed from `{}` to a shape-compatible object:
      - `site_a = null`
      - `site_b = null`
      - `additional = {}`
  - reason: avoid `Inconsistent conditional result types` during apply.
- Helper script bug fixed:
  - `scripts/invoke_phase4_vdi_enablement.ps1`
    - `Get-TfvarsStringValue` now allows empty-string defaults (`[AllowEmptyString()]` on `DefaultValue`).
  - reason: preflight crashed when resolving optional `gcp_project_id` default `""`.
- Apply path notes:
  - full helper apply still blocked in this shell by missing local credentials:
    - AWS CLI credentials missing for preflight checks (workaround: skip flags)
    - Google provider ADC missing for full graph refresh (`Attempted to load application default credentials...`).
  - recovery used targeted Terraform applies (exception workflow) to avoid unrelated provider auth blockers.
- Targeted infra changes applied:
  - Cloudflare additional records:
    - `cloudflare_record.phase4_published_app_additional["admin"]`
    - `cloudflare_record.phase4_published_app_additional["www"]`
    - `cloudflare_record.phase4_published_app_additional["@"]`
  - Site-a TLS origin cert expansion and listener update:
    - `aws_acm_certificate.phase4_site_a_published_app`
    - `cloudflare_record.phase4_site_a_acm_validation[*]`
    - `aws_acm_certificate_validation.phase4_site_a_published_app`
    - `aws_lb_listener.phase4_site_a_https_forward`
  - new Site-a ACM certificate issued and attached:
    - `arn:aws:acm:us-east-1:<AWS_ACCOUNT_ID>:certificate/<REDACTED_CERT_ID>`
    - SAN coverage includes `admin.slothkko.com`, `slothkko.com`, `www.slothkko.com`, `app-a.slothkko.com`.
- Cloudflare SSL mode note:
  - attempted zone SSL setting change via API to align with "Cloudflare handles wildcard SSL" statement.
  - token used in this pass had DNS permissions but not zone SSL settings permissions (`403 Forbidden` on `/zones/.../settings/ssl`), so origin TLS compatibility was solved via ACM SAN expansion instead.
- Verification after apply:
  - DNS:
    - `admin.slothkko.com` resolves publicly (`A <REDACTED_PUBLIC_IP>`, `AAAA <REDACTED_IPV6>`)
    - `www.slothkko.com` resolves publicly
    - `slothkko.com` resolves publicly
  - HTTP/HTTPS probes:
    - `https://admin.slothkko.com/guacamole/` -> `200`
    - `https://app-a.slothkko.com/guacamole/` -> `200`
    - `https://www.slothkko.com/` -> `302` to `https://www.slothkko.com:443/guacamole/`
    - `https://slothkko.com/` -> `200` (serving revised landing page content)

## Admin Panel Runtime Check (2026-03-08 06:29 America/Toronto)
- Executed ops console server process directly:
  - `python -u tools/vdi_ops_console/server.py --host <REDACTED_PRIVATE_IP> --port 8099 --terraform-dir . --command-timeout-seconds 25`
  - environment:
    - `VDI_ADMIN_USERNAME=ops-admin`
    - `VDI_ADMIN_PASSWORD=<redacted>`
- Verified authenticated health endpoint while server was live:
  - `curl -u <admin> http://<REDACTED_PRIVATE_ENDPOINT>/api/health`
  - response confirmed panel is serving and reading Terraform + cluster checks.
- Current health snapshot from panel:
  - `overall.state=red`, `green_light_count=9/10`
  - `site-a`: red because `desktop_ready=false` (`vdi-desktop_ready=0/1`)
  - `site-b`: green (`desktop_ready=true`, active session detected)
  - `site-c/site-d`: red by design in this pass (`worker not enabled`)

## Ops Server Baseline + Guac Access Pass (2026-03-08 07:36 America/Toronto)
- Added new Terraform layer:
  - `phase4_ops_servers.tf`
  - provisions when `phase4_enable_ops_stack=true`:
    - OpenProject server in GCP Site C (Compute Engine + public IP + tagged internet egress route)
    - Git server in AWS Site B (EC2 + Gitea container on `3000`/`2222`)
    - Ansible control node in AWS Site A (EC2 + Ansible tooling + baseline inventory)
  - adds AWS IAM instance profiles with `AmazonSSMManagedInstanceCore` for Site A/B ops nodes.
  - adds security controls:
    - AWS SGs for SSH/web where applicable
    - GCP firewall rules for OpenProject SSH/http access
- Added new Terraform variables and tfvars examples for:
  - enabling/tuning ops stack (`phase4_enable_ops_stack`, `phase4_ops_*`)
  - ops admin access bootstrap (public key and/or password)
  - OpenProject/Git/Ansible sizing and ingress controls
- Added new output:
  - `phase4_ops_servers` (private/public endpoints + Guacamole target metadata)
- Added Guacamole seeding helper:
  - `scripts/invoke_phase4_guac_seed_ops_connections.ps1`
  - reads `phase4_ops_servers` output and upserts SSH connections in Site A/B Guacamole DBs.
- Runtime bring-up notes:
  - OpenProject bootstrap now completes cleanly on GCP (`google-startup-scripts.service` exit `0`) after fixing Docker apt repo codename/substitution issues in startup script rendering.
  - Gitea endpoint validated at `http://<REDACTED_PUBLIC_ENDPOINT>/` (`200`) before ingress lockdown.
  - OpenProject endpoint validated with expected host header:
    - `curl -H "Host: openproject.slothkko.com" http://<REDACTED_PUBLIC_IP>/` -> `302`
    - direct IP probe without host header returns application-level `400` by design.
- Guac-only access hardening applied:
  - requirement: app UIs should only be reachable from Guacamole-side/internal site networks.
  - Terraform defaults changed:
    - `phase4_ops_openproject_http_allowed_ipv4_cidrs = null` and `phase4_ops_git_http_allowed_ipv4_cidrs = null`
    - null/empty now resolves to internal site CIDRs (`<REDACTED_PRIVATE_CIDR>`, `<REDACTED_PRIVATE_CIDR>`, `<REDACTED_PRIVATE_CIDR>`, `<REDACTED_PRIVATE_CIDR>`) plus optional `phase4_ops_trusted_ipv4_cidrs`.
  - targeted apply executed:
    - `aws_security_group.phase4_site_b_git[0]` (Gitea `3000/tcp`)
    - `google_compute_firewall.phase4_site_c_openproject_http[0]` (OpenProject `80/443`)
  - external probe verification after apply:
    - `http://<REDACTED_PUBLIC_ENDPOINT>/` -> unreachable from public internet
    - `http://<REDACTED_PUBLIC_IP>/` -> unreachable from public internet
- Updated:
  - `scripts/invoke_dev_environment_up.ps1` with `-EnableOpsStack`
  - `README.md` with ops stack + Guac seeding workflows
- Validation status:
  - run `terraform fmt` on updated files
  - run `terraform validate`
  - run PowerShell parser checks:
    - `scripts/invoke_phase4_guac_seed_ops_connections.ps1`
    - `scripts/invoke_dev_environment_up.ps1`
  - ran repository grep-based secret checks (no exposed Cloudflare token, SSH password, private keys, or static access keys in tracked content)

## Slothkko Root Portal + Guac Theme Activation Pass (2026-03-08 08:14 America/Toronto)
- Scope completed:
  - finalized rollout of the Slothkko-themed Guacamole front-proxy manifest and enabled root portal serving on published hosts.
  - applied pending ALB listener rule cleanup so `/` no longer redirects to `/guacamole/`.
- Infrastructure apply executed:
  - targeted Terraform plan/apply removed 4 root redirect listener rules:
    - `module.aws_published_app_path_site_a[0].aws_lb_listener_rule.http_root_redirect_forward[0]`
    - `module.aws_published_app_path_site_b[0].aws_lb_listener_rule.http_root_redirect_forward[0]`
    - `aws_lb_listener_rule.phase4_site_a_https_root_redirect_forward[0]`
    - `aws_lb_listener_rule.phase4_site_b_https_root_redirect_forward[0]`
  - apply result: `0 added, 0 changed, 4 destroyed`.
- Live verification:
  - DNS now resolves for Cloudflare-proxied hostnames:
    - `admin.slothkko.com` -> `<REDACTED_PUBLIC_IP>`
    - `app-a.slothkko.com` -> `<REDACTED_PUBLIC_IP>`
    - `slothkko.com` -> `<REDACTED_PUBLIC_IP>`
  - HTTP probes:
    - `https://admin.slothkko.com/` -> `200` (Slothkko VDI Access Portal HTML)
    - `https://app-a.slothkko.com/` -> `200` (same root portal)
    - `https://app-b.slothkko.com/` -> `200` (same root portal)
  - Guacamole theming probe:
    - `https://admin.slothkko.com/guacamole/` HTML includes injected stylesheet:
      - `<link rel="stylesheet" href="/portal/guac-theme.css">`
- Security/config hygiene:
  - reviewed modified files for embedded secrets/keys; only template placeholders and documentation examples remain.
  - no Cloudflare token, private keys, or static credentials present in tracked diffs.

## Forward Proxy Bring-up for Guac Client Surf Control (2026-03-08 09:59 America/Toronto)
- User request:
  - add a forward proxy so Guacamole desktop clients can browse the web with policy controls.
- Root-cause/fix during apply:
  - targeted Terraform plan was failing with:
    - `Invalid provider configuration` for unaliased `registry.terraform.io/hashicorp/aws`.
  - fix applied in `phase4_forward_proxy.tf`:
    - added `provider = aws.site_a` to `data "aws_iam_policy_document" "phase4_site_a_forward_proxy_assume_role"`.
  - after fix, targeted plans/applies succeeded.
- Terraform resources created (Site A):
  - `aws_iam_role.phase4_site_a_forward_proxy[0]` -> `ddc-proposal-site-a-forward-proxy-role`
  - `aws_iam_instance_profile.phase4_site_a_forward_proxy[0]` -> `ddc-proposal-site-a-forward-proxy-profile`
  - `aws_security_group.phase4_site_a_forward_proxy[0]` -> `sg-0f6abf85c4738f606`
  - ingress rules:
    - proxy from VDI CIDRs `<REDACTED_PRIVATE_CIDR>`, `<REDACTED_PRIVATE_CIDR>` on `3128/tcp`
    - SSH admin from `<REDACTED_PUBLIC_CIDR>` on `22/tcp`
  - egress rules:
    - IPv4 `<REDACTED_PRIVATE_CIDR>`
    - IPv6 `::/0`
  - `aws_instance.phase4_site_a_forward_proxy[0]` -> `i-0ec0f03a88355dce6`
- Runtime endpoint details:
  - private proxy endpoint (for Guac desktops): `http://<REDACTED_PRIVATE_ENDPOINT>`
  - public IP (diagnostic only): `<REDACTED_PUBLIC_IP>`
- Browsing policy currently active:
  - allow source clients only from:
    - `<REDACTED_PRIVATE_CIDR>`
    - `<REDACTED_PRIVATE_CIDR>`
  - domain block list:
    - `facebook.com`
    - `instagram.com`
    - `tiktok.com`
    - `x.com`
    - `twitter.com`
  - explicit allow-list is empty (all domains allowed except blocked domains).
- Commands executed:
  - `terraform fmt phase4_forward_proxy.tf`
  - `terraform plan -target="aws_instance.phase4_site_a_forward_proxy" -var="phase2_enable_intercloud=false" -input=false`
  - `terraform apply -target="aws_instance.phase4_site_a_forward_proxy" -var="phase2_enable_intercloud=false" -input=false -auto-approve`
  - `terraform plan -target="aws_vpc_security_group_ingress_rule.phase4_site_a_forward_proxy_ssh" -target="aws_vpc_security_group_egress_rule.phase4_site_a_forward_proxy_egress_ipv6" -var="phase2_enable_intercloud=false" -input=false`
  - `terraform apply -target="aws_vpc_security_group_ingress_rule.phase4_site_a_forward_proxy_ssh" -target="aws_vpc_security_group_egress_rule.phase4_site_a_forward_proxy_egress_ipv6" -var="phase2_enable_intercloud=false" -input=false -auto-approve`
- Post-apply checks:
  - EC2 state verified: instance is `running` with expected private/public IPs.
  - SG rule verification confirms proxy access is restricted to VDI CIDRs.
  - in-cluster egress validation from live VDI desktop pod (`kubectl exec -n vdi deploy/vdi-desktop`):
    - direct internet test (`curl http://example.com`) -> `000` (timeout/no direct egress path)
    - proxy test (`curl -x http://<REDACTED_PRIVATE_ENDPOINT> http://example.com`) -> `200`
    - blocked-domain test (`curl -x http://<REDACTED_PRIVATE_ENDPOINT> http://facebook.com`) -> `403`

## Guacamole Login Branding Override Pass (2026-03-08 15:40 America/Toronto)
- User request:
  - replace default Apache Guacamole login branding/logo with Slothkko branding.
- Changes made:
  - updated `iac/k8s/vdi/guacamole-nodeport.yaml`:
    - expanded `guac-theme.css` selectors to target both `.login-ui` and `#login-ui` (higher match reliability across Guacamole versions/builds).
    - forced login logo override using `/portal/sloth-smile.svg` and `!important` background rules.
    - replaced visible app name text with `SLOTHKKO ACCESS` using CSS pseudo-content.
    - replaced visible version subtitle with `secure workspace`.
    - added new `guac-branding.js` asset to set browser tab title (`Slothkko Access`) and update favicon links to `/portal/sloth-smile.svg`.
    - updated NGINX sub_filter injection for `/guacamole/` HTML:
      - injects both `/portal/guac-theme.css` and `/portal/guac-branding.js` before `</head>`.
- Runtime incident and recovery:
  - direct `kubectl apply -f iac/k8s/vdi/guacamole-nodeport.yaml` reapplied placeholder image tokens from template (`__GUACD_IMAGE__`, `__GUACAMOLE_IMAGE__`, `__NGINX_IMAGE__`, `__POSTGRES_IMAGE__`) causing `InvalidImageName` pods.
  - recovered immediately by restoring deployment images:
    - `deployment/guacamole`: 
      - `guacd=<REDACTED_ECR_IMAGE_URI>`
      - `guacamole=<REDACTED_ECR_IMAGE_URI>`
      - `portal-proxy=<REDACTED_ECR_IMAGE_URI>`
    - `deployment/guacamole-db`:
      - `postgres=<REDACTED_ECR_IMAGE_URI>`
  - additional side effect from direct apply:
    - `guacamole-db-auth` secret was overwritten with placeholder literals (`__GUACAMOLE_DB_NAME__`, `__GUACAMOLE_DB_USER__`, `__GUACAMOLE_DB_PASSWORD__`).
    - because `guacamole-db` uses `emptyDir` storage, the subsequent DB pod restart reinitialized an empty Guacamole DB.
  - restored DB secret values and re-seeded baseline Guacamole state:
    - secret restored to:
      - `database=guacamole_db`
      - `username=guacamole_user`
      - `password=<existing restored value>`
    - rolled `deployment/guacamole-db` and `deployment/guacamole`.
    - re-seeded users and connections:
      - users: `guacadmin`, `john`
      - connections:
        - `Linux Desktop (VNC)` -> `<REDACTED_INTERNAL_DNS>:5900`
        - `Windows Desktop (RDP)` -> `<REDACTED_PRIVATE_ENDPOINT>`
      - permissions restored for both users on both connections (`READ/UPDATE/DELETE/ADMINISTER`).
- rollout verification:
  - `deployment/guacamole` and `deployment/guacamole-db` both returned to healthy state.
- Verification:
  - `https://admin.slothkko.com/guacamole/` HTML now injects:
    - `<link rel="stylesheet" href="/portal/guac-theme.css">`
    - `<script src="/portal/guac-branding.js"></script>`
  - `https://admin.slothkko.com/portal/guac-theme.css` serves updated `#login-ui` + `.login-ui` overrides and Slothkko text replacement rules.
  - `https://admin.slothkko.com/portal/guac-branding.js` served `200` with title/favicon branding logic.

## Root Portal Read-Only Status UX Pass (2026-03-08 19:10 America/Toronto)
- User request:
  - remove admin console login option from the main root portal screen.
  - remove the `Ops Stack` status item.
  - show Site A through Site D health.
  - add a bottom-right status link to a read-only reactor-like status page (no controls).
  - enforce health coloring semantics:
    - green: alive
    - yellow: device in distress
    - red: health check failing
- Changes made in `iac/k8s/vdi/guacamole-nodeport.yaml`:
  - updated portal `index.html`:
    - removed `Admin Console` action.
    - removed `Ops Stack` card.
    - replaced summary cards with Site A/B/C/D cards.
    - added fixed bottom-right `Status Page` link (`/status/`).
  - updated portal `portal.css`:
    - added explicit status color classes (`.dot.green`, `.dot.amber`, `.dot.red`).
    - added card border state styling by `data-state`.
    - added fixed link styling for status page launch control.
  - replaced `portal.js`:
    - health probes now run from the main portal against local proxy endpoints:
      - `/status/api/site-a/healthz`
      - `/status/api/site-b/healthz`
      - `/status/api/site-c/healthz`
      - `/status/api/site-d/healthz`
    - cards now update status text and color on a timer.
  - added new read-only status assets:
    - `status.html`
    - `status.css`
    - `status.js`
    - behavior:
      - no admin controls/actions.
      - per-site check list for `/healthz` and `/guacamole/`.
      - aggregate overall state indicator.
  - updated portal NGINX config (`vdi-portal-nginx`):
    - added `/status` redirect and `/status/` read-only page route.
    - added `/status/api/...` endpoint routes for Site A/B/C/D, proxying to:
      - `https://app-a.slothkko.com/...`
      - `https://app-b.slothkko.com/...`
      - `https://app-c.slothkko.com/...`
      - `https://app-d.slothkko.com/...`
    - probe endpoints support both `/healthz` and `/guacamole/`.
- Runtime adjustment after first deploy attempt:
  - first pass caused `portal-proxy` crash loop because unresolved external hosts in static `proxy_pass` upstreams fail NGINX startup.
  - fixed by:
    - enabling runtime DNS resolution in NGINX (`resolver <REDACTED_INTERNAL_DNS>`).
    - converting external status probe routes to `set $status_probe_url ...` + `proxy_pass $status_probe_url` (runtime resolution).
    - changing Site A probes to local in-pod checks for deterministic health:
      - `/status/api/site-a/healthz` -> `http://<REDACTED_PRIVATE_ENDPOINT>/healthz`
      - `/status/api/site-a/guacamole` -> `http://<REDACTED_PRIVATE_ENDPOINT>/guacamole/`
- Deployment actions executed on live Site A cluster (`ddc-site-a`):
  - updated `ConfigMap/vdi-portal-assets`.
  - updated `ConfigMap/vdi-portal-nginx`.
  - restarted `deployment/guacamole` and confirmed rollout success.
- Post-deploy probes:
  - `https://app-a.slothkko.com/` -> `200`
  - `https://app-a.slothkko.com/status/` -> `200`
  - `https://app-a.slothkko.com/status/api/site-a/healthz` -> `200`
  - `https://app-a.slothkko.com/status/api/site-a/guacamole` -> `200`
  - `https://app-a.slothkko.com/status/api/site-b/healthz` -> `502` (expected while remote endpoint is not resolvable/reachable)
  - `https://app-a.slothkko.com/status/api/site-c/healthz` -> `502` (expected while remote endpoint is not resolvable/reachable)
  - `https://app-a.slothkko.com/status/api/site-d/healthz` -> `502` (expected while remote endpoint is not resolvable/reachable)

## Status Page Navigation Tweak (2026-03-08 18:42 America/Toronto)
- User request:
  - add a button on the read-only status page to return to the main page.
- Change made:
  - updated `status.html` in `iac/k8s/vdi/guacamole-nodeport.yaml`:
    - added `Back to Main` link (`href="/"`) at the top of the status header.
  - updated `status.css`:
    - added `.back-link` and hover styles to match existing portal controls.
- Deployment:
  - updated only `ConfigMap/vdi-portal-assets` in Site A (`ddc-site-a`).
- Verification:
  - `https://slothkko.com/status/` now contains `Back to Main`.

## Guacamole Login Visual + Title Stabilization (2026-03-08 18:49 America/Toronto)
- User report:
  - login page background still appeared white.
  - browser tab/window title visibly changed multiple times during refresh.
- Changes made:
  - updated `guac-theme.css` (portal assets):
    - enforced full-page gradient on `html, body`.
    - set login wrapper surfaces to transparent to avoid white fallback bleed-through.
  - updated `guac-branding.js`:
    - removed delayed second branding pass (`setTimeout`).
    - apply branding immediately once and once on DOM ready (`{ once: true }`).
    - preserves single stable title target (`Slothkko Access`).
- Deployment:
  - updated `ConfigMap/vdi-portal-assets` on Site A (`ddc-site-a`).
- Verification:
  - `https://slothkko.com/portal/guac-theme.css` includes `html, body` full-page gradient rules.
  - `https://slothkko.com/portal/guac-branding.js` no longer includes delayed timeout rewrite logic.

## Guacamole Post-Login Readability Fix (2026-03-08 19:12 America/Toronto)
- User report:
  - connections/home screen text became difficult to read after login styling changes.
- Root cause:
  - login theme CSS selectors were affecting non-login views in the Guacamole SPA.
- Changes made:
  - scoped all `guac-theme.css` styling to login mode only using `.slk-login-page`.
  - updated `guac-branding.js` to dynamically toggle `.slk-login-page` based on visible login password field.
  - kept branding/title behavior while preventing login-only backgrounds from leaking into connection screens.
- Deployment:
  - updated `ConfigMap/vdi-portal-assets` in Site A (`ddc-site-a`).
- Verification:
  - `https://slothkko.com/portal/guac-theme.css` now contains `html.slk-login-page` scoped selectors.
  - `https://slothkko.com/portal/guac-branding.js` now contains `syncThemeMode` + visibility guard logic.

## Guacamole History Remote Host Forwarding Fix (2026-03-08 19:24 America/Toronto)
- User report:
  - Guacamole history `Remote host` column showed `<REDACTED_PRIVATE_IP>` (proxy interface) instead of original client source.
- Approach:
  - preserve original request origin in forwarded headers at NGINX.
  - enable Guacamole/Tomcat proxy IP valve parsing so history uses forwarded source IP.
- Changes made:
  - updated `vdi-portal-nginx` config (`default.conf`):
    - added Cloudflare-aware forwarding map:
      - prefer `$http_cf_connecting_ip` when present.
      - fallback to `$proxy_add_x_forwarded_for`.
    - set headers on `/guacamole/` upstream:
      - `X-Forwarded-For: $client_forwarded_for`
      - `X-Real-IP: $client_forwarded_for`
      - `X-Original-Forwarded-For: $http_x_forwarded_for`
  - updated Guacamole container env:
    - `REMOTE_IP_VALVE_ENABLED=true`
    - `PROXY_IP_HEADER=X-Forwarded-For`
    - `PROXY_PROTOCOL_HEADER=X-Forwarded-Proto`
    - `PROXY_ALLOWED_IPS_REGEX=127\\.0\\.0\\.1|::1|10\\..*|192\\.168\\..*|172\\.(1[6-9]|2[0-9]|3[0-1])\\..*`
  - ensured these env variables are only on container `guacamole` (not `guacd` or `portal-proxy`).
- Deployment actions (Site A / `ddc-site-a`):
  - `kubectl set env deployment/guacamole ...` for Guacamole proxy valve vars.
  - apply updated `ConfigMap/vdi-portal-nginx`.
  - rollout restart + rollout status success for `deployment/guacamole`.
- Expected result:
  - existing history rows remain unchanged (`<REDACTED_PRIVATE_IP>` for prior sessions).
  - new sessions should record forwarded client source IP rather than local loopback.

## Guacamole Remote Host Resolution (Final) (2026-03-08 19:23 America/Toronto)
- User report:
  - remote host values still appeared as `<REDACTED_PRIVATE_IP>` in Guacamole history.
- Findings:
  - live namespace is `vdi` (not `ddc-site-a`).
  - `portal-proxy` was crashlooping due invalid NGINX map regex token (`[^, ]+` with unquoted space).
- Fixes applied:
  - corrected NGINX map regex to `~^(?<first>[^,]+) $first;`.
  - added deterministic client IP fallback chain in `default.conf`:
    - `CF-Connecting-IP` -> `X-Real-IP` -> first `X-Forwarded-For` hop -> `$remote_addr`.
  - kept upstream header propagation to Guacamole:
    - `X-Forwarded-For`, `X-Real-IP`, `X-Forwarded-Proto`.
  - added explicit proxy access log diagnostics:
    - `xff`, `xri`, `cfip`, and computed `effective` IP.
  - restarted `deployment/guacamole` in namespace `vdi` after ConfigMap update.
- Verification:
  - `portal-proxy` logs now show forwarded identity fields, e.g.:
    - `cfip="<REDACTED_PUBLIC_IP>" ... effective="<REDACTED_PUBLIC_IP>"` on `/guacamole/api/tokens` and websocket tunnel requests.
  - PostgreSQL history now records real client source for new sessions:
    - `remote_host = <REDACTED_PUBLIC_IP>` for latest `Windows Desktop (RDP)` entries.
  - older rows remain unchanged and still show `<REDACTED_PRIVATE_IP>` (expected).

## FIDO2 OIDC Login Enablement (Keycloak + Guacamole) (2026-03-08 20:24 America/Toronto)
- User request:
  - implement tap-based FIDO2 login path for Guacamole to add easy security.
- Manifest/template changes:
  - updated `iac/k8s/vdi/guacamole-nodeport.yaml`:
    - added `Secret/keycloak-auth` (admin + bootstrap user credentials placeholders).
    - added `ConfigMap/keycloak-realm-import` with realm `vdi`, WebAuthn passwordless policy, and `guacamole` OIDC client.
    - added `Service/Deployment keycloak` in namespace `vdi`.
    - added `/idp/` reverse-proxy route in `vdi-portal-nginx` (`X-Forwarded-Proto=https`, `X-Forwarded-Port=443`).
    - added Guacamole OIDC env vars (`OPENID_*`) and extension priority (`openid,postgresql`).
    - set Keycloak startup mode to `start-dev` for deterministic startup in this constrained environment.
    - set Keycloak probes to TCP on `8080` (health endpoints under management port were not stable via current path routing).
    - adjusted Keycloak resource requests/limits to fit current VDI node capacity.
- Bootstrap script changes:
  - updated `scripts/invoke_phase4_vdi_service_bootstrap.ps1`:
    - added Keycloak parameters and secret-safe placeholder rendering:
      - `-KeycloakImage`
      - `-KeycloakAdminUsername` / `-KeycloakAdminPassword`
      - `-KeycloakBootstrapUsername` / `-KeycloakBootstrapPassword`
      - `-EcrKeycloakRepositoryName`
    - updated `-UseRegionalEcrImages` flow to include Keycloak image URI replacement.
- ECR mirroring script changes:
  - updated `scripts/invoke_phase4_vdi_ecr_image_mirror.ps1`:
    - added Keycloak mirror inputs and outputs:
      - `-KeycloakSourceImage`
      - `-EcrKeycloakRepositoryName`
    - now pulls/tags/pushes Keycloak alongside existing VDI images.
- Documentation updates:
  - updated `iac/terraform/README.md` script notes for new Keycloak/FIDO2 options and image mirroring scope.
  - updated `docs/13_operations_foundations/authentication.md` with VDI OIDC + WebAuthn flow.
- Live rollout and fixes (namespace `vdi`):
  - deployed Keycloak resources and Guacamole OIDC env config.
  - mirrored Keycloak image to private ECR and switched deployment image to:
    - `<REDACTED_ECR_IMAGE_URI>`
  - resolved Keycloak startup failures by creating DB schema:
    - `CREATE SCHEMA IF NOT EXISTS keycloak ...`
  - verified Keycloak rollout success (`deployment/keycloak` healthy) and Guacamole rollout success.
  - verified OIDC discovery endpoint:
    - `https://slothkko.com/idp/realms/vdi/.well-known/openid-configuration` -> `200`
    - issuer/auth/jwks now resolve with expected `https://slothkko.com/idp/...` URLs.
  - verified Guacamole OpenID redirect endpoint:
    - `https://slothkko.com/guacamole/api/ext/openid/login` -> `303` to Keycloak auth endpoint.
  - verified Guacamole loads OpenID extension before PostgreSQL authorization extension.
- Security/operations note:
  - current Keycloak runtime is `start-dev` due image/build/runtime constraints in this environment; keep this as transitional and move to production-mode Keycloak (`start --optimized` with pre-built image) in the next hardening pass.
- Additional compatibility fixes during rollout:
  - switched Keycloak runtime to `start-dev` after production-mode first-start/image-build loop in this environment.
  - created PostgreSQL schema `keycloak` to satisfy `KC_DB_SCHEMA=keycloak` and unblock Liquibase initialization.
  - enabled `implicitFlowEnabled=true` for Keycloak client `guacamole` (Guacamole OpenID extension requests `response_type=id_token`).
  - corrected `/idp/` proxy forwarding to preserve external HTTPS origin metadata (`X-Forwarded-Proto=https`, `X-Forwarded-Port=443`) so OIDC issuer/JWKS URLs align with `https://slothkko.com/idp/...`.

## OIDC White-Screen Callback Fix + Templated Manifest Recovery (2026-03-08 20:58 America/Toronto)
- User report:
  - after FIDO2 registration, redirect returned to `https://slothkko.com/guacamole/#/?session_state=...&id_token=...` and page stayed white.
- Root cause (primary):
  - Guacamole OpenID validation timed out on JWKS fetch from external endpoint:
    - `https://slothkko.com/idp/realms/vdi/protocol/openid-connect/certs`
  - from inside the Guacamole container, that URL was not reachable (connect timeout), causing token rejection.
- Fix (primary):
  - set `OPENID_JWKS_ENDPOINT` to in-cluster Keycloak service URL:
    - `http://<REDACTED_INTERNAL_DNS>:8080/idp/realms/vdi/protocol/openid-connect/certs`
  - left browser-facing endpoints external (`OPENID_AUTHORIZATION_ENDPOINT`, `OPENID_ISSUER`) to preserve redirect behavior.
- Incident during remediation:
  - applying raw `iac/k8s/vdi/guacamole-nodeport.yaml` directly pushed unresolved placeholders (`__...__`) into live Deployments/Secrets/ConfigMap.
  - this broke image names and auth/bootstrap secrets until corrected.
- Recovery actions:
  - restored deployment images to private ECR for `guacamole`, `guacamole-db`, and `keycloak`.
  - re-ran `invoke_phase4_vdi_service_bootstrap.ps1` in `SiteAOnly` mode with explicit ECR image args to re-render templates correctly.
  - restarted `guacamole-db`, `keycloak`, and `guacamole` so pods consumed corrected secrets.
  - recreated DB schema required by Keycloak:
    - `CREATE SCHEMA IF NOT EXISTS keycloak AUTHORIZATION guacamole_user;`
- Verification:
  - all VDI pods healthy in namespace `vdi` (`guacamole`, `guacamole-db`, `keycloak`, `vdi-desktop`).
  - `/idp/realms/vdi/.well-known/openid-configuration` returns `200`.
  - `/guacamole/api/ext/openid/login` returns `303`.
  - Guacamole logs no longer show `Rejected invalid OpenID token` / `SocketTimeoutException` for JWKS.
  - realm import now contains bootstrap username `guacadmin` (no unresolved placeholder tokens).
- Operational guardrail:
  - do not `kubectl apply` the templated manifest directly from repo.
  - always render via bootstrap script (`invoke_phase4_vdi_service_bootstrap.ps1`) or an equivalent placeholder-substitution step first.

## OIDC Redirect Loop Fix (ID Token Lifetime Mismatch) (2026-03-08 21:05 America/Toronto)
- User report:
  - successful IdP login looped back repeatedly between `/guacamole/` and Keycloak.
- Root cause:
  - Guacamole OpenID validation was configured with:
    - `OPENID_MAX_TOKEN_VALIDITY=5`
  - Keycloak-issued ID tokens had ~15 minute lifetime, so Guacamole rejected them:
    - `The Expiration Time (exp=...) claim value cannot be more than 5 minutes in the future...`
  - this produced repeated `POST /guacamole/api/tokens` `403` and immediate re-redirect to `/idp/.../auth`.
- Fix applied:
  - set `OPENID_MAX_TOKEN_VALIDITY=30` on Guacamole container env.
  - rolled `deployment/guacamole`.
  - updated template manifest (`iac/k8s/vdi/guacamole-nodeport.yaml`) to keep `30` as desired state.
- Verification:
  - `kubectl -n vdi get deploy guacamole ...` shows `OPENID_MAX_TOKEN_VALIDITY=30`.
  - pods healthy after rollout (`guacamole 3/3`, `keycloak 1/1`, `guacamole-db 1/1`).

## Desktop Connections Recovered After DB Reinit (2026-03-08 21:18 America/Toronto)
- User report:
  - Linux and Windows desktop entries disappeared from Guacamole.
- Findings:
  - `guacamole_connection` table was empty.
  - only `guacadmin` existed in Guacamole auth tables; `john` was missing.
- Recovery actions (namespace `vdi`):
  - re-created local user entity/account for `john` (authorization mapping).
  - re-seeded desktop connections:
    - `Linux Desktop (VNC)` -> `<REDACTED_INTERNAL_DNS>:5900`
    - `Windows Desktop (RDP)` -> `<REDACTED_PRIVATE_ENDPOINT>` (username `guacuser`)
  - restored per-connection permissions for both users:
    - `guacadmin`, `john`: `READ/UPDATE/DELETE/ADMINISTER`
  - ensured RDP connection has baseline parameters (`security=any`, `ignore-cert=true`).
- Verification queries:
  - `SELECT connection_name, protocol FROM guacamole_connection` returns both desktop connections.
  - permission join confirms both users mapped to both connections.

## Windows Desktop Rebuild With Known RDP Credential (2026-03-08 21:35 America/Toronto)
- User request:
  - delete and rebuild Windows desktop with a known credential, then stop RDP credential prompts in Guacamole.
- Actions taken (Terraform + AWS profile `ddc`):
  - destroyed `aws_instance.phase4_site_a_windows_desktop[0]`.
  - recreated the same resource with explicit Windows bootstrap `user_data` to ensure local RDP account setup for `guacuser`.
  - new instance:
    - `instance_id = i-09cee8b15417e4aca`
    - `private_ip = <REDACTED_PRIVATE_IP>`
  - waited for EC2 status checks to pass (`instance-status-ok`).
- Guacamole updates:
  - updated `Windows Desktop (RDP)` connection target from old IP to `<REDACTED_PRIVATE_IP>`.
  - stored RDP credential parameters for non-interactive connect (`username/password`) and retained `security=any`, `ignore-cert=true`.
- Verification:
  - DB query confirms Windows connection parameters now include hostname, username, password, port, and RDP security options.

## Slothkko Access Login Recovery (Keycloak Realm Users) (2026-03-08 22:02 America/Toronto)
- User report:
  - `guacadmin` and `john` could not authenticate on Slothkko Access login flow.
- Findings from Keycloak logs:
  - `guacadmin`: `LOGIN_ERROR` with `invalid_user_credentials`.
  - `john`: `LOGIN_ERROR` with `user_not_found`.
- Remediation:
  - reset `guacadmin` password in realm `vdi`.
  - created realm user `john` and set password.
  - completed user profile fields for `john` (first name, last name, email, verified) to remove “Account is not fully set up” gate.
- Verification:
  - direct token auth on realm `vdi` succeeded for both `guacadmin` and `john`.
  - Guacamole DB permissions already mapped for both users on:
    - `Linux Desktop (VNC)`
    - `Windows Desktop (RDP)`

## White Screen / `APP.NAME` Bootstrap Stall Mitigation (2026-03-09 11:45 America/Toronto)
- User report:
  - at work network, loading `https://slothkko.com/guacamole/` stalled on white screen with title `APP.NAME`.
- Findings (from `portal-proxy` access logs):
  - work IP `<REDACTED_PUBLIC_IP>` repeatedly received:
    - `GET /guacamole/` -> `200`
    - `GET /guacamole/app.js?...` -> `304`
    - `GET /guacamole/app.css?...` -> `304`
  - no follow-up `/guacamole/api/*` bootstrap calls were seen for the same client sessions.
  - pattern indicated a client-side bootstrap failure likely caused by stale static bundle reuse.
- Mitigation applied (live ConfigMap `vdi-portal-nginx`):
  - in `location /guacamole/` added:
    - `proxy_set_header If-None-Match "";`
    - `proxy_set_header If-Modified-Since "";`
    - `proxy_hide_header ETag;`
    - `proxy_hide_header Last-Modified;`
    - explicit no-store/no-cache headers on responses.
  - rolled `deployment/guacamole` to pick up updated NGINX config.
- Desired-state update:
  - mirrored same `location /guacamole/` directives into template manifest:
    - `iac/k8s/vdi/guacamole-nodeport.yaml`
- Verification:
  - external check now returns `200` for `/guacamole/app.js?...` even when `If-None-Match` is sent.
  - `/guacamole/api/languages` reachable with `200`.

## Work-Browser Cache Bust + Branding Script Simplification (2026-03-09 12:10 America/Toronto)
- Additional findings:
  - work client (`<REDACTED_PUBLIC_IP>`) still stalled and only requested:
    - `/guacamole/`
    - `/guacamole/app.js`
    - `/guacamole/app.css`
  - no `/guacamole/api/*` calls observed after those requests.
  - no `/portal/*` fetches observed, indicating browser-side reuse of cached portal assets.
- Mitigation applied:
  - simplified `guac-branding.js` to a non-observing, fail-safe implementation (no mutation observers / class toggling loop risk).
  - changed injected asset URLs to versioned query strings:
    - `/portal/guac-theme.css?v=20260309r2`
    - `/portal/guac-branding.js?v=20260309r2`
  - changed `/portal/` cache policy to `Cache-Control: no-store` to reduce stale theme asset reuse.
  - rolled `deployment/guacamole` after ConfigMap updates.
- Verification:
  - `/guacamole/` HTML now injects versioned theme/branding asset URLs.
  - `/portal/guac-branding.js?v=20260309r2` and `/portal/guac-theme.css?v=20260309r2` return `200` with `Cache-Control: no-store`.

## Windows Desktop NetBIOS Noise Control (Port 137) (2026-03-09 12:20 America/Toronto)
- User signal:
  - firewall observed high volume of `137` traffic.
- Findings:
  - Site A Windows desktop security group (`ddc-proposal-site-a-windows-desktop-sg`) had default unrestricted egress (`<REDACTED_PRIVATE_CIDR>`, `::/0`).
- Immediate runtime hardening (AWS CLI, us-east-1):
  - removed default allow-all egress.
  - allowed only:
    - TCP 80 to `<REDACTED_PRIVATE_CIDR>`
    - TCP 443 to `<REDACTED_PRIVATE_CIDR>`
    - UDP 53 to `<REDACTED_PRIVATE_CIDR>` (VPC resolver)
    - TCP 53 to `<REDACTED_PRIVATE_CIDR>`
- Desired-state IaC update:
  - `iac/terraform/phase4_vdi_windows_desktop.tf`
    - set SG `egress = []` to suppress default allow-all rule.
    - added explicit egress rules for HTTP/HTTPS (IPv4/IPv6 controlled CIDRs) and DNS to VPC resolver.

## User Provisioning: `cox` (2026-03-09 14:45 America/Toronto)
- User request:
  - create access user `cox`.
- Keycloak actions:
  - created user `cox` in realm `vdi`.
  - set password (non-temporary) and populated required profile fields:
    - `firstName=Cox`, `lastName=User`, `email=cox@slothkko.local`, `emailVerified=true`.
  - verified credential acceptance via Keycloak admin CLI login against realm `vdi`.
- Guacamole DB actions:
  - ensured `guacamole_entity` + `guacamole_user` row for `cox`.
  - granted same desktop connection permissions as `john`:
    - `Linux Desktop (VNC)`
    - `Windows Desktop (RDP)`
    - with `READ/UPDATE/DELETE/ADMINISTER`.

## Ansible User Provisioning Playbook Added (2026-03-09 15:05 America/Toronto)
- User request:
  - create a playbook to add users and document it.
- Added automation:
  - `iac/ansible/playbooks/vdi_add_user.yml`
  - provisions a VDI user in Keycloak realm `vdi` and Guacamole DB.
  - clones Guacamole connection permissions from template user (default: `john`).
- Added operations documentation:
  - `iac/ansible/README.md` (execution and variables).
  - `docs/13_operations_foundations/vdi_user_provisioning_playbook.md`.
  - linked playbook doc in:
    - `docs/13_operations_foundations/readme.md`
    - `mkdocs.yml` navigation.

## User-Specific Desktop Set for `cox` (2026-03-09 15:22 America/Toronto)
- User request:
  - give `cox` his own set of desktops.
- Actions (Guacamole DB, namespace `vdi`):
  - cloned shared desktop connection objects into user-specific entries:
    - `Cox Linux Desktop (VNC)`
    - `Cox Windows Desktop (RDP)`
  - copied connection parameters/attributes from existing shared templates.
  - set permissions so only `cox` and `guacadmin` have access to the new entries.
  - removed `cox` permissions from shared connections:
    - `Linux Desktop (VNC)`
    - `Windows Desktop (RDP)`
- Result:
  - `cox` now sees only his dedicated connection set.
  - `john` remains on shared desktop connections.

## Ansible Playbook Extended for Per-User VM Provisioning (2026-03-09 15:40 America/Toronto)
- User request:
  - include dedicated VM creation as part of the user-add playbook.
- Changes:
  - updated `iac/ansible/playbooks/vdi_add_user.yml` to add per-user desktop provisioning flow.
  - default mode now provisions:
    - per-user Linux desktop deployment/service in `vdi` namespace.
    - per-user Windows EC2 instance (AWS Site A), then waits for healthy status.
  - playbook now wires dedicated desktop endpoints into per-user Guacamole connections and permissions.
  - retained fallback shared-permission path when `vdi_create_personal_desktops=false`.
- Documentation updates:
  - `iac/ansible/README.md` updated with new required vars and run examples.
  - `docs/13_operations_foundations/vdi_user_provisioning_playbook.md` updated with per-user VM behavior and validation steps.

## Ansible Playbook Reliability Fix for Existing User Windows VMs (2026-03-09 16:05 America/Toronto)
- User request:
  - ensure per-user VM creation path works as part of user-add automation.
- Changes:
  - hardened `iac/ansible/playbooks/vdi_add_user.yml` Windows flow to prefer existing running/pending per-user instances before launching new ones.
  - if an existing per-user instance is `stopping`, playbook waits for `instance-stopped` then starts it.
  - if an existing per-user instance is `stopped`, playbook starts it automatically.
  - launch path is now used only when no existing per-user Windows instance is found.
- Outcome:
  - repeat runs now reliably reuse prior user desktops instead of failing during wait-state transitions.
