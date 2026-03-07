locals {
  phase4_vdi_reference_stack_enabled = local.phase4_capacity_enabled && var.phase4_enable_vdi_reference_stack
}

module "aws_vdi_reference_stack_site_a" {
  count  = local.phase4_vdi_reference_stack_enabled ? 1 : 0
  source = "./modules/aws_vdi_reference_stack"

  providers = {
    aws = aws.site_a
  }

  site_name                            = "site-a"
  name_prefix                          = var.name_prefix
  environment                          = var.environment
  vpc_id                               = module.aws_site_a.vpc_id
  broker_ingress_ipv4_cidrs            = [module.aws_site_a.vpc_ipv4_cidr]
  broker_ingress_ipv6_cidrs            = module.aws_site_a.vpc_ipv6_cidr != null ? [module.aws_site_a.vpc_ipv6_cidr] : []
  desktop_controlled_egress_ipv4_cidrs = var.phase4_vdi_aws_desktop_controlled_egress_ipv4_cidrs
  desktop_controlled_egress_ipv6_cidrs = var.phase4_vdi_aws_desktop_controlled_egress_ipv6_cidrs
  identity_ssm_parameter_arn_patterns  = var.phase4_vdi_identity_ssm_parameter_arn_patterns
  identity_secret_arn_patterns         = var.phase4_vdi_identity_secret_arn_patterns
  tags                                 = local.common_tags
}

module "aws_vdi_reference_stack_site_b" {
  count  = local.phase4_vdi_reference_stack_enabled ? 1 : 0
  source = "./modules/aws_vdi_reference_stack"

  providers = {
    aws = aws.site_b
  }

  site_name                            = "site-b"
  name_prefix                          = var.name_prefix
  environment                          = var.environment
  vpc_id                               = module.aws_site_b.vpc_id
  broker_ingress_ipv4_cidrs            = [module.aws_site_b.vpc_ipv4_cidr]
  broker_ingress_ipv6_cidrs            = module.aws_site_b.vpc_ipv6_cidr != null ? [module.aws_site_b.vpc_ipv6_cidr] : []
  desktop_controlled_egress_ipv4_cidrs = var.phase4_vdi_aws_desktop_controlled_egress_ipv4_cidrs
  desktop_controlled_egress_ipv6_cidrs = var.phase4_vdi_aws_desktop_controlled_egress_ipv6_cidrs
  identity_ssm_parameter_arn_patterns  = var.phase4_vdi_identity_ssm_parameter_arn_patterns
  identity_secret_arn_patterns         = var.phase4_vdi_identity_secret_arn_patterns
  tags                                 = local.common_tags
}

module "gcp_vdi_reference_stack_site_c" {
  count  = local.phase4_vdi_reference_stack_enabled ? 1 : 0
  source = "./modules/gcp_vdi_reference_stack"

  providers = {
    google = google.site_c
  }

  site_name                            = "site-c"
  name_prefix                          = var.name_prefix
  environment                          = var.environment
  project_id                           = var.gcp_project_id
  network_self_link                    = module.gcp_site_c.network_self_link
  broker_ingress_ipv4_cidrs            = [var.site_c_ipv4_cidr]
  desktop_controlled_egress_ipv4_cidrs = var.phase4_vdi_gcp_desktop_controlled_egress_ipv4_cidrs
}

module "gcp_vdi_reference_stack_site_d" {
  count  = local.phase4_vdi_reference_stack_enabled ? 1 : 0
  source = "./modules/gcp_vdi_reference_stack"

  providers = {
    google = google.site_d
  }

  site_name                            = "site-d"
  name_prefix                          = var.name_prefix
  environment                          = var.environment
  project_id                           = var.gcp_project_id
  network_self_link                    = module.gcp_site_d.network_self_link
  broker_ingress_ipv4_cidrs            = [var.site_d_ipv4_cidr]
  desktop_controlled_egress_ipv4_cidrs = var.phase4_vdi_gcp_desktop_controlled_egress_ipv4_cidrs
}

