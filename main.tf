module "networking" {
  source       = "./modules/networking"
  project_name = var.project_name
  region       = var.region
  my_ip_cidr   = var.my_ip_cidr
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

module "msk" {
  source            = "./modules/msk"
  project_name      = var.project_name
  subnet_ids        = module.networking.subnet_ids
  security_group_id = module.networking.lab_security_group_id
}

module "msk_connect" {
  source                     = "./modules/msk_connect"
  project_name               = var.project_name
  bootstrap_brokers          = module.msk.bootstrap_brokers_plaintext
  subnet_ids                 = module.networking.subnet_ids
  security_group_id          = module.networking.lab_security_group_id
  service_execution_role_arn = module.iam.msk_connect_role_arn
  db_host                    = module.rds.endpoint
  db_password                = var.db_password
}
