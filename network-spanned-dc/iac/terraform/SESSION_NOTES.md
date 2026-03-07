# Session Notes - Resume Guide

## Current State (2026-03-07)
- Docs are building and published to GitHub Pages.
- Terraform Phase 1, Phase 2, and Phase 3 are applied and converged.
- Terraform Phase 4 worker-capacity scaffolding is now in code (gated, not applied).
- Terraform Phase 5 resilience-validation pack is now in code (scripts/templates/flags).
- Drift check with Phase 3 enabled:
  - `terraform plan -var "phase3_enable_platform=true"` returns `No changes`.
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
- GCP GKE clusters:
  - Site C: `ddc-proposal-site-c-gke` (`RUNNING`, version `1.34.3-gke.1444000`)
  - Site D: `ddc-proposal-site-d-gke` (`RUNNING`, version `1.34.3-gke.1444000`)
- Design intent:
  - control planes only (no worker node pools yet)
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

## Phase 4 Scaffold (Current)
- New gated flags:
  - `phase4_enable_service_onboarding`
  - `phase4_enable_published_app_path`
  - `phase4_enable_vdi_reference_stack`
- New modules added:
  - `modules/aws_eks_nodegroup`
  - `modules/gcp_gke_node_pool`
- Root wiring added in:
  - `phase4_service_onboarding.tf`

## Phase 5 Scaffold (Current)
- Evidence capture script:
  - `scripts/invoke_phase5_evidence_capture.ps1`
- Documentation and template:
  - `docs/10_implementation/phase5_resilience_handover.md`
  - `docs/04_failover_dr/phase5_execution_record_template.md`
- Terraform deliverable flags:
  - `phase5_enable_resilience_validation`
  - `phase5_enable_backup_restore_drills`
  - `phase5_enable_handover_signoff`

## Next Build Step (Phase 4 Execution)
- Enable and apply worker capacity:
  - `terraform plan -var "phase3_enable_platform=true" -var "phase4_enable_service_onboarding=true"`
- Then implement remaining source-material deliverables:
  - published app path (`WAF + LB + health gating`)
  - VDI reference stack and identity policy controls
- After service onboarding, execute failover and DR runbook evidence capture.

## Phase 5 Execution Starter
```powershell
cd e:\distributed-dc\network-spanned-dc\iac\terraform
$env:GOOGLE_APPLICATION_CREDENTIALS="C:\Users\john\.gcp\ddc-sa.json"
$env:AWS_PROFILE="ddc"
.\scripts\invoke_phase5_evidence_capture.ps1 -ProjectId "worldbuilder-413006"
```
