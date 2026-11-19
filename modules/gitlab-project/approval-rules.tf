resource "gitlab_project_approval_rule" "this" {
  for_each = local.approval_rules

  project                           = gitlab_project.main.id
  name                              = each.key
  approvals_required                = each.value.approvals_required
  rule_type                         = try(each.value.rule_type, "regular")
  user_ids                          = try(each.value.user_ids, null)
  group_ids                         = try(each.value.group_ids, null)
  applies_to_all_protected_branches = try(each.value.applies_to_all_protected_branches, null)
  protected_branch_ids              = try(each.value.protected_branch_ids, null)
  report_type                       = try(each.value.report_type, null)
  disable_importing_default_any_approver_rule_on_create = try(
    each.value.disable_importing_default_any_approver_rule_on_create, null
  )

  lifecycle {
    precondition {
      condition     = length([for rule in values(local.approval_rules) : rule if try(rule.rule_type, "regular") == "any_approver"]) <= 1
      error_message = "A project can define at most one any_approver approval rule."
    }
  }
}
