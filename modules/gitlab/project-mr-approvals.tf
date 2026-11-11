resource "gitlab_project_level_mr_approvals" "projects" {
  for_each = local.project_mr_approvals

  project                                        = gitlab_project.projects[each.key].id
  merge_requests_author_approval                 = each.value.should_allow_author_approval
  merge_requests_disable_committers_approval     = !each.value.should_allow_committer_approval
  disable_overriding_approvers_per_merge_request = !each.value.should_allow_approver_overrides
  reset_approvals_on_push                        = each.value.should_reset_approvals_on_push
  selective_code_owner_removals                  = each.value.should_remove_changed_code_owner_approvals
  require_reauthentication_to_approve            = each.value.should_require_reauthentication_to_approve

  lifecycle {
    precondition {
      condition     = var.configuration.is_enterprise
      error_message = "Project MR approval settings require a supported GitLab Enterprise license and is_enterprise = true."
    }
  }
}