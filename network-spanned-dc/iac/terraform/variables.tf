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

variable "cloudflare_api_token" {
  description = "Cloudflare API token used by Terraform when Cloudflare edge resources are enabled."
  type        = string
  default     = "disabled"
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

variable "phase2_enable_intercloud" {
  description = "Enable Phase 2 inter-cloud VPN/BGP resources."
  type        = bool
  default     = true
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

variable "phase3_gcp_master_authorized_networks" {
  description = "Optional authorized CIDR blocks for GKE control plane access."
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = []
}

variable "phase4_enable_service_onboarding" {
  description = "Enable Phase 4 worker-capacity resources for EKS/GKE."
  type        = bool
  default     = false

  validation {
    condition     = !var.phase4_enable_service_onboarding || var.phase3_enable_platform
    error_message = "phase4_enable_service_onboarding requires phase3_enable_platform=true."
  }
}

variable "phase4_enable_published_app_path" {
  description = "Track whether published app path (WAF/LB/health gating) is enabled."
  type        = bool
  default     = false

  validation {
    condition     = !var.phase4_enable_published_app_path || var.phase4_enable_service_onboarding
    error_message = "phase4_enable_published_app_path requires phase4_enable_service_onboarding=true."
  }
}

variable "phase4_enable_published_app_tls" {
  description = "Enable origin HTTPS listener and ACM certificate automation for published app ALBs."
  type        = bool
  default     = false

  validation {
    condition     = !var.phase4_enable_published_app_tls || var.phase4_enable_published_app_path
    error_message = "phase4_enable_published_app_tls requires phase4_enable_published_app_path=true."
  }

  validation {
    condition     = !var.phase4_enable_published_app_tls || var.phase4_enable_cloudflare_edge
    error_message = "phase4_enable_published_app_tls requires phase4_enable_cloudflare_edge=true for DNS validation automation."
  }

  validation {
    condition     = !var.phase4_enable_published_app_tls || var.phase4_cloudflare_zone_name != null
    error_message = "phase4_enable_published_app_tls requires phase4_cloudflare_zone_name so ACM domains can be constructed."
  }
}

variable "phase4_aws_enable_ingress_internet_edge" {
  description = "Enable AWS ingress internet edge (IGW + public routing) required by published app ALBs."
  type        = bool
  default     = false

  validation {
    condition     = !var.phase4_enable_published_app_path || var.phase4_aws_enable_ingress_internet_edge
    error_message = "phase4_enable_published_app_path requires phase4_aws_enable_ingress_internet_edge=true."
  }
}

variable "phase4_enable_vdi_reference_stack" {
  description = "Track whether VDI reference stack and identity controls are enabled."
  type        = bool
  default     = false

  validation {
    condition     = !var.phase4_enable_vdi_reference_stack || var.phase4_enable_service_onboarding
    error_message = "phase4_enable_vdi_reference_stack requires phase4_enable_service_onboarding=true."
  }
}

variable "phase4_enable_cloudflare_edge" {
  description = "Enable Cloudflare DNS automation for Phase 4 published app endpoints."
  type        = bool
  default     = false

  validation {
    condition     = !var.phase4_enable_cloudflare_edge || var.phase4_enable_published_app_path
    error_message = "phase4_enable_cloudflare_edge requires phase4_enable_published_app_path=true."
  }

  validation {
    condition = (
      !var.phase4_enable_cloudflare_edge ||
      var.phase4_cloudflare_site_a_record_name != null ||
      var.phase4_cloudflare_site_b_record_name != null ||
      length(var.phase4_cloudflare_additional_records) > 0
    )
    error_message = "phase4_enable_cloudflare_edge requires at least one Cloudflare record name (site A, site B, or phase4_cloudflare_additional_records)."
  }

  validation {
    condition = (
      !var.phase4_enable_cloudflare_edge ||
      var.phase4_cloudflare_zone_id != null ||
      var.phase4_cloudflare_zone_name != null
    )
    error_message = "phase4_enable_cloudflare_edge requires phase4_cloudflare_zone_id or phase4_cloudflare_zone_name."
  }

  validation {
    condition     = !var.phase4_enable_cloudflare_edge || var.cloudflare_api_token != "disabled"
    error_message = "phase4_enable_cloudflare_edge requires cloudflare_api_token to be provided."
  }
}

variable "phase4_cloudflare_zone_id" {
  description = "Optional Cloudflare Zone ID where published app DNS records will be managed."
  type        = string
  default     = null
}

variable "phase4_cloudflare_zone_name" {
  description = "Optional Cloudflare zone name where published app DNS records will be managed (for example: slothkko.com)."
  type        = string
  default     = null
}

variable "phase4_cloudflare_site_a_record_name" {
  description = "DNS record name for the Site A published app endpoint (for example: app or app-a). Null skips Site A."
  type        = string
  default     = null
}

variable "phase4_cloudflare_site_b_record_name" {
  description = "DNS record name for the Site B published app endpoint (for example: app-b). Null skips Site B."
  type        = string
  default     = null
}

variable "phase4_cloudflare_additional_records" {
  description = "Additional Cloudflare CNAME records mapped to a published app target site (`site_a` or `site_b`). Record names may be labels (for example `admin`) or FQDNs."
  type        = map(string)
  default     = {}

  validation {
    condition = (
      alltrue([
        for record_name in keys(var.phase4_cloudflare_additional_records) :
        trimspace(record_name) != ""
      ]) &&
      alltrue([
        for target_site in values(var.phase4_cloudflare_additional_records) :
        contains(["site_a", "site_b"], lower(trimspace(target_site)))
      ])
    )
    error_message = "phase4_cloudflare_additional_records keys must be non-empty and values must be one of: site_a, site_b."
  }
}

variable "phase4_cloudflare_record_proxied" {
  description = "Whether Cloudflare proxy (orange cloud) is enabled for published app DNS records. Keep false for DNS-only mode."
  type        = bool
  default     = false
}

variable "phase4_cloudflare_record_ttl" {
  description = "Cloudflare DNS TTL for published app records. Use 1 for automatic when proxied, or >=60 for DNS-only records."
  type        = number
  default     = 300

  validation {
    condition     = var.phase4_cloudflare_record_ttl == 1 || var.phase4_cloudflare_record_ttl >= 60
    error_message = "phase4_cloudflare_record_ttl must be 1 (automatic) or at least 60 seconds."
  }
}

variable "phase4_vdi_aws_desktop_controlled_egress_ipv4_cidrs" {
  description = "IPv4 CIDRs VDI desktops may reach for controlled update egress in AWS."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "phase4_vdi_aws_desktop_controlled_egress_ipv6_cidrs" {
  description = "IPv6 CIDRs VDI desktops may reach for controlled update egress in AWS."
  type        = list(string)
  default     = ["::/0"]
}

variable "phase4_vdi_identity_ssm_parameter_arn_patterns" {
  description = "SSM parameter ARN patterns readable by the AWS VDI broker identity role."
  type        = list(string)
  default     = ["arn:aws:ssm:*:*:parameter/ddc/vdi/*"]
}

variable "phase4_vdi_identity_secret_arn_patterns" {
  description = "Secrets Manager ARN patterns readable by the AWS VDI broker identity role."
  type        = list(string)
  default     = ["arn:aws:secretsmanager:*:*:secret:ddc-vdi-*"]
}

variable "phase4_vdi_aws_node_desired_size" {
  description = "Desired EKS VDI node count per AWS site."
  type        = number
  default     = 1
}

variable "phase4_vdi_aws_node_min_size" {
  description = "Minimum EKS VDI node count per AWS site."
  type        = number
  default     = 1
}

variable "phase4_vdi_aws_node_max_size" {
  description = "Maximum EKS VDI node count per AWS site."
  type        = number
  default     = 2
}

variable "phase4_vdi_aws_node_instance_types" {
  description = "EC2 instance types for EKS VDI node groups."
  type        = list(string)
  default     = ["t3.small"]
}

variable "phase4_vdi_aws_node_labels" {
  description = "Additional labels for EKS VDI node groups."
  type        = map(string)
  default     = {}
}

variable "phase4_vdi_aws_node_taints" {
  description = "Optional taints for EKS VDI node groups."
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  default = [
    {
      key    = "workload"
      value  = "vdi"
      effect = "NO_SCHEDULE"
    }
  ]

  validation {
    condition = alltrue([
      for taint in var.phase4_vdi_aws_node_taints :
      contains(["NO_SCHEDULE", "PREFER_NO_SCHEDULE", "NO_EXECUTE"], taint.effect)
    ])
    error_message = "Each phase4_vdi_aws_node_taints effect must be NO_SCHEDULE, PREFER_NO_SCHEDULE, or NO_EXECUTE."
  }
}

variable "phase4_vdi_aws_node_max_unavailable" {
  description = "Maximum unavailable EKS VDI nodes during rolling update."
  type        = number
  default     = 1
}

variable "phase4_vdi_enable_aws_worker_pools" {
  description = "Enable AWS EKS worker node groups for the VDI reference stack."
  type        = bool
  default     = true
}

variable "phase4_vdi_gcp_desktop_controlled_egress_ipv4_cidrs" {
  description = "IPv4 CIDRs VDI desktops may reach for controlled update egress in GCP."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "phase4_vdi_enable_gcp_worker_pools" {
  description = "Enable GCP GKE worker node pools for the VDI reference stack."
  type        = bool
  default     = true
}

variable "phase4_vdi_gcp_manage_broker_identity" {
  description = "Create and bind dedicated GCP broker service accounts for VDI reference stacks."
  type        = bool
  default     = true
}

variable "phase4_vdi_gcp_node_machine_type" {
  description = "Machine type for GKE VDI node pools."
  type        = string
  default     = "e2-standard-8"
}

variable "phase4_vdi_gcp_node_disk_size_gb" {
  description = "Disk size in GiB for GKE VDI node pools."
  type        = number
  default     = 120
}

variable "phase4_vdi_gcp_node_disk_type" {
  description = "Disk type for GKE VDI node pools."
  type        = string
  default     = "pd-balanced"
}

variable "phase4_vdi_gcp_node_image_type" {
  description = "Image type for GKE VDI node pools."
  type        = string
  default     = "COS_CONTAINERD"
}

variable "phase4_vdi_gcp_node_spot" {
  description = "Use spot nodes for GKE VDI node pools."
  type        = bool
  default     = false
}

variable "phase4_vdi_gcp_node_enable_autoscaling" {
  description = "Enable autoscaling for GKE VDI node pools."
  type        = bool
  default     = true
}

variable "phase4_vdi_gcp_node_min_count" {
  description = "Minimum node count for GKE VDI autoscaling."
  type        = number
  default     = 1
}

variable "phase4_vdi_gcp_node_max_count" {
  description = "Maximum node count for GKE VDI autoscaling."
  type        = number
  default     = 2
}

variable "phase4_vdi_gcp_node_initial_count" {
  description = "Initial node count for GKE VDI node pools."
  type        = number
  default     = 1
}

variable "phase4_vdi_gcp_node_service_account" {
  description = "Optional explicit service account for GKE VDI node pools."
  type        = string
  default     = null
}

variable "phase4_vdi_gcp_node_labels" {
  description = "Additional labels for GKE VDI node pools."
  type        = map(string)
  default     = {}
}

variable "phase4_vdi_gcp_node_tags" {
  description = "Additional network tags for GKE VDI node pools."
  type        = list(string)
  default     = []
}

variable "phase4_published_app_listener_port" {
  description = "Inbound listener port for published app load balancers."
  type        = number
  default     = 80
}

variable "phase4_published_app_https_port" {
  description = "Inbound HTTPS listener port for published app load balancers."
  type        = number
  default     = 443
}

variable "phase4_published_app_tls_ssl_policy" {
  description = "TLS security policy for published app HTTPS listeners."
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "phase4_site_a_published_app_tls_subject_alternative_names" {
  description = "Additional hostnames for the Site A published app ACM certificate. Values may be labels, FQDNs, or '@' for zone apex."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for hostname in var.phase4_site_a_published_app_tls_subject_alternative_names :
      trimspace(hostname) != ""
    ])
    error_message = "phase4_site_a_published_app_tls_subject_alternative_names entries must not be empty."
  }
}

variable "phase4_site_b_published_app_tls_subject_alternative_names" {
  description = "Additional hostnames for the Site B published app ACM certificate. Values may be labels, FQDNs, or '@' for zone apex."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for hostname in var.phase4_site_b_published_app_tls_subject_alternative_names :
      trimspace(hostname) != ""
    ])
    error_message = "phase4_site_b_published_app_tls_subject_alternative_names entries must not be empty."
  }
}

