variable "groups" {
  description = "Decoded group catalog keyed by YAML filename"
  type        = map(any)
}

variable "variable_values" {
  description = "Sensitive values referenced by CI/CD variables in the catalog"
  type        = map(string)
  sensitive   = true
  default     = {}
}
