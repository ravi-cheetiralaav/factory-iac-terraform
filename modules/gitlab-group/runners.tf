resource "gitlab_user_runner" "this" {
  for_each = local.runners

  runner_type      = "group_type"
  group_id         = tonumber(gitlab_group.this[each.value.group_key].id)
  description      = each.value.description
  tag_list         = toset(try(each.value.tag_list, []))
  untagged         = try(each.value.untagged, false)
  locked           = try(each.value.locked, false)
  access_level     = try(each.value.access_level, "not_protected")
  paused           = try(each.value.paused, false)
  maximum_timeout  = try(each.value.maximum_timeout, null)
  maintenance_note = try(each.value.maintenance_note, null)
}
