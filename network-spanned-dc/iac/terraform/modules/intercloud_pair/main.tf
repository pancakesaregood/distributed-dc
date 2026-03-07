locals {
  base_name = "${var.name_prefix}-${var.environment}-${var.pair_name}"

  tunnel_specs = {
    cgw0_t1 = {
      gcp_interface      = 0
      external_interface = 0
      inside_cidr        = var.inside_cidrs["cgw0_t1"]
      preshared_key      = var.preshared_keys["cgw0_t1"]
    }
    cgw0_t2 = {
      gcp_interface      = 0
      external_interface = 1
      inside_cidr        = var.inside_cidrs["cgw0_t2"]
      preshared_key      = var.preshared_keys["cgw0_t2"]
    }
  }
}

resource "google_compute_ha_vpn_gateway" "this" {
  name        = "${local.base_name}-ha-vpn-gw"
  network     = var.gcp_network_self_link
  region      = var.gcp_region
  description = "Inter-cloud HA VPN gateway for ${var.pair_label}"
}

resource "google_compute_router" "this" {
  name        = "${local.base_name}-cr"
  network     = var.gcp_network_self_link
  region      = var.gcp_region
  description = "Inter-cloud Cloud Router for ${var.pair_label}"

  bgp {
    asn            = var.gcp_router_asn
    advertise_mode = "CUSTOM"

    advertised_ip_ranges {
      range       = var.gcp_advertised_ipv4_cidr
      description = "${var.gcp_site_name} IPv4 summary"
    }
  }
}

resource "aws_customer_gateway" "cgw0" {
  type       = "ipsec.1"
  bgp_asn    = var.gcp_router_asn
  ip_address = google_compute_ha_vpn_gateway.this.vpn_interfaces[0].ip_address

  tags = merge(
    var.aws_tags,
    {
      Name      = "${local.base_name}-cgw-0"
      site      = var.aws_site_name
      pair      = var.pair_name
      component = "intercloud-vpn"
    }
  )
}

resource "aws_vpn_connection" "cgw0" {
  type                = "ipsec.1"
  vpn_gateway_id      = var.aws_vpn_gateway_id
  customer_gateway_id = aws_customer_gateway.cgw0.id
  static_routes_only  = false

  local_ipv4_network_cidr  = var.aws_local_ipv4_cidr
  remote_ipv4_network_cidr = var.gcp_remote_ipv4_cidr
  tunnel_inside_ip_version = "ipv4"

  tunnel1_ike_versions  = ["ikev2"]
  tunnel2_ike_versions  = ["ikev2"]
  tunnel1_inside_cidr   = var.inside_cidrs["cgw0_t1"]
  tunnel2_inside_cidr   = var.inside_cidrs["cgw0_t2"]
  tunnel1_preshared_key = var.preshared_keys["cgw0_t1"]
  tunnel2_preshared_key = var.preshared_keys["cgw0_t2"]

  tags = merge(
    var.aws_tags,
    {
      Name      = "${local.base_name}-vpn-cgw-0"
      site      = var.aws_site_name
      pair      = var.pair_name
      component = "intercloud-vpn"
    }
  )
}

resource "google_compute_external_vpn_gateway" "aws" {
  name            = "${local.base_name}-aws-ext-gw"
  redundancy_type = "TWO_IPS_REDUNDANCY"
  labels          = var.gcp_labels

  interface {
    id         = 0
    ip_address = aws_vpn_connection.cgw0.tunnel1_address
  }

  interface {
    id         = 1
    ip_address = aws_vpn_connection.cgw0.tunnel2_address
  }
}

resource "google_compute_vpn_tunnel" "this" {
  for_each = local.tunnel_specs

  name                            = "${local.base_name}-${replace(each.key, "_", "-")}"
  region                          = var.gcp_region
  vpn_gateway                     = google_compute_ha_vpn_gateway.this.self_link
  vpn_gateway_interface           = each.value.gcp_interface
  peer_external_gateway           = google_compute_external_vpn_gateway.aws.self_link
  peer_external_gateway_interface = each.value.external_interface
  shared_secret                   = each.value.preshared_key
  ike_version                     = 2
  router                          = google_compute_router.this.self_link
  labels                          = var.gcp_labels

  description = "Inter-cloud VPN tunnel ${each.key} for ${var.pair_label}"
}

resource "google_compute_router_interface" "this" {
  for_each = local.tunnel_specs

  name       = "${local.base_name}-${replace(each.key, "_", "-")}-if"
  router     = google_compute_router.this.name
  region     = var.gcp_region
  ip_range   = each.key == "cgw0_t1" ? "${aws_vpn_connection.cgw0.tunnel1_cgw_inside_address}/30" : "${aws_vpn_connection.cgw0.tunnel2_cgw_inside_address}/30"
  vpn_tunnel = google_compute_vpn_tunnel.this[each.key].name
}

resource "google_compute_router_peer" "this" {
  for_each = local.tunnel_specs

  name                      = "${local.base_name}-${replace(each.key, "_", "-")}-bgp"
  router                    = google_compute_router.this.name
  region                    = var.gcp_region
  interface                 = google_compute_router_interface.this[each.key].name
  peer_asn                  = var.aws_vpn_gateway_asn
  advertised_route_priority = var.bgp_route_priority
  ip_address                = each.key == "cgw0_t1" ? aws_vpn_connection.cgw0.tunnel1_cgw_inside_address : aws_vpn_connection.cgw0.tunnel2_cgw_inside_address
  peer_ip_address           = each.key == "cgw0_t1" ? aws_vpn_connection.cgw0.tunnel1_vgw_inside_address : aws_vpn_connection.cgw0.tunnel2_vgw_inside_address
}
