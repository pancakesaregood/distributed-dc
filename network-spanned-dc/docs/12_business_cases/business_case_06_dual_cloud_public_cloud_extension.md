# Business Case 06 - Dual-Cloud Public Cloud Extension

## Decision Statement
Approve a staged four-site public cloud implementation using two AWS regions and two GCP regions to extend the existing resilience architecture into a dual-provider operating model.

## Current Problem
- The architecture is documented for four sites, but cloud execution detail is not yet defined.
- Provider-concentrated deployment increases outage and platform dependency risk.
- IPv6 adoption is inconsistent without a cross-cloud target design.

## Proposed Investment
- Build four cloud sites:
  - AWS: `us-east-1` and `us-west-2`
  - GCP: `us-east4` and `us-west1`
- Implement policy-controlled cross-cloud routing with encrypted links.
- Onboard tiered services with explicit failover and promotion runbooks.
- Validate dual-stack behavior (IPv6 primary where available, IPv4 compatibility path where needed).

## Cost Drivers
- Inter-cloud egress and replication traffic.
- Managed network components (Transit Gateway, HA VPN, Cloud Router, load balancing).
- Platform engineering effort for multi-cloud GitOps, testing, and operations.

## Expected Business Outcomes
- Reduced single-provider dependency for critical services.
- Better continuity posture for regional or provider-specific incidents.
- Clear migration runway for IPv6-ready service delivery.

## KPIs
- Tier 1 stateless recovery success across provider boundaries.
- Stateful promotion time during cloud or region failure drills.
- Percent of production services validated on IPv6 paths.
- Inter-cloud egress spend versus approved budget guardrails.

## Recommendation
Approve as a phased proposal with a pilot wave first. Use pilot evidence to finalize full production rollout scope and cost controls.

## Related Proposal
- [Dual-Cloud Four-Site Proposal (AWS + GCP)](../10_implementation/proposal_dual_cloud_4site.md)
