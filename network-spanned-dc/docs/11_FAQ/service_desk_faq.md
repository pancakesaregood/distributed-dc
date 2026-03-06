# Service Desk FAQ

## When an outage ticket arrives, what should I check first?
Start by sizing the problem clearly: is it one user, one site, or multiple sites, and which services are affected? Then check monitoring and alert context so your triage starts from real signals, not assumptions. This first pass defines urgency and helps route the ticket correctly the first time. In plain language, your job is to quickly answer "how big is this?" and "what is most likely broken?"

## What are early warning signs of platform trouble?
Common early indicators include repeated authentication failures, VPN complaints, API timeout spikes, and noticeable site-local degradation. One symptom alone may be noisy, but correlated symptoms often indicate a real shared issue. Capturing these patterns early helps reduce mean time to escalation and improves handoff quality. Think of this as recognizing smoke before the fire spreads.

## How should I escalate tickets to the right team?
Escalate using the documented severity model and ownership mapping, selecting network, security, or platform based on the most likely failing control point. Avoid broad "everyone join" escalations unless the impact is critical and ownership is unclear after initial checks. Targeted escalation reduces confusion and gets the right specialist engaged faster. Good triage is less about speed alone and more about precision with evidence.

## What evidence should I attach before escalation?
Include timestamp, affected users or services, site impact, exact error messages, and any correlated alerts from monitoring. This package gives responders immediate context and avoids repeating discovery steps under pressure. Missing context slows incident response and increases the chance of misrouting. If your handoff would let a new responder act within minutes, the evidence quality is good.

## Where are the official response steps documented?
Response steps are documented in DR runbooks, failover scenario documentation, and service-specific procedures in `docs/`. These documents provide repeatable actions, ownership expectations, and validation checkpoints during incident handling. The service desk should use them as operating guides, not optional references. Consistent use of runbooks is what turns individual experience into team-level reliability.
