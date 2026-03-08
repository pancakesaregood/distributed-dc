module "aws_site_a" {
  source = "./modules/aws_site"

  providers = {
    aws = aws.site_a
  }

  site_name   = "site-a"
  name_prefix = var.name_prefix
  environment = var.environment
  region      = var.aws_site_a_region
  ipv4_cidr   = var.site_a_ipv4_cidr
  ipv6_ula    = var.site_a_ipv6_ula
  tags        = local.common_tags

  enable_ingress_internet_edge = var.phase4_aws_enable_ingress_internet_edge
}

module "aws_site_b" {
  source = "./modules/aws_site"

  providers = {
    aws = aws.site_b
  }

  site_name   = "site-b"
  name_prefix = var.name_prefix
  environment = var.environment
  region      = var.aws_site_b_region
  ipv4_cidr   = var.site_b_ipv4_cidr
  ipv6_ula    = var.site_b_ipv6_ula
  tags        = local.common_tags

  enable_ingress_internet_edge = var.phase4_aws_enable_ingress_internet_edge
}

module "gcp_site_c" {
  source = "./modules/gcp_site"

  providers = {
    google = google.site_c
  }

  site_name   = "site-c"
  name_prefix = var.name_prefix
  environment = var.environment
  region      = var.gcp_site_c_region
  ipv4_cidr   = var.site_c_ipv4_cidr
  ipv6_ula    = var.site_c_ipv6_ula
  enable_ipv6 = var.gcp_enable_ipv6
  labels      = local.common_tags
}

module "gcp_site_d" {
  source = "./modules/gcp_site"

  providers = {
    google = google.site_d
  }

  site_name   = "site-d"
  name_prefix = var.name_prefix
  environment = var.environment
  region      = var.gcp_site_d_region
  ipv4_cidr   = var.site_d_ipv4_cidr
  ipv6_ula    = var.site_d_ipv6_ula
  enable_ipv6 = var.gcp_enable_ipv6
  labels      = local.common_tags
}
