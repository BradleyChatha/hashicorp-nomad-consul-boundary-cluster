locals {
  stop_wasting_my_money = true # Used just for development
}

module "nomad_consul_bootstrap_servers" {
  source                = "../modules/multi_az_servers"
  stop_wasting_my_money = !var.enable_bootstrap_resources || local.stop_wasting_my_money
  region_name           = data.aws_region.current.name
  name                  = "nomad-consul-bootstrap"
  ami                   = data.aws_ami.cluster_golden_image.id
  instance_profile_name = module.iam.instance_profiles.cluster_server.name
  instance_type         = "t4g.micro"
  roles                 = ["nomad", "consul"]
  vpc_id                = module.vpc.vpc.id
  subnet_ids = [
    module.vpc.subnets.public_1.id,
    module.vpc.subnets.public_2.id,
    module.vpc.subnets.public_3.id,
  ]

  user_data = <<-HERE
    #!/usr/bin/bash
    sudo bash /etc/bchatha/scripts/consul_as_server.sh
    sudo bash /etc/bchatha/scripts/nomad_as_server.sh
    sudo bash /etc/bchatha/scripts/consul_userdata.sh
    sudo bash /etc/bchatha/scripts/nomad_userdata.sh
  HERE
}

module "nomad_consul_servers" {
  source                = "../modules/asg"
  user_friendly_name    = "nomad-consul-servers"
  stop_wasting_my_money = !var.finished_bootstrapping || local.stop_wasting_my_money
  ami_id                = data.aws_ami.cluster_golden_image.id
  desired_capacity      = 3
  instance_profile_name = module.iam.instance_profiles.cluster_server.name
  max_size              = 6
  min_size              = 3
  vpc_id                = module.vpc.vpc.id
  cidr                  = var.cidr
  # dbg_ssh_key_name      = aws_key_pair.bootstrap_bastion_ssh[0].key_name
  subnet_ids = [
    module.vpc.subnets.private_compute_1.id,
    module.vpc.subnets.private_compute_2.id,
    module.vpc.subnets.private_compute_3.id,
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
  user_friendly_name    = "nomad-consul-clients"
  stop_wasting_my_money = local.stop_wasting_my_money
  ami_id                = data.aws_ami.cluster_golden_image.id
  desired_capacity      = 1
  instance_profile_name = module.iam.instance_profiles.cluster_client.name
  max_size              = 1
  min_size              = 1
  vpc_id                = module.vpc.vpc.id
  cidr                  = var.cidr
  # dbg_ssh_key_name      = aws_key_pair.bootstrap_bastion_ssh[0].key_name
  subnet_ids = [
    module.vpc.subnets.private_compute_1.id,
    module.vpc.subnets.private_compute_2.id,
    module.vpc.subnets.private_compute_3.id,
  ]
  instance_types = {
    "t4g.micro" = "1"
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
  source                = "../modules/multi_az_servers"
  stop_wasting_my_money = local.stop_wasting_my_money
  region_name           = data.aws_region.current.name
  name                  = "boundary"
  ami                   = data.aws_ami.cluster_golden_image.id
  instance_profile_name = module.iam.instance_profiles.boundary_server.name
  instance_type         = "t4g.micro"
  roles                 = ["boundary"]
  vpc_id                = module.vpc.vpc.id
  subnet_ids = [
    module.vpc.subnets.public_1.id,
    module.vpc.subnets.public_2.id,
    module.vpc.subnets.public_3.id,
  ]

  user_data = <<-HERE
    #!/usr/bin/bash
    sudo bash /etc/bchatha/scripts/boundary_as_server.sh
    sudo bash /etc/bchatha/scripts/boundary_userdata.sh
  HERE
}

module "boundary_clients" {
  source                = "../modules/asg"
  user_friendly_name    = "boundary-clients"
  stop_wasting_my_money = local.stop_wasting_my_money
  ami_id                = data.aws_ami.cluster_golden_image.id
  desired_capacity      = 1
  instance_profile_name = module.iam.instance_profiles.boundary_client.name
  max_size              = 1
  min_size              = 1
  vpc_id                = module.vpc.vpc.id
  cidr                  = var.cidr
  public_ingress_ports  = [9200]
  # dbg_ssh_key_name      = aws_key_pair.bootstrap_bastion_ssh[0].key_name
  subnet_ids = [
    module.vpc.subnets.public_1.id,
    module.vpc.subnets.public_2.id,
    module.vpc.subnets.public_3.id,
  ]
  instance_types = {
    "t4g.micro" = "1"
  }
  user_data = <<-HERE
    #!/usr/bin/bash
    sudo bash /etc/bchatha/scripts/boundary_as_server.sh
    sudo bash /etc/bchatha/scripts/consul_as_client.sh
    sudo bash /etc/bchatha/scripts/boundary_userdata.sh
    sudo bash /etc/bchatha/scripts/consul_userdata.sh
  HERE
}


module "ingress" {
  source                = "../modules/asg"
  user_friendly_name    = "ingress"
  stop_wasting_my_money = local.stop_wasting_my_money
  ami_id                = data.aws_ami.cluster_golden_image.id
  desired_capacity      = 1
  instance_profile_name = module.iam.instance_profiles.traefik.name
  max_size              = 1
  min_size              = 1
  vpc_id                = module.vpc.vpc.id
  cidr                  = var.cidr
  target_group_arn      = aws_lb_target_group.ingress.arn
  dbg_ssh_key_name      = aws_key_pair.bootstrap_bastion_ssh[0].key_name
  subnet_ids = [
    module.vpc.subnets.public_1.id,
    module.vpc.subnets.public_2.id,
    module.vpc.subnets.public_3.id,
  ]
  instance_types = {
    "t4g.micro" = "1"
  }
  user_data = <<-HERE
    #!/usr/bin/bash
    sudo bash /etc/bchatha/scripts/consul_as_client.sh
    sudo bash /etc/bchatha/scripts/consul_userdata.sh
    sudo bash /etc/bchatha/scripts/traefik_userdata.sh
  HERE
}
