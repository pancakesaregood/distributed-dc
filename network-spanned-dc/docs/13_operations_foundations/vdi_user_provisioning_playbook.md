# VDI User Provisioning Playbook

## Purpose
Provide a repeatable process to provision VDI users across:
- Keycloak (`/idp`, realm `vdi`) for SSO authentication.
- Guacamole authorization tables for connection visibility and permissions.

## Automation Artifact
- Playbook: `iac/ansible/playbooks/vdi_add_user.yml`
- Operational notes: `iac/ansible/README.md`

## What the Playbook Does
1. Validates the requested username and required inputs.
2. Reads Keycloak admin credentials from Kubernetes secret `keycloak-auth`.
3. Creates (or updates) user in Keycloak realm `vdi`.
4. Applies user password and profile fields.
5. Reads Guacamole DB credentials from secret `guacamole-db-auth`.
6. Ensures local Guacamole user/entity rows exist.
7. Provisions per-user desktops (default behavior):
   - Linux desktop workload in Kubernetes (`Deployment/Service/Secret` under namespace `vdi`).
   - Windows desktop EC2 instance in Site A (cloned from template instance attributes, or reused and auto-started if already present for the user).
8. Creates or updates dedicated Guacamole connections that point to those user-specific desktop endpoints.
9. Optionally removes non-personal connection permissions from the user (`vdi_personal_desktops_only=true`).
10. Outputs summary including resulting permission row count.

## Prerequisites
- `ansible-playbook` and `kubectl` installed on the operator host.
- Valid Kubernetes context targeting the VDI cluster.
- AWS CLI configured on the operator host for Windows VM creation path.
- Namespace `vdi` reachable with sufficient RBAC to:
  - read secrets
  - exec into `keycloak` and `guacamole-db` pods

## Example Run

```bash
ansible-playbook iac/ansible/playbooks/vdi_add_user.yml \
  -e "vdi_username=cox" \
  -e "vdi_user_password=ChangeMe-Immediately-2026!" \
  -e "vdi_linux_vnc_password=VncPass-For-Cox-2026!" \
  -e "vdi_windows_rdp_password=RdpPass-For-Cox-2026!" \
  -e "aws_profile=ddc" \
  -e "aws_region=us-east-1"
```

## Optional Inputs
- `vdi_user_first_name`
- `vdi_user_last_name`
- `vdi_user_email`
- `guac_permission_template_user` (default `john`)
- `kube_namespace` (default `vdi`)
- `keycloak_realm` (default `vdi`)
- `vdi_create_personal_desktops` (default `true`)
- `vdi_personal_desktops_only` (default `true`)
- `vdi_create_personal_linux_vm` (default `true`)
- `vdi_create_personal_windows_vm` (default `true`)
- `vdi_linux_vnc_password` (required when personal desktop mode is enabled)
- `vdi_windows_rdp_password` (required when personal desktop mode is enabled)
- `vdi_windows_rdp_username` (optional; default derived from username)
- `aws_profile` (optional)
- `aws_region` (default `us-east-1`)

## Validation Checks
- Keycloak user exists and can authenticate through configured IdP flow.
- Dedicated Linux desktop deployment and service are healthy in namespace `vdi`.
- Dedicated Windows instance reaches `running` + `instance-status-ok` in EC2.
- Guacamole user has permission rows for dedicated per-user connections.
- User is visible in Guacamole UI after SSO login and receives intended connection list.

## Security Considerations
- Treat user passwords as secrets; avoid plain text in shell history.
- Prefer secret injection (CI/CD secret store, Ansible vault, or secure prompt).
- Keep template-user permissions least-privilege; avoid cloning admin rights unless explicitly required.
