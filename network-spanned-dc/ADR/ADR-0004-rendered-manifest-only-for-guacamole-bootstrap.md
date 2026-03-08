# ADR-0004: Rendered Manifest Path Required for Guacamole Bootstrap Changes

- Status: Accepted
- Date: 2026-03-08
- Deciders: Platform Engineering

## Context
A direct `kubectl apply` of templated Guacamole manifest content reintroduced unresolved placeholders (image and secret template tokens). This caused:
- `InvalidImageName` pod failures,
- secret value regression,
- DB re-initialization side effects after restart.

## Decision
Treat `iac/k8s/vdi/guacamole-nodeport.yaml` as a template input and apply Guacamole changes only through the rendered/bootstrap path (scripted substitution + controlled apply), not raw direct apply.

Primary execution path:
- `iac/terraform/scripts/invoke_phase4_vdi_service_bootstrap.ps1`

## Consequences
### Positive
- Prevents placeholder token drift into live runtime objects.
- Keeps bootstrap behavior deterministic and repeatable.
- Reduces accidental outage risk during cosmetic/config updates.

### Negative
- Slightly slower manual hotfix loop (requires render/bootstrap workflow).
- Requires operators to use scripted path consistently.

## Evidence
- `iac/terraform/SESSION_NOTES.md` -> "Guacamole Login Branding Override Pass (2026-03-08 15:40 America/Toronto)"
