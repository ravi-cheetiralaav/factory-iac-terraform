variable "configuration" {
  description = "GitLab hierarchy, identities, memberships, labels, push rules, branch protection and approval and deployment policies"
  type = object({
    is_enterprise = optional(bool, false)
    groups = optional(map(object({
      name                   = string
      path                   = string
      description            = optional(string)
      parent_id              = optional(number)
      visibility_level       = optional(string, "private")
      project_creation_level = optional(string, "maintainer")
      mr_approvals = optional(object({
        should_allow_author_approval                              = optional(bool, false)
        should_allow_committer_approval                           = optional(bool, false)
        should_allow_overrides_to_approver_list_per_merge_request = optional(bool, false)
        should_retain_approvals_on_push                           = optional(bool, false)
        should_require_reauthentication_to_approve                = optional(bool)
        should_keep_settings_on_destroy                           = optional(bool, true)
      }))
      protected_environments = optional(map(object({
        deploy_access_levels = set(object({
          access_level           = optional(string)
          group_id               = optional(number)
          user_id                = optional(number)
          group_inheritance_type = optional(number, 0)
        }))
        approval_rules = optional(set(object({
          access_level           = optional(string)
          group_id               = optional(number)
          user_id                = optional(number)
          group_inheritance_type = optional(number, 0)
          required_approvals     = optional(number)
        })), [])
      })), {})
    })), {})
    subgroups = optional(map(object({
      name                   = string
      path                   = string
      parent_group_key       = string
      description            = optional(string)
      visibility_level       = optional(string, "private")
      project_creation_level = optional(string, "maintainer")
      mr_approvals = optional(object({
        should_allow_author_approval                              = optional(bool, false)
        should_allow_committer_approval                           = optional(bool, false)
        should_allow_overrides_to_approver_list_per_merge_request = optional(bool, false)
        should_retain_approvals_on_push                           = optional(bool, false)
        should_require_reauthentication_to_approve                = optional(bool)
        should_keep_settings_on_destroy                           = optional(bool, true)
      }))
      protected_environments = optional(map(object({
        deploy_access_levels = set(object({
          access_level           = optional(string)
          group_id               = optional(number)
          user_id                = optional(number)
          group_inheritance_type = optional(number, 0)
        }))
        approval_rules = optional(set(object({
          access_level           = optional(string)
          group_id               = optional(number)
          user_id                = optional(number)
          group_inheritance_type = optional(number, 0)
          required_approvals     = optional(number)
        })), [])
      })), {})
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
      push_rules = optional(object({
        author_email_regex             = optional(string)
        branch_name_regex              = optional(string)
        commit_message_regex           = optional(string)
        commit_message_negative_regex  = optional(string)
        file_name_regex                = optional(string)
        max_file_size                  = optional(number)
        should_check_committer_email   = optional(bool)
        should_check_committer_name    = optional(bool)
        should_deny_tag_deletion       = optional(bool)
        should_check_member            = optional(bool)
        should_prevent_secrets         = optional(bool)
        should_reject_non_dco_commits  = optional(bool)
        should_reject_unsigned_commits = optional(bool)
      }))
      labels = optional(map(object({
        color       = string
        description = optional(string)
        priority    = optional(number)
      })), {})
      mr_approvals = optional(object({
        should_allow_author_approval               = optional(bool, false)
        should_allow_committer_approval            = optional(bool, false)
        should_allow_approver_overrides            = optional(bool, false)
        should_reset_approvals_on_push             = optional(bool, true)
        should_remove_changed_code_owner_approvals = optional(bool, false)
        should_require_reauthentication_to_approve = optional(bool)
      }))
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