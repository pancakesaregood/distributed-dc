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

variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "network_self_link" {
  description = "VPC network self link hosting the VDI reference stack."
  type        = string
}

variable "manage_broker_identity" {
  description = "Whether this module should create and bind a dedicated broker service account."
  type        = bool
  default     = true
}

variable "broker_service_account_email" {
  description = "Existing broker service account email to use when manage_broker_identity=false."
  type        = string
  default     = null
}

variable "broker_ingress_ipv4_cidrs" {
  description = "IPv4 CIDRs allowed to reach broker HTTPS."
  type        = list(string)
  default     = []
}

variable "desktop_controlled_egress_ipv4_cidrs" {
  description = "IPv4 CIDRs that desktop workloads may reach for controlled egress."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
