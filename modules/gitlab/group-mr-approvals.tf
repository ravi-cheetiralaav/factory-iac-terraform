resource "gitlab_group_level_mr_approvals" "groups" {
  for_each = local.group_mr_approvals

  group                                              = local.group_ids[each.key]
  allow_author_approval                              = each.value.should_allow_author_approval
  allow_committer_approval                           = each.value.should_allow_committer_approval
  allow_overrides_to_approver_list_per_merge_request = each.value.should_allow_overrides_to_approver_list_per_merge_request
  retain_approvals_on_push                           = each.value.should_retain_approvals_on_push
  require_reauthentication_to_approve                = each.value.should_require_reauthentication_to_approve
  keep_settings_on_destroy                           = each.value.should_keep_settings_on_destroy

  lifecycle {
    precondition {
      condition     = var.configuration.is_enterprise
      error_message = "Group MR approval settings require a supported GitLab Enterprise license and is_enterprise = true."
    }
  }
}