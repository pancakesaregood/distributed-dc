output "vpc_id" {
  description = "VPC ID."
  value       = aws_vpc.this.id
}

output "vpc_ipv4_cidr" {
  description = "VPC IPv4 CIDR."
  value       = aws_vpc.this.cidr_block
}

output "vpc_ipv6_cidr" {
  description = "VPC IPv6 CIDR."
  value       = aws_vpc.this.ipv6_cidr_block
}

output "availability_zones" {
  description = "AZs used by this site."
  value       = local.azs
}

output "ingress_subnet_ids" {
  description = "Ingress subnet IDs."
  value = [
    aws_subnet.tier["ingress-a"].id,
    aws_subnet.tier["ingress-b"].id
  ]
}

output "app_subnet_ids" {
  description = "App subnet IDs."
  value = [
    aws_subnet.tier["app-a"].id,
    aws_subnet.tier["app-b"].id
  ]
}

output "data_subnet_ids" {
  description = "Data subnet IDs."
  value = [
    aws_subnet.tier["data-a"].id,
    aws_subnet.tier["data-b"].id
  ]
}
