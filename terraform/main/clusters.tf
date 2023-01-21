module "cluster-eu-west-1" {
  source                     = "../cluster"
  cidr                       = var.cidr
  enable_bootstrap_resources = var.enable_bootstrap_resources
  finished_bootstrapping     = var.finished_bootstrapping
  root_domain_name           = var.root_domain_name
}
