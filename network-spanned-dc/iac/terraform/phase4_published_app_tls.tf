locals {
  phase4_published_app_tls_site_a_enabled = local.phase4_published_app_tls_enabled && var.phase4_cloudflare_site_a_record_name != null
  phase4_published_app_tls_site_b_enabled = local.phase4_published_app_tls_enabled && var.phase4_cloudflare_site_b_record_name != null

  phase4_published_app_tls_site_a_record_name = var.phase4_cloudflare_site_a_record_name == null ? null : trimspace(var.phase4_cloudflare_site_a_record_name)
  phase4_published_app_tls_site_b_record_name = var.phase4_cloudflare_site_b_record_name == null ? null : trimspace(var.phase4_cloudflare_site_b_record_name)

  phase4_published_app_tls_site_a_hostname = local.phase4_published_app_tls_site_a_enabled ? (
    local.phase4_published_app_tls_site_a_record_name == "@" ?
    trimsuffix(var.phase4_cloudflare_zone_name, ".") :
    strcontains(local.phase4_published_app_tls_site_a_record_name, ".") ?
    trimsuffix(local.phase4_published_app_tls_site_a_record_name, ".") :
    "${local.phase4_published_app_tls_site_a_record_name}.${trimsuffix(var.phase4_cloudflare_zone_name, ".")}"
  ) : null

  phase4_published_app_tls_site_b_hostname = local.phase4_published_app_tls_site_b_enabled ? (
    local.phase4_published_app_tls_site_b_record_name == "@" ?
    trimsuffix(var.phase4_cloudflare_zone_name, ".") :
    strcontains(local.phase4_published_app_tls_site_b_record_name, ".") ?
    trimsuffix(local.phase4_published_app_tls_site_b_record_name, ".") :
    "${local.phase4_published_app_tls_site_b_record_name}.${trimsuffix(var.phase4_cloudflare_zone_name, ".")}"
  ) : null

  phase4_published_app_tls_site_a_subject_alternative_names = local.phase4_published_app_tls_site_a_enabled ? [
    for hostname in distinct([
      for san in var.phase4_site_a_published_app_tls_subject_alternative_names :
      (
        trimspace(san) == "@" ?
        trimsuffix(var.phase4_cloudflare_zone_name, ".") :
        strcontains(trimspace(san), ".") ?
        trimsuffix(trimspace(san), ".") :
        "${trimspace(san)}.${trimsuffix(var.phase4_cloudflare_zone_name, ".")}"
      )
      if trimspace(san) != ""
    ]) : hostname
    if lower(hostname) != lower(local.phase4_published_app_tls_site_a_hostname)
  ] : []

  phase4_published_app_tls_site_b_subject_alternative_names = local.phase4_published_app_tls_site_b_enabled ? [
    for hostname in distinct([
      for san in var.phase4_site_b_published_app_tls_subject_alternative_names :
      (
        trimspace(san) == "@" ?
        trimsuffix(var.phase4_cloudflare_zone_name, ".") :
        strcontains(trimspace(san), ".") ?
        trimsuffix(trimspace(san), ".") :
        "${trimspace(san)}.${trimsuffix(var.phase4_cloudflare_zone_name, ".")}"
      )
      if trimspace(san) != ""
    ]) : hostname
    if lower(hostname) != lower(local.phase4_published_app_tls_site_b_hostname)
  ] : []
}

resource "aws_acm_certificate" "phase4_site_a_published_app" {
  provider = aws.site_a
  count    = local.phase4_published_app_tls_site_a_enabled ? 1 : 0

  domain_name               = local.phase4_published_app_tls_site_a_hostname
  subject_alternative_names = local.phase4_published_app_tls_site_a_subject_alternative_names
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    local.common_tags,
    {
      Name      = "${var.name_prefix}-${var.environment}-site-a-pub-cert"
      site      = "site-a"
      component = "published-app-path"
    }
  )
}

