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

}

module "group" {
  source = "../../modules/gitlab-group"

  groups          = local.groups
  variable_values = var.gitlab_variable_values
}

module "project" {
  source   = "../../modules/gitlab-project"
  for_each = local.projects

  spec            = each.value
  namespace_id    = tonumber(module.group.group_ids[each.value.group])
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

output "runner_tokens" {
  description = "Sensitive runner authentication tokens for externally provisioned GitLab Runner processes"
  value = {
    groups   = module.group.runner_tokens
    projects = { for key, project in module.project : key => project.runner_tokens }
  }
  sensitive = true
}

moved {
  from = gitlab_group.this["platform"]
  to   = module.group.gitlab_group.this["platform"]
}

moved {
  from = gitlab_group.this["environment-sub-group"]
  to   = module.group.gitlab_group.this["environment-sub-group"]
}

moved {
  from = gitlab_group.this["devsecops-sub-group"]
  to   = module.group.gitlab_group.this["devsecops-sub-group"]
}

moved {
  from = gitlab_group.this["cicd-templates-sub-group"]
  to   = module.group.gitlab_group.this["cicd-templates-sub-group"]
}

moved {
  from = gitlab_group.this["security-engineering-sub-group"]
  to   = module.group.gitlab_group.this["security-engineering-sub-group"]
}
