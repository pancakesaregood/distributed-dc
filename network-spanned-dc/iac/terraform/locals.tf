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

  phase2_pair_tunnel_inside_cidrs = {
    ac = {
      cgw0_t1 = "169.254.21.0/30"
      cgw0_t2 = "169.254.21.4/30"
    }
    ad = {
      cgw0_t1 = "169.254.22.0/30"
      cgw0_t2 = "169.254.22.4/30"
    }
    bc = {
      cgw0_t1 = "169.254.23.0/30"
      cgw0_t2 = "169.254.23.4/30"
    }
    bd = {
      cgw0_t1 = "169.254.24.0/30"
      cgw0_t2 = "169.254.24.4/30"
    }
  }

  phase2_pair_tunnel_preshared_keys = {
    for pair, tunnels in local.phase2_pair_tunnel_inside_cidrs :
    pair => {
      for tunnel_key, _ in tunnels :
      tunnel_key => substr(sha256("${var.phase2_secret_seed}-${pair}-${tunnel_key}"), 0, 32)
    }
  }
}
