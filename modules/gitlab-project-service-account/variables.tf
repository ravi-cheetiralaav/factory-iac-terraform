variable "project_id" {
  description = "ID of the GitLab project that owns the service accounts"
  type        = string
  nullable    = false
}

variable "accounts" {
  description = "Project service account settings keyed by stable catalog identifier"
  type = map(object({
    name     = optional(string)
    username = optional(string)
    email    = optional(string)
    membership = optional(object({
      access_level = string
      expires_at   = optional(string)
    }))
  }))
  default  = {}
  nullable = false
}
