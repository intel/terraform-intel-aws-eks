#
# Copyright (C) 2024 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

#########################################################
# Local variables, modify for your needs                #
#########################################################

# See policies.md for recommended instances
# General Purpose:** m7i.large, m7i.xlarge, m7i.2xlarge, m7i.4xlarge, m7i.8xlarge, m7i.12xlarge, m7i.16xlarge, m7i.24xlarge, m7i.48xlarge, m7i.metal-24xl, m7i.metal-48xl, m7i-flex.large, m7i-flex.xlarge, m7i-flex.2xlarge, m7i-flex.4xlarge, m7i-flex.8xlarge, m6i.large, m6i.xlarge, m6i.2xlarge, m6i.4xlarge, m6i.8xlarge, m6i.12xlarge, m6i.16xlarge, m6i.24xlarge, m6i.32xlarge, m6i.metal, m6in.large, m6in.xlarge, m6in.2xlarge, m6in.4xlarge, m6in.8xlarge, m6in.12xlarge, m6in.16xlarge, m6in.24xlarge, m6in.32xlarge
# Compute Optimized:** c7i.large, c7i.xlarge, c7i.2xlarge, c7i.4xlarge, c7i.8xlarge, c7i.12xlarge, c7i.16xlarge, c7i.24xlarge, c7i.48xlarge, c7i.metal-24xl, c7i.metal-48xl, c6in.large, c6in.xlarge, c6in.2xlarge, c6in.4xlarge, c6in.8xlarge, c6in.12xlarge, c6in.16xlarge, c6in.24xlarge, c6in.32xlarge c6i.large, c6i.xlarge, c6i.2xlarge, c6i.4xlarge, c6i.8xlarge, c6i.12xlarge, c6i.16xlarge, c6i.24xlarge, c6i.32xlarge, c6i.metal
# Memory Optimized:** r7i.large, r7i.xlarge, r7i.2xlarge, r7i.4xlarge, r7i.8xlarge, r7i.12xlarge, r7i.16xlarge, r7i.24xlarge, r7i.48xlarge, r7i.metal-24xl, r7i.metal-48xl, r7iz.large, r7iz.xlarge, r7iz.2xlarge, r7iz.4xlarge, r7iz.8xlarge, r7iz.12xlarge, r7iz.16xlarge, r7iz.32xlarge, r7iz.metal-16xl, r7iz.metal-32xl, r6in.large, r6in.xlarge, r6in.2xlarge, r6in.4xlarge, r6in.8xlarge, r6in.12xlarge, r6in.16xlarge, r6in.24xlarge, r6in.32xlarge, r6i.large, r6i.xlarge, r6i.2xlarge, r6i.4xlarge, r6i.8xlarge, r6i.12xlarge, r6i.16xlarge, r6i.24xlarge, r6i.32xlarge, r6i.metal x2idn.16xlarge, x2idn.24xlarge, x2idn.32xlarge, x2idn.metal x2iedn.xlarge, x2iedn.2xlarge, x2iedn.4xlarge, x2iedn.8xlarge, x2iedn.16xlarge, x2iedn.24xlarge, x2iedn.32xlarge, x2iedn.metal
# Storage Optimized:** i4i.large, i4i.xlarge, i4i.2xlarge, i4i.4xlarge, i4i.8xlarge, i4i.16xlarge, i4i.32xlarge, i4i.metal
# Accelerated Compute:** trn1.2xlarge, trn1.32xlarge

locals {
  ## VPC
  # true if existing VPC should be used, or false if new one should be created
  use_existing_vpc = false
  # existing VPC
  existing_vpc_id             = "vpc-00000000000000000"
  existing_private_subnet_ids = ["subnet-10000000000000000","subnet-20000000000000000"]
  # newly created VPC
  new_vpc_name_prefix          = "intel-optmod-eks"
  new_vpc_cidr                 = "10.0.0.0/16"
  new_vpc_subnet_cidrs_private = ["10.0.1.0/24", "10.0.2.0/24"]
  new_vpc_subnet_cidrs_public  = ["10.0.11.0/24", "10.0.12.0/24"]

  ## EKS
  # if node group with worker nodes compute-intensive or/and default should be created
  worker_node_create_default           = false
  worker_node_create_compute-intensive = true
  cluster_name_prefix                  = "intel-optmod"
  cluster_version                      = "1.29"
  worker_node_instance                 = "m7i.4xlarge" #  c7i.4xlarge
  worker_node_min_size                 = 1
  worker_node_max_size                 = 2
  worker_node_desired_size             = 1
  worker_node_disk_size                = 100
  worker_node_volume_size              = 100
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"] # or limit as per your requirements

  ## security group
  egress_cidr_blocks = ["0.0.0.0/0"]
}

