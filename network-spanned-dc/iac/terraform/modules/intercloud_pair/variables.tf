variable "pair_name" {
  description = "Short pair key (for example: ac, bd)."
  type        = string
}

variable "pair_label" {
  description = "Human-readable pair label."
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

variable "aws_site_name" {
  description = "AWS site name for tagging."
  type        = string
}

variable "gcp_site_name" {
  description = "GCP site name for labeling and descriptions."
  type        = string
}

variable "aws_vpn_gateway_id" {
  description = "AWS virtual private gateway ID already attached to the VPC."
  type        = string
}

variable "aws_vpn_gateway_asn" {
  description = "ASN used by the AWS VPN gateway for BGP peering."
  type        = number
}

variable "aws_local_ipv4_cidr" {
  description = "Local AWS site summary CIDR."
  type        = string
}

variable "gcp_remote_ipv4_cidr" {
  description = "Remote GCP site summary CIDR used in AWS VPN connection selectors."
  type        = string
}

variable "gcp_network_self_link" {
  description = "Target GCP VPC network self link."
  type        = string
}

variable "gcp_region" {
  description = "GCP region for HA VPN and Cloud Router resources."
  type        = string
}

variable "gcp_router_asn" {
  description = "Cloud Router ASN for this pair."
  type        = number
}

variable "gcp_advertised_ipv4_cidr" {
  description = "GCP site IPv4 summary CIDR advertised to AWS."
  type        = string
}

variable "bgp_route_priority" {
  description = "Cloud Router BGP advertised route priority (lower = preferred)."
  type        = number
}

variable "inside_cidrs" {
  description = "Map of /30 inside CIDRs for pair tunnels."
  type        = map(string)

  validation {
    condition = alltrue([
      contains(keys(var.inside_cidrs), "cgw0_t1"),
      contains(keys(var.inside_cidrs), "cgw0_t2")
    ])
    error_message = "inside_cidrs must include keys cgw0_t1 and cgw0_t2."
  }
}

variable "preshared_keys" {
  description = "Map of pre-shared keys for pair tunnels."
  type        = map(string)
  sensitive   = true

  validation {
    condition = alltrue([
      contains(keys(var.preshared_keys), "cgw0_t1"),
      contains(keys(var.preshared_keys), "cgw0_t2")
    ])
    error_message = "preshared_keys must include keys cgw0_t1 and cgw0_t2."
  }

  validation {
    condition = alltrue([
      for secret in values(var.preshared_keys) :
      length(secret) >= 8 && length(secret) <= 64
    ])
    error_message = "Each pre-shared key must be between 8 and 64 characters."
  }
}

variable "aws_tags" {
  description = "Common AWS tags."
  type        = map(string)
  default     = {}
}

variable "gcp_labels" {
  description = "Common GCP labels."
  type        = map(string)
  default     = {}
}
