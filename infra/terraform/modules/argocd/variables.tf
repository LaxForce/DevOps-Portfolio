variable "git_username" {
  description = "GitHub username for private repositories"
  type        = string
}

variable "git_token" {
  description = "GitHub personal access token"
  type        = string
  sensitive   = true
}