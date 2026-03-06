# Business Case 01 - Multi-Site Resilience Baseline

## Decision Statement
Fund and execute the four-site resilience baseline (edge/firewall/ToR/compute per site) to reduce business outage risk from single-site failure.

## Current Problem
- Single-site dependency increases probability of prolonged service interruption.
- Recovery outcomes are inconsistent without standardized cross-site design.

## Proposed Investment
- Implement per-site baseline infrastructure and inter-site encrypted routing.
- Enforce service placement and failover patterns by service tier.
- Validate failover runbooks against RTO/RPO targets.

## Cost Drivers
- Network/security hardware and lifecycle support.
- Compute host expansion and storage replication overhead.
- Engineering effort for phased rollout and validation.

## Expected Business Outcomes
- Lower outage impact through bounded failure domains.
- Faster, repeatable restoration during incidents.
- Reduced revenue and productivity loss during site events.

## KPIs
- Tier 1 service availability.
- Mean time to restore during failover exercises.
- Percent of critical services with tested cross-site recovery.

## Recommendation
Approve as foundational investment. This is the prerequisite for all other business cases.
