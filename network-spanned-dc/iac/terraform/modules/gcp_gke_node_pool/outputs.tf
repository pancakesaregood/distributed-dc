output "summary" {
  description = "GKE node pool summary."
  value = {
    cluster_name    = google_container_node_pool.this.cluster
    node_pool       = google_container_node_pool.this.name
    workload        = var.node_pool_suffix
    location        = google_container_node_pool.this.location
    version         = google_container_node_pool.this.version
    instance_groups = google_container_node_pool.this.instance_group_urls
  }
}
