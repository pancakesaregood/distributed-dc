# Executive FAQ

## What business problem does this program solve?
This program reduces the risk that one site outage disrupts critical services for too long. It also creates a consistent operating model across locations so teams do not reinvent procedures every time a problem occurs. In simple terms, we are moving from fragile, location-dependent operations to a repeatable multi-site model with better recovery confidence. The outcome we want is fewer surprises during failures and faster return to service when incidents happen.

## Why are we using this architecture approach?
The design intentionally balances resilience and cost by using a Layer 3 multi-site model, phased rollout, and open-source-first tooling where it is fit for purpose. We are not trying to buy every premium feature up front; we are building a strong baseline first and adding complexity only when justified. This gives predictable progress, lower early risk, and clearer budget control. It is a "build the right foundation, then optimize" strategy.

## How are we managing business and delivery risk?
Risk is managed through explicit failure-domain boundaries, documented DR runbooks, backup/restore validation, and measurable acceptance criteria. That means major assumptions are written down, testable, and reviewable instead of implied. When issues appear, we can identify whether the gap is design, process, ownership, or execution. The core principle is governance through evidence rather than governance through optimism.

## How do we measure success in a way leadership can trust?
Success is measured by meeting published RTO/RPO targets, passing recovery exercises, and completing operations handover with clear ownership. These metrics tie directly to service continuity and operational maturity rather than presentation quality. A successful program should show repeatable outcomes in drills and controlled changes, not just completed tasks on a timeline. If recovery evidence is weak, success is incomplete even if build work looks finished.

## What dependencies could delay outcomes?
Key dependencies include WAN capability alignment, unresolved platform decisions in the appendix decision register, and disciplined cross-team delivery. Any one of these can slow implementation or reduce confidence in production readiness if unmanaged. The practical mitigation is to track dependencies visibly, assign accountable owners, and close high-impact unknowns early. Multi-site programs fail quietly when dependencies are treated as "someone else's problem."