module "aws_eks_nodegroup_site_a_vdi" {
  count  = local.phase4_vdi_reference_stack_enabled ? 1 : 0
  source = "./modules/aws_eks_nodegroup"

  providers = {
    aws = aws.site_a
  }

  site_name                        = "site-a"
  name_prefix                      = var.name_prefix
  environment                      = var.environment
  node_group_suffix                = "vdi"
  cluster_name                     = module.aws_eks_site_a[0].summary.cluster_name
  subnet_ids                       = module.aws_site_a.vdi_subnet_ids
  desired_size                     = var.phase4_vdi_aws_node_desired_size
  min_size                         = var.phase4_vdi_aws_node_min_size
  max_size                         = var.phase4_vdi_aws_node_max_size
  instance_types                   = var.phase4_vdi_aws_node_instance_types
  capacity_type                    = var.phase4_aws_node_capacity_type
  disk_size                        = var.phase4_aws_node_disk_size
  ami_type                         = var.phase4_aws_node_ami_type
  labels                           = merge(var.phase4_aws_node_labels, var.phase4_vdi_aws_node_labels, { site = "site-a", workload = "vdi" })
  taints                           = var.phase4_vdi_aws_node_taints
  max_unavailable                  = var.phase4_vdi_aws_node_max_unavailable
  enable_ssm_managed_instance_core = var.phase4_aws_enable_ssm_managed_instance_core
  tags                             = local.common_tags

  depends_on = [
    module.aws_vdi_reference_stack_site_a,
    aws_vpc_endpoint.phase4_site_a_interface,
    aws_vpc_endpoint.phase4_site_a_s3_gateway
  ]
}

module "aws_eks_nodegroup_site_b_vdi" {
  count  = local.phase4_vdi_reference_stack_enabled ? 1 : 0
  source = "./modules/aws_eks_nodegroup"

  providers = {
    aws = aws.site_b
  }

  site_name                        = "site-b"
  name_prefix                      = var.name_prefix
  environment                      = var.environment
  node_group_suffix                = "vdi"
  cluster_name                     = module.aws_eks_site_b[0].summary.cluster_name
  subnet_ids                       = module.aws_site_b.vdi_subnet_ids
  desired_size                     = var.phase4_vdi_aws_node_desired_size
  min_size                         = var.phase4_vdi_aws_node_min_size
  max_size                         = var.phase4_vdi_aws_node_max_size
  instance_types                   = var.phase4_vdi_aws_node_instance_types
  capacity_type                    = var.phase4_aws_node_capacity_type
  disk_size                        = var.phase4_aws_node_disk_size
  ami_type                         = var.phase4_aws_node_ami_type
  labels                           = merge(var.phase4_aws_node_labels, var.phase4_vdi_aws_node_labels, { site = "site-b", workload = "vdi" })
  taints                           = var.phase4_vdi_aws_node_taints
  max_unavailable                  = var.phase4_vdi_aws_node_max_unavailable
  enable_ssm_managed_instance_core = var.phase4_aws_enable_ssm_managed_instance_core
  tags                             = local.common_tags

  depends_on = [
    module.aws_vdi_reference_stack_site_b,
    aws_vpc_endpoint.phase4_site_b_interface,
    aws_vpc_endpoint.phase4_site_b_s3_gateway
  ]
}

module "gcp_gke_node_pool_site_c_vdi" {
  count  = local.phase4_vdi_reference_stack_enabled ? 1 : 0
  source = "./modules/gcp_gke_node_pool"

  providers = {
    google = google.site_c
  }

