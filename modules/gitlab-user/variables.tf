variable "users" {
  description = "GitLab user settings keyed by username"
  type = map(object({
    name             = string
    email            = string
    password_ref     = optional(string)
    is_admin         = optional(bool, false)
    projects_limit   = optional(number, 0)
    can_create_group = optional(bool, false)
    is_external      = optional(bool, false)
    is_auditor       = optional(bool, false)
    reset_password   = optional(bool)
  }))
}

variable "passwords" {
  description = "Sensitive initial passwords keyed by password_ref"
  type        = map(string)
  sensitive   = true
  default     = {}
}

variable "admin_roles" {
  description = "Instance-wide custom admin roles keyed by catalog identifier"
  type = map(object({
    name                = string
    description         = optional(string)
    enabled_permissions = set(string)
  }))
  default  = {}
  nullable = false
}
