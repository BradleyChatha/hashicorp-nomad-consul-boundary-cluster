resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge({
    Name = "bchatha-nomad-cluster"
  }, var.tags)
}

resource "aws_subnet" "subnets" {
  for_each                = var.subnets
  availability_zone       = each.value.availability_zone
  cidr_block              = cidrsubnet(var.cidr, each.value.cidr_newbits, each.value.cidr_netnum)
  map_public_ip_on_launch = each.value.public
  vpc_id                  = aws_vpc.vpc.id

  tags = merge({
    Name                        = "bchatha-nomad-cluster-${each.key}"
    "subnet:availability_zone"  = "${each.value.availability_zone}"
    "subnet:cidr_netnum"        = "${each.value.cidr_netnum}"
    "subnet:cidr_newbits"       = "${each.value.cidr_newbits}"
    "subnet:private_nat_subnet" = "${can(each.value.private_nat_subnet) ? each.value.private_nat_subnet : "N/A"}"
    "subnet:public"             = "${each.value.public}"
    "subnet:public_nat"         = "${each.value.public_nat}"
  }, var.tags)
}