resource "cloudflare_record" "phase4_site_a_acm_validation" {
  for_each = local.phase4_published_app_tls_site_a_enabled ? {
    for dvo in aws_acm_certificate.phase4_site_a_published_app[0].domain_validation_options :
    dvo.domain_name => {
      record_name  = dvo.resource_record_name
      record_type  = dvo.resource_record_type
      record_value = dvo.resource_record_value
    }
  } : {}

  zone_id = local.phase4_cloudflare_zone_id_effective
  name    = trimsuffix(each.value.record_name, ".")
  type    = each.value.record_type
  content = trimsuffix(each.value.record_value, ".")
  ttl     = 60
  proxied = false

  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "phase4_site_a_published_app" {
  provider = aws.site_a
  count    = local.phase4_published_app_tls_site_a_enabled ? 1 : 0

  certificate_arn         = aws_acm_certificate.phase4_site_a_published_app[0].arn
  validation_record_fqdns = [for record in cloudflare_record.phase4_site_a_acm_validation : record.hostname]
}

resource "aws_lb_listener" "phase4_site_a_https_forward" {
  provider = aws.site_a
  count    = local.phase4_published_app_tls_site_a_enabled && length(var.phase4_site_a_published_app_backend_ipv4_targets) > 0 ? 1 : 0

  load_balancer_arn = module.aws_published_app_path_site_a[0].summary.load_balancer_arn
  port              = var.phase4_published_app_https_port
  protocol          = "HTTPS"
  ssl_policy        = var.phase4_published_app_tls_ssl_policy
  certificate_arn   = aws_acm_certificate_validation.phase4_site_a_published_app[0].certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = module.aws_published_app_path_site_a[0].summary.target_group_arn
  }
}

