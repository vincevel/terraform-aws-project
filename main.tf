module "network" {
  source = "./modules/network"

  availability_zone = "${var.aws_region}a"
  allowed_ssh_cidr  = var.allowed_ssh_cidr
  environment       = var.environment
}

module "compute" {
  source = "./modules/compute"

  subnet_id         = module.network.subnet_id
  security_group_id = module.network.security_group_id
  instance_type     = var.instance_type
  public_key_path   = "~/.ssh/terraform-project-key.pub"
  environment       = var.environment
}
