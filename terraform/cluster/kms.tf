locals {
  kms_key_names = [
    "cluster-boundary-root",
    "cluster-boundary-worker-auth",
    "cluster-boundary-recovery",
    "cluster-boundary-config",
  ]
}

resource "aws_kms_key" "keys" {
  for_each            = { for v in local.kms_key_names : v => 0 }
  enable_key_rotation = true
}

resource "aws_kms_alias" "aliases" {
  for_each      = { for v in local.kms_key_names : v => 0 }
  target_key_id = aws_kms_key.keys[each.key].id
  name          = "alias/${each.key}"
}
