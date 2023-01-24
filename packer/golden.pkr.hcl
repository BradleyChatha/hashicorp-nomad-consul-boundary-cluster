locals {
  ami_suffix = formatdate("YYYY-MM-DD-hhmmss", timestamp())
}

variable "ansible_extra_arguments" {
  type    = list(string)
  default = []
}

variable "region" {
  type = string
  default = "eu-west-1"
}

packer {
  required_plugins {
    amazon = {
      version = ">= 1.1.1"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "debian" {
  ami_name                = "cluster-golden-${local.ami_suffix}"
  instance_type           = "t4g.micro"
  ssh_username            = "admin"
  region                  = var.region
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
  name = "golden"
  sources = [
    "source.amazon-ebs.debian",
  ]

  provisioner "ansible" {
    playbook_file = "./golden.ansible.yml"
    use_proxy     = false
    extra_arguments = concat([
      "--extra-vars", "v_nomad_region=${var.region}",
      "--extra-vars", "v_consul_datacenter=${var.region}",
    ], var.ansible_extra_arguments)
  }
}