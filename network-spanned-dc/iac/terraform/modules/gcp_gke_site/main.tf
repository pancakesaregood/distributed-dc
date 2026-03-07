locals {
  base_name = "${var.name_prefix}-${var.environment}-${var.site_name}"
}

resource "google_container_cluster" "this" {
  name     = "${local.base_name}-gke"
  location = var.location

  network    = var.network_self_link
  subnetwork = var.subnetwork_name

  remove_default_node_pool = true
  initial_node_count       = 1
  deletion_protection      = var.deletion_protection
  networking_mode          = "VPC_NATIVE"

  release_channel {
    channel = var.release_channel
  }

  ip_allocation_policy {
    cluster_ipv4_cidr_block  = var.cluster_ipv4_cidr_block
    services_ipv4_cidr_block = var.services_ipv4_cidr_block
  }

  resource_labels = merge(
    var.labels,
    {
      site      = var.site_name
      component = "k8s-control-plane"
    }
  )
}
