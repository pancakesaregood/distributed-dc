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
    vpc_id                        = module.aws_site_a.vpc_id
    vpc_ipv4_cidr                 = module.aws_site_a.vpc_ipv4_cidr
    vpc_ipv6_cidr                 = module.aws_site_a.vpc_ipv6_cidr
    ingress_subnets               = module.aws_site_a.ingress_subnet_ids
    app_subnets                   = module.aws_site_a.app_subnet_ids
    data_subnets                  = module.aws_site_a.data_subnet_ids
    vdi_subnets                   = module.aws_site_a.vdi_subnet_ids
    availability_zones            = module.aws_site_a.availability_zones
    ingress_internet_edge_enabled = module.aws_site_a.ingress_internet_edge_enabled
    ingress_internet_gateway_id   = module.aws_site_a.ingress_internet_gateway_id
    ingress_public_route_table_id = module.aws_site_a.ingress_public_route_table_id
  }
}

output "aws_site_b_network" {
  description = "AWS Site B network outputs."
  value = {
    vpc_id                        = module.aws_site_b.vpc_id
    vpc_ipv4_cidr                 = module.aws_site_b.vpc_ipv4_cidr
    vpc_ipv6_cidr                 = module.aws_site_b.vpc_ipv6_cidr
    ingress_subnets               = module.aws_site_b.ingress_subnet_ids
    app_subnets                   = module.aws_site_b.app_subnet_ids
    data_subnets                  = module.aws_site_b.data_subnet_ids
    vdi_subnets                   = module.aws_site_b.vdi_subnet_ids
    availability_zones            = module.aws_site_b.availability_zones
    ingress_internet_edge_enabled = module.aws_site_b.ingress_internet_edge_enabled
    ingress_internet_gateway_id   = module.aws_site_b.ingress_internet_gateway_id
    ingress_public_route_table_id = module.aws_site_b.ingress_public_route_table_id
  }
}

output "gcp_site_c_network" {
  description = "GCP Site C network outputs."
  value = {
    network_self_link = module.gcp_site_c.network_self_link
    ingress_subnets   = module.gcp_site_c.ingress_subnet_names
    app_subnets       = module.gcp_site_c.app_subnet_names
    data_subnets      = module.gcp_site_c.data_subnet_names
    vdi_subnets       = module.gcp_site_c.vdi_subnet_names
  }
}

output "gcp_site_d_network" {
  description = "GCP Site D network outputs."
  value = {
    network_self_link = module.gcp_site_d.network_self_link
    ingress_subnets   = module.gcp_site_d.ingress_subnet_names
    app_subnets       = module.gcp_site_d.app_subnet_names
    data_subnets      = module.gcp_site_d.data_subnet_names
    vdi_subnets       = module.gcp_site_d.vdi_subnet_names
  }
}

output "phase2_aws_vpn_gateways" {
  description = "AWS VPN gateways created for Phase 2 inter-cloud connectivity."
  value = var.phase2_enable_intercloud ? {
    site_a = {
      vpn_gateway_id = aws_vpn_gateway.site_a[0].id
      asn            = aws_vpn_gateway.site_a[0].amazon_side_asn
    }
    site_b = {
      vpn_gateway_id = aws_vpn_gateway.site_b[0].id
      asn            = aws_vpn_gateway.site_b[0].amazon_side_asn
    }
  } : {}
}

output "phase2_intercloud_links" {
  description = "Inter-cloud pair object summaries for A-C, A-D, B-C, B-D."
  value = var.phase2_enable_intercloud ? {
    ac = module.intercloud_ac[0].summary
    ad = module.intercloud_ad[0].summary
    bc = module.intercloud_bc[0].summary
    bd = module.intercloud_bd[0].summary
  } : {}
}

