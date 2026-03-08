locals {
  phase4_ops_stack_enabled                = var.phase4_enable_ops_stack
  phase4_ops_admin_ssh_public_key_trimmed = var.phase4_ops_admin_ssh_public_key != null ? trimspace(var.phase4_ops_admin_ssh_public_key) : ""
  phase4_ops_admin_ssh_public_key_b64     = local.phase4_ops_admin_ssh_public_key_trimmed != "" ? base64encode(local.phase4_ops_admin_ssh_public_key_trimmed) : ""
  phase4_ops_admin_ssh_password_b64       = var.phase4_ops_admin_ssh_password != null ? base64encode(var.phase4_ops_admin_ssh_password) : ""
  phase4_ops_shared_ssh_cidrs             = distinct(concat([var.site_a_ipv4_cidr, var.site_b_ipv4_cidr, var.site_c_ipv4_cidr, var.site_d_ipv4_cidr], var.phase4_ops_trusted_ipv4_cidrs))
  phase4_ops_openproject_http_allowed_ipv4_cidrs = (
    var.phase4_ops_openproject_http_allowed_ipv4_cidrs != null && length(var.phase4_ops_openproject_http_allowed_ipv4_cidrs) > 0
  ) ? var.phase4_ops_openproject_http_allowed_ipv4_cidrs : local.phase4_ops_shared_ssh_cidrs
  phase4_ops_git_http_allowed_ipv4_cidrs = (
    var.phase4_ops_git_http_allowed_ipv4_cidrs != null && length(var.phase4_ops_git_http_allowed_ipv4_cidrs) > 0
  ) ? var.phase4_ops_git_http_allowed_ipv4_cidrs : local.phase4_ops_shared_ssh_cidrs
  phase4_ops_openproject_network_tag     = "${var.name_prefix}-${var.environment}-site-c-openproject"
  phase4_ops_openproject_zone            = var.phase4_ops_openproject_zone != null ? var.phase4_ops_openproject_zone : "${var.gcp_site_c_region}-b"
  phase4_ops_openproject_secret_key_base = sha256("${var.name_prefix}-${var.environment}-site-c-openproject")

  phase4_ops_linux_admin_bootstrap = <<-EOT
ADMIN_USER="${var.phase4_ops_admin_username}"
if ! id "$${ADMIN_USER}" >/dev/null 2>&1; then
  useradd --create-home --shell /bin/bash "$${ADMIN_USER}"
fi
usermod -aG sudo "$${ADMIN_USER}" || true
install -d -m 700 -o "$${ADMIN_USER}" -g "$${ADMIN_USER}" "/home/$${ADMIN_USER}/.ssh"
if [ -n "${local.phase4_ops_admin_ssh_public_key_b64}" ]; then
  echo "${local.phase4_ops_admin_ssh_public_key_b64}" | base64 -d >"/home/$${ADMIN_USER}/.ssh/authorized_keys"
  chown "$${ADMIN_USER}:$${ADMIN_USER}" "/home/$${ADMIN_USER}/.ssh/authorized_keys"
  chmod 600 "/home/$${ADMIN_USER}/.ssh/authorized_keys"
fi
if [ -n "${local.phase4_ops_admin_ssh_password_b64}" ]; then
  OPS_PASSWORD="$(echo '${local.phase4_ops_admin_ssh_password_b64}' | base64 -d)"
  echo "$${ADMIN_USER}:$${OPS_PASSWORD}" | chpasswd
  sed -i -E 's/^[#[:space:]]*PasswordAuthentication[[:space:]]+.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
  if ! grep -q '^PasswordAuthentication' /etc/ssh/sshd_config; then
    echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config
  fi
else
  sed -i -E 's/^[#[:space:]]*PasswordAuthentication[[:space:]]+.*/PasswordAuthentication no/' /etc/ssh/sshd_config
  if ! grep -q '^PasswordAuthentication' /etc/ssh/sshd_config; then
    echo 'PasswordAuthentication no' >> /etc/ssh/sshd_config
  fi
fi
systemctl restart ssh || systemctl restart sshd || true
  EOT

  phase4_ops_install_docker = <<-EOT
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y ca-certificates curl gnupg lsb-release
install -m 0755 -d /etc/apt/keyrings
if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
fi
chmod a+r /etc/apt/keyrings/docker.gpg
OS_CODENAME="$(. /etc/os-release && echo $${VERSION_CODENAME:-$${UBUNTU_CODENAME:-}})"
if [ -z "$${OS_CODENAME}" ]; then
  OS_CODENAME="noble"
fi
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $${OS_CODENAME} stable" > /etc/apt/sources.list.d/docker.list
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
systemctl enable --now docker
  EOT

  phase4_ops_openproject_startup_script = <<-EOT
#!/bin/bash
set -euxo pipefail
${local.phase4_ops_install_docker}
${local.phase4_ops_linux_admin_bootstrap}
install -d -m 755 /var/lib/openproject/pgdata /var/lib/openproject/assets
docker rm -f openproject || true
docker run -d \
  --name openproject \
  --restart unless-stopped \
  -p 80:80 \
  -e SECRET_KEY_BASE='${local.phase4_ops_openproject_secret_key_base}' \
  -e OPENPROJECT_HOST__NAME='${var.phase4_ops_openproject_host_name}' \
  -e OPENPROJECT_HTTPS='false' \
  -e OPENPROJECT_DEFAULT__LANGUAGE='en' \
  -v /var/lib/openproject/pgdata:/var/openproject/pgdata \
  -v /var/lib/openproject/assets:/var/openproject/assets \
  '${var.phase4_ops_openproject_image}'
  EOT

  phase4_ops_git_user_data = <<-EOT
#!/bin/bash
set -euxo pipefail
${local.phase4_ops_install_docker}
${local.phase4_ops_linux_admin_bootstrap}
install -d -m 755 /var/lib/gitea
docker rm -f gitea || true
docker run -d \
  --name gitea \
  --restart unless-stopped \
  -e USER_UID=1000 \
  -e USER_GID=1000 \
  -p 3000:3000 \
  -p 2222:22 \
  -v /var/lib/gitea:/data \
  -v /etc/timezone:/etc/timezone:ro \
  -v /etc/localtime:/etc/localtime:ro \
  '${var.phase4_ops_git_image}'
  EOT

  phase4_ops_ansible_user_data = <<-EOT
#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y software-properties-common
add-apt-repository --yes --update ppa:ansible/ansible
apt-get install -y ansible git jq python3-pip
${local.phase4_ops_linux_admin_bootstrap}
install -d -m 755 /etc/ansible
cat > /etc/ansible/hosts <<'EOF'
[openproject]
openproject ansible_host=${google_compute_instance.phase4_openproject_server[0].network_interface[0].network_ip} ansible_user=${var.phase4_ops_admin_username}

[git]
gitserver ansible_host=${aws_instance.phase4_git_server[0].private_ip} ansible_user=${var.phase4_ops_admin_username}

[all:vars]
ansible_python_interpreter=/usr/bin/python3
EOF
  EOT
}

