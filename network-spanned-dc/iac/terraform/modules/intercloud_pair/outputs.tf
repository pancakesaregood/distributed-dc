output "summary" {
  description = "Provisioned object summary for the inter-cloud pair."
  value = {
    pair               = var.pair_label
    bgp_route_priority = var.bgp_route_priority

    aws = {
      vpn_gateway_id = var.aws_vpn_gateway_id
      customer_gateway_ids = {
        cgw0 = aws_customer_gateway.cgw0.id
      }
      vpn_connection_ids = {
        cgw0 = aws_vpn_connection.cgw0.id
      }
      tunnel_outside_ips = {
        cgw0_t1 = aws_vpn_connection.cgw0.tunnel1_address
        cgw0_t2 = aws_vpn_connection.cgw0.tunnel2_address
      }
    }

    gcp = {
      ha_vpn_gateway_id = google_compute_ha_vpn_gateway.this.id
      router_name       = google_compute_router.this.name
      tunnel_names = {
        for key, tunnel in google_compute_vpn_tunnel.this :
        key => tunnel.name
      }
      router_peer_names = {
        for key, peer in google_compute_router_peer.this :
        key => peer.name
      }
    }
  }
}
