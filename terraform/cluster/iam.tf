# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
# Author: Bradley Chatha

module "iam" {
  source = "../modules/iam"

  policies = {
    hashicorp_cloud_autojoin = {
      adhoc_statements = {
        AllowDescribeInstances = {
          actions   = ["ec2:DescribeInstances"]
          resources = ["*"]
        }
      }
    }

    consul_server = {
      secrets_read_only = [aws_secretsmanager_secret.cluster_consul_bootstrap_token.arn]
    }

    consul_client = {
      secrets_read_only = [aws_secretsmanager_secret.cluster_consul_client_token.arn]
    }

    boundary_server = {
      kms_key_arns = [
        aws_kms_key.keys["cluster-boundary-root"].arn,
        aws_kms_key.keys["cluster-boundary-worker-auth"].arn,
        aws_kms_key.keys["cluster-boundary-recovery"].arn,
        aws_kms_key.keys["cluster-boundary-config"].arn,
      ]

      secrets_read_only = [
        aws_secretsmanager_secret.cluster_boundary_rds_credentials.arn
      ]
    }

    boundary_client = {
      kms_key_arns = [
        aws_kms_key.keys["cluster-boundary-worker-auth"].arn,
      ]
    }

    boundary_client = {
      kms_key_arns = [
        aws_kms_key.keys["cluster-boundary-worker-auth"].arn,
      ]
    }
  }

  roles = {
    cluster_server = {
      service_role = true
      services     = ["ec2"]

      policies = [
        "hashicorp_cloud_autojoin",
        "consul_server"
      ]
    }

    cluster_client = {
      service_role = true
      services     = ["ec2"]

      policies = [
        "hashicorp_cloud_autojoin",
        "consul_client"
      ]
    }

    boundary_server = {
      service_role = true
      services     = ["ec2"]

      policies = [
        "boundary_server"
      ]
    }

    boundary_client = {
      service_role = true
      services     = ["ec2"]

      policies = [
        "boundary_client"
      ]
    }

    ansible_role_dev_server = {
      service_role = true
      services     = ["ec2"]

      policies = [
        "hashicorp_cloud_autojoin",
        "consul_server",
        "boundary_server"
      ]
    }

    ansible_role_dev_client = {
      service_role = true
      services     = ["ec2"]

      policies = [
        "hashicorp_cloud_autojoin",
        "consul_client",
        "boundary_client"
      ]
    }
  }
}
