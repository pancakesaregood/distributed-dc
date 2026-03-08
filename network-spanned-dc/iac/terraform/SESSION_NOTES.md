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
  - `C:\Users\john\.gcp\ddc-sa.json` length is greater than `0`.

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
$env:GOOGLE_APPLICATION_CREDENTIALS="C:\Users\john\.gcp\ddc-sa.json"
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
  - `.\scripts\invoke_phase4_vdi_enablement.ps1 -AwsProfile "ddc" -GcpCredentialsPath "C:\Users\john\.gcp\ddc-sa.json" -GcpProjectId "worldbuilder-413006" -DisableGcpBrokerIdentity -PreflightOnly`
  - `.\scripts\invoke_phase4_vdi_enablement.ps1 -AwsProfile "ddc" -GcpCredentialsPath "C:\Users\john\.gcp\ddc-sa.json" -GcpProjectId "worldbuilder-413006" -DisableGcpBrokerIdentity -AutoApprove`
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
    - `.\scripts\invoke_phase4_vdi_enablement.ps1 -AwsProfile "ddc" -GcpCredentialsPath "C:\Users\john\.gcp\ddc-sa.json" -GcpProjectId "worldbuilder-413006" -PlanOnly`
    - `.\scripts\invoke_phase4_vdi_enablement.ps1 -AwsProfile "ddc" -GcpCredentialsPath "C:\Users\john\.gcp\ddc-sa.json" -GcpProjectId "worldbuilder-413006" -AutoApprove`
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
    - `.\scripts\invoke_phase4_vdi_enablement.ps1 -AwsProfile "ddc" -GcpCredentialsPath "C:\Users\john\.gcp\ddc-sa.json" -GcpProjectId "worldbuilder-413006" -EnablePublishedAppPath -DisableGcpBrokerIdentity -AutoApprove`
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
  - `.\scripts\invoke_phase4_vdi_enablement.ps1 -AwsProfile "ddc" -GcpCredentialsPath "C:\Users\john\.gcp\ddc-sa.json" -GcpProjectId "worldbuilder-413006" -EnablePublishedAppPath -EnableCloudflareEdge -CloudflareZoneName "slothkko.com" -CloudflareSiteARecordName "app-a" -CloudflareSiteBRecordName "app-b" -DisableGcpBrokerIdentity -AutoApprove`
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
    - `.\scripts\invoke_phase4_published_app_cutover.ps1 -AwsProfile "ddc" -GcpCredentialsPath "C:\Users\john\.gcp\ddc-sa.json" -GcpProjectId "worldbuilder-413006" -DisableGcpBrokerIdentity -PreflightOnly`
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
    - `.\scripts\invoke_phase4_vdi_eks_backend_cutover.ps1 -AwsProfile "ddc" -GcpCredentialsPath "C:\Users\john\.gcp\ddc-sa.json" -GcpProjectId "worldbuilder-413006" -DisableGcpBrokerIdentity -PreflightOnly`
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
    - `.\scripts\invoke_dev_environment_up.ps1 -AwsProfile "ddc" -GcpCredentialsPath "C:\Users\john\.gcp\ddc-sa.json"`
  - stop platform between sessions:
    - `.\scripts\invoke_dev_environment_down.ps1 -AwsProfile "ddc" -GcpCredentialsPath "C:\Users\john\.gcp\ddc-sa.json"`
  - stop platform and suspend inter-cloud VPN/BGP to save more:
    - `.\scripts\invoke_dev_environment_down.ps1 -AwsProfile "ddc" -GcpCredentialsPath "C:\Users\john\.gcp\ddc-sa.json" -SuspendIntercloud`
  - maximum savings (full destroy):
    - `.\scripts\invoke_dev_environment_down.ps1 -AwsProfile "ddc" -GcpCredentialsPath "C:\Users\john\.gcp\ddc-sa.json" -DestroyAll`

## Phase 5 Execution Starter
```powershell
cd e:\distributed-dc\network-spanned-dc\iac\terraform
$env:GOOGLE_APPLICATION_CREDENTIALS="C:\Users\john\.gcp\ddc-sa.json"
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
  - `.\scripts\invoke_phase4_vdi_eks_backend_cutover.ps1 -AwsProfile "ddc" -GcpCredentialsPath "C:\Users\john\.gcp\ddc-sa.json" -GcpProjectId "worldbuilder-413006" -DisableGcpBrokerIdentity -EnablePublishedAppTls -EnableCloudflareEdge -CloudflareZoneName "slothkko.com" -CloudflareSiteARecordName "app-a" -CloudflareSiteBRecordName "app-b" -CloudflareRecordProxied -CloudflareRecordTtl 1 -AutoApprove`
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
  - `.\scripts\invoke_phase4_vdi_eks_backend_cutover.ps1 -AwsProfile "ddc" -GcpCredentialsPath "C:\Users\john\.gcp\ddc-sa.json" -GcpProjectId "worldbuilder-413006" -DisableGcpBrokerIdentity -EnableCloudflareEdge -CloudflareZoneName "slothkko.com" -CloudflareSiteARecordName "app-a" -CloudflareSiteBRecordName "app-b" -AutoApprove`
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
  - updated `guacamole-db-init` ConfigMap in both clusters with the same non-default admin password seed (hash/salt) so DB pod re-initialization does not revert to `guacadmin/guacadmin`.
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
  - `.\scripts\invoke_phase4_vdi_eks_backend_cutover.ps1 -AwsProfile "ddc" -GcpCredentialsPath "C:\Users\john\.gcp\ddc-sa.json" -GcpProjectId "worldbuilder-413006" -DisableGcpBrokerIdentity -EnablePublishedAppTls -EnableCloudflareEdge -CloudflareZoneName "slothkko.com" -CloudflareSiteARecordName "app-a" -CloudflareSiteBRecordName "app-b" -CloudflareRecordProxied -CloudflareRecordTtl 1 -AutoApprove`
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
