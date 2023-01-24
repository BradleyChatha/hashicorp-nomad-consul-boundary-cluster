locals {
  stop_wasting_my_money = false                   # Used just for development
  use_dev_ami           = false                   # Used just for development
  dev_ami               = "ami-09394f54f125933d5" # Debian Bullseye eu-west-1
}

resource "tls_private_key" "cluster_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_sensitive_file" "cluster_ssh" {
  content         = tls_private_key.cluster_ssh.private_key_openssh
  file_permission = 400
  filename        = "../../ansible/generated/cluster_ssh_${data.aws_region.current.name}.pem"
}

resource "aws_key_pair" "cluster_ssh" {
  key_name_prefix = "bchatha-nomad-cluster-ssh"
  public_key      = tls_private_key.cluster_ssh.public_key_openssh
}

module "nomad_consul_servers" {
  source                = "../modules/asg"
  user_friendly_name    = "nomad-consul-servers"
  stop_wasting_my_money = local.stop_wasting_my_money
  ami_id                = local.use_dev_ami ? local.dev_ami : data.aws_ami.cluster_golden_image.id
  desired_capacity      = 3
  instance_profile_name = module.iam.instance_profiles.cluster_server.name
  max_size              = 6
  min_size              = 3
  vpc_id                = module.vpc.vpc.id
  cidr                  = var.cidr
  ssh_key_name          = aws_key_pair.cluster_ssh.key_name
  ssh_cidr              = var.ssh_cidr
  subnet_ids = [
    module.vpc.subnets.public_1.id,
    module.vpc.subnets.public_2.id,
    module.vpc.subnets.public_3.id,
  ]
  instance_types = {
    "t4g.micro" = "1"
  }
  instance_tags = {
    "bchatha:cluster:nomad:role"  = "server"
    "bchatha:cluster:consul:role" = "server"
  }
  user_data = <<-HERE
    #!/usr/bin/bash
    sudo bash /etc/bchatha/scripts/consul_as_server.sh
    sudo bash /etc/bchatha/scripts/nomad_as_server.sh
    sudo bash /etc/bchatha/scripts/consul_userdata.sh
    sudo bash /etc/bchatha/scripts/nomad_userdata.sh
  HERE
}

module "nomad_consul_clients" {
  source                = "../modules/asg"
  stop_wasting_my_money = local.stop_wasting_my_money
  user_friendly_name    = "nomad-consul-clients"
  ami_id                = local.use_dev_ami ? local.dev_ami : data.aws_ami.cluster_golden_image.id
  desired_capacity      = 1
  instance_profile_name = module.iam.instance_profiles.cluster_client.name
  max_size              = 1
  min_size              = 1
  vpc_id                = module.vpc.vpc.id
  cidr                  = var.cidr
  ssh_key_name          = local.use_dev_ami ? aws_key_pair.cluster_ssh.key_name : null
  ssh_cidr              = local.use_dev_ami ? var.ssh_cidr : ""
  subnet_ids = local.use_dev_ami ? [module.vpc.subnets.public_1.id] : [
    module.vpc.subnets.private_compute_1.id,
    module.vpc.subnets.private_compute_2.id,
    module.vpc.subnets.private_compute_3.id,
  ]
  instance_types = {
    "t4g.micro" = "1"
  }
  instance_tags = {
    "bchatha:cluster:nomad:role"  = "client"
    "bchatha:cluster:consul:role" = "client"
  }
  user_data = <<-HERE
    #!/usr/bin/bash
    sudo bash /etc/bchatha/scripts/consul_as_client.sh
    sudo bash /etc/bchatha/scripts/nomad_as_client.sh
    sudo bash /etc/bchatha/scripts/consul_userdata.sh
    sudo bash /etc/bchatha/scripts/nomad_userdata.sh
  HERE
}

