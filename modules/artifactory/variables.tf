variable "configuration" {
  description = "JFrog projects with robot users, Artifactory identities, repositories and permissions"
  type = object({
    projects = optional(map(object({
      key          = string
      display_name = string
      robot_email  = string
    })), {})
    groups = optional(map(object({
      description = optional(string)
    })), {})
    users = optional(map(object({
      email                            = string
      groups                           = optional(set(string), [])
      should_disable_internal_password = optional(bool, false)
      should_disable_ui_access         = optional(bool, false)
    })), {})
    local_generic_repositories = optional(map(object({
      description = optional(string)
    })), {})
    local_docker_repositories = optional(map(object({
      description     = optional(string)
      max_unique_tags = optional(number, 0)
    })), {})
    virtual_generic_repositories = optional(map(object({
      description             = optional(string)
      repositories            = list(string)
      default_deployment_repo = optional(string)
    })), {})
    virtual_docker_repositories = optional(map(object({
      description             = optional(string)
      repositories            = list(string)
      default_deployment_repo = optional(string)
    })), {})
    permission_targets = optional(map(object({
      repositories      = set(string)
      includes_patterns = optional(set(string), ["**"])
      excludes_patterns = optional(set(string), [])
      group_permissions = optional(map(set(string)), {})
      user_permissions  = optional(map(set(string)), {})
    })), {})
  })
  default = {}
}