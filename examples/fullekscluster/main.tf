provider "aws" {
  region = "us-west-2"
  access_key = var.my_access_key
  secret_key = var.my_secret_key
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.7.0"

  cluster_name = "my-eks-cluster"

  tags = {
    Terraform   = "true"
    Environment = "test"
  }

  # EC2 instance type
  worker_groups_launch_template = [
    {
      instance_type = var.instance_type
    }
  ]

  vpc_create     = true
  vpc_cidr       = "10.0.0.0/16"
  public_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}