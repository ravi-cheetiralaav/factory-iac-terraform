resource "gitlab_project_membership" "this" {
  for_each = local.members

  project      = gitlab_project.main.id
  user_id      = try(each.value.user_id, null) != null ? each.value.user_id : try(var.user_ids[each.value.username], null)
  access_level = each.value.access_level
  expires_at   = try(each.value.expires_at, null)

  lifecycle {
    precondition {
      condition     = (try(each.value.user_id, null) != null) != (try(each.value.username, null) != null)
      error_message = "Each project member must specify exactly one of user_id or username."
    }

    precondition {
      condition     = try(each.value.username, null) == null ? true : contains(keys(var.user_ids), each.value.username)
      error_message = "The project member's username must exist in the GitLab user catalog."
    }
  }
}
