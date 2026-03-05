# GitOps Operating Model

## Operating Principle
Configuration for network, compute, security policy, and backup scheduling is defined as code and promoted through controlled pipelines.

## Repository Practices
- Separate folders for network intent, platform manifests, and runbooks.
- Pull requests required for all production-impacting changes.
- Mandatory peer review and automated validation checks.

## Promotion Flow
1. Author change in feature branch.
2. Validate through linting, schema checks, and policy tests.
3. Merge to main branch after approval.
4. Deploy through staged environments before production.

## Rollback
- Keep previous known-good configurations versioned.
- Use explicit rollback commits, not ad hoc device edits.
- Record incident-driven rollbacks in changelog and postmortem artifacts.
