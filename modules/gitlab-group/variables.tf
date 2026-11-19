variable "groups" {
  description = "Decoded group catalog object keyed by YAML filename, with optional settings per group"
  type        = any
}

variable "variable_values" {
  description = "Sensitive values referenced by CI/CD variables in the catalog"
  type        = map(string)
  sensitive   = true
  default     = {}
}

variable "user_ids" {
  description = "GitLab user IDs keyed by catalog username"
  type        = map(number)
  default     = {}
}
