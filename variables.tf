variable "environment" {
  description = "Environment directory containing config.json, selected through TF_VAR_environment or -var"
  type        = string
  nullable    = false
}