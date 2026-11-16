variable "jfrog_url" {
  description = "Self-hosted JFrog platform URL. Artifactory HA is published by the nginx load balancer. Access token is read from JFROG_ACCESS_TOKEN."
  type        = string
}

variable "manage_general_security" {
  description = "Manage artifactory_general_security. Required for anonymous read of trusted repositories."
  type        = bool
  default     = false
}

variable "enable_anonymous_access" {
  description = "Enable anonymous access on the platform. Read is granted only where a global local repository sets anonymous_read."
  type        = bool
  default     = false
}

variable "encryption_policy" {
  description = "Password encryption policy used with artifactory_general_security."
  type        = string
  default     = "SUPPORTED"
}

variable "manage_project_permission_targets" {
  description = "Also create a platform_permission on each project's repositories. Project roles are created either way."
  type        = bool
  default     = true
}
