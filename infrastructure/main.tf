# Calls reusable network and security modules

module "network" {
  source = "./modules/network"

  name                 = local.name
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  db_subnet_cidrs      = var.db_subnet_cidrs
  tags                 = local.common_tags
}


module "security" {
  source = "./modules/security"

  name              = local.name
  vpc_id            = module.network.vpc_id
  alb_ingress_cidrs = var.alb_ingress_cidrs
  frontend_port     = var.frontend_container_port
  backend_port      = var.backend_container_port
  db_port           = var.db_port
  tags              = local.common_tags
}