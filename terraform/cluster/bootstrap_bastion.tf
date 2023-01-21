resource "tls_private_key" "bootstrap_bastion_ssh" {
  count     = var.enable_bootstrap_resources ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_sensitive_file" "bootstrap_bastion_ssh" {
  count           = var.enable_bootstrap_resources ? 1 : 0
  content         = tls_private_key.bootstrap_bastion_ssh[0].private_key_openssh
  file_permission = 400
  filename        = "../../ansible/generated/bootstrap_bastion_ssh_${data.aws_region.current.name}.pem"
}

resource "aws_key_pair" "bootstrap_bastion_ssh" {
  count           = var.enable_bootstrap_resources ? 1 : 0
  key_name_prefix = "bchatha-nomad-cluster-bootstrap-bastion"
  public_key      = tls_private_key.bootstrap_bastion_ssh[0].public_key_openssh
}

resource "aws_security_group" "bootstrap_bastion_ssh" {
  count       = var.enable_bootstrap_resources ? 1 : 0
  name_prefix = "bchatha-nomad-cluster-bootstrap-bastion"
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

resource "aws_instance" "bootstrap_bastion" {
  count                  = var.enable_bootstrap_resources ? 1 : 0
  ami                    = "ami-09394f54f125933d5"
  instance_type          = "t4g.micro"
  key_name               = aws_key_pair.bootstrap_bastion_ssh[0].key_name
  subnet_id              = module.vpc.subnets.public_1.id
  vpc_security_group_ids = [aws_security_group.bootstrap_bastion_ssh[0].id]

  tags = {
    "bchatha:cluster:role" = "server"
  }
}
