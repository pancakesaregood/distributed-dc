# Service Desk FAQ

## What should be checked first during an outage ticket?
- Scope (single user, single site, multi-site), service impact, and current alert state in monitoring.

## What are common early indicators of platform issues?
- Authentication failures, VPN complaints, API timeout spikes, and site-local service degradation.

## How should tickets be escalated?
- Use documented severity and ownership: network/security/platform based on failing control point.

## What evidence is required before escalation?
- Timestamp, affected users/services, site impact, error messages, and any correlated alerts.

## Where are response steps documented?
- In DR runbooks, failover scenarios, and service-specific operations procedures in `docs/`.
