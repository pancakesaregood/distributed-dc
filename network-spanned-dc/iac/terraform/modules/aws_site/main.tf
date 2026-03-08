data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)

  base_name = "${var.name_prefix}-${var.environment}-${var.site_name}"

  tiers = {
    ingress = {
      subnet_offsets = [0, 1]
    }
    app = {
      subnet_offsets = [2, 3]
    }
    data = {
      subnet_offsets = [4, 5]
    }
    vdi = {
      subnet_offsets = [6, 7]
    }
  }

  subnet_plan = merge(
    {
      for tier, cfg in local.tiers :
      "${tier}-a" => {
        tier      = tier
        az        = local.azs[0]
        ipv4_cidr = cidrsubnet(var.ipv4_cidr, 4, cfg.subnet_offsets[0])
        ipv6_cidr = cidrsubnet(aws_vpc.this.ipv6_cidr_block, 8, cfg.subnet_offsets[0])
      }
    },
    {
      for tier, cfg in local.tiers :
      "${tier}-b" => {
        tier      = tier
        az        = local.azs[1]
        ipv4_cidr = cidrsubnet(var.ipv4_cidr, 4, cfg.subnet_offsets[1])
        ipv6_cidr = cidrsubnet(aws_vpc.this.ipv6_cidr_block, 8, cfg.subnet_offsets[1])
      }
    }
  )

  ingress_subnet_keys = [
    for subnet_key, subnet in local.subnet_plan :
    subnet_key if subnet.tier == "ingress"
  ]
}

resource "aws_vpc" "this" {
  cidr_block                       = var.ipv4_cidr
  enable_dns_support               = true
  enable_dns_hostnames             = true
  assign_generated_ipv6_cidr_block = true

  tags = merge(
    var.tags,
    {
      Name      = "${local.base_name}-vpc"
      site      = var.site_name
      region    = var.region
      ipv6_ula  = var.ipv6_ula
      component = "network"
    }
  )
}

resource "aws_subnet" "tier" {
  for_each = local.subnet_plan

  vpc_id                          = aws_vpc.this.id
  availability_zone               = each.value.az
  cidr_block                      = each.value.ipv4_cidr
  ipv6_cidr_block                 = each.value.ipv6_cidr
  assign_ipv6_address_on_creation = true

  tags = merge(
    var.tags,
    {
      Name      = "${local.base_name}-${each.key}"
      site      = var.site_name
      tier      = each.value.tier
      az        = each.value.az
      component = "subnet"
    }
  )
}

resource "aws_internet_gateway" "ingress" {
  count = var.enable_ingress_internet_edge ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    {
      Name      = "${local.base_name}-ingress-igw"
      site      = var.site_name
      component = "ingress-internet-edge"
    }
  )
}

resource "aws_route_table" "ingress_public" {
  count = var.enable_ingress_internet_edge ? 1 : 0

  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ingress[0].id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.ingress[0].id
  }

  tags = merge(
    var.tags,
    {
      Name      = "${local.base_name}-ingress-public-rt"
      site      = var.site_name
      component = "ingress-internet-edge"
    }
  )
}

resource "aws_route_table_association" "ingress_public" {
  for_each = var.enable_ingress_internet_edge ? {
    for subnet_key in local.ingress_subnet_keys :
    subnet_key => aws_subnet.tier[subnet_key].id
  } : {}

  subnet_id      = each.value
  route_table_id = aws_route_table.ingress_public[0].id
}
