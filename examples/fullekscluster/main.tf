provider "aws" {
  region = "us-west-2"
  access_key = var.my_access_key
  secret_key = var.my_secret_key
}

resource "aws_launch_template" "worker_group_template" {
  name_prefix = "worker-group-template"

  launch_template_data = {
    instance_type = var.instance_type
    # Other launch template configuration such as block device mapping, security groups, etc.
  }
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
      launch_template_id = aws_launch_template.worker_group_template.id
    }
  ]
}