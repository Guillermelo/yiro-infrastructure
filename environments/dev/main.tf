module "project_metadata" {
  source = "../../modules/project-metadata"

  project_name    = var.project_name
  environment     = "dev"
  additional_tags = var.additional_tags
}

module "network" {
  source = "../../modules/network"

  project_name       = var.project_name
  environment        = "dev"
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  tags               = module.project_metadata.tags
}

module "alb" {
  source = "../../modules/alb"

  domain_name           = var.alb_domain_name
  allowed_ingress_cidrs = var.allowed_ingress_cidrs

  name_prefix       = module.project_metadata.name_prefix
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids

  backend_health_check_path = var.backend_health_check_path
  sockets_health_check_path = var.sockets_health_check_path

  tags = module.project_metadata.tags
}

module "backend_asg" {
  source = "../../modules/app-asg"

  name_prefix           = "${module.project_metadata.name_prefix}-backend"
  vpc_id                = module.network.vpc_id
  alb_security_group_id = module.alb.security_group_id
  private_subnet_ids    = module.network.private_app_subnet_ids
  target_group_arn      = module.alb.target_group_arns.backend
  app_port              = 5001

  instance_type     = var.backend_instance_type
  min_size          = 1
  desired_capacity  = 1
  max_size          = 2
  health_check_type = "EC2"

  tags = module.project_metadata.tags
}

module "sockets_asg" {
  source = "../../modules/app-asg"

  name_prefix           = "${module.project_metadata.name_prefix}-sockets"
  vpc_id                = module.network.vpc_id
  alb_security_group_id = module.alb.security_group_id
  private_subnet_ids    = module.network.private_app_subnet_ids
  target_group_arn      = module.alb.target_group_arns.sockets
  app_port              = 5004

  instance_type     = var.sockets_instance_type
  min_size          = 1
  desired_capacity  = 1
  max_size          = 2
  health_check_type = "EC2"

  tags = module.project_metadata.tags
}
