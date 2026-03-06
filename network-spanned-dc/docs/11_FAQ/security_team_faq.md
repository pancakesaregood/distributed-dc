# Security Team FAQ

## What security controls are always required, even before advanced features?
We start with strong baseline controls that are simple and dependable: zone-based segmentation, default-deny policy, MFA for privileged and remote access, and centralized logging/monitoring. Think of this as locking internal doors before adding extra cameras and sensors. These controls limit lateral movement, raise authentication confidence, and improve investigation quality. Advanced tooling can be added later, but the baseline cannot be optional.

## How is traffic protected between sites?
Inter-site traffic is encrypted with IPsec using modern parameters (including IKEv2, AES-256-GCM, and PFS) regardless of which WAN transport mode is in use. This means confidentiality and integrity protections are consistent across links, not dependent on provider assumptions. In practical terms, we treat all inter-site paths as untrusted and secure them by design. The encryption policy is meant to be a default operating condition, not a special mode.

## Where do we enforce internet-facing policy?
Internet ingress policy is enforced at site firewalls and DMZ control layers, including WAF and load-balancer tiers where relevant. This creates clear checkpoints for filtering, protocol handling, and exposure management before traffic reaches internal services. It also improves ownership clarity: edge controls are not scattered randomly through the environment. The model is "concentrated enforcement at known control points."

## How are identity and permissions handled?
Identity is anchored in AD-backed authentication, with RBAC policy deciding what each role can do and LDAPS integrations used by dependent services. This allows centralized control, auditability, and policy consistency across systems that need identity decisions. Put simply, authentication answers "who are you?" and RBAC answers "what are you allowed to do?" Keeping both aligned is essential for reliable access governance.

## What telemetry is required for security operations?
Security operations need centralized logs plus high-value events such as authentication activity, firewall/WAF events, and alert-to-runbook mappings for response. Logs without response mapping create noise, while response mapping without logs creates blind spots. The goal is actionable visibility: evidence that can drive triage, containment, and post-incident learning. If telemetry cannot support rapid operator decisions, it is incomplete.
