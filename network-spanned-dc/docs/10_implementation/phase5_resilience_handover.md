# Phase 5 Resilience Validation and Handover

This phase executes the source-material requirements:
- Execute failover scenarios and DR runbooks.
- Perform backup and restore drills against RTO/RPO targets.
- Complete operations handover with runbook sign-off.

Reference sources:
- `docs/10_implementation/readme.md`
- `docs/04_failover_dr/failover_scenarios.md`
- `docs/04_failover_dr/test_plan.md`
- `docs/04_failover_dr/dr_runbooks.md`
- `docs/04_failover_dr/rto_rpo_targets.md`

## Phase 5 Runtime Pack

Script:
- `iac/terraform/scripts/invoke_phase5_evidence_capture.ps1`

The script captures:
- Terraform state/output snapshots.
- AWS VPN and EKS health snapshots.
- GCP VPN, Cloud Router, and GKE health snapshots.
- A generated `phase5_summary.md` and `execution_record.md`.

Default artifact location:
- `iac/terraform/evidence/phase5-<timestamp>/`

## Execution Command

```powershell
cd e:\distributed-dc\network-spanned-dc\iac\terraform
$env:GOOGLE_APPLICATION_CREDENTIALS="C:\Users\john\.gcp\ddc-sa.json"
$env:AWS_PROFILE="ddc"
.\scripts\invoke_phase5_evidence_capture.ps1 -ProjectId "worldbuilder-413006"
```

## Deliverable Checklist

1. Resilience validation:
   - Run targeted failover scenarios (A-F as applicable).
   - Record measured RTO/RPO in generated `execution_record.md`.
2. Backup/restore drills:
   - Run at least one Tier 1 and one Tier 2 restore drill.
   - Link logs and timestamps into `execution_record.md`.
3. Handover sign-off:
   - Obtain Network/Security, Platform, Operations, and Governance sign-offs.
   - Capture residual risks and action owners.

## Terraform Tracking Flags

Phase tracking flags can be set in `terraform.tfvars`:
- `phase5_enable_resilience_validation`
- `phase5_enable_backup_restore_drills`
- `phase5_enable_handover_signoff`

These do not create infrastructure by themselves; they track execution readiness in Terraform outputs.
