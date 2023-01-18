provider "aws" {
  default_tags {
    tags = {
      "provision:tool"    = "terraform"
      "provision:project" = "bchatha_nomad_cluster"
    }
  }
}
