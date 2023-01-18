variable "cidr" {
  type = string
}

variable "boundary_rds_backup_retention_period" {
  type    = number
  default = 0
}

variable "boundary_rds_instance_type" {
  type    = string
  default = "db.t4g.micro"
}

variable "enable_bootstrap_bastion" {
  type = bool
}
