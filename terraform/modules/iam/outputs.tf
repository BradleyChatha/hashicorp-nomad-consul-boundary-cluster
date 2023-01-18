# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
# Author: Bradley Chatha

output "roles" {
  value = aws_iam_role.roles
}

output "instance_profiles" {
  value = aws_iam_instance_profile.profiles
}
