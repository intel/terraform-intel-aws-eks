#
# Copyright (C) 2023 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

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