module "boundary_servers" {
  source                = "../modules/asg"
  user_friendly_name    = "boundary-servers"
  stop_wasting_my_money = local.stop_wasting_my_money
  ami_id                = local.use_dev_ami ? local.dev_ami : data.aws_ami.cluster_golden_image.id
  desired_capacity      = 3
  instance_profile_name = module.iam.instance_profiles.boundary_server.name
  max_size              = 6
  min_size              = 3
  vpc_id                = module.vpc.vpc.id
  cidr                  = var.cidr
  ssh_key_name          = aws_key_pair.cluster_ssh.key_name
  ssh_cidr              = var.ssh_cidr
  subnet_ids = [
    module.vpc.subnets.public_1.id,
    module.vpc.subnets.public_2.id,
    module.vpc.subnets.public_3.id,
  ]
  instance_types = {
    "t4g.micro" = "1"
  }
  instance_tags = {
    "bchatha:cluster:boundary:role" = "server"
  }

  user_data = <<-HERE
    #!/usr/bin/bash
    sudo bash /etc/bchatha/scripts/boundary_as_server.sh
    sudo bash /etc/bchatha/scripts/consul_as_client.sh
    sudo bash /etc/bchatha/scripts/boundary_userdata.sh
    sudo bash /etc/bchatha/scripts/consul_userdata.sh
  HERE
}

module "boundary_clients" {
  source                = "../modules/asg"
  user_friendly_name    = "boundary-clients"
  stop_wasting_my_money = local.stop_wasting_my_money
  ami_id                = local.use_dev_ami ? local.dev_ami : data.aws_ami.cluster_golden_image.id
  desired_capacity      = 1
  instance_profile_name = module.iam.instance_profiles.boundary_client.name
  max_size              = 1
  min_size              = 1
  vpc_id                = module.vpc.vpc.id
  cidr                  = var.cidr
  public_ingress_ports  = [9202]
  ssh_key_name          = aws_key_pair.cluster_ssh.key_name
  ssh_cidr              = var.ssh_cidr
  subnet_ids = [
    module.vpc.subnets.public_1.id,
    module.vpc.subnets.public_2.id,
    module.vpc.subnets.public_3.id,
  ]
  instance_types = {
    "t4g.micro" = "1"
  }
  instance_tags = {
    "bchatha:cluster:boundary:role" = "client"
  }
  user_data = <<-HERE
    #!/usr/bin/bash
    sudo bash /etc/bchatha/scripts/boundary_as_client.sh
    sudo bash /etc/bchatha/scripts/consul_as_client.sh
    sudo bash /etc/bchatha/scripts/boundary_userdata.sh
    sudo bash /etc/bchatha/scripts/consul_userdata.sh
  HERE
}


module "ingress" {
  source                = "../modules/asg"
  user_friendly_name    = "ingress"
  stop_wasting_my_money = local.stop_wasting_my_money
  ami_id                = local.use_dev_ami ? local.dev_ami : data.aws_ami.cluster_golden_image.id
  desired_capacity      = 1
  instance_profile_name = module.iam.instance_profiles.traefik.name
  max_size              = 1
  min_size              = 1
  vpc_id                = module.vpc.vpc.id
  cidr                  = var.cidr
  target_group_arn      = aws_lb_target_group.ingress.arn
  ssh_key_name          = aws_key_pair.cluster_ssh.key_name
  ssh_cidr              = var.ssh_cidr
  subnet_ids = [
    module.vpc.subnets.public_1.id,
    module.vpc.subnets.public_2.id,
    module.vpc.subnets.public_3.id,
  ]
  instance_types = {
    "t4g.micro" = "1"
  }
  instance_tags = {
    "bchatha:cluster:ingress:role" = "ingress"
  }
  user_data = <<-HERE
    #!/usr/bin/bash
    sudo bash /etc/bchatha/scripts/consul_as_client.sh
    sudo bash /etc/bchatha/scripts/consul_userdata.sh
    sudo bash /etc/bchatha/scripts/traefik_userdata.sh
  HERE
}
