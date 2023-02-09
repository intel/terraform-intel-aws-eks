provider "aws" {
  region = "us-west-2"
}

module "eks_example_complete" {
  source = "terraform-aws-modules/eks/examples/complete"

  cluster_name = "my-eks-cluster"

  tags = {
    Terraform = "True"
    Environment = "dev"
  }

  worker_groups_launch_template = [
    {
      instance_type = "m6i.large"
      asg_desired_capacity = 2
    }
  ]

  vpc_enabled = true
}
