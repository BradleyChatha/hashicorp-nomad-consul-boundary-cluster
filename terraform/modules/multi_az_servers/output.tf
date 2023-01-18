# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
# Author: Bradley Chatha

output "ssh_key" {
  value = tls_private_key.ssh
}

output "ssh_key_filename" {
  value = local_sensitive_file.ssh.filename
}

output "servers" {
  value = aws_instance.servers
}
