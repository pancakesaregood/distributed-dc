# The Musings of a Madman

This repository is exactly that: a structured brain dump for designing a four-site, network-spanned datacenter that can survive real-world failure, budget pressure, and architecture review meetings.

At 10,000 feet, this project is:
- A documentation-first architecture package in [`network-spanned-dc/`](./network-spanned-dc/)
- Built around a low-cost, IPv6-first, multi-site DC model
- Focused on practical operations: failover, backups, security, and day-2 runbooks
- Framed around a vendor-managed WAN as an abstraction layer, not a black box
- Organized to move from scope -> design -> diagrams -> DR -> ops -> clarifications

If you want the full narrative, start with the docs home in [`network-spanned-dc/docs/index.md`](./network-spanned-dc/docs/index.md).
