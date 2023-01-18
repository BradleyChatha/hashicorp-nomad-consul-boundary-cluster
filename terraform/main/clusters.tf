# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
# Author: Bradley Chatha

module "cluster-eu-west-1" {
  source                   = "../cluster"
  cidr                     = var.cidr
  enable_bootstrap_bastion = var.enable_bootstrap_bastion
}
