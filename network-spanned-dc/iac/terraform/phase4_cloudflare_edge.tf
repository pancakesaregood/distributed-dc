locals {
  phase4_cloudflare_edge_enabled      = local.phase4_published_app_path_enabled && var.phase4_enable_cloudflare_edge
  phase4_cloudflare_zone_id_effective = var.phase4_cloudflare_zone_id != null ? var.phase4_cloudflare_zone_id : try(data.cloudflare_zone.phase4[0].zone_id, null)
  phase4_cloudflare_additional_records = {
    for record_name, target_site in var.phase4_cloudflare_additional_records :
    trimspace(record_name) => lower(trimspace(target_site))
    if(
      local.phase4_cloudflare_edge_enabled &&
      trimspace(record_name) != "" &&
      !(
        var.phase4_cloudflare_site_a_record_name != null &&
        lower(trimspace(record_name)) == lower(trimspace(var.phase4_cloudflare_site_a_record_name))
      ) &&
      !(
        var.phase4_cloudflare_site_b_record_name != null &&
        lower(trimspace(record_name)) == lower(trimspace(var.phase4_cloudflare_site_b_record_name))
      )
    )
  }
}

data "cloudflare_zone" "phase4" {
  count = (
    local.phase4_cloudflare_edge_enabled &&
    var.phase4_cloudflare_zone_id == null
  ) ? 1 : 0

  name = var.phase4_cloudflare_zone_name
}

resource "cloudflare_record" "phase4_published_app_site_a" {
  count = (
    local.phase4_cloudflare_edge_enabled &&
    var.phase4_cloudflare_site_a_record_name != null
  ) ? 1 : 0

  zone_id = local.phase4_cloudflare_zone_id_effective
  name    = var.phase4_cloudflare_site_a_record_name
  type    = "CNAME"
  content = module.aws_published_app_path_site_a[0].summary.load_balancer_dns
  proxied = var.phase4_cloudflare_record_proxied
  ttl     = var.phase4_cloudflare_record_ttl

  # Ensures repeated applies can safely update existing DNS records in-zone.
  allow_overwrite = true
}

resource "cloudflare_record" "phase4_published_app_site_b" {
  count = (
    local.phase4_cloudflare_edge_enabled &&
    var.phase4_cloudflare_site_b_record_name != null
  ) ? 1 : 0

  zone_id = local.phase4_cloudflare_zone_id_effective
  name    = var.phase4_cloudflare_site_b_record_name
  type    = "CNAME"
  content = module.aws_published_app_path_site_b[0].summary.load_balancer_dns
  proxied = var.phase4_cloudflare_record_proxied
  ttl     = var.phase4_cloudflare_record_ttl

  allow_overwrite = true
}

resource "cloudflare_record" "phase4_published_app_additional" {
  for_each = local.phase4_cloudflare_additional_records

  zone_id = local.phase4_cloudflare_zone_id_effective
  name    = each.key
  type    = "CNAME"
  content = each.value == "site_a" ? module.aws_published_app_path_site_a[0].summary.load_balancer_dns : module.aws_published_app_path_site_b[0].summary.load_balancer_dns
  proxied = var.phase4_cloudflare_record_proxied
  ttl     = var.phase4_cloudflare_record_ttl

  allow_overwrite = true
}
