data "aws_ami" "cluster_golden_image" {
  most_recent = true
  owners      = [data.aws_caller_identity.me.account_id]
  filter {
    name   = "name"
    values = ["cluster-golden*"]
  }
}
