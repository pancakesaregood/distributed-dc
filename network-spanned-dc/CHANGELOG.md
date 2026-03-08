# Changelog

## [0.5.0] - 2026-03-08
### Added
- Phase 4 Cloudflare edge extensions:
  - additional hostname mapping (`admin`, `www`, `@`) support
  - published-app TLS SAN support for additional hostnames
  - Cloudflare DNS output expansion for additional records
- New Terraform resources and wiring for:
  - published-app TLS listeners and ACM validation (`phase4_published_app_tls.tf`)
  - Cloudflare edge records module entrypoint (`phase4_cloudflare_edge.tf`)
- VDI operations and service onboarding tooling:
  - `scripts/invoke_phase4_vdi_ecr_image_mirror.ps1`
  - `scripts/invoke_phase4_vdi_service_bootstrap.ps1`
  - `scripts/invoke_phase4_published_app_cutover.ps1`
  - `scripts/invoke_phase4_vdi_eks_backend_cutover.ps1`
  - `scripts/invoke_vdi_ops_console.ps1`
  - `tools/vdi_ops_console/*` (local admin panel)
- Kubernetes manifests for VDI bootstrap and sample desktop:
  - `iac/k8s/vdi/guacamole-nodeport.yaml`
  - `iac/k8s/vdi/guacamole-postgresql-init.sql`
  - `iac/k8s/vdi/vdi-desktop-vnc.yaml`

### Changed
- Terraform Phase 4 modules/variables/outputs updated for:
  - ingress internet edge controls for published app path
  - ALB root redirect and HTTPS listener integration
  - Cloudflare DNS automation and TLS validation flows
  - VDI reference stack controls and output shaping
- `invoke_phase4_vdi_enablement.ps1` expanded with:
  - stronger preflight validation (AWS/GCP checks and published app checks)
  - backend target override support
  - improved diagnostics collection and health-check orchestration
  - Cloudflare/TLS apply argument handling improvements
- `invoke_phase5_evidence_capture.ps1` expanded to capture:
  - published app endpoint states
  - Cloudflare DNS resolving/target-alignment states
- Terraform runbook/session documentation updated in:
  - `iac/terraform/README.md`
  - `iac/terraform/SESSION_NOTES.md`

## [0.4.0] - 2026-03-07
### Added
- Phase 5 resilience-validation pack:
  - `iac/terraform/scripts/invoke_phase5_evidence_capture.ps1`
  - `docs/10_implementation/phase5_resilience_handover.md`
  - `docs/04_failover_dr/phase5_execution_record_template.md`
- Terraform Phase 5 deliverable tracking flags and outputs for resilience validation, backup/restore drills, and handover sign-off.

### Changed
- MkDocs navigation updated to include Phase 5 implementation and DR template pages.
- Terraform and repository notes updated to reflect Phase 5 readiness workflow.

## [0.3.0] - 2026-03-07
### Added
- Terraform Phase 4 scaffold for service onboarding capacity in `iac/terraform/phase4_service_onboarding.tf`.
- Reusable modules for worker capacity:
  - `modules/aws_eks_nodegroup`
  - `modules/gcp_gke_node_pool`
- Phase 4 deliverable tracking flags:
  - `phase4_enable_service_onboarding`
  - `phase4_enable_published_app_path`
  - `phase4_enable_vdi_reference_stack`

### Changed
- Terraform variables, outputs, examples, and runbook notes updated for Phase 4 planning/execution.

## [0.2.0] - 2026-03-07
### Added
- Terraform Phase 2 inter-cloud VPN/BGP deployment across A-C, A-D, B-C, B-D pairs.
- Terraform Phase 3 platform baseline with EKS control planes in AWS Site A/Site B and GKE clusters in GCP Site C/Site D.
- New reusable Terraform modules for inter-cloud pairing and cloud Kubernetes control planes.
- Deployment/runbook notes in `iac/terraform/SESSION_NOTES.md`, including quota and API prerequisites.

### Changed
- Terraform root variables, outputs, and documentation updated for phased cloud deployment controls.
- `phase3_enable_platform` feature flag added to safely control platform resource rollout.

## [0.1.0] - 2026-03-05
### Added
- Initial `network-spanned-dc` documentation set.
- Complete scope, architecture, diagram, failover, backup, security, operations, WAN, and appendix sections.
- MkDocs navigation and local preview configuration.
- ADR log and repository governance files.

### Git Commit History
- `a61963e` Initial spanned DC architecture documentation set
- `b58ce61` fixed maps
- `50348aa` dhcp+ad
- `51ed08d` WAN
- `55648cf` L3 + Guest
- `c24c135` normalization
- `9895a8c` clients
- `d15d375` root readme
- `6742ea0` clients+
- `249907a` wan transport
- `46df33b` freevdi
- `d07fbbb` multi-tunnel
- `bcee14d` nat64
- `040a5a4` condense
- `97836d9` published apps
- `1a228cb` appendix ++
- `7678d58` full
