variable "name_prefix" {
  description = "Resource name prefix."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the cache security group is created."
  type        = string
}

variable "subnet_ids" {
  description = "Private data subnet IDs for the ElastiCache subnet group."
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "Application security group IDs allowed to connect to Redis."
  type        = map(string)

  validation {
    condition     = length(var.allowed_security_group_ids) > 0
    error_message = "At least one application security group must be allowed."
  }
}

variable "node_type" {
  description = "ElastiCache node type."
  type        = string
  default     = "cache.t4g.micro"
}

variable "engine_version" {
  description = "Redis engine version."
  type        = string
  default     = "7.1"
}

variable "snapshot_retention_limit" {
  description = "Days to retain automatic snapshots."
  type        = number
  default     = 7
}

variable "tags" {
  description = "Resource tags."
  type        = map(string)
  default     = {}
}
