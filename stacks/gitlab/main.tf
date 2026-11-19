locals {
  group_files   = fileset("${path.module}/../../catalog/gitlab/groups", "*.yaml")
  project_files = fileset("${path.module}/../../catalog/gitlab/projects", "*.yaml")

  groups = {
    for file in local.group_files :
    trimsuffix(file, ".yaml") => yamldecode(file("${path.module}/../../catalog/gitlab/groups/${file}"))
  }

  projects = {
    for file in local.project_files :
    trimsuffix(file, ".yaml") => yamldecode(file("${path.module}/../../catalog/gitlab/projects/${file}"))
  }

  users       = yamldecode(file("${path.module}/../../catalog/gitlab/users.yaml"))
  admin_roles = yamldecode(file("${path.module}/../../catalog/gitlab/admin-roles.yaml"))
}

module "user" {
  source = "../../modules/gitlab-user"

  users       = local.users
  passwords   = var.gitlab_user_passwords
  admin_roles = local.admin_roles
}

moved {
  from = module.admin_role.gitlab_admin_role.main
  to   = module.user.gitlab_admin_role.main
}

module "group" {
  source = "../../modules/gitlab-group"

  groups          = local.groups
  user_ids        = module.user.user_ids
  variable_values = var.gitlab_variable_values
}


module "project" {
  source   = "../../modules/gitlab-project"
  for_each = local.projects

  spec            = each.value
  namespace_id    = tonumber(module.group.group_ids[each.value.group])
  user_ids        = module.user.user_ids
  variable_values = var.gitlab_variable_values

  depends_on = [terraform_data.catalog_checks]
}

output "group_ids" {
  description = "GitLab group IDs keyed by catalog filename"
  value       = module.group.group_ids
}

output "project_ids" {
  description = "GitLab project IDs keyed by catalog filename"
  value       = { for key, project in module.project : key => project.project_id }
}

output "project_service_account_ids" {
  description = "GitLab service account user IDs keyed by project and service account catalog identifiers"
  value = {
    for key, project in module.project : key => project.service_account_ids
    if length(project.service_account_ids) > 0
  }
}

output "user_ids" {
  description = "GitLab user IDs keyed by username"
  value       = module.user.user_ids
}

output "admin_role_ids" {
  description = "GitLab global admin role IDs keyed by catalog identifier"
  value       = module.user.admin_role_ids
}

output "runner_tokens" {
  description = "Sensitive runner authentication tokens for externally provisioned GitLab Runner processes"
  value = {
    groups   = module.group.runner_tokens
    projects = { for key, project in module.project : key => project.runner_tokens }
  }
  sensitive = true
}

