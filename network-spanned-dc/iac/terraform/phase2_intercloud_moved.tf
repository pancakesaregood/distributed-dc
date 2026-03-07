moved {
  from = aws_vpn_gateway.site_a
  to   = aws_vpn_gateway.site_a[0]
}

moved {
  from = aws_vpn_gateway.site_b
  to   = aws_vpn_gateway.site_b[0]
}

moved {
  from = aws_vpn_gateway_route_propagation.site_a_main
  to   = aws_vpn_gateway_route_propagation.site_a_main[0]
}

moved {
  from = aws_vpn_gateway_route_propagation.site_b_main
  to   = aws_vpn_gateway_route_propagation.site_b_main[0]
}

moved {
  from = module.intercloud_ac
  to   = module.intercloud_ac[0]
}

moved {
  from = module.intercloud_ad
  to   = module.intercloud_ad[0]
}

moved {
  from = module.intercloud_bc
  to   = module.intercloud_bc[0]
}

moved {
  from = module.intercloud_bd
  to   = module.intercloud_bd[0]
}
