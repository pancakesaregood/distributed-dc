locals {
  phase4_capacity_enabled                    = var.phase4_enable_service_onboarding && var.phase3_enable_platform
  phase4_aws_private_endpoint_access_enabled = local.phase4_capacity_enabled && var.phase4_aws_enable_private_service_endpoints
  phase4_aws_interface_endpoint_services = toset([
    "ec2",
    "eks",
    "sts",
    "ecr.api",
    "ecr.dkr"
  ])
}

data "aws_route_tables" "phase4_site_a_vpc" {
  count    = local.phase4_aws_private_endpoint_access_enabled ? 1 : 0
  provider = aws.site_a

  filter {
    name   = "vpc-id"
    values = [module.aws_site_a.vpc_id]
  }
}

data "aws_route_tables" "phase4_site_b_vpc" {
  count    = local.phase4_aws_private_endpoint_access_enabled ? 1 : 0
  provider = aws.site_b

  filter {
    name   = "vpc-id"
    values = [module.aws_site_b.vpc_id]
  }
}

resource "aws_security_group" "phase4_site_a_vpce" {
  count    = local.phase4_aws_private_endpoint_access_enabled ? 1 : 0
  provider = aws.site_a

  name        = "${var.name_prefix}-${var.environment}-site-a-vpce-sg"
  description = "Allow HTTPS from Site A VPC workloads to private AWS endpoints."
  vpc_id      = module.aws_site_a.vpc_id

  ingress {
    description = "HTTPS from Site A VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [module.aws_site_a.vpc_ipv4_cidr]
  }

  egress {
    description = "All egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.common_tags,
    {
      Name      = "${var.name_prefix}-${var.environment}-site-a-vpce-sg"
      site      = "site-a"
      component = "aws-private-endpoint-access"
    }
  )
}

resource "aws_security_group" "phase4_site_b_vpce" {
  count    = local.phase4_aws_private_endpoint_access_enabled ? 1 : 0
  provider = aws.site_b

  name        = "${var.name_prefix}-${var.environment}-site-b-vpce-sg"
  description = "Allow HTTPS from Site B VPC workloads to private AWS endpoints."
  vpc_id      = module.aws_site_b.vpc_id

  ingress {
    description = "HTTPS from Site B VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [module.aws_site_b.vpc_ipv4_cidr]
  }

  egress {
    description = "All egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.common_tags,
    {
      Name      = "${var.name_prefix}-${var.environment}-site-b-vpce-sg"
      site      = "site-b"
      component = "aws-private-endpoint-access"
    }
  )
}

resource "aws_vpc_endpoint" "phase4_site_a_interface" {
  for_each = local.phase4_aws_private_endpoint_access_enabled ? local.phase4_aws_interface_endpoint_services : toset([])
  provider = aws.site_a

  vpc_id              = module.aws_site_a.vpc_id
  service_name        = "com.amazonaws.${var.aws_site_a_region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = module.aws_site_a.app_subnet_ids
  security_group_ids  = [aws_security_group.phase4_site_a_vpce[0].id]

  tags = merge(
    local.common_tags,
    {
      Name      = "${var.name_prefix}-${var.environment}-site-a-vpce-${replace(each.value, ".", "-")}"
      site      = "site-a"
      component = "aws-private-endpoint-access"
      service   = each.value
    }
  )
}

resource "aws_vpc_endpoint" "phase4_site_b_interface" {
  for_each = local.phase4_aws_private_endpoint_access_enabled ? local.phase4_aws_interface_endpoint_services : toset([])
  provider = aws.site_b

  vpc_id              = module.aws_site_b.vpc_id
  service_name        = "com.amazonaws.${var.aws_site_b_region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = module.aws_site_b.app_subnet_ids
  security_group_ids  = [aws_security_group.phase4_site_b_vpce[0].id]

  tags = merge(
    local.common_tags,
    {
      Name      = "${var.name_prefix}-${var.environment}-site-b-vpce-${replace(each.value, ".", "-")}"
      site      = "site-b"
      component = "aws-private-endpoint-access"
      service   = each.value
    }
  )
}

