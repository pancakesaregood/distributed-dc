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

variable "aws_site_a_vpn_asn" {
  description = "AWS Site A VPN gateway ASN for BGP."
  type        = number
  default     = 64512
}

variable "aws_site_b_vpn_asn" {
  description = "AWS Site B VPN gateway ASN for BGP."
  type        = number
  default     = 64513
}

variable "phase2_primary_bgp_priority" {
  description = "BGP advertised route priority for primary links (lower is preferred)."
  type        = number
  default     = 100
}

variable "phase2_failover_bgp_priority" {
  description = "BGP advertised route priority for cross/failover links."
  type        = number
  default     = 200
}

variable "phase2_gcp_router_asns" {
  description = "Cloud Router ASNs per inter-cloud pair key (ac, ad, bc, bd)."
  type        = map(number)
  default = {
    ac = 65010
    ad = 65011
    bc = 65020
    bd = 65021
  }

  validation {
    condition = alltrue([
      contains(keys(var.phase2_gcp_router_asns), "ac"),
      contains(keys(var.phase2_gcp_router_asns), "ad"),
      contains(keys(var.phase2_gcp_router_asns), "bc"),
      contains(keys(var.phase2_gcp_router_asns), "bd")
    ])
    error_message = "phase2_gcp_router_asns must contain keys ac, ad, bc, bd."
  }
}

variable "phase2_secret_seed" {
  description = "Seed used to derive deterministic Phase 2 tunnel pre-shared keys."
  type        = string
  default     = "replace-this-phase2-seed"
  sensitive   = true
}

variable "phase3_enable_platform" {
  description = "Enable Phase 3 platform resources (EKS/GKE control planes)."
  type        = bool
  default     = false
}

variable "phase3_aws_eks_cluster_version" {
  description = "Optional EKS cluster version for Site A/B. Null lets AWS choose."
  type        = string
  default     = null
}

variable "phase3_aws_enabled_cluster_log_types" {
  description = "EKS control plane log types to enable."
  type        = list(string)
  default     = ["api", "audit", "authenticator"]
}

variable "phase3_aws_endpoint_public_access" {
  description = "Whether EKS API endpoints are publicly reachable."
  type        = bool
  default     = true
}

variable "phase3_aws_endpoint_private_access" {
  description = "Whether EKS API endpoints are privately reachable."
  type        = bool
  default     = false
}

variable "phase3_aws_public_access_cidrs" {
  description = "CIDRs allowed to access public EKS API endpoints."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "phase3_gcp_release_channel" {
  description = "GKE release channel for Site C/D."
  type        = string
  default     = "REGULAR"

  validation {
    condition = contains(
      ["RAPID", "REGULAR", "STABLE", "UNSPECIFIED"],
      var.phase3_gcp_release_channel
    )
    error_message = "phase3_gcp_release_channel must be one of RAPID, REGULAR, STABLE, UNSPECIFIED."
  }
}

variable "phase3_gcp_deletion_protection" {
  description = "Enable deletion protection on GKE clusters."
  type        = bool
  default     = false
}

variable "phase3_site_c_cluster_ipv4_cidr_block" {
  description = "Optional Site C GKE Pod CIDR range."
  type        = string
  default     = null
}

variable "phase3_site_c_services_ipv4_cidr_block" {
  description = "Optional Site C GKE Services CIDR range."
  type        = string
  default     = null
}

variable "phase3_site_d_cluster_ipv4_cidr_block" {
  description = "Optional Site D GKE Pod CIDR range."
  type        = string
  default     = null
}

variable "phase3_site_d_services_ipv4_cidr_block" {
  description = "Optional Site D GKE Services CIDR range."
  type        = string
  default     = null
}
