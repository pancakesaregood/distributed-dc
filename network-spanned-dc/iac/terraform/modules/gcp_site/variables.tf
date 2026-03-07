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

variable "region" {
  description = "GCP region for the site."
  type        = string
}

variable "ipv4_cidr" {
  description = "IPv4 CIDR block for the site network."
  type        = string
}

variable "ipv6_ula" {
  description = "Logical ULA prefix metadata."
  type        = string
}

variable "enable_ipv6" {
  description = "Enable dual-stack subnet mode when supported."
  type        = bool
  default     = true
}

variable "labels" {
  description = "Common labels."
  type        = map(string)
  default     = {}
}
