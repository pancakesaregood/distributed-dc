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
  description = "AWS region for the site."
  type        = string
}

variable "ipv4_cidr" {
  description = "IPv4 CIDR for site VPC."
  type        = string
}

variable "ipv6_ula" {
  description = "Logical ULA prefix metadata."
  type        = string
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}

variable "enable_ingress_internet_edge" {
  description = "Create IGW and public routing for ingress subnets."
  type        = bool
  default     = false
}
