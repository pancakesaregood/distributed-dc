locals {
  phase4_site_a_forward_proxy_enabled = local.phase4_vdi_reference_stack_enabled && var.phase4_enable_forward_proxy_site_a

  phase4_site_a_forward_proxy_subnet_id = (
    var.phase4_forward_proxy_site_a_subnet_id != null ?
    var.phase4_forward_proxy_site_a_subnet_id :
    module.aws_site_a.ingress_subnet_ids[0]
  )

  phase4_site_a_forward_proxy_private_ip = (
    var.phase4_forward_proxy_site_a_private_ip != null ?
    var.phase4_forward_proxy_site_a_private_ip :
    cidrhost(cidrsubnet(var.site_a_ipv4_cidr, 4, 0), 50)
  )

  phase4_site_a_forward_proxy_client_ipv4_cidrs = (
    var.phase4_forward_proxy_site_a_allowed_client_ipv4_cidrs != null &&
    length(var.phase4_forward_proxy_site_a_allowed_client_ipv4_cidrs) > 0
    ) ? var.phase4_forward_proxy_site_a_allowed_client_ipv4_cidrs : [
    cidrsubnet(var.site_a_ipv4_cidr, 4, 6),
    cidrsubnet(var.site_a_ipv4_cidr, 4, 7)
  ]

  phase4_site_a_forward_proxy_allow_domains = distinct([
    for domain in var.phase4_forward_proxy_site_a_allow_domains :
    lower(trimspace(domain))
    if trimspace(domain) != ""
  ])

  phase4_site_a_forward_proxy_block_domains = distinct([
    for domain in var.phase4_forward_proxy_site_a_block_domains :
    lower(trimspace(domain))
    if trimspace(domain) != ""
  ])

  phase4_site_a_forward_proxy_startup_script = <<-EOT
#!/bin/bash
set -euo pipefail

dnf install -y squid

cat > /etc/squid/squid.conf <<'SQUIDCONF'
http_port ${var.phase4_forward_proxy_site_a_listen_port}
visible_hostname site-a-forward-proxy
dns_v4_first on

acl local_clients src ${join(" ", local.phase4_site_a_forward_proxy_client_ipv4_cidrs)}
acl SSL_ports port 443
acl Safe_ports port 80
acl Safe_ports port 443
acl Safe_ports port 21
acl Safe_ports port 70
acl Safe_ports port 210
acl Safe_ports port 1025-65535
acl Safe_ports port 280
acl Safe_ports port 488
acl Safe_ports port 591
acl Safe_ports port 777
acl CONNECT method CONNECT

http_access deny !Safe_ports
http_access deny CONNECT !SSL_ports
%{if length(local.phase4_site_a_forward_proxy_block_domains) > 0~}
acl blocked_domains dstdomain ${join(" ", local.phase4_site_a_forward_proxy_block_domains)}
http_access deny local_clients blocked_domains
%{endif~}
%{if length(local.phase4_site_a_forward_proxy_allow_domains) > 0~}
acl allowed_domains dstdomain ${join(" ", local.phase4_site_a_forward_proxy_allow_domains)}
http_access deny local_clients !allowed_domains
%{endif~}
http_access allow local_clients
http_access deny all

cache deny all
access_log stdio:/var/log/squid/access.log
cache_log /var/log/squid/cache.log
SQUIDCONF

systemctl enable squid
systemctl restart squid
EOT
}

