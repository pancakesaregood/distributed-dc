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
  description = "VPC ID that hosts the VDI stack."
  type        = string
}

variable "broker_ingress_ipv4_cidrs" {
  description = "IPv4 CIDRs allowed to reach the broker HTTPS endpoint."
  type        = list(string)
  default     = []
}

variable "broker_ingress_ipv6_cidrs" {
  description = "IPv6 CIDRs allowed to reach the broker HTTPS endpoint."
  type        = list(string)
  default     = []
}

variable "desktop_controlled_egress_ipv4_cidrs" {
  description = "IPv4 CIDRs that VDI desktops may reach for controlled update traffic."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "desktop_controlled_egress_ipv6_cidrs" {
  description = "IPv6 CIDRs that VDI desktops may reach for controlled update traffic."
  type        = list(string)
  default     = ["::/0"]
}

variable "identity_ssm_parameter_arn_patterns" {
  description = "SSM parameter ARN patterns that the VDI broker identity can read."
  type        = list(string)
  default     = ["arn:aws:ssm:*:*:parameter/ddc/vdi/*"]
}

variable "identity_secret_arn_patterns" {
  description = "Secrets Manager ARN patterns that the VDI broker identity can read."
  type        = list(string)
  default     = ["arn:aws:secretsmanager:*:*:secret:ddc-vdi-*"]
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}
