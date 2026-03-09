# Ansible Operations Playbooks

This folder contains day-2 playbooks for VDI operations.

## Prerequisites
- `ansible-playbook` available on the control host.
- `kubectl` available on the control host and authenticated to the target cluster.
- Access to namespace `vdi`.

## Playbooks
- `playbooks/vdi_add_user.yml`
  - Creates or updates a user in Keycloak realm `vdi`.
  - Sets user password and basic profile fields.
  - Ensures a corresponding Guacamole user/entity exists.
  - By default creates dedicated desktops for that user:
    - Linux desktop (Kubernetes deployment/service in namespace `vdi`)
    - Windows desktop (AWS EC2 instance in Site A VPC)
  - Creates or updates dedicated Guacamole connections bound to those user-specific desktop targets.

## Usage

Example:

```bash
ansible-playbook iac/ansible/playbooks/vdi_add_user.yml \
  -e "vdi_username=cox" \
  -e "vdi_user_password=ChangeMe-Immediately-2026!" \
  -e "vdi_linux_vnc_password=VncPass-For-Cox-2026!" \
  -e "vdi_windows_rdp_password=RdpPass-For-Cox-2026!"
```

Override optional fields:

```bash
ansible-playbook iac/ansible/playbooks/vdi_add_user.yml \
  -e "vdi_username=alice" \
  -e "vdi_user_password=StrongPasswordHere" \
  -e "vdi_linux_vnc_password=StrongLinuxVncPass" \
  -e "vdi_windows_rdp_password=StrongWindowsRdpPass" \
  -e "vdi_user_first_name=Alice" \
  -e "vdi_user_last_name=Ng" \
  -e "vdi_user_email=alice@slothkko.com" \
  -e "guac_permission_template_user=john" \
  -e "aws_region=us-east-1" \
  -e "aws_profile=ddc"
```

## Required Variables
- `vdi_username`
- `vdi_user_password`
- `vdi_linux_vnc_password` (required when `vdi_create_personal_desktops=true`)
- `vdi_windows_rdp_password` (required when `vdi_create_personal_desktops=true`)

## Optional Variables
- `vdi_user_first_name` (default: `vdi_username`)
- `vdi_user_last_name` (default: `User`)
- `vdi_user_email` (default: `<vdi_username>@slothkko.local`)
- `guac_permission_template_user` (default: `john`)
- `kube_namespace` (default: `vdi`)
- `keycloak_realm` (default: `vdi`)
- `vdi_create_personal_desktops` (default: `true`)
- `vdi_personal_desktops_only` (default: `true`)
- `vdi_create_personal_linux_vm` (default: `true`)
- `vdi_create_personal_windows_vm` (default: `true`)
- `vdi_windows_rdp_username` (default: derived from username)
- `aws_region` (default: `us-east-1`)
- `aws_profile` (optional AWS profile name)
- `vdi_windows_template_role_tag` (default: `vdi-windows-desktop`)
- `vdi_windows_instance_name_prefix` (default: `slothkko-vdi-win`)

## Notes
- The playbook is idempotent for user/entity/permission creation and re-apply of dedicated desktop resources.
- Password is always applied to the Keycloak user when the playbook runs.
- If a per-user Windows desktop already exists in a stopped state, the playbook starts it and reuses the same instance.
- Keep user passwords out of shell history in production (use vault, CI secret store, or prompt workflows).
- For Windows provisioning, AWS CLI credentials and permissions are required on the Ansible control host.
