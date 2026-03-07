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

variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
}

variable "subnet_ids" {
  description = "Subnets for node placement."
  type        = list(string)
}

variable "desired_size" {
  description = "Desired node count."
  type        = number
}

variable "min_size" {
  description = "Minimum node count."
  type        = number
}

variable "max_size" {
  description = "Maximum node count."
  type        = number
}

variable "instance_types" {
  description = "EC2 instance types used by the node group."
  type        = list(string)
  default     = ["t3.large"]
}

variable "capacity_type" {
  description = "Capacity type for nodes."
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.capacity_type)
    error_message = "capacity_type must be ON_DEMAND or SPOT."
  }
}

variable "disk_size" {
  description = "Root volume size in GiB."
  type        = number
  default     = 80
}

variable "ami_type" {
  description = "Optional EKS AMI type."
  type        = string
  default     = null
}

variable "labels" {
  description = "Kubernetes labels for nodes."
  type        = map(string)
  default     = {}
}

variable "taints" {
  description = "Optional Kubernetes taints."
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  default = []

  validation {
    condition = alltrue([
      for taint in var.taints :
      contains(["NO_SCHEDULE", "PREFER_NO_SCHEDULE", "NO_EXECUTE"], taint.effect)
    ])
    error_message = "Each taint.effect must be NO_SCHEDULE, PREFER_NO_SCHEDULE, or NO_EXECUTE."
  }
}

variable "max_unavailable" {
  description = "Maximum unavailable nodes during updates."
  type        = number
  default     = 1
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}
