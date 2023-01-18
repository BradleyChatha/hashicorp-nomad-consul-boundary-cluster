# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
# Author: Bradley Chatha

resource "aws_db_instance" "boundary" {
  allocated_storage         = 10
  backup_retention_period   = var.boundary_rds_backup_retention_period
  db_name                   = "boundary"
  db_subnet_group_name      = aws_db_subnet_group.boundary.name
  engine                    = "postgres"
  engine_version            = "14.5"
  final_snapshot_identifier = "boundary-FINAL-snapshot"
  identifier_prefix         = "boundary-${data.aws_region.current.name}"
  instance_class            = var.boundary_rds_instance_type
  multi_az                  = true
  password                  = random_password.boundary_initial_admin_password.result # Note: Bootstrapping will instantly change this
  port                      = 25432
  username                  = random_password.boundary_admin_username.result
  vpc_security_group_ids    = [aws_security_group.boundary_rds.id]
  kms_key_id                = aws_kms_key.boundary_rds_encryption_at_rest.arn
  storage_encrypted         = true
}

resource "aws_db_subnet_group" "boundary" {
  name_prefix = "boundary-${data.aws_region.current.name}"
  subnet_ids = [
    module.vpc.subnets.private_compute_1.id,
    module.vpc.subnets.private_compute_2.id,
    module.vpc.subnets.private_compute_3.id,
  ]
}

resource "random_password" "boundary_initial_admin_password" {
  length  = 32
  lower   = true
  upper   = true
  numeric = true
  special = false
}

resource "random_password" "boundary_admin_username" {
  length  = 32
  lower   = true
  upper   = true
  numeric = true
  special = false
}

resource "aws_kms_key" "boundary_rds_encryption_at_rest" {
  enable_key_rotation = true
}

resource "aws_security_group" "boundary_rds" {
  name_prefix = "boundary-rds-${data.aws_region.current.name}"
  vpc_id      = module.vpc.vpc.id

  ingress {
    cidr_blocks = [var.cidr]
    protocol    = "TCP"
    from_port   = 25432
    to_port     = 25432
  }

  egress {
    cidr_blocks = [var.cidr]
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
  }
}
