# VDI as a Service

## Overview

Virtual Desktop Infrastructure (VDI) is provided as an enterprise-grade managed service using a fully open-source stack. The service delivers browser-accessible virtual desktops to internal users, remote VPN users, and managed contractors without requiring any client software installation. Desktop workloads run as VMs on the existing site hypervisor clusters. Access is brokered entirely through the existing security zones, WAF, and firewall policy.

---

## Stack Components

### Apache Guacamole (Access Gateway)

[Apache Guacamole](https://guacamole.apache.org/) is the core access broker. It provides a clientless HTML5 web interface supporting RDP, VNC, and SSH protocols. Users authenticate via the existing Active Directory integration. No VPN or client agent is required for desktop access — users connect via HTTPS through the existing DMZ path.

| Component | Role |
|---|---|
| `guacamole-client` | Java web application. Serves the HTML5 browser interface and manages user sessions. Deployed as a Podman container in the Containers zone. |
| `guacd` | Native proxy daemon. Translates between the web client protocol and the underlying RDP/VNC/SSH backend. Runs as a co-located Podman container alongside `guacamole-client`. |
| `guacamole-db` | PostgreSQL database for connection configuration, user-to-desktop mappings, and session metadata. Deployed as a Tier 1 Stateful VM in the Servers/VMs zone. |

Guacamole integrates with the site AD domain controller via LDAPS for authentication and group-based desktop assignment. MFA is enforced at the Guacamole layer using TOTP or Duo (via the Guacamole MFA extension), in addition to AD authentication.

### Desktop VM Pool

Desktop VMs run on the site hypervisor cluster in a dedicated VDI segment (`:0070`). Each site maintains a pool of desktop VMs serving local users. Remote users reaching the site via VPN are served by the nearest site's Guacamole instance.

**Supported desktop OS options:**
- Linux (Ubuntu LTS or Fedora) with XRDP for RDP access — recommended for open-source alignment.
- Windows (with appropriate licensing) for workloads requiring Windows-native applications. Native RDP is used in this case.

Desktop VMs are domain-joined to the site AD domain on first boot via automation. Group Policy applies desktop hardening, drive mapping, and access controls.

**Desktop pool modes:**

| Mode | Description | Use Case |
|---|---|---|
| Persistent | Each user is assigned a dedicated desktop VM. State persists between sessions. | Power users, developers, long-running workloads |
| Pooled (stateless) | VMs are drawn from a shared pool and reset to a clean template snapshot after each session. | Task workers, contractors, temporary access |

### Protocol Layer

| Protocol | Use Case | Notes |
|---|---|---|
| RDP (port 3389) | Windows VMs, Linux with XRDP | Preferred. Supports drive redirection, clipboard, printing, audio. |
| VNC (port 5900–5999) | Linux VMs without XRDP | Lower overhead. Less feature-rich for desktop use. |
| SSH | Server access through Guacamole | Useful for admin and developer shell sessions via the same portal. |

---

## Network Architecture

### VDI Segment

Desktop VMs are placed in a dedicated VDI/Desktop segment at each site:

| Site | VDI Segment |
|---|---|
| Site A | `fdca:fcaf:e000:0070::/64` |
| Site B | `fdca:fcaf:e100:0070::/64` |
| Site C | `fdca:fcaf:e200:0070::/64` |
| Site D | `fdca:fcaf:e300:0070::/64` |

This segment is a dedicated firewall zone (`VDI`). Desktop VMs are isolated from management and guest zones. Access to application services is permitted per AD group policy.

### Traffic Flow

**Inbound user access (browser):**
```
User browser (HTTPS)
  → WAF (OWASP inspection)
    → nginx LB (TLS termination, load balances across Guacamole instances)
      → guacamole-client (Containers zone)
        → guacd (Containers zone)
          → RDP/VNC → Desktop VM (VDI segment)
```

**Desktop VM to AD:**
```
Desktop VM (VDI segment)
  → AD Domain Controller (Servers/VMs segment)
    → Group policy applied, drive/resource mapping
```

**Desktop VM to application services:**
```
Desktop VM (VDI segment)
  → Firewall VDI zone policy
    → Servers/VMs segment (permitted application ports, per AD group)
```

Desktop VMs do not have direct internet access. Controlled internet egress for updates and approved destinations is routed through the firewall with explicit policy.

### Firewall Zone Policy (VDI Zone)

| Source | Destination | Protocol | Permitted |
|---|---|---|---|
| Containers (guacd) | VDI | RDP 3389, VNC 5900-5999 | Yes — connection from Guacamole to desktops |
| VDI | Servers/VMs | Application ports | Per AD group membership |
| VDI | Containers | Application ports | Per AD group membership |
| VDI | Management | Any | Denied |
| VDI | Guest | Any | Denied |
| VDI | Internet (direct) | Any | Denied — egress via controlled path only |
| VDI | L3OUT (controlled egress) | 80, 443 | Permitted for approved update and repo destinations |

---

## Spanning Model

Guacamole instances are **Tier 1 Stateless** — each site runs its own instance backed by a local `guacd`. Session state is stored in the `guacamole-db` PostgreSQL instance which is **Tier 1 Stateful** and replicated cross-site over IPsec tunnels.

Desktop VM pools are **local to each site**. A user connecting from the local network or via VPN is directed to the nearest site's Guacamole instance by DNS or GeoDNS. Cross-site desktop access is possible but not the default; it is reserved for failover scenarios.

| Component | Class | Spanning |
|---|---|---|
| guacamole-client | Tier 1 Stateless | Active at all sites |
| guacd | Tier 1 Stateless | Active at all sites, co-located with client |
| guacamole-db | Tier 1 Stateful | Active-standby, replicated across sites |
| Desktop VM pool | Local-Only | Per-site pools, local assignment |

---

## Provisioning and Lifecycle

- Desktop VM templates are version-controlled and built from a hardened base image via GitOps automation.
- New desktops are provisioned from the current template snapshot. Template updates are applied by rebuilding pooled VMs or scheduling persistent VM refreshes.
- Guacamole connection records are managed via the `guacamole-db` and provisioned through automation (e.g., Ansible). Manual connection creation is not permitted in production.
- Desktop VMs join the AD domain on first boot via an unattended setup script sourced from the GitOps configuration store.
- Persistent desktop VMs are snapshotted on a defined schedule as an additional recovery point independent of the backup schedule.

---

## Security Considerations

- Guacamole enforces MFA (TOTP minimum) for all desktop sessions in addition to AD authentication.
- All session traffic between the browser and Guacamole is HTTPS, terminating at the nginx LB. TLS 1.2 minimum; TLS 1.3 preferred.
- Traffic between `guacd` and desktop VMs is unencrypted RDP/VNC on the internal VDI segment. This segment is isolated by firewall zone; no external entity can reach it directly. Encrypt the RDP session at the Windows/XRDP layer if compliance requirements mandate it.
- Clipboard and file transfer policies are controlled at the Guacamole layer. Disable clipboard and drive redirection for pooled desktops unless explicitly required.
- Desktop VM sessions are logged at the Guacamole layer (session start, end, user identity). Guacamole session recording (screen capture) is available as an optional control for high-sensitivity environments.
- Desktop VMs are subject to the same patch lifecycle as server VMs. Pooled desktops receive patches automatically on template rebuild and pool refresh.
