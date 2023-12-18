#
# Copyright (C) 2023 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

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
