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
  description = "GKE location (region for regional cluster)."
  type        = string
}

variable "network_self_link" {
  description = "VPC network self link."
  type        = string
}

variable "subnetwork_name" {
  description = "Subnetwork name used by the GKE cluster."
  type        = string
}

variable "release_channel" {
  description = "GKE release channel."
  type        = string
  default     = "REGULAR"
}

variable "deletion_protection" {
  description = "Whether to protect cluster from deletion."
  type        = bool
  default     = false
}

variable "cluster_ipv4_cidr_block" {
  description = "Optional Pod CIDR range."
  type        = string
  default     = null
}

variable "services_ipv4_cidr_block" {
  description = "Optional Services CIDR range."
  type        = string
  default     = null
}

variable "labels" {
  description = "Common labels."
  type        = map(string)
  default     = {}
}
