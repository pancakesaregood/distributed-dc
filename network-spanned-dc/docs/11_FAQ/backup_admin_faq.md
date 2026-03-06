# Backup Admin FAQ

## What backup strategy is required?
- 3-2-1 aligned model with local recoverability plus at least one off-domain or immutable copy.

## What data classes are covered?
- Tier 1 stateful data, platform configs, repositories, VM images, and supporting service metadata.

## How often are restore tests required?
- Scheduled restore exercises per documented cadence, including monthly sampling and broader periodic tests.

## How is ransomware resilience addressed?
- Through immutability controls, credential separation, and validated restore workflows.

## What proves backup readiness?
- Successful restore evidence, retention compliance, and alignment with RTO/RPO targets in DR documentation.
