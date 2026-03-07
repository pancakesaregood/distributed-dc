output "summary" {
  description = "VDI policy and identity control summary for one GCP site."
  value = {
    site                  = var.site_name
    service_account_email = google_service_account.broker.email
    broker_network_tag    = local.broker_tag
    desktop_network_tag   = local.desktop_tag
    firewall_rules = {
      broker_https_ingress      = google_compute_firewall.broker_https_ingress.name
      broker_to_desktop         = google_compute_firewall.broker_to_desktop.name
      desktop_controlled_egress = google_compute_firewall.desktop_controlled_egress.name
      desktop_default_deny      = google_compute_firewall.desktop_default_egress_deny.name
    }
  }
}
