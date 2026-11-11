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