locals {
  base_name = substr(lower("${var.name_prefix}-${var.environment}-${var.site_name}"), 0, 40)

  broker_tag  = substr("${local.base_name}-vdi-broker", 0, 63)
  desktop_tag = substr("${local.base_name}-vdi-desktop", 0, 63)

  service_account_id = trimsuffix(
    substr(lower("${var.name_prefix}-${var.site_name}-vdi-broker-sa"), 0, 30),
    "-"
  )
}

resource "google_service_account" "broker" {
  account_id   = local.service_account_id
  project      = var.project_id
  display_name = "${upper(var.site_name)} VDI Broker Service Account"
}

resource "google_project_iam_member" "broker_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.broker.email}"
}

resource "google_project_iam_member" "broker_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.broker.email}"
}

resource "google_project_iam_member" "broker_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.broker.email}"
}

resource "google_compute_firewall" "broker_https_ingress" {
  name    = substr("${local.base_name}-vdi-broker-https", 0, 63)
  project = var.project_id
  network = var.network_self_link

  direction     = "INGRESS"
  priority      = 1000
  source_ranges = var.broker_ingress_ipv4_cidrs
  target_tags   = [local.broker_tag]

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }
}

resource "google_compute_firewall" "broker_to_desktop" {
  name    = substr("${local.base_name}-vdi-broker-desktop", 0, 63)
  project = var.project_id
  network = var.network_self_link

  direction   = "INGRESS"
  priority    = 1000
  source_tags = [local.broker_tag]
  target_tags = [local.desktop_tag]

  allow {
    protocol = "tcp"
    ports    = ["3389", "5900-5999"]
  }
}

resource "google_compute_firewall" "desktop_controlled_egress" {
  name    = substr("${local.base_name}-vdi-desktop-egress-allow", 0, 63)
  project = var.project_id
  network = var.network_self_link

  direction          = "EGRESS"
  priority           = 1000
  target_tags        = [local.desktop_tag]
  destination_ranges = var.desktop_controlled_egress_ipv4_cidrs

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
}

resource "google_compute_firewall" "desktop_default_egress_deny" {
  name    = substr("${local.base_name}-vdi-desktop-egress-deny", 0, 63)
  project = var.project_id
  network = var.network_self_link

  direction          = "EGRESS"
  priority           = 65534
  target_tags        = [local.desktop_tag]
  destination_ranges = ["0.0.0.0/0"]

  deny {
    protocol = "all"
  }
}
