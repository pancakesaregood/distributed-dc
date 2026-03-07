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

## Next Build Step
- Apply and validate published app path when ready:
  - set `phase4_enable_published_app_path=true`
  - set backend targets:
    - `phase4_site_a_published_app_backend_ipv4_targets`
    - `phase4_site_b_published_app_backend_ipv4_targets`
- Published app path pre-flight:
  - Current dry-run with `phase4_enable_published_app_path=true` proposes `12` creates (ALB/SG/TG/listener/WAF x2 sites).
  - If backend target lists are empty, listener mode is `fixed-response` (`503`), which is safe for edge bring-up.
  - To forward live traffic, provide reachable backend IPs in app/data tiers and rerun plan.
- Suggested next-pass commands:
  - `terraform plan -var "phase4_enable_published_app_path=true"`
  - `terraform apply -var "phase4_enable_published_app_path=true" -auto-approve`
- Apply and validate VDI reference stack when ready:
  - set `phase4_enable_vdi_reference_stack=true`
  - keep `phase4_enable_service_onboarding=true` and `phase3_enable_platform=true`
  - review VDI sizing controls:
    - `phase4_vdi_aws_node_*`
    - `phase4_vdi_gcp_node_*`
  - run (recommended helper):
    - `.\scripts\invoke_phase4_vdi_enablement.ps1 -AwsProfile "ddc" -GcpCredentialsPath "C:\Users\john\.gcp\ddc-sa.json" -GcpProjectId "worldbuilder-413006" -PlanOnly`
    - `.\scripts\invoke_phase4_vdi_enablement.ps1 -AwsProfile "ddc" -GcpCredentialsPath "C:\Users\john\.gcp\ddc-sa.json" -GcpProjectId "worldbuilder-413006" -AutoApprove`
- Execute failover scenarios and backup/restore drills; record outcomes in latest `execution_record.md`.

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
