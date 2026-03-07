output "site_summary" {
  description = "Per-site summary values for orchestration and documentation."
  value       = local.sites
}

output "intercloud_pair_policy" {
  description = "Target inter-cloud path policy matrix for A-C, B-D, A-D, B-C."
  value       = local.intercloud_pairs
}

output "aws_site_a_network" {
  description = "AWS Site A network outputs."
  value = {
    vpc_id             = module.aws_site_a.vpc_id
    vpc_ipv4_cidr      = module.aws_site_a.vpc_ipv4_cidr
    vpc_ipv6_cidr      = module.aws_site_a.vpc_ipv6_cidr
    ingress_subnets    = module.aws_site_a.ingress_subnet_ids
    app_subnets        = module.aws_site_a.app_subnet_ids
    data_subnets       = module.aws_site_a.data_subnet_ids
    availability_zones = module.aws_site_a.availability_zones
  }
}

output "aws_site_b_network" {
  description = "AWS Site B network outputs."
  value = {
    vpc_id             = module.aws_site_b.vpc_id
    vpc_ipv4_cidr      = module.aws_site_b.vpc_ipv4_cidr
    vpc_ipv6_cidr      = module.aws_site_b.vpc_ipv6_cidr
    ingress_subnets    = module.aws_site_b.ingress_subnet_ids
    app_subnets        = module.aws_site_b.app_subnet_ids
    data_subnets       = module.aws_site_b.data_subnet_ids
    availability_zones = module.aws_site_b.availability_zones
  }
}

output "gcp_site_c_network" {
  description = "GCP Site C network outputs."
  value = {
    network_self_link = module.gcp_site_c.network_self_link
    ingress_subnets   = module.gcp_site_c.ingress_subnet_names
    app_subnets       = module.gcp_site_c.app_subnet_names
    data_subnets      = module.gcp_site_c.data_subnet_names
  }
}

output "gcp_site_d_network" {
  description = "GCP Site D network outputs."
  value = {
    network_self_link = module.gcp_site_d.network_self_link
    ingress_subnets   = module.gcp_site_d.ingress_subnet_names
    app_subnets       = module.gcp_site_d.app_subnet_names
    data_subnets      = module.gcp_site_d.data_subnet_names
  }
}

output "phase2_aws_vpn_gateways" {
  description = "AWS VPN gateways created for Phase 2 inter-cloud connectivity."
  value = {
    site_a = {
      vpn_gateway_id = aws_vpn_gateway.site_a.id
      asn            = aws_vpn_gateway.site_a.amazon_side_asn
    }
    site_b = {
      vpn_gateway_id = aws_vpn_gateway.site_b.id
      asn            = aws_vpn_gateway.site_b.amazon_side_asn
    }
  }
}

output "phase2_intercloud_links" {
  description = "Inter-cloud pair object summaries for A-C, A-D, B-C, B-D."
  value = {
    ac = module.intercloud_ac.summary
    ad = module.intercloud_ad.summary
    bc = module.intercloud_bc.summary
    bd = module.intercloud_bd.summary
  }
}

output "phase3_platform_enabled" {
  description = "Whether Phase 3 platform resources are enabled in this apply."
  value       = var.phase3_enable_platform
}

output "phase3_aws_eks_clusters" {
  description = "Phase 3 EKS cluster summaries for Site A/B when enabled."
  value = var.phase3_enable_platform ? {
    site_a = module.aws_eks_site_a[0].summary
    site_b = module.aws_eks_site_b[0].summary
  } : {}
}

output "phase3_gcp_gke_clusters" {
  description = "Phase 3 GKE cluster summaries for Site C/D when enabled."
  value = var.phase3_enable_platform ? {
    site_c = module.gcp_gke_site_c[0].summary
    site_d = module.gcp_gke_site_d[0].summary
  } : {}
}
