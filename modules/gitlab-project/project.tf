resource "gitlab_project" "main" {
  depends_on = [terraform_data.checks]

  name                            = var.spec.name
  path                            = try(var.spec.path, null)
  namespace_id                    = var.namespace_id
  description                     = try(var.spec.description, null)
  visibility_level                = try(var.spec.visibility_level, "private")
  default_branch                  = try(var.spec.default_branch, null)
  initialize_with_readme          = try(var.spec.initialize_with_readme, false)
  archive_on_destroy              = try(var.spec.archive_on_destroy, true)
  shared_runners_enabled          = try(var.spec.shared_runners_enabled, true)
  group_runners_enabled           = try(var.spec.group_runners_enabled, true)
  issues_access_level             = try(var.spec.issues_access_level, "enabled")
  merge_requests_access_level     = try(var.spec.merge_requests_access_level, "enabled")
  wiki_access_level               = try(var.spec.wiki_access_level, "enabled")
  snippets_access_level           = try(var.spec.snippets_access_level, "enabled")
  builds_access_level             = try(var.spec.builds_access_level, "enabled")
  container_registry_access_level = try(var.spec.container_registry_access_level, "enabled")
}
