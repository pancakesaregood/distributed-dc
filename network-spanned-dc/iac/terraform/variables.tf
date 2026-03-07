variable "name_prefix" {
  description = "Global name prefix for resources."
  type        = string
  default     = "ddc"
}

variable "environment" {
  description = "Environment tag/name (for example: dev, stage, prod, proposal)."
  type        = string
  default     = "proposal"
}

variable "owner" {
  description = "Owner/team tag value."
  type        = string
  default     = "platform"
}

variable "aws_profile" {
  description = "AWS shared credentials profile name. Set to null to use env vars/instance role."
  type        = string
  default     = null
}

variable "aws_site_a_region" {
  description = "AWS region for Site A."
  type        = string
  default     = "us-east-1"
}

variable "aws_site_b_region" {
  description = "AWS region for Site B."
  type        = string
  default     = "us-west-2"
}

variable "gcp_project_id" {
  description = "GCP project ID for Site C and Site D resources."
  type        = string
}

variable "gcp_credentials_json" {
  description = "Optional GCP credentials JSON string. Set null to use ADC."
  type        = string
  default     = null
  sensitive   = true
}

variable "gcp_site_c_region" {
  description = "GCP region for Site C."
  type        = string
  default     = "us-east4"
}

variable "gcp_site_d_region" {
  description = "GCP region for Site D."
  type        = string
  default     = "us-west1"
}

variable "site_a_ipv4_cidr" {
  description = "IPv4 CIDR for Site A VPC."
  type        = string
  default     = "10.10.0.0/20"
}

variable "site_b_ipv4_cidr" {
  description = "IPv4 CIDR for Site B VPC."
  type        = string
  default     = "10.20.0.0/20"
}

variable "site_c_ipv4_cidr" {
  description = "IPv4 CIDR for Site C VPC network."
  type        = string
  default     = "10.30.0.0/20"
}

variable "site_d_ipv4_cidr" {
  description = "IPv4 CIDR for Site D VPC network."
  type        = string
  default     = "10.40.0.0/20"
}

variable "site_a_ipv6_ula" {
  description = "Logical IPv6 ULA summary for Site A."
  type        = string
  default     = "fdca:fcaf:e000::/56"
}

variable "site_b_ipv6_ula" {
  description = "Logical IPv6 ULA summary for Site B."
  type        = string
  default     = "fdca:fcaf:e100::/56"
}

variable "site_c_ipv6_ula" {
  description = "Logical IPv6 ULA summary for Site C."
  type        = string
  default     = "fdca:fcaf:e200::/56"
}

variable "site_d_ipv6_ula" {
  description = "Logical IPv6 ULA summary for Site D."
  type        = string
  default     = "fdca:fcaf:e300::/56"
}

variable "gcp_enable_ipv6" {
  description = "Enable IPv6-capable subnet stack for GCP site networks."
  type        = bool
  default     = true
}
