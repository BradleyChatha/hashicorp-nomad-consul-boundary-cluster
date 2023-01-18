# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
# Author: Bradley Chatha

locals {
  all_private_subnets_wanting_nat = { for k, v in var.subnets : k => v if !v.public && can(v.private_nat_subnet) }
}

resource "aws_route_table" "tables" {
  for_each = var.subnets
  vpc_id   = aws_vpc.vpc.id
  tags = merge({
    Name = "bchatha-nomad-cluster-${each.key}"
  }, var.tags)
}

resource "aws_route_table_association" "associations" {
  for_each       = var.subnets
  route_table_id = aws_route_table.tables[each.key].id
  subnet_id      = aws_subnet.subnets[each.key].id
}

resource "aws_route" "public_to_internet_gateway_routes" {
  for_each               = { for k, v in var.subnets : k => v if v.public }
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gateway.id
  route_table_id         = aws_route_table.tables[each.key].id
}

resource "aws_route" "private_to_nat_gateway_routes" {
  for_each               = local.all_private_subnets_wanting_nat
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.gateways[each.value.private_nat_subnet].id
  route_table_id         = aws_route_table.tables[each.key].id
}
