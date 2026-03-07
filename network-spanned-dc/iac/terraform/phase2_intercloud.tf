resource "aws_vpn_gateway" "site_a" {
  provider        = aws.site_a
  vpc_id          = module.aws_site_a.vpc_id
  amazon_side_asn = var.aws_site_a_vpn_asn

  tags = merge(
    local.common_tags,
    {
      Name      = "${var.name_prefix}-${var.environment}-site-a-vgw"
      site      = "site-a"
      component = "intercloud-vpn"
    }
  )
}

resource "aws_vpn_gateway" "site_b" {
  provider        = aws.site_b
  vpc_id          = module.aws_site_b.vpc_id
  amazon_side_asn = var.aws_site_b_vpn_asn

  tags = merge(
    local.common_tags,
    {
      Name      = "${var.name_prefix}-${var.environment}-site-b-vgw"
      site      = "site-b"
      component = "intercloud-vpn"
    }
  )
}

data "aws_route_table" "site_a_main" {
  provider = aws.site_a
  vpc_id   = module.aws_site_a.vpc_id

  filter {
    name   = "association.main"
    values = ["true"]
  }
}

data "aws_route_table" "site_b_main" {
  provider = aws.site_b
  vpc_id   = module.aws_site_b.vpc_id

  filter {
    name   = "association.main"
    values = ["true"]
  }
}

resource "aws_vpn_gateway_route_propagation" "site_a_main" {
  provider       = aws.site_a
  route_table_id = data.aws_route_table.site_a_main.id
  vpn_gateway_id = aws_vpn_gateway.site_a.id
}

resource "aws_vpn_gateway_route_propagation" "site_b_main" {
  provider       = aws.site_b
  route_table_id = data.aws_route_table.site_b_main.id
  vpn_gateway_id = aws_vpn_gateway.site_b.id
}

module "intercloud_ac" {
  source = "./modules/intercloud_pair"

  providers = {
    aws    = aws.site_a
    google = google.site_c
  }

  pair_name                = "ac"
  pair_label               = "site-a-site-c"
  name_prefix              = var.name_prefix
  environment              = var.environment
  aws_site_name            = "site-a"
  gcp_site_name            = "site-c"
  aws_vpn_gateway_id       = aws_vpn_gateway.site_a.id
  aws_vpn_gateway_asn      = var.aws_site_a_vpn_asn
  aws_local_ipv4_cidr      = var.site_a_ipv4_cidr
  gcp_remote_ipv4_cidr     = var.site_c_ipv4_cidr
  gcp_network_self_link    = module.gcp_site_c.network_self_link
  gcp_region               = var.gcp_site_c_region
  gcp_router_asn           = var.phase2_gcp_router_asns["ac"]
  gcp_advertised_ipv4_cidr = var.site_c_ipv4_cidr
  bgp_route_priority       = var.phase2_primary_bgp_priority
  inside_cidrs             = local.phase2_pair_tunnel_inside_cidrs["ac"]
  preshared_keys           = local.phase2_pair_tunnel_preshared_keys["ac"]
  aws_tags                 = local.common_tags
  gcp_labels               = local.common_tags
}

module "intercloud_ad" {
  source = "./modules/intercloud_pair"

  providers = {
    aws    = aws.site_a
    google = google.site_d
  }

  pair_name                = "ad"
  pair_label               = "site-a-site-d"
  name_prefix              = var.name_prefix
  environment              = var.environment
  aws_site_name            = "site-a"
  gcp_site_name            = "site-d"
  aws_vpn_gateway_id       = aws_vpn_gateway.site_a.id
  aws_vpn_gateway_asn      = var.aws_site_a_vpn_asn
  aws_local_ipv4_cidr      = var.site_a_ipv4_cidr
  gcp_remote_ipv4_cidr     = var.site_d_ipv4_cidr
  gcp_network_self_link    = module.gcp_site_d.network_self_link
  gcp_region               = var.gcp_site_d_region
  gcp_router_asn           = var.phase2_gcp_router_asns["ad"]
  gcp_advertised_ipv4_cidr = var.site_d_ipv4_cidr
  bgp_route_priority       = var.phase2_failover_bgp_priority
  inside_cidrs             = local.phase2_pair_tunnel_inside_cidrs["ad"]
  preshared_keys           = local.phase2_pair_tunnel_preshared_keys["ad"]
  aws_tags                 = local.common_tags
  gcp_labels               = local.common_tags
}

module "intercloud_bc" {
  source = "./modules/intercloud_pair"

  providers = {
    aws    = aws.site_b
    google = google.site_c
  }

  pair_name                = "bc"
  pair_label               = "site-b-site-c"
  name_prefix              = var.name_prefix
  environment              = var.environment
  aws_site_name            = "site-b"
  gcp_site_name            = "site-c"
  aws_vpn_gateway_id       = aws_vpn_gateway.site_b.id
  aws_vpn_gateway_asn      = var.aws_site_b_vpn_asn
  aws_local_ipv4_cidr      = var.site_b_ipv4_cidr
  gcp_remote_ipv4_cidr     = var.site_c_ipv4_cidr
  gcp_network_self_link    = module.gcp_site_c.network_self_link
  gcp_region               = var.gcp_site_c_region
  gcp_router_asn           = var.phase2_gcp_router_asns["bc"]
  gcp_advertised_ipv4_cidr = var.site_c_ipv4_cidr
  bgp_route_priority       = var.phase2_failover_bgp_priority
  inside_cidrs             = local.phase2_pair_tunnel_inside_cidrs["bc"]
  preshared_keys           = local.phase2_pair_tunnel_preshared_keys["bc"]
  aws_tags                 = local.common_tags
  gcp_labels               = local.common_tags
}

module "intercloud_bd" {
  source = "./modules/intercloud_pair"

  providers = {
    aws    = aws.site_b
    google = google.site_d
  }

  pair_name                = "bd"
  pair_label               = "site-b-site-d"
  name_prefix              = var.name_prefix
  environment              = var.environment
  aws_site_name            = "site-b"
  gcp_site_name            = "site-d"
  aws_vpn_gateway_id       = aws_vpn_gateway.site_b.id
  aws_vpn_gateway_asn      = var.aws_site_b_vpn_asn
  aws_local_ipv4_cidr      = var.site_b_ipv4_cidr
  gcp_remote_ipv4_cidr     = var.site_d_ipv4_cidr
  gcp_network_self_link    = module.gcp_site_d.network_self_link
  gcp_region               = var.gcp_site_d_region
  gcp_router_asn           = var.phase2_gcp_router_asns["bd"]
  gcp_advertised_ipv4_cidr = var.site_d_ipv4_cidr
  bgp_route_priority       = var.phase2_primary_bgp_priority
  inside_cidrs             = local.phase2_pair_tunnel_inside_cidrs["bd"]
  preshared_keys           = local.phase2_pair_tunnel_preshared_keys["bd"]
  aws_tags                 = local.common_tags
  gcp_labels               = local.common_tags
}
