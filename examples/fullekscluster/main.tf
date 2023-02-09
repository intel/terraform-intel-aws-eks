provider "aws" {
  region = "us-west-2"
}

module "eks_example_complete" {
  source = "terraform-aws-modules/eks/examples/complete"

  cluster_name = "my-eks-cluster"
  subnets = ["subnet-049df61146f12", "subnet-049df61146f13", "subnet-049df61146f14"]
  vpc_id = "vpc-049df61146f12"

  tags = {
    Terraform = "True"
    Environment = "dev"
  }

  worker_groups_launch_template = [
    {
      instance_type = var.instance_type
      asg_desired_capacity = 2
    }
  ]
}
