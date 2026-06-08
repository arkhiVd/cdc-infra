module "networking" {
  source       = "./modules/networking"
  project_name = var.project_name
  region       = var.region
}

module "iam" {
  source       = "./modules/iam"
  project_name = var.project_name
}

module "rds" {
  source            = "./modules/rds"
  project_name      = var.project_name
  subnet_ids        = module.networking.subnet_ids
  security_group_id = module.networking.lab_security_group_id
  db_password       = var.db_password
}
