variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name to be used as prefix"
  type        = string
  default     = "leon-phonebook"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
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