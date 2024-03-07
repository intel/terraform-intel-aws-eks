#
# Copyright (C) 2024 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.31""
    }
  }
}

