# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
# Author: Bradley Chatha

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_sensitive_file" "ssh" {
  content         = tls_private_key.ssh.private_key_openssh
  file_permission = 400
  filename        = "../../ansible/generated/${var.name}_ssh_${var.region_name}.pem"
}

resource "aws_key_pair" "ssh" {
  key_name_prefix = "${var.name}-${var.region_name}"
  public_key      = tls_private_key.ssh.public_key_openssh
}

resource "aws_security_group" "ssh" {
  name_prefix = "${var.name}-${var.region_name}"
  vpc_id      = var.vpc_id
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    description = "INSECURE Allows SSH ingress from any IP"
  }

  ingress {
    cidr_blocks = ["10.0.0.0/8"]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    description = "INSECURE Allows all ingress from VPC"
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    description = "INSECURE Allows all egerss to any IP"
  }
}

resource "aws_instance" "servers" {
  for_each               = var.stop_wasting_my_money ? [] : var.subnet_ids
  ami                    = var.ami
  iam_instance_profile   = var.instance_profile_name
  instance_type          = var.instance_type
  key_name               = aws_key_pair.ssh.key_name
  subnet_id              = each.value
  vpc_security_group_ids = [aws_security_group.ssh.id]
  user_data              = var.user_data

  tags = { for v in var.roles : "bchatha:cluster:${v}:role" => var.role }
}