resource "aws_vpc_endpoint" "phase4_site_a_s3_gateway" {
  count    = local.phase4_aws_private_endpoint_access_enabled ? 1 : 0
  provider = aws.site_a

  vpc_id            = module.aws_site_a.vpc_id
  service_name      = "com.amazonaws.${var.aws_site_a_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = data.aws_route_tables.phase4_site_a_vpc[0].ids

  tags = merge(
    local.common_tags,
    {
      Name      = "${var.name_prefix}-${var.environment}-site-a-vpce-s3-gateway"
      site      = "site-a"
      component = "aws-private-endpoint-access"
      service   = "s3"
    }
  )
}

resource "aws_vpc_endpoint" "phase4_site_b_s3_gateway" {
  count    = local.phase4_aws_private_endpoint_access_enabled ? 1 : 0
  provider = aws.site_b

  vpc_id            = module.aws_site_b.vpc_id
  service_name      = "com.amazonaws.${var.aws_site_b_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = data.aws_route_tables.phase4_site_b_vpc[0].ids

  tags = merge(
    local.common_tags,
    {
      Name      = "${var.name_prefix}-${var.environment}-site-b-vpce-s3-gateway"
      site      = "site-b"
      component = "aws-private-endpoint-access"
      service   = "s3"
    }
  )
}

module "aws_eks_nodegroup_site_a" {
  count  = local.phase4_capacity_enabled ? 1 : 0
  source = "./modules/aws_eks_nodegroup"

  providers = {
    aws = aws.site_a
  }

  site_name                        = "site-a"
  name_prefix                      = var.name_prefix
  environment                      = var.environment
  node_group_suffix                = "general"
  cluster_name                     = module.aws_eks_site_a[0].summary.cluster_name
  subnet_ids                       = module.aws_site_a.app_subnet_ids
  desired_size                     = var.phase4_aws_node_desired_size
  min_size                         = var.phase4_aws_node_min_size
  max_size                         = var.phase4_aws_node_max_size
  instance_types                   = var.phase4_aws_node_instance_types
  capacity_type                    = var.phase4_aws_node_capacity_type
  disk_size                        = var.phase4_aws_node_disk_size
  ami_type                         = var.phase4_aws_node_ami_type
  labels                           = merge(var.phase4_aws_node_labels, { site = "site-a" })
  taints                           = var.phase4_aws_node_taints
  max_unavailable                  = var.phase4_aws_node_max_unavailable
  enable_ssm_managed_instance_core = var.phase4_aws_enable_ssm_managed_instance_core
  tags                             = local.common_tags

  depends_on = [
    aws_vpc_endpoint.phase4_site_a_interface,
    aws_vpc_endpoint.phase4_site_a_s3_gateway
  ]
}

module "aws_eks_nodegroup_site_b" {
  count  = local.phase4_capacity_enabled ? 1 : 0
  source = "./modules/aws_eks_nodegroup"

  providers = {
    aws = aws.site_b
  }

  site_name                        = "site-b"
  name_prefix                      = var.name_prefix
  environment                      = var.environment
  node_group_suffix                = "general"
  cluster_name                     = module.aws_eks_site_b[0].summary.cluster_name
  subnet_ids                       = module.aws_site_b.app_subnet_ids
  desired_size                     = var.phase4_aws_node_desired_size
  min_size                         = var.phase4_aws_node_min_size
  max_size                         = var.phase4_aws_node_max_size
  instance_types                   = var.phase4_aws_node_instance_types
  capacity_type                    = var.phase4_aws_node_capacity_type
  disk_size                        = var.phase4_aws_node_disk_size
  ami_type                         = var.phase4_aws_node_ami_type
  labels                           = merge(var.phase4_aws_node_labels, { site = "site-b" })
  taints                           = var.phase4_aws_node_taints
  max_unavailable                  = var.phase4_aws_node_max_unavailable
  enable_ssm_managed_instance_core = var.phase4_aws_enable_ssm_managed_instance_core
  tags                             = local.common_tags

