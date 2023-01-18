variable "cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "enable_bootstrap_bastion" {
  type    = bool
  default = true
}
