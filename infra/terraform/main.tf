terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    helm = {
      source = "hashicorp/helm"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
    null = {
      source = "hashicorp/null"
    }
  }
}

module "vpc" {
  source = "./modules/vpc"

  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = "10.0.0.0/16"
  azs          = ["ap-south-1a", "ap-south-1b"]
}

module "security" {
  source = "./modules/security"

  project_name = var.project_name
  vpc_id       = module.vpc.vpc_id
}

module "eks" {
  source = "./modules/eks"

  project_name        = var.project_name
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  cluster_sg_id      = module.security.cluster_sg_id
  node_sg_id         = module.security.node_sg_id
  git_username       = var.git_username
  git_token          = var.git_token
  mongodb_root_password = var.mongodb_root_password
  mongodb_user          = var.mongodb_user
  mongodb_password      = var.mongodb_password
}

module "argocd" {
  source = "./modules/argocd"
  
  git_username = var.git_username
  git_token    = var.git_token

  depends_on = [module.eks]
}