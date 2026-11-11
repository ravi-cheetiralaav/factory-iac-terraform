resource "project_project" "projects" {
  for_each = var.configuration.projects

  key                        = each.value.key
  display_name               = each.value.display_name
  description                = "Paired with GitLab project configuration ${each.key}"
  max_storage_in_gibibytes   = -1
  block_deployments_on_limit = false

  admin_privileges {
    manage_members   = false
    manage_resources = false
    index_resources  = false
  }

  lifecycle {
    prevent_destroy = true

    precondition {
      condition     = length(distinct([for project in values(var.configuration.projects) : project.key])) == length(var.configuration.projects)
      error_message = "Each GitLab project must map to a unique JFrog project key."
    }
  }
}