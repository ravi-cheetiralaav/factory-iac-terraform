resource "gitlab_project" "projects" {
  for_each = var.configuration.projects

  name                                             = each.value.name
  path                                             = each.value.path
  namespace_id                                     = local.group_ids[each.value.group_key]
  description                                      = each.value.description
  default_branch                                   = each.value.default_branch
  visibility_level                                 = each.value.visibility_level
  initialize_with_readme                           = each.value.should_initialize_with_readme
  only_allow_merge_if_pipeline_succeeds            = each.value.should_require_successful_pipeline
  only_allow_merge_if_all_discussions_are_resolved = each.value.should_require_resolved_discussions
  remove_source_branch_after_merge                 = true
  merge_method                                     = each.value.merge_method

  lifecycle {
    prevent_destroy = true
  }
}