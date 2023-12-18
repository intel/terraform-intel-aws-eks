#
# Copyright (C) 2023 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

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
  cluster_version                      = "1.28"
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

resource "random_string" "random_suffix" {
  length  = 5
  special = false
  upper   = false
}

