output "summary" {
  description = "GKE cluster summary."
  value = {
    cluster_name       = google_container_cluster.this.name
    cluster_id         = google_container_cluster.this.id
    endpoint           = google_container_cluster.this.endpoint
    location           = google_container_cluster.this.location
    master_version     = google_container_cluster.this.master_version
    services_ipv4_cidr = google_container_cluster.this.services_ipv4_cidr
  }
}
