resource "gitlab_project_membership" "this" {
  for_each = local.members

  project      = gitlab_project.main.id
  user_id      = each.value.user_id
  access_level = each.value.access_level
  expires_at   = try(each.value.expires_at, null)
}
