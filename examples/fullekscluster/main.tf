provider "aws" {
  region = "us-west-2"
}

module "eks_example_complete" {
  source  = "terraform-aws-modules/eks/aws//examples/complete"
  version = "19.7.0"

  cluster_name = "my-eks-cluster"
  subnets = ["subnet-049df61146f12", "subnet-049df61146f13", "subnet-049df61146f14"]
  vpc_id = "vpc-049df61146f12"
  tags = {
    Terraform = "True"
    Environment = "dev"
  }

  depends_on = [
    aws_security_group.worker_group,
  ]

  worker_groups_launch_template = [
    {
      instance_type = var.instance_type
      asg_desired_capacity = 2
    }
  ]
}

resource "aws_security_group" "worker_group" {
  name = "worker_group_security_group"
  description = "Used for worker group access"
  vpc_id = module.eks.vpc_id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
