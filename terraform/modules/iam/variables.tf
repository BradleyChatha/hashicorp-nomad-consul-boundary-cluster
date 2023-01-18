# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
# Author: Bradley Chatha

variable "policies" {
  type = map(object({
    secrets_read_only = optional(set(string), [])
    kms_key_arns      = optional(set(string), [])
    adhoc_statements = optional(map(object({
      actions   = set(string)
      resources = set(string)
    })), {})
  }))
}

variable "roles" {
  type = map(object({
    policies     = set(string)
    services     = set(string)
    service_role = optional(bool, false)
  }))
}
