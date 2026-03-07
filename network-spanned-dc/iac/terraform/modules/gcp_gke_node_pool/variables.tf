variable "site_name" {
  description = "Site short name."
  type        = string
}

variable "name_prefix" {
  description = "Global name prefix."
  type        = string
}

variable "environment" {
  description = "Environment identifier."
  type        = string
}

variable "node_pool_suffix" {
  description = "Suffix used in the GKE node pool name."
  type        = string
  default     = "general"
}

variable "location" {
  description = "Cluster location (region or zone)."
  type        = string
}

variable "cluster_name" {
  description = "Target GKE cluster name."
  type        = string
}

variable "machine_type" {
  description = "Node machine type."
  type        = string
  default     = "e2-standard-4"
}

variable "disk_size_gb" {
  description = "Node disk size in GiB."
  type        = number
  default     = 100
}

variable "disk_type" {
  description = "Node disk type."
  type        = string
  default     = "pd-standard"
}

variable "image_type" {
  description = "Node image type."
  type        = string
  default     = "COS_CONTAINERD"
}

variable "spot" {
  description = "Use spot nodes."
  type        = bool
  default     = false
}

variable "enable_autoscaling" {
  description = "Enable cluster autoscaling for the node pool."
  type        = bool
  default     = true
}

variable "min_node_count" {
  description = "Minimum node count when autoscaling is enabled."
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Maximum node count when autoscaling is enabled."
  type        = number
  default     = 3
}

variable "initial_node_count" {
  description = "Initial node count when creating the node pool."
  type        = number
  default     = 1
}

variable "service_account" {
  description = "Optional service account for nodes."
  type        = string
  default     = null
}

variable "node_labels" {
  description = "Node labels."
  type        = map(string)
  default     = {}
}

variable "node_tags" {
  description = "Network tags for nodes."
  type        = list(string)
  default     = []
}

variable "node_oauth_scopes" {
  description = "OAuth scopes assigned to node service account tokens."
  type        = list(string)
  default = [
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/monitoring",
    "https://www.googleapis.com/auth/devstorage.read_only"
  ]
}

variable "disable_legacy_metadata_endpoints" {
  description = "Disable legacy metadata endpoints on GKE nodes."
  type        = bool
  default     = true
}

variable "enable_secure_boot" {
  description = "Enable Secure Boot on shielded GKE nodes."
  type        = bool
  default     = true
}

variable "enable_integrity_monitoring" {
  description = "Enable integrity monitoring on shielded GKE nodes."
  type        = bool
  default     = true
}

variable "workload_metadata_mode" {
  description = "Workload metadata mode for node pools."
  type        = string
  default     = "GCE_METADATA"

  validation {
    condition = contains(
      ["GCE_METADATA", "GKE_METADATA"],
      var.workload_metadata_mode
    )
    error_message = "workload_metadata_mode must be GCE_METADATA or GKE_METADATA."
  }
}
