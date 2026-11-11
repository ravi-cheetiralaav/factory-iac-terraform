resource "artifactory_user" "robots" {
  for_each = var.configuration.projects

  name                       = "robot-${each.value.key}"
  email                      = each.value.robot_email
  groups                     = []
  admin                      = false
  profile_updatable          = false
  internal_password_disabled = true
  disable_ui_access          = true

  lifecycle {
    prevent_destroy = true

    precondition {
      condition     = !contains(keys(var.configuration.users), "robot-${each.value.key}")
      error_message = "Robot usernames are managed automatically and must not also appear in artifactory.users."
    }
  }
}

resource "project_role" "ci_publishers" {
  for_each = var.configuration.projects

  project_key  = project_project.projects[each.key].key
  name         = "ci-publisher"
  type         = "CUSTOM"
  environments = ["DEV", "PROD"]
  actions = [
    "READ_REPOSITORY",
    "ANNOTATE_REPOSITORY",
    "DEPLOY_CACHE_REPOSITORY",
    "READ_BUILD",
    "ANNOTATE_BUILD",
    "DEPLOY_BUILD"
  ]
}

resource "project_user" "robots" {
  for_each = var.configuration.projects

  project_key = project_project.projects[each.key].key
  name        = artifactory_user.robots[each.key].name
  roles       = [project_role.ci_publishers[each.key].name]
}