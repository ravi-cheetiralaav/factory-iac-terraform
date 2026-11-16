resource "gitlab_group_membership" "this" {
  for_each = local.members

  group_id     = tonumber(gitlab_group.this[each.value.group_key].id)
  user_id      = each.value.user_id
  access_level = each.value.access_level
  expires_at   = try(each.value.expires_at, null)
}
