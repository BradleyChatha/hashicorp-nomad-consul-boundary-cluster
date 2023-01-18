# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
# Author: Bradley Chatha

variable "cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "enable_bootstrap_bastion" {
  type    = bool
  default = true
}
