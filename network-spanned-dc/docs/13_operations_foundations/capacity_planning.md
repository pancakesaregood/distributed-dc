# Capacity Planning

## Purpose
Capacity planning ensures infrastructure can meet current demand and planned growth while preserving resilience targets.

## Planning Inputs
- Service tier inventory and workload criticality.
- Historical utilization for CPU, memory, storage, and network.
- Business growth forecast and seasonal demand patterns.
- Failure-domain requirements (N+1 and cross-site coverage).

## Planning Model
- Baseline: current committed load per site.
- Growth: forecast demand by quarter.
- Resilience: capacity with one-host or one-site degradation assumptions.

## Threshold Framework
- Compute expansion trigger: sustained utilization above defined guardrail.
- Storage expansion trigger: projected capacity breach within planning window.
- Network expansion trigger: sustained interface saturation or packet loss trend.

## Review Cadence
- Monthly: utilization trend and hot-spot review.
- Quarterly: forecast refresh and hardware lifecycle alignment.
- Pre-change: impact assessment for major service onboarding.

## Decision Outputs
- Add host/storage/network capacity.
- Rebalance workload placement by site and tier.
- Tune service limits, reservations, and autoscaling policies.

## Success Metrics
- No critical service degraded by preventable capacity exhaustion.
- Capacity actions completed before threshold breach.
- Consistent headroom maintained for DR and failover conditions.
