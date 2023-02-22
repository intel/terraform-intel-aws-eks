provider "aws" {
  region = "us-west-2"
}

module "eks_example_complete" {
  source  = "terraform-aws-modules/eks/aws//examples/complete"
  version = "19.7.0"
}
