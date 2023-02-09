module "eks_example_complete" {
  source  = "terraform-aws-modules/eks/aws//examples/complete"
  version = var.version
}