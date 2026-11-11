resource "gitlab_project_label" "labels" {
  for_each = local.project_labels

  project     = gitlab_project.projects[each.value.project_key].id
  name        = each.value.name
  color       = each.value.color
  description = each.value.description
  priority    = each.value.priority
}