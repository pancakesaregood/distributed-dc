locals {
  base_name = "${var.name_prefix}-${var.environment}-${var.site_name}"
}

resource "google_container_node_pool" "this" {
  name       = "${local.base_name}-pool-general"
  location   = var.location
  cluster    = var.cluster_name
  node_count = var.enable_autoscaling ? null : var.initial_node_count

  dynamic "autoscaling" {
    for_each = var.enable_autoscaling ? [1] : []
    content {
      min_node_count = var.min_node_count
      max_node_count = var.max_node_count
    }
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    machine_type    = var.machine_type
    disk_size_gb    = var.disk_size_gb
    disk_type       = var.disk_type
    image_type      = var.image_type
    spot            = var.spot
    service_account = var.service_account
    labels          = var.node_labels
    tags            = var.node_tags
  }

  initial_node_count = var.initial_node_count
}
