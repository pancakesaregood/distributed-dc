# Services Spanning Model

## Service Classes

| Class | Typical Services | Spanning Pattern | Notes |
|---|---|---|---|
| Tier 1 Stateless | Internal APIs, web frontends, ingress | Active-active across 2 to 4 sites | Load balancing via DNS or anycast ingress |
| Tier 1 Stateful | Databases, message queues | Active-standby or quorum-based multi-site | Replication latency must match write profile |
| Tier 2 Platform | CI runners, artifact mirrors | Active-standby across 2 sites | Cost-optimized with controlled failover |
| Local-Only | Site facility services, VDI desktop VM pools | Single-site | No cross-site failover requirement |

## Spanning Guidance
- Use application-level replication for stateful services. All replication traffic crosses the IPsec-encrypted inter-site tunnels; no additional application-layer encryption is required for transport security, though it is permitted for defense-in-depth.
- Use DNS or BGP anycast only for stateless ingress points.
- Keep control-plane quorum odd-sized and failure-tolerant.
- Avoid synchronous writes across all four sites unless strict latency targets are validated. Note that IPsec encapsulation adds a small overhead to inter-site round-trip time; account for this when measuring replication latency budgets.

## Dependency Ordering
1. Identity and DNS availability.
2. Configuration and secrets distribution plane.
3. Data services and message fabrics.
4. Application services and user-facing endpoints.
5. VDI access layer (Guacamole) — depends on identity (AD), data (guacamole-db), and compute (desktop VMs).

## Failover Principle
Failover is policy-driven and explicit. The design avoids hidden dependencies on stretched L2 or undefined transport behavior.
