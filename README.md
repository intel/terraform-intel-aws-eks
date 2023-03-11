<p align="center">
  <img src="https://github.com/intel/terraform-intel-aws-postgresql/blob/main/images/logo-classicblue-800px.png?raw=true" alt="Intel Logo" width="250"/>
</p>

# Intel® Cloud Optimization Modules for Terraform

© Copyright 2022, Intel Corporation

## Amazon EKS Module
In this repository, we are providing an example to create an Amazon Elastic Kubernetes Service (EKS) cluster optimized on 3rd generation of Intel Xeon scalable processors (code named Ice Lake). The example will be creating an EKS cluster with an EKS managed node group. 

As of the time of creating this example, the EKS managed node group does not support the 4th generation on Inten Xeon scalable processors (code named Sapphire Rapids). However, if you are going to use the self managed node group within EKS instead, you can spin up the EKS cluster on Sapphire Rapids CPU based EC2 instances. 

We are leveraging the Amazon EKS Terraform module that is already available on Terraform registry - https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest

Our example will create an EKS cluster with a single EKS managed node group. The node group is a collection of Intel Ice Lake based EC2 instance types. This node group is using an autoscaling configuration. Within this example, we have provided parameters to scale the minimum size, desired size and the maximum size of the EKS cluster.

## Usage

See examples folder for code ./examples/Simple-Example/main.tf

Example of main.tf

```hcl
provider "aws" {
  region = local.region
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

locals {
  name            = "ex-${replace(basename(path.cwd), "_", "-")}"
  cluster_version = "1.24"
  region          = "us-east-1"
  vpc_id          = "vpc-5ea60f23"

  tags = {
    Example    = local.name
    GithubRepo = "terraform-aws-eks"
    GithubOrg  = "terraform-aws-modules"
    Owner      = "rajiv.mandal@intel.com"
    Duration   = "5"
  }
}

################################################################################
# EKS Module
################################################################################

module "eks" {
  source = "terraform-aws-modules/eks/aws"

  cluster_name                   = local.name
  cluster_version                = local.cluster_version
  cluster_endpoint_public_access = true
  vpc_id                         = local.vpc_id
  subnet_ids                     = ["subnet-6fa98422", "subnet-9478e5f2"]
  control_plane_subnet_ids       = ["subnet-a3009efc", "subnet-add384a3"]

  eks_managed_node_group_defaults = {
    ami_type                   = "AL2_x86_64"
    instance_types             = ["m6i.large", "c6i.large", "m6i.2xlarge", "r6i.large"]
    iam_role_attach_cni_policy = true
  }

  eks_managed_node_groups = {
    # Default node group - as provided by AWS EKS
    default-node-group = {
      # By default, the module creates a launch template to ensure tags are propagated to instances, etc.,
      # so we need to disable it to use the default template provided by the AWS EKS managed node group service
      use_custom_launch_template = false

      disk_size = 50

      min_size     = 2
      max_size     = 6
      desired_size = 2

      # Remote access cannot be specified with a launch template
      remote_access = {
        ec2_ssh_key               = module.key_pair.key_pair_name
        source_security_group_ids = [aws_security_group.remote_access.id]
      }
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
- The VM has a public IP address. If you want your VM to not have a public IP
- The subnet_ids and control_plane_subnet_ids parameters are provided in the example. Each of these parameters need two subnets within your VPC. All the subnets used in these parameters should be unique

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

No modules.

## Resources

No resources.

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END_TF_DOCS -->