locals {
  base_name = "${var.name_prefix}-${var.environment}-${var.site_name}"

  subnets = {
    ingress = cidrsubnet(var.ipv4_cidr, 4, 0)
    app     = cidrsubnet(var.ipv4_cidr, 4, 1)
    data    = cidrsubnet(var.ipv4_cidr, 4, 2)
  }
}

resource "google_compute_network" "this" {
  name                            = "${local.base_name}-vpc"
  auto_create_subnetworks         = false
  routing_mode                    = "GLOBAL"
  delete_default_routes_on_create = true

  # Enables internal ULA-style IPv6 support when provider/API supports it.
  enable_ula_internal_ipv6 = var.enable_ipv6
}

resource "google_compute_subnetwork" "tier" {
  for_each = local.subnets

  name          = "${local.base_name}-${each.key}"
  ip_cidr_range = each.value
  region        = var.region
  network       = google_compute_network.this.id

  stack_type       = var.enable_ipv6 ? "IPV4_IPV6" : "IPV4_ONLY"
  ipv6_access_type = var.enable_ipv6 ? "INTERNAL" : null

  description = "tier=${each.key},site=${var.site_name},ipv6_ula=${var.ipv6_ula}"

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}
