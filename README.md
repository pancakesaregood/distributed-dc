# The Musings of a Madman

This repository is exactly that: a structured brain dump for designing a four-site, network-spanned datacenter that can survive real-world failure, budget pressure, and architecture review meetings.

At 10,000 feet, this project is:
- A documentation-first architecture package in [`network-spanned-dc/`](./network-spanned-dc/)
- Built around a low-cost, IPv6-first, multi-site DC model
- Focused on practical operations: failover, backups, security, and day-2 runbooks
- Framed around a vendor-managed WAN as an abstraction layer, not a black box
- Organized to move from scope -> design -> diagrams -> DR -> ops -> clarifications

Best way to use this repo: treat it like a playbook, not a novel. Start at scope, jump to architecture and diagrams, then pull the runbook/operations docs for execution.

Quick use examples:
1. Run an architecture review: use `docs/01_scope` + `docs/02_architecture` + `docs/03_diagrams`.
2. Plan a DR tabletop: use `docs/04_failover_dr` + `docs/05_backup`.
3. Build an implementation plan: use `docs/10_implementation` + `docs/12_business_cases`.
4. Onboard ops/support teams: use `docs/11_FAQ` + `docs/13_operations_foundations`.

If you want the full narrative, start with the docs home in [`network-spanned-dc/docs/index.md`](./network-spanned-dc/docs/index.md).


python -m mkdocs build -f network-spanned-dc\mkdocs.yml