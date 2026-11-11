resource "gitlab_group_protected_environment" "environments" {
  for_each = local.group_protected_environments

  group                = local.group_ids[each.value.group_key]
  environment          = each.value.environment
  deploy_access_levels = each.value.deploy_access_levels
  approval_rules       = each.value.approval_rules

  depends_on = [gitlab_group_membership.memberships]

  lifecycle {
    precondition {
      condition     = var.configuration.is_enterprise
      error_message = "Group protected environments require a supported GitLab Enterprise license and is_enterprise = true."
    }
  }
}