variable "phase4_published_app_allowed_ingress_ipv4_cidrs" {
  description = "Allowed IPv4 client CIDRs for the published app path."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "phase4_published_app_allowed_ingress_ipv6_cidrs" {
  description = "Allowed IPv6 client CIDRs for the published app path."
  type        = list(string)
  default     = ["::/0"]
}

variable "phase4_published_app_health_check_path" {
  description = "HTTP health check path used for published app backend gating."
  type        = string
  default     = "/healthz"
}

variable "phase4_published_app_root_redirect_path" {
  description = "Optional HTTP path that root requests ('/') should redirect to on published app listeners."
  type        = string
  default     = "/guacamole/"

  validation {
    condition     = var.phase4_published_app_root_redirect_path == null || startswith(var.phase4_published_app_root_redirect_path, "/")
    error_message = "phase4_published_app_root_redirect_path must be null or an absolute path beginning with '/'."
  }
}

variable "phase4_published_app_backend_port" {
  description = "Backend application port for published app target groups."
  type        = number
  default     = 80
}

variable "phase4_published_app_waf_rate_limit" {
  description = "Per-5-minute IP threshold for published app WAF rate-limiting."
  type        = number
  default     = 2000
}

variable "phase4_site_a_published_app_backend_ipv4_targets" {
  description = "Site A backend IPv4 targets for the published app path."
  type        = list(string)
  default     = []
}

variable "phase4_site_b_published_app_backend_ipv4_targets" {
  description = "Site B backend IPv4 targets for the published app path."
  type        = list(string)
  default     = []
}

variable "phase4_aws_node_desired_size" {
  description = "Desired EKS node count per AWS site."
  type        = number
  default     = 2
}

variable "phase4_aws_node_min_size" {
  description = "Minimum EKS node count per AWS site."
  type        = number
  default     = 1
}

variable "phase4_aws_node_max_size" {
  description = "Maximum EKS node count per AWS site."
  type        = number
  default     = 4
}

variable "phase4_aws_node_instance_types" {
  description = "EC2 instance types for EKS node groups."
  type        = list(string)
  default     = ["t3.small"]
}

variable "phase4_aws_node_capacity_type" {
  description = "Capacity type for EKS node groups."
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.phase4_aws_node_capacity_type)
    error_message = "phase4_aws_node_capacity_type must be ON_DEMAND or SPOT."
  }
}

