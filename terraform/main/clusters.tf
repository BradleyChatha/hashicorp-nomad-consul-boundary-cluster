module "cluster" {
  source                          = "../cluster"
  cidr                            = var.cidr
  enable_bootstrap_resources      = var.enable_bootstrap_resources
  root_domain_name                = var.root_domain_name
  allow_instant_delete_of_secrets = true
  ssh_cidr                        = var.ssh_cidr
}
