# modules/eks/main.tf

terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
    aws = {
      source  = "hashicorp/aws"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
    }
    helm = {
      source  = "hashicorp/helm"
    }
    null = {
      source  = "hashicorp/null"
    }
  }
}

# Break the provider cycle with locals
locals {
  cluster_endpoint = aws_eks_cluster.main.endpoint
  cluster_ca       = aws_eks_cluster.main.certificate_authority[0].data
}

# Provider configurations
provider "kubernetes" {
  host                   = local.cluster_endpoint
  cluster_ca_certificate = base64decode(local.cluster_ca)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.main.name]
    command     = "aws"
  }
}

provider "helm" {
  kubernetes {
    host                   = local.cluster_endpoint
    cluster_ca_certificate = base64decode(local.cluster_ca)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.main.name]
      command     = "aws"
    }
  }
}

provider "kubectl" {
  host                   = local.cluster_endpoint
  cluster_ca_certificate = base64decode(local.cluster_ca)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.main.name]
    command     = "aws"
  }
}

data "aws_secretsmanager_secret_version" "mongodb_secret" {
  secret_id = aws_secretsmanager_secret.mongodb_secret.id
  depends_on = [aws_secretsmanager_secret_version.mongodb_secret_version]
}

# EKS Cluster Role
resource "aws_iam_role" "cluster" {
  name = "${var.project_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

# Node Group Role
resource "aws_iam_role" "nodes" {
  name = "${var.project_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "ecr_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.nodes.name
}

# EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = "${var.project_name}-cluster"
  role_arn = aws_iam_role.cluster.arn
  version  = "1.27"

  vpc_config {
    security_group_ids      = [var.cluster_sg_id]
    subnet_ids             = var.private_subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true # Allows kubectl access from outside VPC
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy
  ]
}

# EKS Node Group
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "main"
  node_role_arn   = aws_iam_role.nodes.arn
  subnet_ids      = var.private_subnet_ids

  scaling_config {
    desired_size = 3
    max_size     = 3 # Max 3 nodes as per requirements
    min_size     = 1
  }

  instance_types = ["t3a.medium"]

  # Add tags for cluster autoscaler
  tags = {
    owner           = "leon.lax"
    bootcamp        = "BC22"
    expiration_date = "01-03-2025"
    Name            = "${var.project_name}-node-group"
    "k8s.io/cluster-autoscaler/enabled"                      = "true"
    "k8s.io/cluster-autoscaler/${var.project_name}-cluster" = "owned"
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_policy,
    aws_iam_role_policy_attachment.cni_policy,
    aws_iam_role_policy_attachment.ecr_policy,
  ]
}

# Create AWS Secrets Manager secret for Git credentials
resource "aws_secretsmanager_secret" "git_credentials" {
  name = "${var.project_name}-git-creds"

  lifecycle{
    ignore_changes = all
  }
}

resource "aws_secretsmanager_secret_version" "git_credentials" {
  secret_id = aws_secretsmanager_secret.git_credentials.id
  secret_string = jsonencode({
    username = var.git_username
    password = var.git_token
  })
}

resource "aws_secretsmanager_secret" "mongodb_secret" {
  name = "${var.project_name}-mongodb-secrets"
  lifecycle {
    ignore_changes = [name]
  }
}

resource "aws_secretsmanager_secret_version" "mongodb_secret_version" {
  secret_id = aws_secretsmanager_secret.mongodb_secret.id
  secret_string = jsonencode({
    "root_password" = var.mongodb_root_password
    "username"      = var.mongodb_user
    "password"      = var.mongodb_password
  })
}

resource "kubernetes_namespace" "phonebook" {
  metadata {
    name = "phonebook"
  }
  lifecycle {
    ignore_changes = [metadata]
  }
}

resource "kubernetes_secret" "mongodb_secret" {
  metadata {
    name      = "mongodb-credentials"
    namespace = kubernetes_namespace.phonebook.metadata[0].name
  }
  data = {
    "mongodb-root-password" = jsondecode(data.aws_secretsmanager_secret_version.mongodb_secret.secret_string)["root_password"]
    "mongodb-passwords"     = jsondecode(data.aws_secretsmanager_secret_version.mongodb_secret.secret_string)["password"]
    "mongodb-usernames"     = jsondecode(data.aws_secretsmanager_secret_version.mongodb_secret.secret_string)["username"]
    "mongodb-database"      = "phonebook"
    "mongodb-replica-set-key" = random_string.replica_set_key.result
    "uri"                  = "mongodb://${jsondecode(data.aws_secretsmanager_secret_version.mongodb_secret.secret_string)["username"]}:${jsondecode(data.aws_secretsmanager_secret_version.mongodb_secret.secret_string)["password"]}@phonebook-mongodb-headless:27017/phonebook?replicaSet=rs0&authSource=phonebook"
  }
  depends_on = [kubernetes_namespace.phonebook]
}

resource "random_string" "replica_set_key" {
  length  = 32
  special = false
}