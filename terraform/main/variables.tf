variable "cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "enable_bootstrap_resources" {
  type    = bool
  default = true
}

variable "root_domain_name" {
  type    = string
  default = "chatha.dev"
}

variable "ssh_cidr" {
  type    = string
  default = "0.0.0.0/0"
}
