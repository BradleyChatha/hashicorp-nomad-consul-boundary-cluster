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

variable "enable_bootstrap_resources" {
  type = bool
}

variable "root_domain_name" {
  type = string
}

variable "allow_instant_delete_of_secrets" {
  type = bool
}

variable "ssh_cidr" {
  type = string
}
