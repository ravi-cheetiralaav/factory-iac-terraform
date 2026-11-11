resource "gitlab_project_push_rules" "projects" {
  for_each = local.project_push_rules

  project                       = gitlab_project.projects[each.key].id
  author_email_regex            = each.value.author_email_regex
  branch_name_regex             = each.value.branch_name_regex
  commit_message_regex          = each.value.commit_message_regex
  commit_message_negative_regex = each.value.commit_message_negative_regex
  file_name_regex               = each.value.file_name_regex
  max_file_size                 = each.value.max_file_size
  commit_committer_check        = each.value.should_check_committer_email
  commit_committer_name_check   = each.value.should_check_committer_name
  deny_delete_tag               = each.value.should_deny_tag_deletion
  member_check                  = each.value.should_check_member
  prevent_secrets               = each.value.should_prevent_secrets
  reject_non_dco_commits        = each.value.should_reject_non_dco_commits
  reject_unsigned_commits       = each.value.should_reject_unsigned_commits

  lifecycle {
    precondition {
      condition     = var.configuration.is_enterprise
      error_message = "Project push rules require GitLab Premium or Ultimate and is_enterprise = true."
    }
  }
}