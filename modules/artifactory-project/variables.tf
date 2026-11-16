variable "spec" {
  description = "Decoded project catalog file."
  type        = any
}

variable "xray_security_policy_name" {
  description = "Critical security policy created by the global catalog."
  type        = string
  default     = "gdc-security-critical"
}

variable "xray_malicious_policy_name" {
  description = "Malicious-package policy created by the global catalog. Empty skips that assignment."
  type        = string
  default     = "gdc-malicious-packages"
}

variable "direct_members" {
  description = "Existing users to add directly to the project. Use this for SSO accounts. Do not create those users in Terraform."
  type = list(object({
    name  = string
    roles = set(string)
  }))
  default = []
}

variable "manage_project_permission_targets" {
  description = "Create a platform_permission for this project's own repositories. Project roles are always created. Set this to false if the platform rejects global permission targets on project repositories."
  type        = bool
  default     = true
}
