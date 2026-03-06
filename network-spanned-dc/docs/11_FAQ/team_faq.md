# Team FAQ

## What are we actually building?
We are building a four-site, Layer 3 spanned datacenter model where each site can fail independently without collapsing the entire environment. Inter-site traffic is encrypted, and architecture boundaries are explicit so troubleshooting and recovery remain manageable. In simple terms, we are trading fragile "all eggs in one basket" behavior for controlled multi-site resilience. The design is meant to be operable under normal conditions and understandable during bad days.

## What does the default baseline include before optional enhancements?
The baseline includes routed access, zone segmentation, an IPsec tunnel mesh between sites, BGP route exchange, and local internet breakout where appropriate. This gives a strong operational core without requiring advanced SDN features on day one. It is intentionally practical: enough structure for resilience and governance, without introducing unnecessary early complexity. Optional enhancements can be layered later once baseline stability is proven.

## What is the rollout order, and why this sequence?
The sequence is site foundation first, inter-site activation second, service onboarding third, and resilience validation with handover last. This order lowers risk because each stage depends on controls established in the previous stage. If we onboard services too early, we amplify unknowns and make failures harder to isolate. A staged order turns deployment into a series of controlled gates rather than one large cutover gamble.

## What happens when we have unresolved design questions?
Open decisions are tracked in `09_appendix/abstractions_clarifications_needed.md` and moved through governance review before production sign-off. This keeps uncertain assumptions visible and accountable instead of hidden in side conversations. It also gives leadership and operators a shared view of what is settled versus pending. In plain terms, unknowns are managed as work items, not ignored as background noise.

## How do we know implementation is truly complete?
Completion means acceptance criteria are met, DR and restore evidence is captured, and operations ownership is formally handed over. Finishing build tasks is not enough if recovery evidence or support readiness is missing. We consider the work done only when teams can run, support, and recover the system confidently. "Operationally ready" is the real finish line.
