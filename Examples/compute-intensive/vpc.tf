#
# Copyright (C) 2023 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

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

