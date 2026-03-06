# User FAQ

## Will this change how I log in and use services every day?
For most people, day-to-day workflows should look the same or very similar. You will still use approved internal access paths on-site and approved remote paths when off-site. The underlying architecture changes are mostly about resilience and operations, not forcing users to relearn normal tasks. If a user-facing change is required, it should be communicated ahead of time with clear instructions.

## Should I expect planned downtime during rollout?
Some planned maintenance windows are expected as the rollout proceeds in stages. These windows are used to apply controlled changes with validation checkpoints, which is safer than large unannounced cutovers. Teams should communicate timing and expected impact in advance so users can plan around it. The goal is short, predictable disruption now to avoid longer, unplanned disruption later.

## How does remote access work in this model?
Remote access is provided through VPN and policy-based access controls, with MFA required for stronger identity assurance. This means access decisions are based on both who you are and the policy tied to your role and context. From a user perspective, it may feel similar to current remote access, but controls are more explicit and consistent. In short, the experience aims to stay practical while security confidence improves.

## If one site fails, will my services and data still be available?
Critical services are designed for multi-site continuity based on service tier and replication patterns. That does not mean every service fails over instantly in every scenario, but the architecture is built so major dependencies are not trapped in one location. Recovery targets and behavior are documented so teams know what to expect under different failure cases. The practical outcome is better continuity and clearer recovery behavior during incidents.

## Who should I contact if something is not working?
Start with the service desk so incidents enter the standard triage and escalation workflow. The service desk gathers initial evidence and routes the issue to the right specialist team if needed. This avoids fragmented reporting and helps responders see the full pattern of impact. One consistent intake path improves resolution speed and communication quality.
