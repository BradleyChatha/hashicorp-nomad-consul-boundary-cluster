# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
# Author: Bradley Chatha

resource "aws_launch_template" "golden" {
  credit_specification {
    cpu_credits = "standard"
  }

  iam_instance_profile {
    name = var.instance_profile_name
  }

  name_prefix                          = var.user_friendly_name
  key_name                             = var.dbg_ssh_key_name
  image_id                             = var.ami_id
  instance_initiated_shutdown_behavior = "terminate"
  vpc_security_group_ids               = [aws_security_group.asg.id]
  user_data                            = base64encode(var.user_data)
  update_default_version               = true
}

resource "aws_autoscaling_group" "asg" {
  name_prefix           = var.user_friendly_name
  capacity_rebalance    = true
  min_size              = var.stop_wasting_my_money ? 0 : var.min_size
  max_size              = var.stop_wasting_my_money ? 0 : var.max_size
  desired_capacity      = var.stop_wasting_my_money ? 0 : var.desired_capacity
  desired_capacity_type = "units"
  default_cooldown      = 15
  termination_policies  = ["OldestLaunchTemplate", "OldestInstance"]
  vpc_zone_identifier   = var.subnet_ids

  mixed_instances_policy {
    instances_distribution {
      spot_allocation_strategy = "capacity-optimized"
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.golden.id
      }

      dynamic "override" {
        for_each = var.instance_types
        content {
          instance_type     = override.key
          weighted_capacity = override.value
        }
      }
    }
  }
}

resource "aws_security_group" "asg" {
  name_prefix = var.user_friendly_name
  vpc_id      = var.vpc_id

  ingress {
    cidr_blocks = [var.cidr]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    description = "Allow all VPC ingress"
  }

  egress {
    cidr_blocks = [var.cidr]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    description = "Allow all VPC egress"
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    description = "Allow egress to entire internet"
  }

  dynamic "ingress" {
    for_each = var.dbg_ssh_key_name != null ? [1] : []
    content {
      cidr_blocks = ["0.0.0.0/0"]
      from_port   = 22
      to_port     = 22
      protocol    = "TCP"
      description = "DEBUG Allow SSH connections"
    }
  }

  dynamic "ingress" {
    for_each = var.public_ingress_ports
    content {
      cidr_blocks = ["0.0.0.0/0"]
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "TCP"
      description = "Public Ingress"
    }
  }
}
