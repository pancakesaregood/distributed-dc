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

  dynamic "master_authorized_networks_config" {
    for_each = length(var.master_authorized_networks) > 0 ? [1] : []
    content {
      dynamic "cidr_blocks" {
        for_each = var.master_authorized_networks
        content {
          cidr_block   = cidr_blocks.value.cidr_block
          display_name = cidr_blocks.value.display_name
        }
      }
    }
  }

  resource_labels = merge(
    var.labels,
    {
      site      = var.site_name
      component = "k8s-control-plane"
    }
  )
}