resource "aws_lb_listener_rule" "phase4_site_a_https_root_redirect_forward" {
  provider = aws.site_a
  count    = local.phase4_published_app_tls_site_a_enabled && length(var.phase4_site_a_published_app_backend_ipv4_targets) > 0 && var.phase4_published_app_root_redirect_path != null ? 1 : 0

  listener_arn = aws_lb_listener.phase4_site_a_https_forward[0].arn
  priority     = 1

  action {
    type = "redirect"

    redirect {
      host        = "#{host}"
      path        = var.phase4_published_app_root_redirect_path
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

resource "aws_lb_listener" "phase4_site_a_https_fixed" {
  provider = aws.site_a
  count    = local.phase4_published_app_tls_site_a_enabled && length(var.phase4_site_a_published_app_backend_ipv4_targets) == 0 ? 1 : 0

  load_balancer_arn = module.aws_published_app_path_site_a[0].summary.load_balancer_arn
  port              = var.phase4_published_app_https_port
  protocol          = "HTTPS"
  ssl_policy        = var.phase4_published_app_tls_ssl_policy
  certificate_arn   = aws_acm_certificate_validation.phase4_site_a_published_app[0].certificate_arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "application/json"
      message_body = "{\"status\":\"unavailable\",\"reason\":\"no registered backends\"}"
      status_code  = "503"
    }
  }
}

resource "aws_lb_listener_rule" "phase4_site_a_https_root_redirect_fixed" {
  provider = aws.site_a
  count    = local.phase4_published_app_tls_site_a_enabled && length(var.phase4_site_a_published_app_backend_ipv4_targets) == 0 && var.phase4_published_app_root_redirect_path != null ? 1 : 0

  listener_arn = aws_lb_listener.phase4_site_a_https_fixed[0].arn
  priority     = 1

  action {
    type = "redirect"

    redirect {
      host        = "#{host}"
      path        = var.phase4_published_app_root_redirect_path
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

resource "aws_acm_certificate" "phase4_site_b_published_app" {
  provider = aws.site_b
  count    = local.phase4_published_app_tls_site_b_enabled ? 1 : 0

  domain_name               = local.phase4_published_app_tls_site_b_hostname
  subject_alternative_names = local.phase4_published_app_tls_site_b_subject_alternative_names
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    local.common_tags,
    {
      Name      = "${var.name_prefix}-${var.environment}-site-b-pub-cert"
      site      = "site-b"
      component = "published-app-path"
    }
  )
}

resource "cloudflare_record" "phase4_site_b_acm_validation" {
  for_each = local.phase4_published_app_tls_site_b_enabled ? {
    for dvo in aws_acm_certificate.phase4_site_b_published_app[0].domain_validation_options :
    dvo.domain_name => {
      record_name  = dvo.resource_record_name
      record_type  = dvo.resource_record_type
      record_value = dvo.resource_record_value
    }
  } : {}

  zone_id = local.phase4_cloudflare_zone_id_effective
  name    = trimsuffix(each.value.record_name, ".")
  type    = each.value.record_type
  content = trimsuffix(each.value.record_value, ".")
  ttl     = 60
  proxied = false

  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "phase4_site_b_published_app" {
  provider = aws.site_b
  count    = local.phase4_published_app_tls_site_b_enabled ? 1 : 0

  certificate_arn         = aws_acm_certificate.phase4_site_b_published_app[0].arn
  validation_record_fqdns = [for record in cloudflare_record.phase4_site_b_acm_validation : record.hostname]
}

resource "aws_lb_listener" "phase4_site_b_https_forward" {
  provider = aws.site_b
  count    = local.phase4_published_app_tls_site_b_enabled && length(var.phase4_site_b_published_app_backend_ipv4_targets) > 0 ? 1 : 0

  load_balancer_arn = module.aws_published_app_path_site_b[0].summary.load_balancer_arn
  port              = var.phase4_published_app_https_port
  protocol          = "HTTPS"
  ssl_policy        = var.phase4_published_app_tls_ssl_policy
  certificate_arn   = aws_acm_certificate_validation.phase4_site_b_published_app[0].certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = module.aws_published_app_path_site_b[0].summary.target_group_arn
  }
}

resource "aws_lb_listener_rule" "phase4_site_b_https_root_redirect_forward" {
  provider = aws.site_b
  count    = local.phase4_published_app_tls_site_b_enabled && length(var.phase4_site_b_published_app_backend_ipv4_targets) > 0 && var.phase4_published_app_root_redirect_path != null ? 1 : 0

  listener_arn = aws_lb_listener.phase4_site_b_https_forward[0].arn
  priority     = 1

  action {
    type = "redirect"

    redirect {
      host        = "#{host}"
      path        = var.phase4_published_app_root_redirect_path
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

resource "aws_lb_listener" "phase4_site_b_https_fixed" {
  provider = aws.site_b
  count    = local.phase4_published_app_tls_site_b_enabled && length(var.phase4_site_b_published_app_backend_ipv4_targets) == 0 ? 1 : 0

  load_balancer_arn = module.aws_published_app_path_site_b[0].summary.load_balancer_arn
  port              = var.phase4_published_app_https_port
  protocol          = "HTTPS"
  ssl_policy        = var.phase4_published_app_tls_ssl_policy
  certificate_arn   = aws_acm_certificate_validation.phase4_site_b_published_app[0].certificate_arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "application/json"
      message_body = "{\"status\":\"unavailable\",\"reason\":\"no registered backends\"}"
      status_code  = "503"
    }
  }
}

resource "aws_lb_listener_rule" "phase4_site_b_https_root_redirect_fixed" {
  provider = aws.site_b
  count    = local.phase4_published_app_tls_site_b_enabled && length(var.phase4_site_b_published_app_backend_ipv4_targets) == 0 && var.phase4_published_app_root_redirect_path != null ? 1 : 0

  listener_arn = aws_lb_listener.phase4_site_b_https_fixed[0].arn
  priority     = 1

  action {
    type = "redirect"

    redirect {
      host        = "#{host}"
      path        = var.phase4_published_app_root_redirect_path
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
