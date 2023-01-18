variable "region_name" {
  type = string
}

variable "name" {
  type = string
}

variable "ami" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "subnet_ids" {
  type = set(string)
}

variable "roles" {
  type = set(string)
}

variable "vpc_id" {
  type = string
}

variable "user_data" {
  type = string
}

variable "instance_profile_name" {
  type = string
}

variable "stop_wasting_my_money" {
  type = bool
}

variable "role" {
  type    = string
  default = "server"
}