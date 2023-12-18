<p align="center">
  <img src="https://github.com/intel/terraform-intel-aws-vm/blob/main/images/logo-classicblue-800px.png?raw=true" alt="Intel Logo" width="250"/>
</p>

# Intel® Optimized Cloud Modules for Terraform

© Copyright 2023, Intel Corporation

## AWS EKS module for compute-intensive workloads

Configuration in this directory creates one new [AWS EKS](https://aws.amazon.com/eks/) cluster with worker nodes. It can be done in an existing VPC, or a new VPC can be created.

The worker nodes are created on an EC2 instances with [4th Generation Intel® Xeon® Scalable Processor](https://www.intel.com/content/www/us/en/products/docs/processors/xeon-accelerated/4th-gen-xeon-scalable-processors.html), and optimized for [compute-intensive](https://github.com/anuket-project/anuket-specifications/blob/master/doc/ref_arch/kubernetes/chapters/chapter03.rst#scheduling-pods-with-non-resilient-applications) workloads by activating [static CPU Manager policy](https://kubernetes.io/docs/tasks/administer-cluster/cpu-management-policies/) for better workload isolation and installing [Node Feature Discovery](https://github.com/kubernetes-sigs/node-feature-discovery) (NFD) for better mapping of workloads to worker node hardware configurations, or using default configuration without such features.

## Usage

### Credentials

To run these you need to have AWS AIM user with permission policy similar to the one in [my-role.json](./my-role.json), mapped to [shell environment variables](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html#envvars-set) AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY and AWS_DEFAULT_REGION. More in [example EKS IAM policies](https://docs.aws.amazon.com/eks/latest/userguide/security_iam_id-based-policy-examples.html).

### Prerequisites

Install CLI for:

Required:

* [aws](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
* [terraform](https://developer.hashicorp.com/terraform/install)

Optional:
* [git](https://github.com/git-guides/install-git#install-git-on-linux)
* [jq](https://github.com/jqlang/jq/releases)

### Note on egress rules

Please note that current configuration creates worker nodes where the security group rule allows egress to all public internet addresses. If this does not satisfy your requirements, in [main.tf](./main.tf#L49) modify the value for egress_cidr_blocks, or find other ways to limit connectivity or other ways to create desired clusters.

### Creating new or using existing VPC

#### Option 1: Creating EKS cluster in a new VPC

This is simpler option which will provision all required resources.

It will create new vDC with required networking constructs, EKS control plane and worker nodes.

#### Option 2: Creating EKS cluster in existing VPC

This is more complex option where you need to ensure that your existing VPC is configured to run EKS, including security group and connectivity. For troubleshooting you can look [EKS troubleshooting](https://docs.aws.amazon.com/eks/latest/userguide/troubleshooting.html).

If you like to use an existing VPC, then in [main.tf](./main.tf#L24) configure ```use_existing_vpc = true```, and configure existing_vpc_id and existing_private_subnet_ids. This will in existing VPC with two private subnets, create EKS control plane and worker nodes.

In a region defined in your AWS_DEFAULT_REGION environment variable, you can get list of vpc_id's with

```
aws ec2 describe-vpcs | jq -r ' .Vpcs[] | select ( .State == "available" ) | "\( .VpcId ) \( .CidrBlock ) \( .Tags[] | select ( .Key == "Name" ) | .Value ) " '
```

and in chosen VPC_ID get the list of private subnets with

```
aws ec2 describe-subnets | jq -r ' .Subnets[] | select( ( .VpcId == "vpc-00000000000000000" ) and ( .State == "available" ) ) | select ( ( .Tags[].Key == "Name" ) and ( .Tags[].Value | contains( "private" ) ) ) | "\( .SubnetId ) \( .CidrBlock ) \( .AvailabilityZone ) " '
```

### Creating EKS cluster

The module configuration will create compute-intensive worker nodes with activated CPU pinning (by having Kubelet configured with static CPU policy), and install NFD. If you don't like CPU pinning, in [main.tf](./main.tf#L36) configure ```worker_node_create_default = true``` and ```worker_node_create_compute-intensive = false```.

Also check configurations in other .tf files.

```
terraform init
terraform plan
terraform apply
```

which in outputs will give VPC ID, ARN and owner ID, cluster name, ARN and endpoint, and aws CLI command to update Kube config file.

### Completing cluster creation

Check that the new cluster is created with

```
aws eks list-clusters | jq -r '.clusters[]' | grep "$( terraform output -raw cluster_name )"
```

Create Kubeconfig file with

```
rm -rf ~/.kube/cache ~/.kube/config
aws eks update-kubeconfig --region "${AWS_DEFAULT_REGION}" --name "$( terraform output -raw cluster_name )"
```

Check that you can see new worker nodes with

```
kubectl get nodes -o wide
```

and that the nodes of desired configurations got created

```
kubectl get nodes -o json | jq -r '.items[].metadata | "\( .name ) \( .labels."iac-tool/node-profile" )"'
```

Optionally install SSM Agent daemonset with

```
kubectl apply -f ssm_daemonset.yaml
```

or follow the guide [here](https://docs.aws.amazon.com/prescriptive-guidance/latest/patterns/install-ssm-agent-on-amazon-eks-worker-nodes-by-using-kubernetes-daemonset.html#install-ssm-agent-on-amazon-eks-worker-nodes-by-using-kubernetes-daemonset-tools).

Optionally install Node Feature Discovery with

```
kubectl apply -k https://github.com/kubernetes-sigs/node-feature-discovery/deployment/overlays/default?ref=v0.14.3
```

or follow the guide [here](https://github.com/kubernetes-sigs/node-feature-discovery#quick-start--the-short-short-version).

### Using node labels

Each created worker node will have labels as per [eks.tf](./eks.tf#L59), and optionally additional ones added by NFD. Those labels can be used for pod scheduling with pod configurations including ```nodeSelector:``` fields like explained in Kubernetes Docs [here](https://kubernetes.io/docs/tasks/configure-pod-container/assign-pods-nodes/#create-a-pod-that-gets-scheduled-to-your-chosen-node).

### Validation of CPU pinning

To validate that CPU pinning is activated on worker nodes do

```
cd ~/some_folder
git clone https://github.com/intel/container-experience-kits.git
cd container-experience-kits/validation/sylva-validation/stack-validation/image/
./validate.sh --only validateCPUPinning
```

which will for each worker node in the cluster report if CPU pinning is activated or not, like

```
          {
            "name": "ip-00-0-0-00.aws-region.compute.internal",
            "pass": true,
            "debug": "allrange=0-15 cpusetcpus=8"
          },
```

That test case deploys daemonset, from inside each pod checks that cpusets are limited, and deletes the daemonset.

### Destroying cluster

```
terraform destroy
```

## Supported Regions

These modules support all AWS Regions that are enabled in your AWS account.

## Deployment Time

This will provision requested resources in about 15 minutes. 

## Security

When using any of these modules in your AWS account, do not use the AWS account root user. Leverage the IAM service to create IAM credentials and follow the principle of "least privilege" permissions for the credentials you create.

## Disclaimer

Intel technologies may require enabled hardware, software or service activation. No product or component can be absolutely secure. Performance varies by use, configuration and other factors. See our complete legal [Notices and Disclaimers](https://edc.intel.com/content/www/us/en/products/performance/benchmarks/overview/#GUID-26B0C71C-25E9-477D-9007-52FCA56EE18C).

