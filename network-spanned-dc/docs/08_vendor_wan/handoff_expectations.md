# Handoff Expectations

## Technical Handoff
- Dual logical handoffs per site preferred for edge redundancy.
- Clear demarcation of vendor and customer responsibilities. The vendor is responsible for the private circuit L3 service up to the handoff point. The customer is responsible for IPsec tunnel termination on the site edge pair.
- Documented MTU and encapsulation expectations. IPsec tunnel mode with IPv6 introduces additional header overhead; the agreed handoff MTU must accommodate this. A minimum inner MTU of 1400 bytes is required; 1500 bytes preferred with jumbo frame support on the WAN circuit.
- Defined route exchange parameters per edge peer. BGP sessions from the customer edge will originate from inside IPsec tunnel endpoints; vendor must route return traffic correctly.
- Vendor must not perform deep-packet inspection or traffic modification on ESP-encapsulated packets.

## Resilience Expectations
- Failure of one handoff should not isolate a site when dual handoff is present.
- Handoff restoration timelines must be observable and reportable.
- Vendor must support coordinated failover testing windows.

## Support Expectations
- 24x7 incident response channel for major outages.
- Ticket references tied to measurable SLA outcomes.
- Post-incident reports for outages affecting inter-site reachability.
