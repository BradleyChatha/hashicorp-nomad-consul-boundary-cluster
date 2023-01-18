# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
# Author: Bradley Chatha

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
