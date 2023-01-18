# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
# Author: Bradley Chatha

variable "ami_id" {
  type = string
}

variable "instance_types" {
  type = map(string)
}

variable "instance_profile_name" {
  type = string
}

variable "user_data" {
  type = string
}

variable "min_size" {
  type = number
}

variable "max_size" {
  type = number
}

variable "desired_capacity" {
  type = number
}

variable "stop_wasting_my_money" {
  type = bool
}

variable "subnet_ids" {
  type = set(string)
}

variable "vpc_id" {
  type = string
}

variable "cidr" {
  type = string
}

variable "dbg_ssh_key_name" {
  type    = any # string or null
  default = null
}

variable "user_friendly_name" {
  type = string
}

variable "public_ingress_ports" {
  type    = set(string)
  default = []
}