output "phase2_intercloud_enabled" {
  description = "Whether Phase 2 inter-cloud VPN/BGP resources are enabled in this apply."
  value       = var.phase2_enable_intercloud
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

output "phase4_service_onboarding_enabled" {
  description = "Whether Phase 4 worker capacity is enabled."
  value       = var.phase4_enable_service_onboarding
}

output "phase4_aws_eks_nodegroups" {
  description = "Phase 4 EKS node group summaries for Site A/B when enabled."
  value = local.phase4_capacity_enabled ? {
    site_a = module.aws_eks_nodegroup_site_a[0].summary
    site_b = module.aws_eks_nodegroup_site_b[0].summary
  } : {}
}

output "phase4_gcp_gke_node_pools" {
  description = "Phase 4 GKE node pool summaries for Site C/D when enabled."
  value = local.phase4_capacity_enabled ? {
    site_c = module.gcp_gke_node_pool_site_c[0].summary
    site_d = module.gcp_gke_node_pool_site_d[0].summary
  } : {}
}

output "phase4_published_app_paths" {
  description = "Phase 4 published app path summaries for Site A/B when enabled."
  value = local.phase4_published_app_path_enabled ? {
    site_a = merge(module.aws_published_app_path_site_a[0].summary, {
      https_listener_port = local.phase4_published_app_tls_site_a_enabled ? var.phase4_published_app_https_port : null
      https_listener_arn  = length(aws_lb_listener.phase4_site_a_https_forward) > 0 ? aws_lb_listener.phase4_site_a_https_forward[0].arn : (length(aws_lb_listener.phase4_site_a_https_fixed) > 0 ? aws_lb_listener.phase4_site_a_https_fixed[0].arn : null)
      tls_certificate_arn = length(aws_acm_certificate_validation.phase4_site_a_published_app) > 0 ? aws_acm_certificate_validation.phase4_site_a_published_app[0].certificate_arn : null
    })
    site_b = merge(module.aws_published_app_path_site_b[0].summary, {
      https_listener_port = local.phase4_published_app_tls_site_b_enabled ? var.phase4_published_app_https_port : null
      https_listener_arn  = length(aws_lb_listener.phase4_site_b_https_forward) > 0 ? aws_lb_listener.phase4_site_b_https_forward[0].arn : (length(aws_lb_listener.phase4_site_b_https_fixed) > 0 ? aws_lb_listener.phase4_site_b_https_fixed[0].arn : null)
      tls_certificate_arn = length(aws_acm_certificate_validation.phase4_site_b_published_app) > 0 ? aws_acm_certificate_validation.phase4_site_b_published_app[0].certificate_arn : null
    })
  } : {}
}

output "phase4_cloudflare_edge_records" {
  description = "Cloudflare DNS records for Phase 4 published app endpoints and optional additional hostnames when enabled."
  value = local.phase4_cloudflare_edge_enabled ? {
    site_a = length(cloudflare_record.phase4_published_app_site_a) > 0 ? {
      id       = cloudflare_record.phase4_published_app_site_a[0].id
      hostname = cloudflare_record.phase4_published_app_site_a[0].hostname
      proxied  = cloudflare_record.phase4_published_app_site_a[0].proxied
      target   = cloudflare_record.phase4_published_app_site_a[0].content
    } : null
    site_b = length(cloudflare_record.phase4_published_app_site_b) > 0 ? {
      id       = cloudflare_record.phase4_published_app_site_b[0].id
      hostname = cloudflare_record.phase4_published_app_site_b[0].hostname
      proxied  = cloudflare_record.phase4_published_app_site_b[0].proxied
      target   = cloudflare_record.phase4_published_app_site_b[0].content
    } : null
    additional = {
      for record_name, record in cloudflare_record.phase4_published_app_additional :
      record_name => {
        id       = record.id
        hostname = record.hostname
        proxied  = record.proxied
        target   = record.content
      }
    }
    } : {
    site_a     = null
    site_b     = null
    additional = {}
  }
}

output "phase4_vdi_reference_stacks" {
  description = "Phase 4 VDI reference stack summaries for Site A/B/C/D when enabled."
  value = local.phase4_vdi_reference_stack_enabled ? {
    aws = {
      site_a = {
        controls = module.aws_vdi_reference_stack_site_a[0].summary
        worker   = length(module.aws_eks_nodegroup_site_a_vdi) > 0 ? module.aws_eks_nodegroup_site_a_vdi[0].summary : null
      }
      site_b = {
        controls = module.aws_vdi_reference_stack_site_b[0].summary
        worker   = length(module.aws_eks_nodegroup_site_b_vdi) > 0 ? module.aws_eks_nodegroup_site_b_vdi[0].summary : null
      }
    }
    gcp = {
      site_c = {
        controls = module.gcp_vdi_reference_stack_site_c[0].summary
        worker   = length(module.gcp_gke_node_pool_site_c_vdi) > 0 ? module.gcp_gke_node_pool_site_c_vdi[0].summary : null
      }
      site_d = {
        controls = module.gcp_vdi_reference_stack_site_d[0].summary
        worker   = length(module.gcp_gke_node_pool_site_d_vdi) > 0 ? module.gcp_gke_node_pool_site_d_vdi[0].summary : null
      }
    }
  } : null
}

output "phase4_vdi_desktops" {
  description = "Guacamole-ready desktop endpoint metadata for Phase 4 VDI desktops."
  value = local.phase4_vdi_reference_stack_enabled ? {
    site_a = {
      linux = {
        guac_target = "Linux Desktop (VNC)"
        protocol    = "vnc"
        hostname    = "vdi-desktop.vdi.svc.cluster.local"
        port        = 5900
      }
      windows = local.phase4_site_a_windows_desktop_enabled ? {
        guac_target = "Windows Desktop (RDP)"
        protocol    = "rdp"
        instance_id = aws_instance.phase4_site_a_windows_desktop[0].id
        private_ip  = aws_instance.phase4_site_a_windows_desktop[0].private_ip
        port        = 3389
        username    = var.phase4_vdi_site_a_windows_desktop_rdp_username
      } : null
    }
  } : null
}

output "phase4_forward_proxy" {
  description = "Site A forward proxy endpoint and policy summary when enabled."
  value = local.phase4_site_a_forward_proxy_enabled ? {
    site                 = "site-a"
    private_ip           = aws_instance.phase4_site_a_forward_proxy[0].private_ip
    public_ip            = aws_instance.phase4_site_a_forward_proxy[0].public_ip
    listen_port          = var.phase4_forward_proxy_site_a_listen_port
    proxy_url            = "http://${aws_instance.phase4_site_a_forward_proxy[0].private_ip}:${var.phase4_forward_proxy_site_a_listen_port}"
    allowed_client_cidrs = local.phase4_site_a_forward_proxy_client_ipv4_cidrs
    allow_domains        = local.phase4_site_a_forward_proxy_allow_domains
    block_domains        = local.phase4_site_a_forward_proxy_block_domains
  } : null
}

output "phase4_ops_servers" {
  description = "Phase 4 standalone ops server endpoints and Guacamole SSH target metadata when enabled."
  value = var.phase4_enable_ops_stack ? {
    openproject = {
      site        = "site-c"
      private_ip  = google_compute_instance.phase4_openproject_server[0].network_interface[0].network_ip
      public_ip   = google_compute_address.phase4_site_c_openproject_public_ip[0].address
      ssh_port    = 22
      ssh_user    = var.phase4_ops_admin_username
      app_url     = "http://${google_compute_address.phase4_site_c_openproject_public_ip[0].address}/"
      guac_target = "OpenProject (Site C)"
    }
    git = {
      site           = "site-b"
      private_ip     = aws_instance.phase4_git_server[0].private_ip
      public_ip      = aws_instance.phase4_git_server[0].public_ip
      ssh_port       = 2222
      ssh_user       = var.phase4_ops_admin_username
      app_url        = "http://${aws_instance.phase4_git_server[0].public_ip}:3000/"
      clone_ssh_hint = "ssh://${var.phase4_ops_admin_username}@${aws_instance.phase4_git_server[0].public_ip}:2222/<org>/<repo>.git"
      guac_target    = "Git Server (Site B)"
    }
    ansible = {
      site        = "site-a"
      private_ip  = aws_instance.phase4_ansible_control_node[0].private_ip
      public_ip   = aws_instance.phase4_ansible_control_node[0].public_ip
      ssh_port    = 22
      ssh_user    = var.phase4_ops_admin_username
      guac_target = "Ansible Control (Site A)"
    }
  } : null
}

output "phase4_deliverable_flags" {
  description = "Phase 4 source-material deliverable flags."
  value = {
    service_onboarding_capacity = var.phase4_enable_service_onboarding
    published_app_path          = var.phase4_enable_published_app_path
    published_app_tls           = var.phase4_enable_published_app_tls
    aws_ingress_internet_edge   = var.phase4_aws_enable_ingress_internet_edge
    cloudflare_edge             = var.phase4_enable_cloudflare_edge
    vdi_reference_stack         = var.phase4_enable_vdi_reference_stack
    ops_stack                   = var.phase4_enable_ops_stack
  }
}

output "phase5_deliverable_flags" {
  description = "Phase 5 source-material deliverable flags."
  value = {
    resilience_validation = var.phase5_enable_resilience_validation
    backup_restore_drills = var.phase5_enable_backup_restore_drills
    handover_signoff      = var.phase5_enable_handover_signoff
  }
}
