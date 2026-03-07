module "aws_eks_site_a" {
  count  = var.phase3_enable_platform ? 1 : 0
  source = "./modules/aws_eks_site"

  providers = {
    aws = aws.site_a
  }

  site_name                 = "site-a"
  name_prefix               = var.name_prefix
  environment               = var.environment
  subnet_ids                = module.aws_site_a.app_subnet_ids
  cluster_version           = var.phase3_aws_eks_cluster_version
  enabled_cluster_log_types = var.phase3_aws_enabled_cluster_log_types
  endpoint_public_access    = var.phase3_aws_endpoint_public_access
  endpoint_private_access   = var.phase3_aws_endpoint_private_access
  public_access_cidrs       = var.phase3_aws_public_access_cidrs
  tags                      = local.common_tags
}

module "aws_eks_site_b" {
  count  = var.phase3_enable_platform ? 1 : 0
  source = "./modules/aws_eks_site"

  providers = {
    aws = aws.site_b
  }

  site_name                 = "site-b"
  name_prefix               = var.name_prefix
  environment               = var.environment
  subnet_ids                = module.aws_site_b.app_subnet_ids
  cluster_version           = var.phase3_aws_eks_cluster_version
  enabled_cluster_log_types = var.phase3_aws_enabled_cluster_log_types
  endpoint_public_access    = var.phase3_aws_endpoint_public_access
  endpoint_private_access   = var.phase3_aws_endpoint_private_access
  public_access_cidrs       = var.phase3_aws_public_access_cidrs
  tags                      = local.common_tags
}

module "gcp_gke_site_c" {
  count  = var.phase3_enable_platform ? 1 : 0
  source = "./modules/gcp_gke_site"

  providers = {
    google = google.site_c
  }

  site_name                  = "site-c"
  name_prefix                = var.name_prefix
  environment                = var.environment
  location                   = var.gcp_site_c_region
  network_self_link          = module.gcp_site_c.network_self_link
  subnetwork_name            = module.gcp_site_c.app_subnet_names[0]
  release_channel            = var.phase3_gcp_release_channel
  deletion_protection        = var.phase3_gcp_deletion_protection
  cluster_ipv4_cidr_block    = var.phase3_site_c_cluster_ipv4_cidr_block
  services_ipv4_cidr_block   = var.phase3_site_c_services_ipv4_cidr_block
  master_authorized_networks = var.phase3_gcp_master_authorized_networks
  labels                     = local.common_tags
}

module "gcp_gke_site_d" {
  count  = var.phase3_enable_platform ? 1 : 0
  source = "./modules/gcp_gke_site"

  providers = {
    google = google.site_d
  }

  site_name                  = "site-d"
  name_prefix                = var.name_prefix
  environment                = var.environment
  location                   = var.gcp_site_d_region
  network_self_link          = module.gcp_site_d.network_self_link
  subnetwork_name            = module.gcp_site_d.app_subnet_names[0]
  release_channel            = var.phase3_gcp_release_channel
  deletion_protection        = var.phase3_gcp_deletion_protection
  cluster_ipv4_cidr_block    = var.phase3_site_d_cluster_ipv4_cidr_block
  services_ipv4_cidr_block   = var.phase3_site_d_services_ipv4_cidr_block
  master_authorized_networks = var.phase3_gcp_master_authorized_networks
  labels                     = local.common_tags
}
