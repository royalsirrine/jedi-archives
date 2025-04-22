provider "google" {
  project = var.project_id
  region = var.region
}

module "network" {
  source = "./modules/network"
  vpc_name = "galaxy-vpc"
  network_cidr = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  region = var.region
  project_id = var.project_id
  domain_controller_ip = module.domain_controller.domain_controller_private_ip
  mid_server_instance_group_a = module.compute_instances.mid_server_instance_group_id
  mid_server_instance_group_b = module.compute_instances.mid_server_instance_group_b_id
}

module "firewall_rules" {
  source = "./modules/firewall_rules"
  vpc_id = module.network.vpc_id
}

module "compute_instances" {
  source = "./modules/compute_instances"
  public_subnet_ids = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids
  firewall_tags = module.firewall_rules.firewall_tags
  key_name = var.key_name
  instance_types = var.instance_types
  region = var.region
  project_id = var.project_id
  domain_controller_ip = module.domain_controller.domain_controller_private_ip
  mid_server_service_account = module.secret_manager.mid_server_service_account
}

module "domain_controller" {
  source = "./modules/domain_controller"
  private_subnet_id = module.network.private_subnet_ids[0]
  firewall_tags = [module.firewall_rules.firewall_tags["imperial_security"]]
  key_name = var.key_name
  region = var.region
  project_id = var.project_id
}

module "secret_manager" {
  source = "./modules/secret_manager"
  project_id = var.project_id
  environment = "hackathon"
}
