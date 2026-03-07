locals {
  common_tags = {
    project     = var.name_prefix
    environment = var.environment
    owner       = var.owner
    managed_by  = "terraform"
  }

  sites = {
    site_a = {
      cloud     = "aws"
      region    = var.aws_site_a_region
      ipv4_cidr = var.site_a_ipv4_cidr
      ipv6_ula  = var.site_a_ipv6_ula
    }
    site_b = {
      cloud     = "aws"
      region    = var.aws_site_b_region
      ipv4_cidr = var.site_b_ipv4_cidr
      ipv6_ula  = var.site_b_ipv6_ula
    }
    site_c = {
      cloud     = "gcp"
      region    = var.gcp_site_c_region
      ipv4_cidr = var.site_c_ipv4_cidr
      ipv6_ula  = var.site_c_ipv6_ula
    }
    site_d = {
      cloud     = "gcp"
      region    = var.gcp_site_d_region
      ipv4_cidr = var.site_d_ipv4_cidr
      ipv6_ula  = var.site_d_ipv6_ula
    }
  }

  intercloud_pairs = [
    {
      left_site      = "site_a"
      right_site     = "site_c"
      preference     = "primary-east"
      bgp_preference = 100
    },
    {
      left_site      = "site_b"
      right_site     = "site_d"
      preference     = "primary-west"
      bgp_preference = 100
    },
    {
      left_site      = "site_a"
      right_site     = "site_d"
      preference     = "cross-failover"
      bgp_preference = 200
    },
    {
      left_site      = "site_b"
      right_site     = "site_c"
      preference     = "cross-failover"
      bgp_preference = 200
    }
  ]
}
