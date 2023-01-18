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
