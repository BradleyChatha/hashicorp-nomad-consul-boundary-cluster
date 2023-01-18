locals {
  all_subnets_with_a_public_nat = { for k, v in var.subnets : k => v if v.public && v.public_nat }
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.vpc.id
  tags   = merge({}, var.tags)
}

resource "aws_nat_gateway" "gateways" {
  for_each      = local.all_subnets_with_a_public_nat
  allocation_id = aws_eip.nat_ips[each.key].id
  subnet_id     = aws_subnet.subnets[each.key].id

  tags = merge({
    Name = "bchatha-nomad-cluster-${each.key}"
  }, var.tags)
}

resource "aws_eip" "nat_ips" {
  for_each = local.all_subnets_with_a_public_nat
  tags     = merge({}, var.tags)
}
