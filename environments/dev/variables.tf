variable "allowed_ingress_cidrs" {
  description = "Approved public IPv4 CIDRs for ALB access."
  type        = list(string)
  default     = []
}

variable "alb_domain_name" {
  description = "ALB certificate domain name."
  type        = string
}

variable "aws_region" {
  description = "AWS deployment region."
  type        = string
}

variable "vpc_cidr" {
  description = "VPC IPv4 /20 CIDR."
  type        = string
}

variable "availability_zones" {
  description = "Two AZs in the selected region; keep their order stable."
  type        = list(string)
}

variable "project_name" {
  description = "Short project name."
  type        = string
}

variable "backend_health_check_path" {
  description = "Backend HTTP health check path."
  type        = string
}

variable "sockets_health_check_path" {
  description = "Sockets HTTP health check path."
  type        = string
}

variable "additional_tags" {
  description = "Additional environment resource tags."
  type        = map(string)
  default     = {}
}

variable "backend_instance_type" {
  description = "EC2 instance type for the backend ASG."
  type        = string
  default     = "t3.micro"
}

variable "sockets_instance_type" {
  description = "EC2 instance type for the sockets ASG."
  type        = string
  default     = "t3.micro"
}

variable "cache_node_type" {
  description = "ElastiCache node type for Redis."
  type        = string
  default     = "cache.t4g.micro"
}

variable "cache_engine_version" {
  description = "Redis engine version for ElastiCache."
  type        = string
  default     = "7.1"
}

variable "cache_snapshot_retention_limit" {
  description = "Number of days to retain Redis snapshots."
  type        = number
  default     = 7
}
