# Backup Admin FAQ

## What is our backup strategy in plain English?
We follow a "3-2-1" style strategy because it is a practical safety net: keep multiple copies, keep them on different storage types, and keep at least one copy separated from the main environment. One copy should be recoverable quickly for common incidents, while another should be isolated or immutable so it cannot be easily altered by an attacker or admin mistake. This gives us both speed and durability. The short version is: one backup is not a strategy, and two similar backups in one blast radius are still risky.

## What exactly do we have to back up?
We back up the important business data and also the technical pieces needed to rebuild services correctly. That includes Tier 1 stateful data, platform configurations, repositories, VM images, and related service metadata. If you can recover files but cannot recover identity mappings, configs, or automation state, your restore is incomplete. A good backup scope restores service behavior, not just raw bytes.

## How often do we prove restores actually work?
Backups are tested on a documented cadence, with regular monthly sampling plus broader scheduled recovery exercises. This matters because "backup completed" is not the same as "recovery will succeed under pressure." Restore tests prove that retention, integrity, permissions, and runbook steps still match reality. If a team cannot restore predictably in test, it should assume risk in production until fixed.

## How do we design backups to resist ransomware?
We combine immutability controls, separated credentials, and restore workflows that are tested end to end. Immutability helps prevent silent modification or deletion of backup sets, and credential separation limits how far one compromised account can reach. We also verify that restore procedures work without requiring compromised systems to be trusted. In practical terms, resilience is not just storage configuration; it is the full process from compromise to clean recovery.

## What counts as proof that backup readiness is real?
Readiness is demonstrated by evidence, not intent. We need successful restore results, retention policy compliance, and alignment with documented RTO/RPO goals in DR materials. Evidence should be timestamped, reproducible, and understandable by operations and audit stakeholders. If we cannot show recent proof, we should treat recovery confidence as unknown and close the gap quickly.
