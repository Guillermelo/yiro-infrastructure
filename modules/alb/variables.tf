variable "allowed_ingress_cidrs" {
  description = "Approved public IPv4 CIDRs, including the on-premise Traefik proxy."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.allowed_ingress_cidrs : can(cidrnetmask(cidr))
    ])
    error_message = "Each entry must be a valid IPv4 CIDR."
  }
}

variable "domain_name" {
  description = "ALB certificate domain name."
  type        = string
}

variable "name_prefix" {
  description = "Resource name prefix."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs in two distinct AZs."
  type        = list(string)

  validation {
    condition = (
      length(var.public_subnet_ids) == 2 &&
      length(distinct(var.public_subnet_ids)) == 2
    )
    error_message = "Provide two distinct public subnet IDs."
  }
}

variable "backend_health_check_path" {
  description = "Backend HTTP health check path."
  type        = string
}

variable "sockets_health_check_path" {
  description = "Sockets HTTP health check path."
  type        = string
}

variable "tags" {
  description = "Resource tags."
  type        = map(string)
  default     = {}
}
