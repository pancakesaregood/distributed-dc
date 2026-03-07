locals {
  phase4_published_app_path_enabled = local.phase4_capacity_enabled && var.phase4_enable_published_app_path
}

module "aws_published_app_path_site_a" {
  count  = local.phase4_published_app_path_enabled ? 1 : 0
  source = "./modules/aws_published_app_path"

  providers = {
    aws = aws.site_a
  }

  site_name                  = "site-a"
  name_prefix                = var.name_prefix
  environment                = var.environment
  vpc_id                     = module.aws_site_a.vpc_id
  ingress_subnet_ids         = module.aws_site_a.ingress_subnet_ids
  listener_port              = var.phase4_published_app_listener_port
  allowed_ingress_ipv4_cidrs = var.phase4_published_app_allowed_ingress_ipv4_cidrs
  allowed_ingress_ipv6_cidrs = var.phase4_published_app_allowed_ingress_ipv6_cidrs
  health_check_path          = var.phase4_published_app_health_check_path
  backend_target_port        = var.phase4_published_app_backend_port
  backend_ipv4_targets       = var.phase4_site_a_published_app_backend_ipv4_targets
  waf_rate_limit             = var.phase4_published_app_waf_rate_limit
  tags                       = local.common_tags
}

module "aws_published_app_path_site_b" {
  count  = local.phase4_published_app_path_enabled ? 1 : 0
  source = "./modules/aws_published_app_path"

  providers = {
    aws = aws.site_b
  }

  site_name                  = "site-b"
  name_prefix                = var.name_prefix
  environment                = var.environment
  vpc_id                     = module.aws_site_b.vpc_id
  ingress_subnet_ids         = module.aws_site_b.ingress_subnet_ids
  listener_port              = var.phase4_published_app_listener_port
  allowed_ingress_ipv4_cidrs = var.phase4_published_app_allowed_ingress_ipv4_cidrs
  allowed_ingress_ipv6_cidrs = var.phase4_published_app_allowed_ingress_ipv6_cidrs
  health_check_path          = var.phase4_published_app_health_check_path
  backend_target_port        = var.phase4_published_app_backend_port
  backend_ipv4_targets       = var.phase4_site_b_published_app_backend_ipv4_targets
  waf_rate_limit             = var.phase4_published_app_waf_rate_limit
  tags                       = local.common_tags
}
