variable "private_subnet_ids" {
  description = "Private application subnet IDs for the ASG."
  type        = list(string)
}

variable "target_group_arn" {
  description = "ALB target group ARN for this service."
  type        = string
}

variable "ami_id" {
  description = "Optional pinned AMI ID. Null uses the latest Amazon Linux 2023x86_64 AMI."
  type        = string
  default     = null
  nullable    = true
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.micro"
}

variable "min_size" {
  type    = number
  default = 1
}

variable "desired_capacity" {
  type    = number
  default = 1
}

variable "max_size" {
  type    = number
  default = 2
}

variable "health_check_type" {
  description = "ASG health check source. Use EC2 until the application serves its health endpoint."
  type        = string
  default     = "EC2"

  validation {
    condition     = contains(["EC2", "ELB"], var.health_check_type)
    error_message = "health_check_type must be EC2 or ELB."
  }
}

variable "root_volume_size" {
  type    = number
  default = 20
}

variable "user_data" {
  description = "Optional cloud-init/bash bootstrap script."
  type        = string
  default     = null
  nullable    = true
}

variable "name_prefix" {
  description = "Resource name prefix."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID."
  type        = string
}

variable "alb_security_group_id" {
  description = "ALB security group ID."
  type        = string
}

variable "app_port" {
  description = "Published application port."
  type        = number
}

variable "tags" {
  description = "Resource tags."
  type        = map(string)
  default     = {}
}
