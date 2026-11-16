variable "environment" {
  description = "Environment directory containing gitlab.json and, when enabled, jfrog.json, selected through TF_VAR_environment or -var"
  type        = string
  nullable    = false
}

variable "should_manage_artifactory" {
  description = "Enable Artifactory and paired JFrog Projects; disable only when state contains no Artifactory resources"
  type        = bool
  default     = false
  nullable    = false
}

variable "artifactory_secrets" {
  description = "SMTP password and OAuth client secrets supplied externally, never in environment configuration JSON"
  type = object({
    mail_password        = optional(string)
    oauth_client_secrets = optional(map(string), {})
  })
  default   = {}
  sensitive = true
  nullable  = false
}