# Abstractions and Clarifications Needed

This section lists required decisions before final implementation. Each item states why it matters and the design impact.

## 1) WAN Service Type and Routing Control
- Decision needed: confirm whether WAN offers full BGP policy control, managed routing only, or mixed control.
- Why it matters: determines how much routing failover logic can be controlled directly by the platform team.
- Design impact: affects BGP policy depth, fallback strategy, and observability requirements.

## 2) Switch Hardware and OS Capability for EVPN-VXLAN
- Decision needed: confirm if ToR platforms support EVPN-VXLAN in hardware and desired feature set.
- Why it matters: controls whether SDN Option 1 is feasible without host-overlay complexity.
- Design impact: determines whether fabric uses EVPN overlay or routed-access baseline.

## 3) Virtualization Stack Choice
- Decision needed: select the supported KVM-based platform and management plane.
- Why it matters: impacts HA behavior, backup integration, and operational training.
- Design impact: changes runbooks, automation tooling, and lifecycle management process.

## 4) Storage Replication Approach and Targets
- Decision needed: choose asynchronous replication, quorum model, or hybrid by service tier.
- Why it matters: directly drives achievable RPO and inter-site bandwidth consumption.
- Design impact: changes service spanning classification and failover timelines.

## 5) Identity and MFA Approach
- Decision needed: select authoritative IdP and MFA mechanism for administrators and service operators.
- Why it matters: identity is a control-plane dependency for incident response and auditability.
- Design impact: affects access runbooks, break-glass design, and security baseline controls.

## 6) Backup Tooling and Immutability Requirements
- Decision needed: select backup software stack and confirm immutability policy depth.
- Why it matters: ransomware resilience and restore confidence depend on these controls.
- Design impact: determines retention architecture, cost profile, and restore workflow complexity.

## 7) Traffic Patterns and Latency Constraints
- Decision needed: quantify inter-site latency tolerance and read/write traffic patterns for Tier 1 stateful services.
- Why it matters: replication mode and failover correctness depend on realistic latency and bandwidth assumptions.
- Design impact: affects service placement, anycast usage, and achievable RTO/RPO commitments.
