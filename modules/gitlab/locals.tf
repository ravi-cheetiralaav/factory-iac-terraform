locals {
  project_push_rules = {
    for key, project in var.configuration.projects : key => project.push_rules
    if project.push_rules != null
  }
  project_mr_approvals = {
    for key, project in var.configuration.projects : key => project.mr_approvals
    if project.mr_approvals != null
  }
  project_labels = merge({}, [
    for project_key, project in var.configuration.projects : {
      for name, label in project.labels : jsonencode([project_key, name]) => merge(label, {
        project_key = project_key
        name        = name
      })
    }
  ]...)
  group_configurations = merge(var.configuration.groups, var.configuration.subgroups)
  group_mr_approvals = {
    for key, group in local.group_configurations : key => group.mr_approvals
    if group.mr_approvals != null
  }
  group_protected_environments = merge({}, [
    for group_key, group in local.group_configurations : {
      for environment, protection in group.protected_environments : jsonencode([group_key, environment]) => merge(protection, {
        group_key   = group_key
        environment = environment
      })
    }
  ]...)
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