  depends_on = [
    aws_vpc_endpoint.phase4_site_b_interface,
    aws_vpc_endpoint.phase4_site_b_s3_gateway
  ]
}

module "gcp_gke_node_pool_site_c" {
  count  = local.phase4_capacity_enabled ? 1 : 0
  source = "./modules/gcp_gke_node_pool"

  providers = {
    google = google.site_c
  }

  site_name                         = "site-c"
  name_prefix                       = var.name_prefix
  environment                       = var.environment
  node_pool_suffix                  = "general"
  location                          = var.gcp_site_c_region
  cluster_name                      = module.gcp_gke_site_c[0].summary.cluster_name
  machine_type                      = var.phase4_gcp_node_machine_type
  disk_size_gb                      = var.phase4_gcp_node_disk_size_gb
  disk_type                         = var.phase4_gcp_node_disk_type
  image_type                        = var.phase4_gcp_node_image_type
  spot                              = var.phase4_gcp_node_spot
  enable_autoscaling                = var.phase4_gcp_node_enable_autoscaling
  min_node_count                    = var.phase4_gcp_node_min_count
  max_node_count                    = var.phase4_gcp_node_max_count
  initial_node_count                = var.phase4_gcp_node_initial_count
  service_account                   = var.phase4_gcp_node_service_account
  node_labels                       = merge(var.phase4_gcp_node_labels, { site = "site-c" })
  node_tags                         = var.phase4_gcp_node_tags
  node_oauth_scopes                 = var.phase4_gcp_node_oauth_scopes
  disable_legacy_metadata_endpoints = var.phase4_gcp_node_disable_legacy_metadata_endpoints
  enable_secure_boot                = var.phase4_gcp_node_enable_secure_boot
  enable_integrity_monitoring       = var.phase4_gcp_node_enable_integrity_monitoring
  workload_metadata_mode            = var.phase4_gcp_node_workload_metadata_mode
}

module "gcp_gke_node_pool_site_d" {
  count  = local.phase4_capacity_enabled ? 1 : 0
  source = "./modules/gcp_gke_node_pool"

  providers = {
    google = google.site_d
  }

  site_name                         = "site-d"
  name_prefix                       = var.name_prefix
  environment                       = var.environment
  node_pool_suffix                  = "general"
  location                          = var.gcp_site_d_region
  cluster_name                      = module.gcp_gke_site_d[0].summary.cluster_name
  machine_type                      = var.phase4_gcp_node_machine_type
  disk_size_gb                      = var.phase4_gcp_node_disk_size_gb
  disk_type                         = var.phase4_gcp_node_disk_type
  image_type                        = var.phase4_gcp_node_image_type
  spot                              = var.phase4_gcp_node_spot
  enable_autoscaling                = var.phase4_gcp_node_enable_autoscaling
  min_node_count                    = var.phase4_gcp_node_min_count
  max_node_count                    = var.phase4_gcp_node_max_count
  initial_node_count                = var.phase4_gcp_node_initial_count
  service_account                   = var.phase4_gcp_node_service_account
  node_labels                       = merge(var.phase4_gcp_node_labels, { site = "site-d" })
  node_tags                         = var.phase4_gcp_node_tags
  node_oauth_scopes                 = var.phase4_gcp_node_oauth_scopes
  disable_legacy_metadata_endpoints = var.phase4_gcp_node_disable_legacy_metadata_endpoints
  enable_secure_boot                = var.phase4_gcp_node_enable_secure_boot
  enable_integrity_monitoring       = var.phase4_gcp_node_enable_integrity_monitoring
  workload_metadata_mode            = var.phase4_gcp_node_workload_metadata_mode
}