data "aws_ssm_parameter" "phase4_site_a_forward_proxy_ami" {
  provider = aws.site_a
  count    = local.phase4_site_a_forward_proxy_enabled ? 1 : 0

  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

data "aws_iam_policy_document" "phase4_site_a_forward_proxy_assume_role" {
  provider = aws.site_a

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "phase4_site_a_forward_proxy" {
  provider = aws.site_a
  count    = local.phase4_site_a_forward_proxy_enabled ? 1 : 0

  name               = "${var.name_prefix}-${var.environment}-site-a-forward-proxy-role"
  assume_role_policy = data.aws_iam_policy_document.phase4_site_a_forward_proxy_assume_role.json

  tags = merge(
    local.common_tags,
    {
      Name      = "${var.name_prefix}-${var.environment}-site-a-forward-proxy-role"
      site      = "site-a"
      component = "forward-proxy"
    }
  )
}

resource "aws_iam_role_policy_attachment" "phase4_site_a_forward_proxy_ssm" {
  provider = aws.site_a
  count    = local.phase4_site_a_forward_proxy_enabled ? 1 : 0

  role       = aws_iam_role.phase4_site_a_forward_proxy[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "phase4_site_a_forward_proxy" {
  provider = aws.site_a
  count    = local.phase4_site_a_forward_proxy_enabled ? 1 : 0

  name = "${var.name_prefix}-${var.environment}-site-a-forward-proxy-profile"
  role = aws_iam_role.phase4_site_a_forward_proxy[0].name
}

resource "aws_security_group" "phase4_site_a_forward_proxy" {
  provider = aws.site_a
  count    = local.phase4_site_a_forward_proxy_enabled ? 1 : 0

  name        = "${var.name_prefix}-${var.environment}-site-a-forward-proxy-sg"
  description = "Site A forward proxy ingress controls."
  vpc_id      = module.aws_site_a.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name      = "${var.name_prefix}-${var.environment}-site-a-forward-proxy-sg"
      site      = "site-a"
      component = "forward-proxy"
    }
  )
}

resource "aws_vpc_security_group_ingress_rule" "phase4_site_a_forward_proxy_from_clients" {
  provider = aws.site_a
  for_each = local.phase4_site_a_forward_proxy_enabled ? {
    for cidr in local.phase4_site_a_forward_proxy_client_ipv4_cidrs :
    cidr => cidr
  } : {}

  security_group_id = aws_security_group.phase4_site_a_forward_proxy[0].id
  description       = "Proxy access from approved client CIDR ${each.value}"
  ip_protocol       = "tcp"
  from_port         = var.phase4_forward_proxy_site_a_listen_port
  to_port           = var.phase4_forward_proxy_site_a_listen_port
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_ingress_rule" "phase4_site_a_forward_proxy_ssh" {
  provider = aws.site_a
  for_each = local.phase4_site_a_forward_proxy_enabled ? {
    for cidr in var.phase4_forward_proxy_site_a_ssh_allowed_ipv4_cidrs :
    cidr => cidr
  } : {}

  security_group_id = aws_security_group.phase4_site_a_forward_proxy[0].id
  description       = "Optional SSH admin access from ${each.value}"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "phase4_site_a_forward_proxy_egress_ipv4" {
  provider = aws.site_a
  count    = local.phase4_site_a_forward_proxy_enabled ? 1 : 0

  security_group_id = aws_security_group.phase4_site_a_forward_proxy[0].id
  description       = "Forward proxy outbound internet IPv4."
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "phase4_site_a_forward_proxy_egress_ipv6" {
  provider = aws.site_a
  count    = local.phase4_site_a_forward_proxy_enabled ? 1 : 0

  security_group_id = aws_security_group.phase4_site_a_forward_proxy[0].id
  description       = "Forward proxy outbound internet IPv6."
  ip_protocol       = "-1"
  cidr_ipv6         = "::/0"
}

resource "aws_instance" "phase4_site_a_forward_proxy" {
  provider = aws.site_a
  count    = local.phase4_site_a_forward_proxy_enabled ? 1 : 0

  ami                         = data.aws_ssm_parameter.phase4_site_a_forward_proxy_ami[0].value
  instance_type               = var.phase4_forward_proxy_site_a_instance_type
  subnet_id                   = local.phase4_site_a_forward_proxy_subnet_id
  private_ip                  = local.phase4_site_a_forward_proxy_private_ip
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.phase4_site_a_forward_proxy[0].name
  vpc_security_group_ids      = [aws_security_group.phase4_site_a_forward_proxy[0].id]
  user_data                   = local.phase4_site_a_forward_proxy_startup_script

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = merge(
    local.common_tags,
    {
      Name      = "${var.name_prefix}-${var.environment}-site-a-forward-proxy"
      site      = "site-a"
      component = "forward-proxy"
    }
  )

  depends_on = [
    aws_vpc_security_group_ingress_rule.phase4_site_a_forward_proxy_from_clients,
    aws_vpc_security_group_egress_rule.phase4_site_a_forward_proxy_egress_ipv4
  ]
}
