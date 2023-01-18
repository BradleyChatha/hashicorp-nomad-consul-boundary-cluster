# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
# Author: Bradley Chatha

locals {
  ami_suffix = formatdate("YYYY-MM-DD-hhmmss", timestamp())
}

packer {
  required_plugins {
    amazon = {
      version = ">= 1.1.1"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "debian-eu-west-1" {
  ami_name                = "cluster-golden-${local.ami_suffix}"
  instance_type           = "t4g.micro"
  ssh_username            = "admin"
  region                  = "eu-west-1"
  temporary_key_pair_type = "ed25519"

  source_ami_filter {
    filters = {
      name             = "debian-11-arm64*"
      root-device-type = "ebs"
    }

    most_recent = true
    owners      = ["136693071363"]
  }
}

build {
  name = "cluster"
  sources = [
    "source.amazon-ebs.debian-eu-west-1",
  ]

  provisioner "ansible" {
    playbook_file = "./golden.ansible.yml"
    use_proxy     = false
  }
}