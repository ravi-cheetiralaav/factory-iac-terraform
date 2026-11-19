locals {
  push_rules = merge({}, try(var.spec.push_rules, null))
}

resource "gitlab_project_push_rules" "main" {
  count = length(local.push_rules) > 0 ? 1 : 0

  project                       = gitlab_project.main.id
  author_email_regex            = lookup(local.push_rules, "author_email_regex", null)
  branch_name_regex             = lookup(local.push_rules, "branch_name_regex", null)
  commit_committer_check        = lookup(local.push_rules, "commit_committer_check", null)
  commit_committer_name_check   = lookup(local.push_rules, "commit_committer_name_check", null)
  commit_message_negative_regex = lookup(local.push_rules, "commit_message_negative_regex", null)
  commit_message_regex          = lookup(local.push_rules, "commit_message_regex", null)
  deny_delete_tag               = lookup(local.push_rules, "deny_delete_tag", null)
  file_name_regex               = lookup(local.push_rules, "file_name_regex", null)
  max_file_size                 = lookup(local.push_rules, "max_file_size", null)
  member_check                  = lookup(local.push_rules, "member_check", null)
  prevent_secrets               = lookup(local.push_rules, "prevent_secrets", null)
  reject_non_dco_commits        = lookup(local.push_rules, "reject_non_dco_commits", null)
  reject_unsigned_commits       = lookup(local.push_rules, "reject_unsigned_commits", null)
}
