resource "gitlab_group" "groups" {
  for_each = var.configuration.groups

  name                    = each.value.name
  path                    = each.value.path
  description             = each.value.description
  parent_id               = each.value.parent_id
  visibility_level        = each.value.visibility_level
  project_creation_level  = each.value.project_creation_level
  subgroup_creation_level = "owner"

  lifecycle {
    prevent_destroy = true
  }
}

resource "gitlab_group" "subgroups" {
  for_each = var.configuration.subgroups

  name                    = each.value.name
  path                    = each.value.path
  parent_id               = gitlab_group.groups[each.value.parent_group_key].id
  description             = each.value.description
  visibility_level        = each.value.visibility_level
  project_creation_level  = each.value.project_creation_level
  subgroup_creation_level = "owner"

  lifecycle {
    prevent_destroy = true
    precondition {
      condition     = !contains(keys(var.configuration.groups), each.key)
      error_message = "Group and subgroup configuration keys must be distinct."
    }
  }
}