variable "phase4_aws_node_disk_size" {
  description = "Disk size in GiB for EKS nodes."
  type        = number
  default     = 80
}

variable "phase4_aws_node_ami_type" {
  description = "Optional AMI type override for EKS node groups."
  type        = string
  default     = null
}

variable "phase4_aws_node_labels" {
  description = "Additional node labels for EKS node groups."
  type        = map(string)
  default     = {}
}

variable "phase4_aws_node_taints" {
  description = "Optional taints for EKS node groups."
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  default = []
}

variable "phase4_aws_node_max_unavailable" {
  description = "Maximum unavailable EKS nodes during rolling update."
  type        = number
  default     = 1
}

variable "phase4_aws_enable_ssm_managed_instance_core" {
  description = "Attach AmazonSSMManagedInstanceCore to Phase 4 EKS worker roles."
  type        = bool
  default     = false
}

variable "phase4_aws_enable_private_service_endpoints" {
  description = "Create private VPC endpoints required for EKS worker bootstrap/runtime."
  type        = bool
  default     = true
}

variable "phase4_gcp_node_machine_type" {
  description = "Machine type for GKE node pools."
  type        = string
  default     = "e2-standard-4"
}

variable "phase4_gcp_node_disk_size_gb" {
  description = "Disk size in GiB for GKE node pools."
  type        = number
  default     = 100
}

