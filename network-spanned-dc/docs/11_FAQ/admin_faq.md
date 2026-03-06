# Admin FAQ

## If I am an administrator, do I get full power everywhere?
Not by default, and that is intentional. Think of admin access like the master keys in a large building: you only hand out the exact key a person needs for the room they are working in, and only for as long as they need it. Our model uses role-based access control (RBAC), multi-factor authentication (MFA), and time-bounded elevation so high-risk privileges are temporary, tracked, and reviewable. This lowers the chance of accidental damage, credential abuse, and unclear accountability.

## How should I make production changes without surprising users?
Treat every production change like a tiny software release, even when it feels small. Changes should be proposed in Git, reviewed by a peer, approved, and then executed through the documented workflow instead of direct ad hoc edits. That gives you history, rollback context, and clear ownership, which are critical during incident review. In simple terms: if a change is not in the change workflow, it effectively did not happen in a controlled way.

## What checks should I always run before and after a change?
Before a change, confirm the system is healthy so you are not stacking new risk on top of existing problems. During and after the change, validate the expected behavior, check key service signals, and confirm alerts and runbooks still match the current environment. The goal is not only "did it apply?" but also "did service quality stay acceptable?" and "can support teams still respond correctly?" These checks turn change execution into a repeatable safety routine instead of a one-time guess.

## What is the incident flow when something breaks?
The service desk performs first-pass triage so everyone starts from one consistent intake path. From there, incidents are escalated to platform, network, or security teams based on the failing control point and runbook ownership. This prevents duplicate work, missing handoffs, and "who owns this?" confusion during high-pressure events. The key idea is simple: start centralized, then route to the specialist with evidence attached.

## Which documents are the source of truth?
The documentation in this repository is the authoritative source, including architecture decisions, runbooks, operations standards, and acceptance criteria. If a wiki page, chat snippet, or memory conflicts with the repository docs, the repository wins until formally updated. That rule keeps execution aligned across teams and reduces drift over time. In practice, always link your work and decisions back to the relevant docs path.
