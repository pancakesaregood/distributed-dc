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

variable "vpc_id" {
  description = "VPC ID that hosts the published app path."
  type        = string
}

variable "ingress_subnet_ids" {
  description = "Subnet IDs used by the internet-facing ALB."
  type        = list(string)
}

variable "listener_port" {
  description = "Inbound HTTP listener port."
  type        = number
  default     = 80
}

variable "allowed_ingress_ipv4_cidrs" {
  description = "Allowed IPv4 CIDRs for client ingress traffic."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_ingress_ipv6_cidrs" {
  description = "Allowed IPv6 CIDRs for client ingress traffic."
  type        = list(string)
  default     = ["::/0"]
}

variable "health_check_path" {
  description = "HTTP health check path used for backend gating."
  type        = string
  default     = "/healthz"
}

variable "backend_target_port" {
  description = "Backend application port for target registration and health checks."
  type        = number
  default     = 80
}

variable "backend_ipv4_targets" {
  description = "IPv4 backend targets registered in the ALB target group."
  type        = list(string)
  default     = []
}

variable "waf_rate_limit" {
  description = "Per-5-minute IP request threshold for WAF rate limiting."
  type        = number
  default     = 2000
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}
