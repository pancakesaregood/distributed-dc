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
