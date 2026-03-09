locals {
  phase4_site_a_windows_desktop_enabled = local.phase4_vdi_reference_stack_enabled && var.phase4_vdi_site_a_windows_desktop_enabled
  phase4_site_a_windows_desktop_subnet_id = (
    var.phase4_vdi_site_a_windows_desktop_subnet_id != null ?
    var.phase4_vdi_site_a_windows_desktop_subnet_id :
    module.aws_site_a.vdi_subnet_ids[0]
  )
  phase4_site_a_windows_desktop_ami_id_effective = (
    var.phase4_vdi_site_a_windows_desktop_ami_id != null ?
    var.phase4_vdi_site_a_windows_desktop_ami_id :
    try(data.aws_ssm_parameter.phase4_site_a_windows_desktop_ami[0].value, null)
  )
  phase4_site_a_vpc_resolver_ipv4 = cidrhost(module.aws_site_a.vpc_ipv4_cidr, 2)
}

data "aws_ssm_parameter" "phase4_site_a_windows_desktop_ami" {
  provider = aws.site_a
  count = (
    local.phase4_site_a_windows_desktop_enabled &&
    var.phase4_vdi_site_a_windows_desktop_ami_id == null
  ) ? 1 : 0

  name = var.phase4_vdi_site_a_windows_desktop_ami_ssm_parameter_name
}

resource "aws_security_group" "phase4_site_a_windows_desktop" {
  provider = aws.site_a
  count    = local.phase4_site_a_windows_desktop_enabled ? 1 : 0

  name        = "${var.name_prefix}-${var.environment}-site-a-windows-desktop-sg"
  description = "Site A Windows desktop for Guacamole RDP"
  vpc_id      = module.aws_site_a.vpc_id
  egress      = []

  tags = {
    Name        = "${var.name_prefix}-${var.environment}-site-a-windows-desktop-sg"
    Project     = var.name_prefix
    Environment = var.environment
    Role        = "vdi-windows-desktop"
  }
}

resource "aws_vpc_security_group_ingress_rule" "phase4_site_a_windows_desktop_rdp_from_site_a_vpc" {
  provider = aws.site_a
  count    = local.phase4_site_a_windows_desktop_enabled ? 1 : 0

  security_group_id = aws_security_group.phase4_site_a_windows_desktop[0].id
  description       = "RDP from Site A VPC"
  ip_protocol       = "tcp"
  from_port         = 3389
  to_port           = 3389
  cidr_ipv4         = module.aws_site_a.vpc_ipv4_cidr
}

resource "aws_vpc_security_group_egress_rule" "phase4_site_a_windows_desktop_http_ipv4" {
  provider = aws.site_a
  for_each = local.phase4_site_a_windows_desktop_enabled ? toset(var.phase4_vdi_aws_desktop_controlled_egress_ipv4_cidrs) : toset([])

  security_group_id = aws_security_group.phase4_site_a_windows_desktop[0].id
  description       = "Controlled HTTP egress for Windows desktop."
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "phase4_site_a_windows_desktop_https_ipv4" {
  provider = aws.site_a
  for_each = local.phase4_site_a_windows_desktop_enabled ? toset(var.phase4_vdi_aws_desktop_controlled_egress_ipv4_cidrs) : toset([])

  security_group_id = aws_security_group.phase4_site_a_windows_desktop[0].id
  description       = "Controlled HTTPS egress for Windows desktop."
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "phase4_site_a_windows_desktop_http_ipv6" {
  provider = aws.site_a
  for_each = local.phase4_site_a_windows_desktop_enabled ? toset(var.phase4_vdi_aws_desktop_controlled_egress_ipv6_cidrs) : toset([])

  security_group_id = aws_security_group.phase4_site_a_windows_desktop[0].id
  description       = "Controlled HTTP egress for Windows desktop (IPv6)."
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv6         = each.value
}

resource "aws_vpc_security_group_egress_rule" "phase4_site_a_windows_desktop_https_ipv6" {
  provider = aws.site_a
  for_each = local.phase4_site_a_windows_desktop_enabled ? toset(var.phase4_vdi_aws_desktop_controlled_egress_ipv6_cidrs) : toset([])

  security_group_id = aws_security_group.phase4_site_a_windows_desktop[0].id
  description       = "Controlled HTTPS egress for Windows desktop (IPv6)."
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv6         = each.value
}

resource "aws_vpc_security_group_egress_rule" "phase4_site_a_windows_desktop_dns_udp_resolver" {
  provider = aws.site_a
  count    = local.phase4_site_a_windows_desktop_enabled ? 1 : 0

  security_group_id = aws_security_group.phase4_site_a_windows_desktop[0].id
  description       = "DNS UDP to VPC resolver."
  ip_protocol       = "udp"
  from_port         = 53
  to_port           = 53
  cidr_ipv4         = "${local.phase4_site_a_vpc_resolver_ipv4}/32"
}

resource "aws_vpc_security_group_egress_rule" "phase4_site_a_windows_desktop_dns_tcp_resolver" {
  provider = aws.site_a
  count    = local.phase4_site_a_windows_desktop_enabled ? 1 : 0

  security_group_id = aws_security_group.phase4_site_a_windows_desktop[0].id
  description       = "DNS TCP to VPC resolver."
  ip_protocol       = "tcp"
  from_port         = 53
  to_port           = 53
  cidr_ipv4         = "${local.phase4_site_a_vpc_resolver_ipv4}/32"
}

resource "aws_instance" "phase4_site_a_windows_desktop" {
  provider = aws.site_a
  count    = local.phase4_site_a_windows_desktop_enabled ? 1 : 0

  ami                         = local.phase4_site_a_windows_desktop_ami_id_effective
  instance_type               = var.phase4_vdi_site_a_windows_desktop_instance_type
  subnet_id                   = local.phase4_site_a_windows_desktop_subnet_id
  vpc_security_group_ids      = [aws_security_group.phase4_site_a_windows_desktop[0].id]
  associate_public_ip_address = false
  disable_api_termination     = var.phase4_vdi_site_a_windows_desktop_disable_api_termination
  user_data                   = var.phase4_vdi_site_a_windows_desktop_user_data

  tags = {
    Name        = "${var.name_prefix}-${var.environment}-site-a-windows-desktop"
    Project     = var.name_prefix
    Environment = var.environment
    Role        = "vdi-windows-desktop"
  }

  lifecycle {
    # Keep imported/manual desktop stable unless explicitly changed by operators.
    ignore_changes = [ami, user_data, user_data_base64]
  }
}
