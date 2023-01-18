module "cluster-eu-west-1" {
  source                   = "../cluster"
  cidr                     = var.cidr
  enable_bootstrap_bastion = var.enable_bootstrap_bastion
}
