variable "spec" {
  description = "Decoded YAML configuration for one GitLab project"
  type        = any
}

variable "namespace_id" {
  description = "Numeric ID of the GitLab group that owns the project"
  type        = number
}

variable "variable_values" {
  description = "Sensitive values referenced by CI/CD variables in the catalog"
  type        = map(string)
  sensitive   = true
  default     = {}
}
