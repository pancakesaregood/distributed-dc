# Team FAQ

## What are we implementing?
- A four-site, Layer 3 spanned datacenter design with per-site failure domains and encrypted inter-site traffic.

## What is the default deployment baseline?
- Routed-access baseline with zone segmentation, IPsec tunnel mesh, BGP route exchange, and local internet breakout.

## What is our implementation order?
- Site foundation first, then inter-site activation, then service onboarding, then resilience validation and handover.

## How are open decisions handled?
- Tracked in `09_appendix/abstractions_clarifications_needed.md` with governance review before production sign-off.

## What defines completion?
- Acceptance criteria met, DR/restore evidence captured, and operations ownership formally handed over.
