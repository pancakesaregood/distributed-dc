# Server Team FAQ

## What is our default server platform, in simple terms?
The baseline is KVM virtualization for core compute, with Podman used when containerized services are the right fit. You can think of KVM as the main apartment building and containers as lightweight units used when speed and portability help. This approach keeps the platform predictable while still allowing modern service packaging patterns. The intent is practical flexibility without uncontrolled platform sprawl.

## How many hosts should each site have at minimum?
Each site needs at least two hypervisor hosts so one host failure does not immediately remove the site from service. Additional hosts are added based on capacity forecasts and resilience targets, not by guesswork. Minimum counts provide fault tolerance; scaling decisions provide performance headroom. In short, two is the floor, not the long-term plan for growth-heavy workloads.

## How should hosts be connected to the network?
Hosts should be dual-homed to ToR-A and ToR-B, with physical A/B cable path separation. This avoids single points of failure in both switching and physical cabling paths. If one switch or one cable path fails, the host should still maintain network connectivity. The design assumes real-world failures and builds survivability directly into host wiring standards.

## How do we place workloads so failures hurt less?
Tier 1 services are spread across hosts and sites, and anti-affinity rules prevent critical replicas from landing on the same host. That means one host outage is less likely to remove all copies of an important service. Placement policy is a resilience control, not just a scheduling preference. A good placement strategy turns hardware failures into manageable events instead of major incidents.

## How should patching be executed safely?
Patching is done in staged waves by site and service tier, with pre-checks, rollback plans, and post-change validation required each time. This prevents all risk from being concentrated in one maintenance window and gives teams controlled stopping points. The goal is not to patch quickly at all costs; the goal is to patch safely and keep service quality stable. Good patch practice is measured by reliable outcomes, not just patch count.
