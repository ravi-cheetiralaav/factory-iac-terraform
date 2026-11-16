variable "spec" {
  description = "Decoded catalog/global.yaml."
  type        = any
}

variable "manage_general_security" {
  description = "Manage artifactory_general_security. Self-hosted only. JFrog Cloud blocks this API."
  type        = bool
  default     = false
}

variable "enable_anonymous_access" {
  description = "Turn on platform anonymous access. Used only when manage_general_security is true. Grant read separately via anonymous_read on local repositories."
  type        = bool
  default     = false
}

variable "encryption_policy" {
  description = "Password encryption policy owned by artifactory_general_security. SUPPORTED, REQUIRED, or UNSUPPORTED."
  type        = string
  default     = "SUPPORTED"

  validation {
    condition     = contains(["SUPPORTED", "REQUIRED", "UNSUPPORTED"], var.encryption_policy)
    error_message = "encryption_policy must be SUPPORTED, REQUIRED, or UNSUPPORTED."
  }
}
