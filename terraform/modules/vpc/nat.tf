# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
# Author: Bradley Chatha

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
