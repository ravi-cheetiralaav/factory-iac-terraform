resource "gitlab_group" "this" {
  for_each = var.groups

  depends_on = [terraform_data.checks]

  name        = each.value.name
  path        = each.value.path
  description = try(each.value.description, null)
  parent_id = try(each.value.parent_group, null) == null ? null : tonumber(
    gitlab_group.this[each.value.parent_group].id
  )

  visibility_level                                 = try(each.value.visibility_level, "private")
  project_creation_level                           = try(each.value.project_creation_level, "maintainer")
  subgroup_creation_level                          = try(each.value.subgroup_creation_level, "owner")
  shared_runners_setting                           = try(each.value.shared_runners_setting, "enabled")
  membership_lock                                  = try(each.value.membership_lock, false)
  require_two_factor_authentication                = try(each.value.require_two_factor_authentication, false)
  request_access_enabled                           = try(each.value.request_access_enabled, false)
  emails_enabled                                   = try(each.value.emails_enabled, true)
  lfs_enabled                                      = try(each.value.lfs_enabled, true)
  prevent_forking_outside_group                    = try(each.value.prevent_forking_outside_group, false)
  archive_on_destroy                               = try(each.value.archive_on_destroy, true)
  default_branch                                   = try(each.value.default_branch, null)
  only_allow_merge_if_pipeline_succeeds            = try(each.value.only_allow_merge_if_pipeline_succeeds, null)
  only_allow_merge_if_all_discussions_are_resolved = try(each.value.only_allow_merge_if_all_discussions_are_resolved, null)
}
