locals {
  base_name = "${var.name_prefix}-${var.environment}-${var.site_name}"
}

resource "aws_security_group" "broker" {
  name        = "${local.base_name}-vdi-broker-sg"
  description = "VDI broker policy boundary."
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name      = "${local.base_name}-vdi-broker-sg"
      site      = var.site_name
      component = "vdi-broker-policy"
    }
  )
}

resource "aws_security_group" "desktop" {
  name        = "${local.base_name}-vdi-desktop-sg"
  description = "VDI desktop policy boundary."
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name      = "${local.base_name}-vdi-desktop-sg"
      site      = var.site_name
      component = "vdi-desktop-policy"
    }
  )
}

resource "aws_vpc_security_group_ingress_rule" "broker_https_ipv4" {
  for_each = toset(var.broker_ingress_ipv4_cidrs)

  security_group_id = aws_security_group.broker.id
  description       = "HTTPS broker ingress from approved IPv4 CIDRs."
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_ingress_rule" "broker_https_ipv6" {
  for_each = toset(var.broker_ingress_ipv6_cidrs)

  security_group_id = aws_security_group.broker.id
  description       = "HTTPS broker ingress from approved IPv6 CIDRs."
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv6         = each.value
}

resource "aws_vpc_security_group_egress_rule" "broker_to_desktop_rdp" {
  security_group_id            = aws_security_group.broker.id
  description                  = "Broker to desktop RDP."
  ip_protocol                  = "tcp"
  from_port                    = 3389
  to_port                      = 3389
  referenced_security_group_id = aws_security_group.desktop.id
}

resource "aws_vpc_security_group_egress_rule" "broker_to_desktop_vnc" {
  security_group_id            = aws_security_group.broker.id
  description                  = "Broker to desktop VNC."
  ip_protocol                  = "tcp"
  from_port                    = 5900
  to_port                      = 5999
  referenced_security_group_id = aws_security_group.desktop.id
}

resource "aws_vpc_security_group_ingress_rule" "desktop_from_broker_rdp" {
  security_group_id            = aws_security_group.desktop.id
  description                  = "Desktop accepts RDP from broker."
  ip_protocol                  = "tcp"
  from_port                    = 3389
  to_port                      = 3389
  referenced_security_group_id = aws_security_group.broker.id
}

resource "aws_vpc_security_group_ingress_rule" "desktop_from_broker_vnc" {
  security_group_id            = aws_security_group.desktop.id
  description                  = "Desktop accepts VNC from broker."
  ip_protocol                  = "tcp"
  from_port                    = 5900
  to_port                      = 5999
  referenced_security_group_id = aws_security_group.broker.id
}

resource "aws_vpc_security_group_egress_rule" "desktop_to_updates_http_ipv4" {
  for_each = toset(var.desktop_controlled_egress_ipv4_cidrs)

  security_group_id = aws_security_group.desktop.id
  description       = "Desktop controlled egress HTTP."
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "desktop_to_updates_https_ipv4" {
  for_each = toset(var.desktop_controlled_egress_ipv4_cidrs)

  security_group_id = aws_security_group.desktop.id
  description       = "Desktop controlled egress HTTPS."
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "desktop_to_updates_http_ipv6" {
  for_each = toset(var.desktop_controlled_egress_ipv6_cidrs)

  security_group_id = aws_security_group.desktop.id
  description       = "Desktop controlled egress HTTP IPv6."
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv6         = each.value
}

resource "aws_vpc_security_group_egress_rule" "desktop_to_updates_https_ipv6" {
  for_each = toset(var.desktop_controlled_egress_ipv6_cidrs)

  security_group_id = aws_security_group.desktop.id
  description       = "Desktop controlled egress HTTPS IPv6."
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv6         = each.value
}

data "aws_iam_policy_document" "broker_assume" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "broker" {
  name               = "${local.base_name}-vdi-broker-role"
  assume_role_policy = data.aws_iam_policy_document.broker_assume.json

  tags = merge(
    var.tags,
    {
      Name      = "${local.base_name}-vdi-broker-role"
      site      = var.site_name
      component = "vdi-identity"
    }
  )
}

data "aws_iam_policy_document" "broker_identity" {
  statement {
    sid       = "ReadVdiParameterPath"
    effect    = "Allow"
    actions   = ["ssm:GetParameter", "ssm:GetParameters", "ssm:GetParametersByPath"]
    resources = var.identity_ssm_parameter_arn_patterns
  }

  statement {
    sid       = "ReadVdiSecrets"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
    resources = var.identity_secret_arn_patterns
  }

  statement {
    sid       = "DirectoryLookup"
    effect    = "Allow"
    actions   = ["ds:DescribeDirectories"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "broker_identity" {
  name   = "${local.base_name}-vdi-broker-policy"
  policy = data.aws_iam_policy_document.broker_identity.json
}

resource "aws_iam_role_policy_attachment" "broker_identity" {
  role       = aws_iam_role.broker.name
  policy_arn = aws_iam_policy.broker_identity.arn
}

resource "aws_iam_role_policy_attachment" "broker_ssm_core" {
  role       = aws_iam_role.broker.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "broker_cloudwatch_agent" {
  role       = aws_iam_role.broker.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "broker" {
  name = "${local.base_name}-vdi-broker-profile"
  role = aws_iam_role.broker.name
}
