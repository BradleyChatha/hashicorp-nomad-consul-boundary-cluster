locals {
  enable_ansible_role_development_resources = 1
}

resource "tls_private_key" "dev_ssh" {
  count     = local.enable_ansible_role_development_resources
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_sensitive_file" "dev_ssh" {
  count           = local.enable_ansible_role_development_resources
  content         = tls_private_key.dev_ssh[0].private_key_openssh
  file_permission = 400
  filename        = "../../ansible/generated/dev_ssh.pem"
}

resource "aws_key_pair" "dev_ssh" {
  count           = local.enable_ansible_role_development_resources
  key_name_prefix = "bchatha-nomad-cluster-dev-ssh"
  public_key      = tls_private_key.dev_ssh[0].public_key_openssh
}

resource "aws_security_group" "dev_ssh" {
  count       = local.enable_ansible_role_development_resources
  name_prefix = "bchatha-nomad-cluster-dev-ssh"
  vpc_id      = module.vpc.vpc.id
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

resource "aws_instance" "dev_servers" {
  count                  = 3 * local.enable_ansible_role_development_resources
  ami                    = "ami-09394f54f125933d5"
  iam_instance_profile   = module.iam.instance_profiles.ansible_role_dev_server.name
  instance_type          = "t4g.micro"
  key_name               = aws_key_pair.dev_ssh[0].key_name
  subnet_id              = module.vpc.subnets.public_1.id
  vpc_security_group_ids = [aws_security_group.dev_ssh[0].id]

  tags = {
    "bchatha:cluster:nomad:role"    = "server"
    "bchatha:cluster:consul:role"   = "server"
    "bchatha:cluster:boundary:role" = "server"
  }
}

resource "aws_instance" "dev_clients" {
  count                  = 1 * local.enable_ansible_role_development_resources
  ami                    = "ami-09394f54f125933d5"
  iam_instance_profile   = module.iam.instance_profiles.ansible_role_dev_client.name
  instance_type          = "t4g.micro"
  key_name               = aws_key_pair.dev_ssh[0].key_name
  subnet_id              = module.vpc.subnets.public_1.id
  vpc_security_group_ids = [aws_security_group.dev_ssh[0].id]

  tags = {
    "bchatha:cluster:nomad:role"    = "client"
    "bchatha:cluster:consul:role"   = "client"
    "bchatha:cluster:boundary:role" = "client"
  }
}

resource "local_file" "dev_inventory" {
  count    = local.enable_ansible_role_development_resources
  filename = "../../ansible/generated/dev.inventory"
  content  = <<HERE
[servers]
%{for server in aws_instance.dev_servers}
${server.public_ip} ansible_connection=ssh ansible_user=admin ansible_ssh_private_key_file=generated/dev_ssh.pem 
%{endfor}
[clients]
%{for client in aws_instance.dev_clients}
${client.public_ip} ansible_connection=ssh ansible_user=admin ansible_ssh_private_key_file=generated/dev_ssh.pem 
%{endfor}
[bastion]
%{if var.enable_bootstrap_bastion}
${aws_instance.bootstrap_bastion[0].public_ip} ansible_connection=ssh ansible_user=admin ansible_ssh_private_key_file=generated/bootstrap_bastion_ssh_eu-west-1.pem f_postgres_username=${aws_db_instance.boundary.username} f_postgres_password=${aws_db_instance.boundary.password} f_postgres_host=${aws_db_instance.boundary.address} f_postgres_port=${aws_db_instance.boundary.port} f_postgres_db_name=${aws_db_instance.boundary.db_name}
%{endif}
[boundary_servers]
%{for server in aws_instance.dev_servers}
${server.public_ip} ansible_connection=ssh ansible_user=admin ansible_ssh_private_key_file=generated/dev_ssh.pem 
%{endfor}
  HERE
}
