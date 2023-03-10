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
  subnet_ids                     = ["subnet-6fa98422","subnet-9478e5f2"]
  control_plane_subnet_ids       = ["subnet-a3009efc", "subnet-add384a3"]

  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"
    instance_types = ["m6i.large", "c6i.large", "m6i.2xlarge", "r6i.large"]
    iam_role_attach_cni_policy = true
  }

  eks_managed_node_groups = {
    # Default node group - as provided by AWS EKS
    default_node_group = {
      # By default, the module creates a launch template to ensure tags are propagated to instances, etc.,
      # so we need to disable it to use the default template provided by the AWS EKS managed node group service
      use_custom_launch_template = false

      disk_size = 50

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