variable "phase4_gcp_node_disk_type" {
  description = "Disk type for GKE node pools."
  type        = string
  default     = "pd-standard"
}

variable "phase4_gcp_node_image_type" {
  description = "Image type for GKE node pools."
  type        = string
  default     = "COS_CONTAINERD"
}

variable "phase4_gcp_node_spot" {
  description = "Use spot VMs for GKE node pools."
  type        = bool
  default     = false
}

variable "phase4_gcp_node_enable_autoscaling" {
  description = "Enable autoscaling for GKE node pools."
  type        = bool
  default     = true
}

variable "phase4_gcp_node_min_count" {
  description = "Minimum node count for GKE autoscaling."
  type        = number
  default     = 1
}

variable "phase4_gcp_node_max_count" {
  description = "Maximum node count for GKE autoscaling."
  type        = number
  default     = 3
}

variable "phase4_gcp_node_initial_count" {
  description = "Initial node count for GKE node pools."
  type        = number
  default     = 1
}

variable "phase4_gcp_node_service_account" {
  description = "Optional service account for GKE node pools."
  type        = string
  default     = null
}

variable "phase4_gcp_node_labels" {
  description = "Additional labels for GKE nodes."
  type        = map(string)
  default     = {}
}

variable "phase4_gcp_node_tags" {
  description = "Network tags for GKE nodes."
  type        = list(string)
  default     = []
}

