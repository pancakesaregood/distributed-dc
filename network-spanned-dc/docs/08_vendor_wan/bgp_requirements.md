# BGP Requirements

## Session Model
- eBGP between each site edge and WAN handoff.
- Redundant sessions per site where dual handoff exists.
- Authentication and session hardening per security policy.

## Prefix Policy
- Advertise only site summary `/56` prefixes.
- Accept only approved internal and required service prefixes.
- Block default route unless explicitly approved in design governance.

## Convergence and Stability
- Use conservative timer settings aligned with WAN SLA and failover objectives.
- Apply route dampening carefully to avoid masking true failures.
- Monitor flap events and tie to incident review workflow.

## Anycast Support
- Optional `/128` anycast advertisements allowed for internal DNS and ingress VIPs.
- Anycast advertisements must be health-gated to avoid blackholing traffic.
