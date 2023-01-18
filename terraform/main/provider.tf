# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
# Author: Bradley Chatha

provider "aws" {
  default_tags {
    tags = {
      "provision:tool"    = "terraform"
      "provision:project" = "bchatha_nomad_cluster"
    }
  }
}
