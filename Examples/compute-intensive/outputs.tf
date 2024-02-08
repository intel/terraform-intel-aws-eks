#
# Copyright (C) 2024 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

################################################################################
# Region
################################################################################

output "aws_region" {
  description = "AWS region"
  value       = trim(data.aws_region.current.name, "\"")
}

################################################################################
# VPC
################################################################################

output "vpc_id" {
  description = "VPC ID"
  value       = trim(local.use_existing_vpc ? local.existing_vpc_id : module.vpc.vpc_id, "\"")
}
output "vpc_arn" {
  description = "VPC ARN"
  value       = trim(local.use_existing_vpc ? data.aws_vpc.existing[0].arn : module.vpc.vpc_arn, "\"")
}
output "vpc_owner_id" {
  description = "VPC owning AWS account ID"
  value       = trim(local.use_existing_vpc ? data.aws_vpc.existing[0].owner_id : module.vpc.vpc_owner_id, "\"")
}

################################################################################
# Cluster
################################################################################

output "cluster_name" {
  description = "EKS cluster name"
  value       = trim(module.eks.cluster_name, "\"")
}
output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = trim(module.eks.cluster_arn, "\"")
}
output "cluster_endpoint" {
  description = "Kubernetes API server endpoint"
  value       = trim(module.eks.cluster_endpoint, "\"")
}
output "cluster_certificate_authority_data" {
  description = "Kubernetes certificate"
  value       = trim(module.eks.cluster_certificate_authority_data, "\"")
  sensitive   = true
}

################################################################################
# Configure kubectl
################################################################################

output "configure_kubectl" {
  description = "Update your kubeconfig"
  value       = "aws eks update-kubeconfig --region ${data.aws_region.current.name} --name ${module.eks.cluster_name}"
}
