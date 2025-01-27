# modules/argocd/main.tf

terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"  # Note: gavinbunney not hashicorp
      version = "~> 1.14"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    helm = {
      source = "hashicorp/helm"
    }
    null = {
      source = "hashicorp/null"
    }
  }
} 

# Create namespace for ArgoCD
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

# Create Kubernetes secret for Git credentials
resource "kubernetes_secret" "git_credentials" {
  metadata {
    name      = "git-credentials"
    namespace = kubernetes_namespace.argocd.metadata[0].name
  }

  data = {
    username = var.git_username
    password = var.git_token
  }

  type = "Opaque"
}

# Install ArgoCD using Helm
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  version    = "5.51.6"

  values = [
    <<-EOT
    configs:
      cm:
        timeout.reconciliation: 180s
        application.instanceLabelKey: argocd.argoproj.io/instance
    server:
      config:
        repositories: |
          - type: git
            url: https://github.com/LaxForce/gitops-config
            usernameSecret:
              name: git-credentials
              key: username
            passwordSecret:
              name: git-credentials
              key: password
      extraArgs:
        - --insecure
    EOT
  ]
}

# Create directory for manifests if it doesn't exist
resource "null_resource" "create_manifests_dir" {
  provisioner "local-exec" {
    command = "mkdir -p ${path.module}/manifests"
  }
}

# Copy root application manifest
resource "null_resource" "copy_root_app" {
  provisioner "local-exec" {
    command = "cp ${path.root}/../../gitops-config/applications/root-application.yaml ${path.module}/manifests/"
  }

  depends_on = [
    null_resource.create_manifests_dir
  ]
}

# Apply root application
resource "kubectl_manifest" "root_application" {
  yaml_body = file("${path.module}/manifests/root-application.yaml")

  depends_on = [
    helm_release.argocd
  ]
}