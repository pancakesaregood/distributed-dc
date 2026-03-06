# Abstractions and Clarifications Needed

This appendix is the pre-implementation decision register. Every item below should be closed before production deployment approval.

## Decision Register

| ID | Decision | Current Assumption | Why it matters | Design impact |
| --- | --- | --- | --- | --- |
| A-01 | WAN control model (customer-managed BGP policy vs provider-managed routing) | Customer controls BGP policy at each site edge; WAN is treated as L3 transport only | Determines who owns failover behavior and policy logic | Affects route filtering, preference tuning, and static fallback usage |
| A-02 | Transport mode per site pair (Mode A private circuit, Mode B internet, or mixed) | Mode A preferred; Mode B allowed where private circuit is unavailable | Changes reliability and operational risk profile | Alters SLA expectations, MTU planning, and incident workflows |
| A-03 | BGP session hardening method | TCP-AO preferred; TCP MD5 allowed only where TCP-AO is unsupported | Protects control plane from spoofed or reset sessions | Impacts key rotation process and platform compatibility |
| A-04 | ToR and NOS capability for EVPN-VXLAN | Routed-access baseline unless EVPN features are validated in hardware | Avoids adopting overlay features that cannot be operated safely | Decides SDN path (Option 1 vs Option 3) |
| A-05 | Firewall and remote access platform standard | One platform family across all sites | Needed for consistent policy, HA behavior, and VPN operations | Drives runbooks, team training, and lifecycle management |
| A-06 | Virtualization management stack | KVM-based stack with shared operational tooling | Core dependency for placement, backup, and restore behavior | Changes automation approach and patching model |
| A-07 | Tier 1 stateful replication model | Service-specific active-standby or quorum based on latency budgets | Directly constrains achievable RPO and failover safety | Defines placement rules, write locality, and DR sequence |
| A-08 | Identity provider and MFA standard | AD-backed identity with MFA for privileged and remote access | Identity is a control-plane dependency during incidents | Affects break-glass flow, audit evidence, and access policy |
| A-09 | Backup tooling and immutability depth | 3-2-1 baseline with at least one immutable or off-domain copy | Determines ransomware resilience and restore confidence | Impacts retention cost, legal hold workflow, and restore SLAs |
| A-10 | Observability stack baseline | Prometheus + Grafana + central logs (Loki or OpenSearch) | Needed for actionable alerts and post-incident evidence | Defines telemetry schema, dashboards, and retention policy |
| A-11 | Published app traffic steering model | GeoDNS by default; anycast for selected stateless services | Governs internet ingress behavior and failure domains | Changes health check design and rollback patterns |
| A-12 | DR test evidence and sign-off workflow | Monthly restore sampling plus quarterly scenario tests | Required to prove RTO/RPO claims in audits and incident reviews | Affects staffing cadence and acceptance criteria closure |

## Exit Criteria for This Appendix

- Every open item has a named owner and a target decision date.
- Items affecting security, failover, or data durability have linked runbook updates.
- Remaining open items are accepted as explicit risks by architecture governance.
