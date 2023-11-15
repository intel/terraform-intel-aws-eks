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
  cluster_version = "1.28"
  region          = "us-east-1"
  vpc_id          = "vpc-5ea60f23" # Update with your own VPC id that is available in the region you are testing
  # Defining the instance types that will be allowed in the EKS managed node group. This includes the latest Intel CPU
  # that is in the EKS Managed Node group
  instance_types = ["c7i.8xlarge"]

  tags = {
    GithubRepo = "terraform-aws-eks"
    GithubOrg  = "terraform-aws-modules"
    Owner      = "john.doe@abc.com"
    Duration   = "5"
  }
}

################################################################################
# Random resource for generating unique EKS cluster names
################################################################################
resource "random_id" "rid" {
  byte_length = 5
}

################################################################################
# EKS Module
################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.10.0"

  cluster_name                   = "my-eks-cluster-${random_id.rid.dec}"
  cluster_version                = local.cluster_version
  cluster_endpoint_public_access = true
  vpc_id                         = local.vpc_id

  # Update with your own subnet ids in the vpc you are testing. Two unique subnet ids needed for subnet_ids
  # Two additional unique subnet ids needed for control_plane_subnet_ids
  subnet_ids               = ["subnet-a3009efc", "subnet-9478e5f2"] # Change based on your vpcs and subnets
  control_plane_subnet_ids = ["subnet-48fc6769", "subnet-6fa98422"] # Change based on your vpcs and subnets

  eks_managed_node_group_defaults = {
    ami_type                   = "AL2_x86_64"
    instance_types             = local.instance_types
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

  key_name_prefix    = "my-eks-cluster-${random_id.rid.dec}"
  create_private_key = true

  tags = local.tags
}

resource "aws_security_group" "remote_access" {
  name_prefix = "my-eks-cluster-${random_id.rid.dec}-remote-access"
  description = "Allow remote SSH access"
  vpc_id      = local.vpc_id

  tags = merge(local.tags, { Name = "my-eks-cluster-${random_id.rid.dec}-remote" })
}

# Modify the `ingress_rules` variable in the variables.tf file to allow the required ports for your CIDR ranges
resource "aws_security_group_rule" "ingress_rules" {
  count             = length(var.ingress_rules)
  type              = "ingress"
  security_group_id = aws_security_group.remote_access.id
  from_port         = var.ingress_rules[count.index].from_port
  to_port           = var.ingress_rules[count.index].to_port
  protocol          = var.ingress_rules[count.index].protocol
  cidr_blocks       = [var.ingress_rules[count.index].cidr_blocks]
}

# Create a role that will provide an EC2 instance role with required permissions to access EKS clusters
resource "aws_iam_role" "role" {
  name = "test-role-${random_id.rid.dec}"

  assume_role_policy = <<EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": "sts:AssumeRole",
          "Principal": {
            "Service": "ec2.amazonaws.com"
          },
          "Effect": "Allow",
          "Sid": ""
        }
      ]
    }
EOF
}

resource "aws_iam_policy" "policy" {
  name        = "test-policy-${random_id.rid.dec}"
  description = "A test policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "eks:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = "${aws_iam_role.role.name}"
  policy_arn = "${aws_iam_policy.policy.arn}"
}

# Create the EC2 instance profile
resource "aws_iam_instance_profile" "test_profile" {
  name = "test_profile"
  role = "${aws_iam_role.role.name}"
}

# Create the EC2 instance and attach the role created with EKS permissions
resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "TF_key" {
  key_name   = "TF_key-${random_id.rid.dec}"
  public_key = tls_private_key.rsa.public_key_openssh
}

resource "local_file" "TF_private_key" {
  content  = tls_private_key.rsa.private_key_pem
  filename = "tfkey.private"
}

resource "aws_security_group" "ssh_security_group" {
  description = "security group to configure ports for ssh"
  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    ## CHANGE THE IP CIDR BLOCK BELOW TO ALL YOUR OWN SSH PORT ##
    cidr_blocks = ["136.52.34.139/32"]

  }
}

resource "aws_network_interface_sg_attachment" "sg_attachment" {
  security_group_id    = aws_security_group.ssh_security_group.id
  network_interface_id = module.ec2-vm.primary_network_interface_id
}

resource "aws_network_interface_sg_attachment" "sg_attachment_eks" {
  security_group_id    = module.eks.cluster_primary_security_group_id
  network_interface_id = module.ec2-vm.primary_network_interface_id
}

module "ec2-vm" {
  source   = "intel/aws-vm/intel"
  key_name = aws_key_pair.TF_key.key_name
  instance_type = "t3.large"
  iam_instance_profile = "${aws_iam_instance_profile.test_profile.name}"

  # tag instance to make it Self-Aware these tags are optional and can set as few or as many as you like.
  tags = {
    Name                              = "my-vm-${random_id.rid.dec}"
    Owner    = "OwnerName-${random_id.rid.dec}",
    Duration = "2"
  }
}