data "aws_ssm_parameter" "phase4_site_a_ubuntu_ami" {
  count    = local.phase4_ops_stack_enabled ? 1 : 0
  provider = aws.site_a

  name = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

data "aws_ssm_parameter" "phase4_site_b_ubuntu_ami" {
  count    = local.phase4_ops_stack_enabled ? 1 : 0
  provider = aws.site_b

  name = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

data "aws_iam_policy_document" "phase4_ops_instance_assume_role" {
  provider = aws.site_a

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "phase4_site_a_ops" {
  count    = local.phase4_ops_stack_enabled ? 1 : 0
  provider = aws.site_a

  name               = "${var.name_prefix}-${var.environment}-site-a-ops-role"
  assume_role_policy = data.aws_iam_policy_document.phase4_ops_instance_assume_role.json

  tags = merge(
    local.common_tags,
    {
      Name      = "${var.name_prefix}-${var.environment}-site-a-ops-role"
      site      = "site-a"
      component = "ops"
    }
  )
}

resource "aws_iam_role_policy_attachment" "phase4_site_a_ops_ssm" {
  count    = local.phase4_ops_stack_enabled ? 1 : 0
  provider = aws.site_a

  role       = aws_iam_role.phase4_site_a_ops[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "phase4_site_a_ops" {
  count    = local.phase4_ops_stack_enabled ? 1 : 0
  provider = aws.site_a

  name = "${var.name_prefix}-${var.environment}-site-a-ops-profile"
  role = aws_iam_role.phase4_site_a_ops[0].name
}

resource "aws_iam_role" "phase4_site_b_ops" {
  count    = local.phase4_ops_stack_enabled ? 1 : 0
  provider = aws.site_b

  name               = "${var.name_prefix}-${var.environment}-site-b-ops-role"
  assume_role_policy = data.aws_iam_policy_document.phase4_ops_instance_assume_role.json

  tags = merge(
    local.common_tags,
    {
      Name      = "${var.name_prefix}-${var.environment}-site-b-ops-role"
      site      = "site-b"
      component = "ops"
    }
  )
}

resource "aws_iam_role_policy_attachment" "phase4_site_b_ops_ssm" {
  count    = local.phase4_ops_stack_enabled ? 1 : 0
  provider = aws.site_b

  role       = aws_iam_role.phase4_site_b_ops[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "phase4_site_b_ops" {
  count    = local.phase4_ops_stack_enabled ? 1 : 0
  provider = aws.site_b

  name = "${var.name_prefix}-${var.environment}-site-b-ops-profile"
  role = aws_iam_role.phase4_site_b_ops[0].name
}

resource "aws_security_group" "phase4_site_a_ansible" {
  count    = local.phase4_ops_stack_enabled ? 1 : 0
  provider = aws.site_a

  name        = "${var.name_prefix}-${var.environment}-site-a-ansible-sg"
  description = "Inbound SSH for Site A Ansible control node."
  vpc_id      = module.aws_site_a.vpc_id

  ingress {
    description = "SSH from internal and trusted IPv4 ranges"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = local.phase4_ops_shared_ssh_cidrs
  }

  egress {
    description = "All egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.common_tags,
    {
      Name      = "${var.name_prefix}-${var.environment}-site-a-ansible-sg"
      site      = "site-a"
      component = "ops"
      service   = "ansible"
    }
  )
}

resource "aws_security_group" "phase4_site_b_git" {
  count    = local.phase4_ops_stack_enabled ? 1 : 0
  provider = aws.site_b

  name        = "${var.name_prefix}-${var.environment}-site-b-git-sg"
  description = "Inbound SSH and web UI access for Site B git server."
  vpc_id      = module.aws_site_b.vpc_id

  ingress {
    description = "SSH from internal and trusted IPv4 ranges"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = local.phase4_ops_shared_ssh_cidrs
  }

  ingress {
    description = "Gitea web UI"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = local.phase4_ops_git_http_allowed_ipv4_cidrs
  }

  ingress {
    description = "Gitea SSH"
    from_port   = 2222
    to_port     = 2222
    protocol    = "tcp"
    cidr_blocks = local.phase4_ops_shared_ssh_cidrs
  }

  egress {
    description = "All egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.common_tags,
    {
      Name      = "${var.name_prefix}-${var.environment}-site-b-git-sg"
      site      = "site-b"
      component = "ops"
      service   = "git"
    }
  )
}

resource "aws_instance" "phase4_git_server" {
  count    = local.phase4_ops_stack_enabled ? 1 : 0
  provider = aws.site_b

  ami                         = data.aws_ssm_parameter.phase4_site_b_ubuntu_ami[0].value
  instance_type               = var.phase4_ops_git_instance_type
  subnet_id                   = module.aws_site_b.ingress_subnet_ids[0]
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.phase4_site_b_git[0].id]
  iam_instance_profile        = aws_iam_instance_profile.phase4_site_b_ops[0].name
  key_name                    = var.phase4_ops_aws_key_pair_name
  user_data                   = local.phase4_ops_git_user_data

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_size           = var.phase4_ops_git_root_volume_size_gb
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = merge(
    local.common_tags,
    {
      Name      = "${var.name_prefix}-${var.environment}-site-b-git"
      site      = "site-b"
      component = "ops"
      service   = "git"
    }
  )
}

resource "google_compute_route" "phase4_site_c_openproject_internet_egress" {
  count    = local.phase4_ops_stack_enabled ? 1 : 0
  provider = google.site_c

  name             = substr(replace("${var.name_prefix}-${var.environment}-site-c-openproject-egress", "_", "-"), 0, 63)
  network          = module.gcp_site_c.network_self_link
  dest_range       = "0.0.0.0/0"
  next_hop_gateway = "default-internet-gateway"
  priority         = 1000
  tags             = [local.phase4_ops_openproject_network_tag]
}

resource "google_compute_firewall" "phase4_site_c_openproject_ssh" {
  count    = local.phase4_ops_stack_enabled ? 1 : 0
  provider = google.site_c

  name    = "${var.name_prefix}-${var.environment}-site-c-openproject-ssh"
  network = module.gcp_site_c.network_self_link

  direction     = "INGRESS"
  source_ranges = local.phase4_ops_shared_ssh_cidrs
  target_tags   = [local.phase4_ops_openproject_network_tag]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_firewall" "phase4_site_c_openproject_http" {
  count    = local.phase4_ops_stack_enabled ? 1 : 0
  provider = google.site_c

  name    = "${var.name_prefix}-${var.environment}-site-c-openproject-http"
  network = module.gcp_site_c.network_self_link

  direction     = "INGRESS"
  source_ranges = local.phase4_ops_openproject_http_allowed_ipv4_cidrs
  target_tags   = [local.phase4_ops_openproject_network_tag]

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
}

resource "google_compute_address" "phase4_site_c_openproject_public_ip" {
  count    = local.phase4_ops_stack_enabled ? 1 : 0
  provider = google.site_c

  name   = "${var.name_prefix}-${var.environment}-site-c-openproject-ip"
  region = var.gcp_site_c_region
}

resource "google_compute_instance" "phase4_openproject_server" {
  count    = local.phase4_ops_stack_enabled ? 1 : 0
  provider = google.site_c

  name         = "${var.name_prefix}-${var.environment}-site-c-openproject"
  machine_type = var.phase4_ops_openproject_machine_type
  zone         = local.phase4_ops_openproject_zone
  tags         = [local.phase4_ops_openproject_network_tag]

  labels = merge(
    local.common_tags,
    {
      site      = "site-c"
      component = "ops"
      service   = "openproject"
    }
  )

  boot_disk {
    auto_delete = true

    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2404-lts-amd64"
      size  = var.phase4_ops_openproject_boot_disk_size_gb
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = module.gcp_site_c.app_subnet_names[0]

    access_config {
      nat_ip = google_compute_address.phase4_site_c_openproject_public_ip[0].address
    }
  }

  metadata_startup_script = local.phase4_ops_openproject_startup_script

  service_account {
    scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write"
    ]
  }

  depends_on = [google_compute_route.phase4_site_c_openproject_internet_egress]
}

resource "aws_instance" "phase4_ansible_control_node" {
  count    = local.phase4_ops_stack_enabled ? 1 : 0
  provider = aws.site_a

  ami                         = data.aws_ssm_parameter.phase4_site_a_ubuntu_ami[0].value
  instance_type               = var.phase4_ops_ansible_instance_type
  subnet_id                   = module.aws_site_a.ingress_subnet_ids[0]
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.phase4_site_a_ansible[0].id]
  iam_instance_profile        = aws_iam_instance_profile.phase4_site_a_ops[0].name
  key_name                    = var.phase4_ops_aws_key_pair_name
  user_data                   = local.phase4_ops_ansible_user_data

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_size           = var.phase4_ops_ansible_root_volume_size_gb
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = merge(
    local.common_tags,
    {
      Name      = "${var.name_prefix}-${var.environment}-site-a-ansible"
      site      = "site-a"
      component = "ops"
      service   = "ansible"
    }
  )
}
