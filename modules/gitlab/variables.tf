variable "configuration" {
  description = "GitLab groups, one level of subgroups, projects, users, memberships and protected branches"
  type = object({
    is_enterprise = optional(bool, false)
    groups = optional(map(object({
      name                   = string
      path                   = string
      description            = optional(string)
      parent_id              = optional(number)
      visibility_level       = optional(string, "private")
      project_creation_level = optional(string, "maintainer")
    })), {})
    subgroups = optional(map(object({
      name                   = string
      path                   = string
      parent_group_key       = string
      description            = optional(string)
      visibility_level       = optional(string, "private")
      project_creation_level = optional(string, "maintainer")
    })), {})
    users = optional(map(object({
      name                    = string
      email                   = string
      is_external             = optional(bool, false)
      should_send_reset_email = optional(bool, true)
      state                   = optional(string, "active")
    })), {})
    existing_users = optional(set(string), [])
    group_memberships = optional(map(object({
      group_key    = string
      username     = string
      access_level = optional(string, "developer")
      expires_at   = optional(string)
    })), {})
    project_memberships = optional(map(object({
      project_key  = string
      username     = string
      access_level = optional(string, "developer")
      expires_at   = optional(string)
    })), {})
    projects = optional(map(object({
      name                                = string
      path                                = string
      group_key                           = string
      description                         = optional(string)
      default_branch                      = optional(string, "main")
      visibility_level                    = optional(string, "private")
      should_initialize_with_readme       = optional(bool, true)
      should_require_successful_pipeline  = optional(bool, true)
      should_require_resolved_discussions = optional(bool, true)
      merge_method                        = optional(string, "merge")
      branch_protections = optional(map(object({
        push_access_level                  = optional(string, "no one")
        merge_access_level                 = optional(string, "maintainer")
        should_allow_force_push            = optional(bool, false)
        should_require_code_owner_approval = optional(bool, false)
      })), {})
    })), {})
  })
  default = {}
}