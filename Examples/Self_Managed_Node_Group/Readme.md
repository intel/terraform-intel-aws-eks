<p align="center">
  <img src="https://github.com/OTCShare2/terraform-intel-aws-eks/blob/main/images/logo-classicblue-800px.png?raw=true" alt="Intel Logo" width="250"/>
</p>

# Intel® Cloud Optimization Modules for Terraform

© Copyright 2022, Intel Corporation

## Amazon EKS Module
Creates an Amazon Elastic Kubernetes Service (EKS) cluster optimized on 4th generation of Intel Xeon scalable processors (code named Sapphire Rapids). The example will be creating an EKS cluster with a self managed node group. 

This is an EKS cluster with a single self managed node group. We are using the default node group. The node group is a collection of Intel Sapphire Rapids based EC2 instance types. This node group is using an autoscaling configuration. Within this example, we have provided parameters to scale the minimum size, desired size and the maximum size of the node group within the EKS cluster.

As of the time of publication of this example, EC2 instances based on Intel 4th gen Xeon sclable processors (code named Sapphire Rapids) is available in private preview.

## Usage

See examples folder for code ./examples/Self_Managed_Node_Group/main.tf

Example of main.tf

```hcl
#########################################################
# Local variables, modify for your needs                #
#########################################################

# See policies.md for recommended instances
# General Purpose:** m6i.large, m6i.xlarge, m6i.2xlarge, m6i.4xlarge, m6i.8xlarge, m6i.12xlarge, m6i.16xlarge, m6i.24xlarge, m6i.32xlarge, m6i.metal, m6in.large, m6in.xlarge, m6in.2xlarge, m6in.4xlarge, m6in.8xlarge, m6in.12xlarge, m6in.16xlarge, m6in.24xlarge, m6in.32xlarge
# Compute Optimized:** c6in.large, c6in.xlarge, c6in.2xlarge, c6in.4xlarge, c6in.8xlarge, c6in.12xlarge, c6in.16xlarge, c6in.24xlarge, c6in.32xlarge c6i.large, c6i.xlarge, c6i.2xlarge, c6i.4xlarge, c6i.8xlarge, c6i.12xlarge, c6i.16xlarge, c6i.24xlarge, c6i.32xlarge, c6i.metal
# Memory Optimized:** r7iz.large, r7iz.xlarge, r7iz.2xlarge, r7iz.4xlarge, r7iz.8xlarge, r7iz.12xlarge, r7iz.24xlarge, r7iz.32xlarge, r7iz.metal16xl, r7iz.metal32xl, r6in.large, r6in.xlarge, r6in.2xlarge, r6in.4xlarge, r6in.8xlarge, r6in.12xlarge, r6in.16xlarge, r6in.24xlarge, r6in.32xlarge, r6i.large, r6i.xlarge, r6i.2xlarge, r6i.4xlarge, r6i.8xlarge, r6i.12xlarge, r6i.16xlarge, r6i.24xlarge, r6i.32xlarge, r6i.metal x2idn.16xlarge, x2idn.24xlarge, x2idn.32xlarge, x2idn.metal x2iedn.xlarge, x2iedn.2xlarge, x2iedn.4xlarge, x2iedn.8xlarge, x2iedn.16xlarge, x2iedn.24xlarge, x2iedn.32xlarge, x2iedn.metal
# Storage Optimized:** i4i.large, i4i.xlarge, i4i.2xlarge, i4i.4xlarge, i4i.8xlarge, i4i.16xlarge, i4i.32xlarge, i4i.metal
# Accelerated Compute:** trn1.2xlarge, trn1.32xlarge

locals {
  name            = "ex-${replace(basename(path.cwd), "_", "-")}"
  cluster_version = "1.24"
  region          = "us-east-1"
  vpc_id          = "vpc-example12" # Update with your own VPC id that is available in the region you are testing
  instance_type = "r7iz.large"

  tags = {
    Example    = local.name
    GithubRepo = "terraform-aws-eks"
    GithubOrg  = "terraform-aws-modules"
    Owner      = "john.doe@abc.com"
    Duration   = "5"
  }
}

################################################################################
# EKS Module
################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.10.0"

  cluster_name                   = local.name
  cluster_version                = local.cluster_version
  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  vpc_id = local.vpc_id

  # Update with your own subnet ids in the vpc you are testing. Two unique subnet ids needed for subnet_ids
  # Two additional unique subnet ids needed for control_plane_subnet_ids
  subnet_ids                     = ["subnet-example12", "subnet-example23"] # Change based on your vpcs and subnets
  control_plane_subnet_ids       = ["subnet-example34", "subnet-example45"] # Change based on your vpcs and subnets

  # Self managed node groups will not automatically create the aws-auth configmap so we need to
  create_aws_auth_configmap = true
  manage_aws_auth_configmap = true

  self_managed_node_group_defaults = {
    # enable discovery of autoscaling groups by cluster-autoscaler
    autoscaling_group_tags = {
      "k8s.io/cluster-autoscaler/enabled" : true,
      "k8s.io/cluster-autoscaler/${local.name}" : "owned",
    }
  }

  self_managed_node_groups = {
    # Default node group - overriding the instance type and the auto scaling configuration
    default_node_group = {
      instance_type = local.instance_type
      min_size      = 2
      max_size      = 4
      desired_size  = 2
    }
  }
  tags = local.tags
}

module "key_pair" {
  source  = "terraform-aws-modules/key-pair/aws"
  version = "~> 2.0"

  key_name_prefix    = local.name
  create_private_key = true

  tags = local.tags
}

resource "aws_security_group" "remote_access" {
  name_prefix = "${local.name}-remote-access"
  description = "Allow remote SSH access"
  vpc_id      = local.vpc_id

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(local.tags, { Name = "${local.name}-remote" })
}
```

Run Terraform

```hcl
terraform init  
terraform plan
terraform apply

```

Note that this example may create resources. Run `terraform destroy` when you don't need these resources anymore.

## Considerations  
- The AWS region is provided within the example. Update the region to your region of choice
- The EKS cluster is created in the VPC provided within the example. Update the VPC value to create the cluster in your VPC of choice
- The cluster has a public IP address. If you want your EKS cluster to not have a public IP, override the value accordingly
- The subnet_ids and control_plane_subnet_ids parameters are provided in the example. Each of these parameters need two subnets within your VPC. All the subnets used in these parameters should be unique

<!-- BEGIN_TF_DOCS -->
## Requirements

## Providers

## Modules

## Resources

## Inputs

## Outputs

<!-- END_TF_DOCS -->
