terraform {
  backend "s3" {
    key = "terraform/nomad_cluster.tfstate"
  }
}
