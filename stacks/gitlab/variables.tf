variable "gitlab_base_url" {
  description = "GitLab API endpoint, including the /api/v4/ path and trailing slash"
  type        = string
  default     = "https://gitlab.com/api/v4/"

  validation {
    condition     = endswith(var.gitlab_base_url, "/")
    error_message = "gitlab_base_url must end with a slash."
  }
}

variable "gitlab_variable_values" {
  description = "Sensitive values for CI/CD variables referenced by value_ref in catalog files"
  type        = map(string)
  sensitive   = true
  default     = {}
}

variable "gitlab_user_passwords" {
  description = "Sensitive initial GitLab user passwords keyed by catalog password_ref"
  type        = map(string)
  sensitive   = true
  default     = {}
}
