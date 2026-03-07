# Changelog

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
