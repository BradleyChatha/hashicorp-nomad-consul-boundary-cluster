# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
# Author: Bradley Chatha

data "aws_ami" "cluster_golden_image" {
  most_recent = true
  owners      = [data.aws_caller_identity.me.account_id]
  filter {
    name   = "name"
    values = ["cluster-golden*"]
  }
}
