# Admin FAQ

## What access model is used for administrators?
- Least-privilege RBAC with MFA and time-bounded elevation for privileged tasks.

## How are changes made to production?
- Through Git-backed, peer-reviewed change workflows rather than ad hoc direct edits.

## What are the standard operational checks?
- Pre-change health verification, post-change validation, and alert/runbook confirmation.

## How are incidents handled?
- Service desk triage first, then escalation to platform/network/security teams per runbook mapping.

## What documentation is authoritative?
- The docs tree in this repository, including architecture, runbooks, and acceptance criteria.