variable "phase4_gcp_node_oauth_scopes" {
  description = "OAuth scopes assigned to GKE node tokens."
  type        = list(string)
  default = [
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/monitoring",
    "https://www.googleapis.com/auth/devstorage.read_only"
  ]
}

variable "phase4_gcp_node_disable_legacy_metadata_endpoints" {
  description = "Disable legacy metadata endpoints on GKE nodes."
  type        = bool
  default     = true
}

variable "phase4_gcp_node_enable_secure_boot" {
  description = "Enable Shielded VM Secure Boot on GKE nodes."
  type        = bool
  default     = true
}

variable "phase4_gcp_node_enable_integrity_monitoring" {
  description = "Enable Shielded VM integrity monitoring on GKE nodes."
  type        = bool
  default     = true
}

variable "phase4_gcp_node_workload_metadata_mode" {
  description = "Workload metadata mode for GKE nodes."
  type        = string
  default     = "GCE_METADATA"

  validation {
    condition = contains(
      ["GCE_METADATA", "GKE_METADATA"],
      var.phase4_gcp_node_workload_metadata_mode
    )
    error_message = "phase4_gcp_node_workload_metadata_mode must be GCE_METADATA or GKE_METADATA."
  }
}

variable "phase4_enable_ops_stack" {
  description = "Enable Phase 4 standalone ops servers (OpenProject in Site C, git server in Site B, and Ansible control node in Site A)."
  type        = bool
  default     = false

  validation {
    condition     = !var.phase4_enable_ops_stack || var.phase4_aws_enable_ingress_internet_edge
    error_message = "phase4_enable_ops_stack requires phase4_aws_enable_ingress_internet_edge=true so AWS ops instances can bootstrap packages."
  }

  validation {
    condition = (
      !var.phase4_enable_ops_stack ||
      (var.phase4_ops_admin_ssh_public_key != null && trimspace(var.phase4_ops_admin_ssh_public_key) != "") ||
      (var.phase4_ops_admin_ssh_password != null && trimspace(var.phase4_ops_admin_ssh_password) != "")
    )
    error_message = "phase4_enable_ops_stack requires phase4_ops_admin_ssh_public_key or phase4_ops_admin_ssh_password."
  }
}

variable "phase4_ops_admin_username" {
  description = "Bootstrap admin username configured on OpenProject, git, and Ansible nodes."
  type        = string
  default     = "opsadmin"

  validation {
    condition     = can(regex("^[a-z_][a-z0-9_-]{0,30}$", var.phase4_ops_admin_username))
    error_message = "phase4_ops_admin_username must match Linux username rules: ^[a-z_][a-z0-9_-]{0,30}$."
  }
}

