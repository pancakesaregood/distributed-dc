locals {
  base_name = "${var.name_prefix}-${var.environment}-${var.site_name}"

  backend_targets = {
    for idx, ip in var.backend_ipv4_targets :
    tostring(idx) => ip
  }
}

resource "aws_security_group" "alb" {
  name        = "${local.base_name}-pub-alb-sg"
  description = "Allow published app ingress and outbound backend access."
  vpc_id      = var.vpc_id

  ingress {
    description      = "Published app client ingress"
    from_port        = var.listener_port
    to_port          = var.listener_port
    protocol         = "tcp"
    cidr_blocks      = var.allowed_ingress_ipv4_cidrs
    ipv6_cidr_blocks = var.allowed_ingress_ipv6_cidrs
  }

  dynamic "ingress" {
    for_each = var.https_listener_port == null ? [] : [var.https_listener_port]
    content {
      description      = "Published app client TLS ingress"
      from_port        = ingress.value
      to_port          = ingress.value
      protocol         = "tcp"
      cidr_blocks      = var.allowed_ingress_ipv4_cidrs
      ipv6_cidr_blocks = var.allowed_ingress_ipv6_cidrs
    }
  }

  egress {
    description = "Backend and service egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name      = "${local.base_name}-pub-alb-sg"
      site      = var.site_name
      component = "published-app-path"
    }
  )
}

resource "aws_lb" "this" {
  name               = substr("${local.base_name}-pub-alb", 0, 32)
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.ingress_subnet_ids

  enable_deletion_protection = false
  idle_timeout               = 60
  drop_invalid_header_fields = true

  tags = merge(
    var.tags,
    {
      Name      = "${local.base_name}-pub-alb"
      site      = var.site_name
      component = "published-app-path"
    }
  )
}

resource "aws_lb_target_group" "app" {
  name        = substr("${local.base_name}-pub-tg", 0, 32)
  port        = var.backend_target_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    protocol            = "HTTP"
    path                = var.health_check_path
    port                = tostring(var.backend_target_port)
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }

  tags = merge(
    var.tags,
    {
      Name      = "${local.base_name}-pub-tg"
      site      = var.site_name
      component = "published-app-path"
    }
  )
}

resource "aws_lb_target_group_attachment" "app" {
  for_each = local.backend_targets

  target_group_arn = aws_lb_target_group.app.arn
  target_id        = each.value
  port             = var.backend_target_port
}

resource "aws_lb_listener" "http_forward" {
  count = length(var.backend_ipv4_targets) > 0 ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = var.listener_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_lb_listener_rule" "http_root_redirect_forward" {
  count = length(var.backend_ipv4_targets) > 0 && var.root_redirect_path != null ? 1 : 0

  listener_arn = aws_lb_listener.http_forward[0].arn
  priority     = 1

  action {
    type = "redirect"

    redirect {
      host        = "#{host}"
      path        = var.root_redirect_path
      port        = "#{port}"
      protocol    = "#{protocol}"
      query       = "#{query}"
      status_code = "HTTP_302"
    }
  }

  condition {
    path_pattern {
      values = ["/"]
    }
  }
}

resource "aws_lb_listener" "http_fixed" {
  count = length(var.backend_ipv4_targets) == 0 ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = var.listener_port
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "application/json"
      message_body = "{\"status\":\"unavailable\",\"reason\":\"no registered backends\"}"
      status_code  = "503"
    }
  }
}

resource "aws_lb_listener_rule" "http_root_redirect_fixed" {
  count = length(var.backend_ipv4_targets) == 0 && var.root_redirect_path != null ? 1 : 0

  listener_arn = aws_lb_listener.http_fixed[0].arn
  priority     = 1

  action {
    type = "redirect"

    redirect {
      host        = "#{host}"
      path        = var.root_redirect_path
      port        = "#{port}"
      protocol    = "#{protocol}"
      query       = "#{query}"
      status_code = "HTTP_302"
    }
  }

  condition {
    path_pattern {
      values = ["/"]
    }
  }
}

resource "aws_wafv2_web_acl" "this" {
  name  = "${local.base_name}-pub-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "aws-managed-common"
    priority = 0

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${replace(local.base_name, "-", "_")}_pub_common"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "aws-managed-known-bad-inputs"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${replace(local.base_name, "-", "_")}_pub_bad_inputs"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "rate-limit"
    priority = 2

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.waf_rate_limit
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${replace(local.base_name, "-", "_")}_pub_rate_limit"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${replace(local.base_name, "-", "_")}_pub_web_acl"
    sampled_requests_enabled   = true
  }

  tags = merge(
    var.tags,
    {
      Name      = "${local.base_name}-pub-waf"
      site      = var.site_name
      component = "published-app-path"
    }
  )
}

resource "aws_wafv2_web_acl_association" "this" {
  resource_arn = aws_lb.this.arn
  web_acl_arn  = aws_wafv2_web_acl.this.arn
}
