variable "project_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "cluster_sg_id" {
  type = string
}

variable "node_sg_id" {
  type = string
}

variable "git_username" {
  description = "GitHub username for private repositories"
  type        = string
}

variable "git_token" {
  description = "GitHub personal access token for private repositories"
  type        = string
  sensitive   = true
}

variable "mongodb_root_password" {
  type        = string
  sensitive   = true
}

variable "mongodb_user" {
  type        = string
}

variable "mongodb_password" {
  type        = string
  sensitive   = true
}