# VDI Ops Console

Admin-only operations panel for the VDI reference stack.

## Features

- Live health board with "green light" indicators for:
  - EKS Site A/Site B VDI nodes and deployments
  - GKE Site C/Site D worker pool status (when enabled)
  - Terraform-delivered Cloudflare and inter-cloud link topology
- Topology map for Site A/B/C/D plus Cloudflare edge.
- Admin actions:
  - restart `vdi-desktop`, `guacamole`, or `guacamole-db`
  - reset hung desktop pod
  - inspect active Guacamole sessions
  - inspect desktop process list

## Security model

- HTTP Basic authentication is mandatory.
- Credentials are loaded from environment:
  - `VDI_ADMIN_USERNAME`
  - `VDI_ADMIN_PASSWORD`
- Recommended run mode:
  - bind to `127.0.0.1`
  - access through SSH tunnel/VPN or reverse proxy with stronger auth controls.

## Run

From `network-spanned-dc\iac\terraform`:

```powershell
.\scripts\invoke_vdi_ops_console.ps1 `
  -AdminUsername "ops-admin" `
  -AdminPassword "<strong-password>" `
  -OpenBrowser
```

Direct Python launch:

```powershell
$env:VDI_ADMIN_USERNAME = "ops-admin"
$env:VDI_ADMIN_PASSWORD = "<strong-password>"
python .\tools\vdi_ops_console\server.py --host 127.0.0.1 --port 8099 --terraform-dir .
```
