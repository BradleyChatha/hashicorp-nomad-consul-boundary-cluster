locals {
  flat_list_of_role_policy_mappings = flatten([for k, v in var.roles : [for p in v.policies : { role : k, policy : p }]])
  flat_list_of_user_policy_mappings = flatten([for k, v in var.users : [for p in v.policies : { user : k, policy : p }]])
}

resource "aws_iam_policy" "policies" {
  for_each    = var.policies
  name_prefix = each.key
  policy      = data.aws_iam_policy_document.documents[each.key].json
}

data "aws_iam_policy_document" "documents" {
  for_each = var.policies

  dynamic "statement" {
    for_each = each.value.adhoc_statements
    content {
      actions   = statement.value.actions
      resources = statement.value.resources
      sid       = statement.key
    }
  }

  dynamic "statement" {
    for_each = length(each.value.secrets_read_only) > 0 ? [1] : []
    content {
      actions   = ["secretsmanager:GetSecretValue"]
      resources = each.value.secrets_read_only
      sid       = "SecretsReadOnly"
    }
  }

  dynamic "statement" {
    for_each = length(each.value.kms_key_arns) > 0 ? [1] : []
    content {
      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:DescribeKey",
      ]
      resources = each.value.kms_key_arns
      sid       = "KMSUsage"
    }
  }
}

resource "aws_iam_role" "roles" {
  for_each           = var.roles
  name_prefix        = each.key
  assume_role_policy = data.aws_iam_policy_document.assume_role_policies[each.key].json
}

data "aws_iam_policy_document" "assume_role_policies" {
  for_each = var.roles

  statement {
    actions = ["sts:AssumeRole"]

    dynamic "principals" {
      for_each = length(each.value.services) > 0 ? [1] : []
      content {
        type        = "Service"
        identifiers = toset([for v in each.value.services : "${v}.amazonaws.com"])
      }
    }
  }
}

resource "aws_iam_role_policy_attachment" "role_policies" {
  count      = length(local.flat_list_of_role_policy_mappings)
  role       = aws_iam_role.roles[local.flat_list_of_role_policy_mappings[count.index].role].id
  policy_arn = aws_iam_policy.policies[local.flat_list_of_role_policy_mappings[count.index].policy].arn
}

resource "aws_iam_instance_profile" "profiles" {
  for_each    = { for k, v in var.roles : k => v if v.service_role }
  name_prefix = each.key
  role        = aws_iam_role.roles[each.key].name
}

resource "aws_iam_user" "users" {
  for_each = var.users
  name     = "${each.key}-${data.aws_region.current.name}"
}

resource "aws_iam_user_policy_attachment" "user_policies" {
  count      = length(local.flat_list_of_user_policy_mappings)
  user       = aws_iam_user.users[local.flat_list_of_user_policy_mappings[count.index].user].id
  policy_arn = aws_iam_policy.policies[local.flat_list_of_user_policy_mappings[count.index].policy].arn
}
