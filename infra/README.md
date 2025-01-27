# Infrastructure Repository

This repository contains the Infrastructure as Code (IaC) for the Phonebook application using Terraform.

## Repository Structure

```
infra/
├── bootstrap
│   ├── main.tf
│   └── terraform.tfstate
└── terraform
    ├── backend.tf
    ├── main.tf
    ├── modules
    │   ├── argocd
    │   │   ├── main.tf
    │   │   ├── manifests
    │   │   │   └── root-application.yaml
    │   │   └── variables.tf
    │   ├── eks
    │   │   ├── main.tf
    │   │   ├── outputs.tf
    │   │   └── variables.tf
    │   ├── security
    │   │   ├── main.tf
    │   │   ├── outputs.tf
    │   │   └── variables.tf
    │   └── vpc
    │       ├── main.tf
    │       ├── outputs.tf
    │       └── variables.tf
    ├── providers.tf
    ├── terraform.tfvars
    └── variables.tf


```

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0.0
- kubectl
- helm

## Infrastructure Components

### VPC Module
- Dedicated VPC with public and private subnets
- NAT Gateway for private subnet internet access
- Internet Gateway for public subnet access
- Proper tagging for EKS use

### Security Module
- Security groups for EKS cluster and nodes
- Inbound/outbound rules for cluster communication
- Node-to-node communication rules
- Control plane to worker node rules

### EKS Module
- EKS cluster with version 1.27
- Node group with t3a.medium instances
- AWS EBS CSI Driver integration
- Secrets management for MongoDB and Git credentials
- Kubernetes namespace setup

### Argo CD Module
- Argo CD installation via Helm
- Git repository configuration
- Root application setup

## Quick Start

1. Initialize Terraform:
   ```bash
   terraform init
   ```

2. Review planned changes:
   ```bash
   terraform plan
   ```

3. Apply infrastructure:
   ```bash
   terraform apply
   ```

4. Configure kubectl:
   ```bash
   aws eks update-kubeconfig --name <cluster-name> --region <region>
   ```

## Configuration

### Required Variables
- `project_name`: Project identifier
- `environment`: Deployment environment
- `aws_region`: AWS region for deployment
- `git_username`: GitHub username
- `git_token`: GitHub personal access token
- `mongodb_root_password`: MongoDB root password
- `mongodb_user`: MongoDB application user
- `mongodb_password`: MongoDB application password

### State Management
- State stored in S3 bucket
- State locking using DynamoDB
- Bucket: `leon-phonebook-app-tf-state`
- Key: `phonebook/terraform.tfstate`
- DynamoDB table: `terraform-state-lock`

## Resource Specifications

### Networking
- VPC CIDR: 10.0.0.0/16
- 2 Availability Zones
- Public and private subnets per AZ

### EKS Cluster
- Version: 1.27
- Max nodes: 3
- Instance type: t3a.medium
- Private endpoint access enabled
- Public endpoint access enabled

## Tags

All resources are tagged with:
- Project
- Environment
- ManagedBy: terraform
- Owner: leon.lax
- Bootcamp: BC22
- Expiration_date: 01-03-2025

## Security Considerations

- EKS cluster runs in private subnets
- Public access restricted to kubectl operations
- Secrets stored in AWS Secrets Manager
- Security groups limit access to required ports only
- Node groups use IAM roles with least privilege

## Maintenance

### Updating EKS Version
1. Modify eks_version in variables
2. Plan and apply changes
3. Update node groups as needed

### Adding New Resources
1. Create new module if needed
2. Add module to main.tf
3. Define variables and outputs
4. Update README with new components

### Cleanup
```bash
terraform destroy
```

## Troubleshooting

1. State Issues:
   ```bash
   terraform force-unlock <lock-id>
   ```

2. Node Group Issues:
   ```bash
   aws eks describe-nodegroup --cluster-name <cluster> --nodegroup-name <nodegroup>
   ```

3. Cluster Access:
   ```bash
   aws eks get-token --cluster-name <cluster>
   ```
