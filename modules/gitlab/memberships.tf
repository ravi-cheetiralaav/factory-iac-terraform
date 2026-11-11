resource "gitlab_group_membership" "memberships" {
  for_each = var.configuration.group_memberships

  group_id     = local.group_ids[each.value.group_key]
  user_id      = local.user_ids[each.value.username]
  access_level = each.value.access_level
  expires_at   = each.value.expires_at
}

resource "gitlab_project_membership" "memberships" {
  for_each = var.configuration.project_memberships

  project      = gitlab_project.projects[each.value.project_key].id
  user_id      = local.user_ids[each.value.username]
  access_level = each.value.access_level
  expires_at   = each.value.expires_at
}