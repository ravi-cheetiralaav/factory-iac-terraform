resource "gitlab_group" "groups" {
  for_each = var.configuration.groups

  name                    = each.value.name
  path                    = each.value.path
  description             = each.value.description
  parent_id               = each.value.parent_id
  visibility_level        = each.value.visibility_level
  project_creation_level  = each.value.project_creation_level
  subgroup_creation_level = "owner"

  lifecycle {
    prevent_destroy = true
  }
}

resource "gitlab_group" "subgroups" {
  for_each = var.configuration.subgroups

  name                    = each.value.name
  path                    = each.value.path
  parent_id               = gitlab_group.groups[each.value.parent_group_key].id
  description             = each.value.description
  visibility_level        = each.value.visibility_level
  project_creation_level  = each.value.project_creation_level
  subgroup_creation_level = "owner"

  lifecycle {
    prevent_destroy = true
    precondition {
      condition     = !contains(keys(var.configuration.groups), each.key)
      error_message = "Group and subgroup configuration keys must be distinct."
    }
  }
}

resource "gitlab_user" "users" {
  for_each = var.configuration.users

  username              = each.key
  name                  = each.value.name
  email                 = each.value.email
  is_admin              = false
  is_external           = each.value.is_external
  can_create_group      = false
  projects_limit        = 0
  force_random_password = true
  reset_password        = each.value.should_send_reset_email
  skip_confirmation     = false
  state                 = each.value.state

  lifecycle {
    prevent_destroy = true
    precondition {
      condition     = !contains(var.configuration.existing_users, each.key)
      error_message = "A username must be either managed or looked up, not both."
    }
  }
}

data "gitlab_user" "existing" {
  for_each = var.configuration.existing_users
  username = each.key
}

locals {
  group_ids = merge(
    { for key, group in gitlab_group.groups : key => group.id },
    { for key, group in gitlab_group.subgroups : key => group.id }
  )
  user_ids = merge(
    { for username, user in gitlab_user.users : username => user.id },
    { for username, user in data.gitlab_user.existing : username => user.id }
  )
  branch_protections = merge({}, [
    for project_key, project in var.configuration.projects : {
      for branch, protection in merge({
        (project.default_branch) = {
          push_access_level                  = "no one"
          merge_access_level                 = "maintainer"
          should_allow_force_push            = false
          should_require_code_owner_approval = false
        }
        }, project.branch_protections) : jsonencode([project_key, branch]) => merge(protection, {
        project_key = project_key
        branch      = branch
      })
    }
  ]...)
}

resource "gitlab_project" "projects" {
  for_each = var.configuration.projects

  name                                             = each.value.name
  path                                             = each.value.path
  namespace_id                                     = local.group_ids[each.value.group_key]
  description                                      = each.value.description
  default_branch                                   = each.value.default_branch
  visibility_level                                 = each.value.visibility_level
  initialize_with_readme                           = each.value.should_initialize_with_readme
  only_allow_merge_if_pipeline_succeeds            = each.value.should_require_successful_pipeline
  only_allow_merge_if_all_discussions_are_resolved = each.value.should_require_resolved_discussions
  remove_source_branch_after_merge                 = true
  merge_method                                     = each.value.merge_method

  lifecycle {
    prevent_destroy = true
  }
}

resource "gitlab_group_membership" "memberships" {
  for_each = var.configuration.group_memberships

  group_id     = local.group_ids[each.value.group_key]
  user_id      = local.user_ids[each.value.username]
  access_level = each.value.access_level
  expires_at   = each.value.expires_at
}

resource "gitlab_project_membership" "memberships" {
  for_each = var.configuration.project_memberships

  project      = gitlab_project.projects[each.value.project_key].id
  user_id      = local.user_ids[each.value.username]
  access_level = each.value.access_level
  expires_at   = each.value.expires_at
}

resource "gitlab_branch_protection" "branches" {
  for_each = local.branch_protections

  project                      = gitlab_project.projects[each.value.project_key].id
  branch                       = each.value.branch
  push_access_level            = var.configuration.is_enterprise ? null : each.value.push_access_level
  merge_access_level           = var.configuration.is_enterprise ? null : each.value.merge_access_level
  allowed_to_push              = var.configuration.is_enterprise ? [{ access_level = each.value.push_access_level }] : null
  allowed_to_merge             = var.configuration.is_enterprise ? [{ access_level = each.value.merge_access_level }] : null
  allow_force_push             = each.value.should_allow_force_push
  code_owner_approval_required = var.configuration.is_enterprise ? each.value.should_require_code_owner_approval : null

  lifecycle {
    precondition {
      condition     = var.configuration.is_enterprise || !each.value.should_require_code_owner_approval
      error_message = "Code owner approval requires a supported GitLab Enterprise license and is_enterprise = true."
    }
  }
}