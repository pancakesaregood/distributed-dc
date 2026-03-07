output "network_self_link" {
  description = "Network self link."
  value       = google_compute_network.this.self_link
}

output "ingress_subnet_names" {
  description = "Ingress subnet name."
  value       = [google_compute_subnetwork.tier["ingress"].name]
}

output "app_subnet_names" {
  description = "App subnet name."
  value       = [google_compute_subnetwork.tier["app"].name]
}

output "data_subnet_names" {
  description = "Data subnet name."
  value       = [google_compute_subnetwork.tier["data"].name]
}
