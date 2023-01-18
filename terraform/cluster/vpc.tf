module "vpc" {
  source = "../modules/vpc"
  cidr   = var.cidr
  subnets = {
    public_1 = { public = true, public_nat = true, cidr_newbits = 10, cidr_netnum = 0, availability_zone = "${data.aws_region.current.name}a" }
    public_2 = { public = true, public_nat = false, cidr_newbits = 10, cidr_netnum = 1, availability_zone = "${data.aws_region.current.name}b" }
    public_3 = { public = true, public_nat = false, cidr_newbits = 10, cidr_netnum = 2, availability_zone = "${data.aws_region.current.name}c" }

    private_compute_1 = { public = false, private_nat_subnet = "public_1", cidr_newbits = 3, cidr_netnum = 1, availability_zone = "${data.aws_region.current.name}a" }
    private_compute_2 = { public = false, private_nat_subnet = "public_1", cidr_newbits = 3, cidr_netnum = 2, availability_zone = "${data.aws_region.current.name}b" }
    private_compute_3 = { public = false, private_nat_subnet = "public_1", cidr_newbits = 3, cidr_netnum = 3, availability_zone = "${data.aws_region.current.name}c" }
  }
}
