locals {
  phase4_capacity_enabled = var.phase4_enable_service_onboarding && var.phase3_enable_platform
}

module "aws_eks_nodegroup_site_a" {
  count  = local.phase4_capacity_enabled ? 1 : 0
  source = "./modules/aws_eks_nodegroup"

  providers = {
    aws = aws.site_a
  }

  site_name       = "site-a"
  name_prefix     = var.name_prefix
  environment     = var.environment
  cluster_name    = module.aws_eks_site_a[0].summary.cluster_name
  subnet_ids      = module.aws_site_a.app_subnet_ids
  desired_size    = var.phase4_aws_node_desired_size
  min_size        = var.phase4_aws_node_min_size
  max_size        = var.phase4_aws_node_max_size
  instance_types  = var.phase4_aws_node_instance_types
  capacity_type   = var.phase4_aws_node_capacity_type
  disk_size       = var.phase4_aws_node_disk_size
  ami_type        = var.phase4_aws_node_ami_type
  labels          = merge(var.phase4_aws_node_labels, { site = "site-a" })
  taints          = var.phase4_aws_node_taints
  max_unavailable = var.phase4_aws_node_max_unavailable
  tags            = local.common_tags
}

module "aws_eks_nodegroup_site_b" {
  count  = local.phase4_capacity_enabled ? 1 : 0
  source = "./modules/aws_eks_nodegroup"

  providers = {
    aws = aws.site_b
  }

  site_name       = "site-b"
  name_prefix     = var.name_prefix
  environment     = var.environment
  cluster_name    = module.aws_eks_site_b[0].summary.cluster_name
  subnet_ids      = module.aws_site_b.app_subnet_ids
  desired_size    = var.phase4_aws_node_desired_size
  min_size        = var.phase4_aws_node_min_size
  max_size        = var.phase4_aws_node_max_size
  instance_types  = var.phase4_aws_node_instance_types
  capacity_type   = var.phase4_aws_node_capacity_type
  disk_size       = var.phase4_aws_node_disk_size
  ami_type        = var.phase4_aws_node_ami_type
  labels          = merge(var.phase4_aws_node_labels, { site = "site-b" })
  taints          = var.phase4_aws_node_taints
  max_unavailable = var.phase4_aws_node_max_unavailable
  tags            = local.common_tags
}

module "gcp_gke_node_pool_site_c" {
  count  = local.phase4_capacity_enabled ? 1 : 0
  source = "./modules/gcp_gke_node_pool"

  providers = {
    google = google.site_c
  }

  site_name          = "site-c"
  name_prefix        = var.name_prefix
  environment        = var.environment
  location           = var.gcp_site_c_region
  cluster_name       = module.gcp_gke_site_c[0].summary.cluster_name
  machine_type       = var.phase4_gcp_node_machine_type
  disk_size_gb       = var.phase4_gcp_node_disk_size_gb
  disk_type          = var.phase4_gcp_node_disk_type
  image_type         = var.phase4_gcp_node_image_type
  spot               = var.phase4_gcp_node_spot
  enable_autoscaling = var.phase4_gcp_node_enable_autoscaling
  min_node_count     = var.phase4_gcp_node_min_count
  max_node_count     = var.phase4_gcp_node_max_count
  initial_node_count = var.phase4_gcp_node_initial_count
  service_account    = var.phase4_gcp_node_service_account
  node_labels        = merge(var.phase4_gcp_node_labels, { site = "site-c" })
  node_tags          = var.phase4_gcp_node_tags
}

module "gcp_gke_node_pool_site_d" {
  count  = local.phase4_capacity_enabled ? 1 : 0
  source = "./modules/gcp_gke_node_pool"

  providers = {
    google = google.site_d
  }

  site_name          = "site-d"
  name_prefix        = var.name_prefix
  environment        = var.environment
  location           = var.gcp_site_d_region
  cluster_name       = module.gcp_gke_site_d[0].summary.cluster_name
  machine_type       = var.phase4_gcp_node_machine_type
  disk_size_gb       = var.phase4_gcp_node_disk_size_gb
  disk_type          = var.phase4_gcp_node_disk_type
  image_type         = var.phase4_gcp_node_image_type
  spot               = var.phase4_gcp_node_spot
  enable_autoscaling = var.phase4_gcp_node_enable_autoscaling
  min_node_count     = var.phase4_gcp_node_min_count
  max_node_count     = var.phase4_gcp_node_max_count
  initial_node_count = var.phase4_gcp_node_initial_count
  service_account    = var.phase4_gcp_node_service_account
  node_labels        = merge(var.phase4_gcp_node_labels, { site = "site-d" })
  node_tags          = var.phase4_gcp_node_tags
}
