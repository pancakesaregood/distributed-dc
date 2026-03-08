locals {
  phase4_published_app_path_enabled        = local.phase4_capacity_enabled && var.phase4_enable_published_app_path
  phase4_published_app_tls_enabled         = local.phase4_published_app_path_enabled && var.phase4_enable_published_app_tls
  phase4_published_app_to_vdi_eks_nodeport = local.phase4_published_app_path_enabled && local.phase4_vdi_reference_stack_enabled && var.phase4_vdi_enable_aws_worker_pools
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
  https_listener_port        = local.phase4_published_app_tls_enabled ? var.phase4_published_app_https_port : null
  allowed_ingress_ipv4_cidrs = var.phase4_published_app_allowed_ingress_ipv4_cidrs
  allowed_ingress_ipv6_cidrs = var.phase4_published_app_allowed_ingress_ipv6_cidrs
  health_check_path          = var.phase4_published_app_health_check_path
  root_redirect_path         = var.phase4_published_app_root_redirect_path
  backend_target_port        = var.phase4_published_app_backend_port
  backend_ipv4_targets       = var.phase4_site_a_published_app_backend_ipv4_targets
  waf_rate_limit             = var.phase4_published_app_waf_rate_limit
  tags                       = local.common_tags

  depends_on = [module.aws_site_a]
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
  https_listener_port        = local.phase4_published_app_tls_enabled ? var.phase4_published_app_https_port : null
  allowed_ingress_ipv4_cidrs = var.phase4_published_app_allowed_ingress_ipv4_cidrs
  allowed_ingress_ipv6_cidrs = var.phase4_published_app_allowed_ingress_ipv6_cidrs
  health_check_path          = var.phase4_published_app_health_check_path
  root_redirect_path         = var.phase4_published_app_root_redirect_path
  backend_target_port        = var.phase4_published_app_backend_port
  backend_ipv4_targets       = var.phase4_site_b_published_app_backend_ipv4_targets
  waf_rate_limit             = var.phase4_published_app_waf_rate_limit
  tags                       = local.common_tags

  depends_on = [module.aws_site_b]
}

resource "aws_vpc_security_group_ingress_rule" "phase4_site_a_published_app_to_vdi_eks_nodeport" {
  provider = aws.site_a
  count    = local.phase4_published_app_to_vdi_eks_nodeport ? 1 : 0

  security_group_id            = module.aws_eks_site_a[0].summary.cluster_security_group_id
  referenced_security_group_id = module.aws_published_app_path_site_a[0].summary.security_group_id
  ip_protocol                  = "tcp"
  from_port                    = var.phase4_published_app_backend_port
  to_port                      = var.phase4_published_app_backend_port
  description                  = "Allow published app ALB health/data traffic to EKS VDI nodeport"
}

resource "aws_vpc_security_group_ingress_rule" "phase4_site_b_published_app_to_vdi_eks_nodeport" {
  provider = aws.site_b
  count    = local.phase4_published_app_to_vdi_eks_nodeport ? 1 : 0

  security_group_id            = module.aws_eks_site_b[0].summary.cluster_security_group_id
  referenced_security_group_id = module.aws_published_app_path_site_b[0].summary.security_group_id
  ip_protocol                  = "tcp"
  from_port                    = var.phase4_published_app_backend_port
  to_port                      = var.phase4_published_app_backend_port
  description                  = "Allow published app ALB health/data traffic to EKS VDI nodeport"
}