  site_name                         = "site-c"
  name_prefix                       = var.name_prefix
  environment                       = var.environment
  node_pool_suffix                  = "vdi"
  location                          = var.gcp_site_c_region
  cluster_name                      = module.gcp_gke_site_c[0].summary.cluster_name
  machine_type                      = var.phase4_vdi_gcp_node_machine_type
  disk_size_gb                      = var.phase4_vdi_gcp_node_disk_size_gb
  disk_type                         = var.phase4_vdi_gcp_node_disk_type
  image_type                        = var.phase4_vdi_gcp_node_image_type
  spot                              = var.phase4_vdi_gcp_node_spot
  enable_autoscaling                = var.phase4_vdi_gcp_node_enable_autoscaling
  min_node_count                    = var.phase4_vdi_gcp_node_min_count
  max_node_count                    = var.phase4_vdi_gcp_node_max_count
  initial_node_count                = var.phase4_vdi_gcp_node_initial_count
  service_account                   = coalesce(var.phase4_vdi_gcp_node_service_account, module.gcp_vdi_reference_stack_site_c[0].summary.service_account_email)
  node_labels                       = merge(var.phase4_gcp_node_labels, var.phase4_vdi_gcp_node_labels, { site = "site-c", workload = "vdi" })
  node_tags                         = distinct(concat(var.phase4_gcp_node_tags, var.phase4_vdi_gcp_node_tags, [module.gcp_vdi_reference_stack_site_c[0].summary.broker_network_tag, module.gcp_vdi_reference_stack_site_c[0].summary.desktop_network_tag]))
  node_oauth_scopes                 = var.phase4_gcp_node_oauth_scopes
  disable_legacy_metadata_endpoints = var.phase4_gcp_node_disable_legacy_metadata_endpoints
  enable_secure_boot                = var.phase4_gcp_node_enable_secure_boot
  enable_integrity_monitoring       = var.phase4_gcp_node_enable_integrity_monitoring
  workload_metadata_mode            = var.phase4_gcp_node_workload_metadata_mode

  depends_on = [module.gcp_vdi_reference_stack_site_c]
}

module "gcp_gke_node_pool_site_d_vdi" {
  count  = local.phase4_vdi_reference_stack_enabled ? 1 : 0
  source = "./modules/gcp_gke_node_pool"

  providers = {
    google = google.site_d
  }

  site_name                         = "site-d"
  name_prefix                       = var.name_prefix
  environment                       = var.environment
  node_pool_suffix                  = "vdi"
  location                          = var.gcp_site_d_region
  cluster_name                      = module.gcp_gke_site_d[0].summary.cluster_name
  machine_type                      = var.phase4_vdi_gcp_node_machine_type
  disk_size_gb                      = var.phase4_vdi_gcp_node_disk_size_gb
  disk_type                         = var.phase4_vdi_gcp_node_disk_type
  image_type                        = var.phase4_vdi_gcp_node_image_type
  spot                              = var.phase4_vdi_gcp_node_spot
  enable_autoscaling                = var.phase4_vdi_gcp_node_enable_autoscaling
  min_node_count                    = var.phase4_vdi_gcp_node_min_count
  max_node_count                    = var.phase4_vdi_gcp_node_max_count
  initial_node_count                = var.phase4_vdi_gcp_node_initial_count
  service_account                   = coalesce(var.phase4_vdi_gcp_node_service_account, module.gcp_vdi_reference_stack_site_d[0].summary.service_account_email)
  node_labels                       = merge(var.phase4_gcp_node_labels, var.phase4_vdi_gcp_node_labels, { site = "site-d", workload = "vdi" })
  node_tags                         = distinct(concat(var.phase4_gcp_node_tags, var.phase4_vdi_gcp_node_tags, [module.gcp_vdi_reference_stack_site_d[0].summary.broker_network_tag, module.gcp_vdi_reference_stack_site_d[0].summary.desktop_network_tag]))
  node_oauth_scopes                 = var.phase4_gcp_node_oauth_scopes
  disable_legacy_metadata_endpoints = var.phase4_gcp_node_disable_legacy_metadata_endpoints
  enable_secure_boot                = var.phase4_gcp_node_enable_secure_boot
  enable_integrity_monitoring       = var.phase4_gcp_node_enable_integrity_monitoring
  workload_metadata_mode            = var.phase4_gcp_node_workload_metadata_mode

  depends_on = [module.gcp_vdi_reference_stack_site_d]
}