variable "phase4_ops_admin_ssh_public_key" {
  description = "Optional SSH public key injected into the ops admin account on all ops servers."
  type        = string
  default     = null
}

variable "phase4_ops_admin_ssh_password" {
  description = "Optional SSH password for the ops admin account on all ops servers."
  type        = string
  default     = null
  sensitive   = true
}

variable "phase4_ops_aws_key_pair_name" {
  description = "Optional AWS EC2 key pair name attached to Site A/B ops instances."
  type        = string
  default     = null
}

variable "phase4_ops_trusted_ipv4_cidrs" {
  description = "Additional trusted IPv4 CIDRs allowed SSH access to ops servers."
  type        = list(string)
  default     = []
}

variable "phase4_ops_openproject_http_allowed_ipv4_cidrs" {
  description = "IPv4 CIDRs allowed to reach OpenProject HTTP/HTTPS in Site C. Null or empty defaults to site CIDRs plus phase4_ops_trusted_ipv4_cidrs."
  type        = list(string)
  default     = null
}

variable "phase4_ops_git_http_allowed_ipv4_cidrs" {
  description = "IPv4 CIDRs allowed to reach Git server web UI in Site B. Null or empty defaults to site CIDRs plus phase4_ops_trusted_ipv4_cidrs."
  type        = list(string)
  default     = null
}

variable "phase4_ops_openproject_machine_type" {
  description = "GCP machine type for the Site C OpenProject server."
  type        = string
  default     = "e2-standard-4"
}

variable "phase4_ops_openproject_boot_disk_size_gb" {
  description = "Boot disk size in GiB for the Site C OpenProject server."
  type        = number
  default     = 80

  validation {
    condition     = var.phase4_ops_openproject_boot_disk_size_gb >= 20
    error_message = "phase4_ops_openproject_boot_disk_size_gb must be at least 20 GiB."
  }
}

variable "phase4_ops_openproject_zone" {
  description = "Optional explicit zone for Site C OpenProject server. Null defaults to <gcp_site_c_region>-b."
  type        = string
  default     = null
}

variable "phase4_ops_openproject_image" {
  description = "Container image for OpenProject deployment in Site C."
  type        = string
  default     = "openproject/openproject:17"
}

variable "phase4_ops_openproject_host_name" {
  description = "Host name advertised by OpenProject (for example: openproject.slothkko.com)."
  type        = string
  default     = "openproject.local"
}

variable "phase4_ops_git_instance_type" {
  description = "EC2 instance type for the Site B git server."
  type        = string
  default     = "t3.small"
}

variable "phase4_ops_git_root_volume_size_gb" {
  description = "Root volume size in GiB for the Site B git server."
  type        = number
  default     = 60

  validation {
    condition     = var.phase4_ops_git_root_volume_size_gb >= 20
    error_message = "phase4_ops_git_root_volume_size_gb must be at least 20 GiB."
  }
}

variable "phase4_ops_git_image" {
  description = "Container image for Git server deployment in Site B."
  type        = string
  default     = "docker.gitea.com/gitea:1.25.4"
}

variable "phase4_ops_ansible_instance_type" {
  description = "EC2 instance type for the Site A Ansible control node."
  type        = string
  default     = "t3.small"
}

variable "phase4_ops_ansible_root_volume_size_gb" {
  description = "Root volume size in GiB for the Site A Ansible control node."
  type        = number
  default     = 40

  validation {
    condition     = var.phase4_ops_ansible_root_volume_size_gb >= 20
    error_message = "phase4_ops_ansible_root_volume_size_gb must be at least 20 GiB."
  }
}

variable "phase5_enable_resilience_validation" {
  description = "Track readiness to execute Phase 5 failover scenarios and DR runbooks."
  type        = bool
  default     = false
}

variable "phase5_enable_backup_restore_drills" {
  description = "Track readiness to execute backup and restore drills for Phase 5."
  type        = bool
  default     = false
}

variable "phase5_enable_handover_signoff" {
  description = "Track readiness to complete operations handover sign-off."
  type        = bool
  default     = false
}