## data that over aws provider will be checked and used during runtime
data "aws_region" "current" {}
data "aws_vpc" "existing" {
  count = local.use_existing_vpc ? 1 : 0
  id    = local.existing_vpc_id
}
data "aws_subnet" "private1" {
  count = local.use_existing_vpc ? 1 : 0
  id    = local.existing_private_subnet_ids[0]
}
data "aws_subnet" "private2" {
  count = local.use_existing_vpc ? 1 : 0
  id    = local.existing_private_subnet_ids[1]
}

resource "random_string" "random_suffix" {
  length  = 5
  special = false
  upper   = false
}

################################################################################
# VPC Module
################################################################################

module "vpc" {
  source     = "terraform-aws-modules/vpc/aws"
  create_vpc = !local.use_existing_vpc
  #count           = local.use_existing_vpc ? 0 : 1
  name            = "${local.new_vpc_name_prefix}-${random_string.random_suffix.result}"
  cidr            = local.new_vpc_cidr
  azs             = ["${data.aws_region.current.name}a", "${data.aws_region.current.name}b", "${data.aws_region.current.name}c", "${data.aws_region.current.name}d"]
  private_subnets = local.new_vpc_subnet_cidrs_private
  public_subnets  = local.new_vpc_subnet_cidrs_public

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

################################################################################
# EKS Module
################################################################################

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "${local.cluster_name_prefix}-${random_string.random_suffix.result}"
  cluster_version = local.cluster_version
  #cluster_endpoint_private_access = true
  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = local.cluster_endpoint_public_access_cidrs
  vpc_id                               = local.use_existing_vpc ? local.existing_vpc_id : module.vpc.vpc_id
  subnet_ids                           = local.use_existing_vpc ? local.existing_private_subnet_ids : module.vpc.private_subnets
  create_cluster_security_group        = false
  cluster_security_group_id            = aws_security_group.cluster_sg.id
  create_node_security_group           = false
  node_security_group_id               = aws_security_group.cluster_sg.id
  eks_managed_node_group_defaults = {
    instance_types = [local.worker_node_instance]
    min_size       = local.worker_node_min_size
    max_size       = local.worker_node_max_size
    desired_size   = local.worker_node_desired_size # in EKS module is immutable and > than min_size which can change during lifecycle
    ami_type       = "AL2_x86_64"
    disk_size      = local.worker_node_disk_size
    block_device_mappings = {
      xvda = {
        device_name = "/dev/xvda"
        ebs = {
          volume_size           = local.worker_node_volume_size
          delete_on_termination = true
        }
      }
    }
    iam_role_additional_policies = {
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }
  }
  eks_managed_node_groups = {
    default = {
      create = local.worker_node_create_default
      labels = {
        "anuket.io/profile"     = "basic"
        "iac-tool/node-profile" = "default"
      }
    }
    comp-int-p = {
      create                  = local.worker_node_create_compute-intensive
      pre_bootstrap_user_data = <<-EOT
#! /bin/bash
set -ex
yum -y update
cat <<-EOF > /etc/profile.d/bootstrap.sh
export KUBELET_EXTRA_ARGS="--cpu-manager-policy=static"
EOF
sed -i '/^set -o errexit/a\\nsource /etc/profile.d/bootstrap.sh' /etc/eks/bootstrap.sh
sed -i 's/KUBELET_EXTRA_ARGS=$2/KUBELET_EXTRA_ARGS="$2 $KUBELET_EXTRA_ARGS"/' /etc/eks/bootstrap.sh
EOT
      labels = {
        "anuket.io/profile"                      = "basic"
        "iac-tool/node-profile"                  = "compute-intensive"
        "iac-tool/kubelet-cpu-manager-policy"    = "static"
        "iac-tool/tf-kubelet-cpu-manager-policy" = "pre-bootstrap-user-data"
      }
    }
  }

  cluster_security_group_additional_rules = {
    egress_nodes_ephemeral_ports_tcp = {
      description                = "To node 1025-65535"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "egress"
      source_node_security_group = true
    }
  }
}

################################################################################
# Security Group Resource
################################################################################

resource "aws_security_group" "cluster_sg" {
  name        = "${local.cluster_name_prefix}-${random_string.random_suffix.result}-cluster-sg"
  description = "Security group for ${local.cluster_name_prefix}-${random_string.random_suffix.result} cluster."
  vpc_id      = local.use_existing_vpc ? local.existing_vpc_id : module.vpc.vpc_id
  ingress {
    description = "From VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [local.use_existing_vpc ? data.aws_vpc.existing[0].cidr_block : module.vpc.vpc_cidr_block] #  if needed to SSH into worker nodes, then also add public IP from bastion VM
  }
  egress {
    description = "From VPC. To all"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = local.egress_cidr_blocks
  }
}
