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

resource "artifactory_group" "groups" {
  for_each = var.configuration.groups

  name             = each.key
  description      = each.value.description
  admin_privileges = false
  auto_join        = false

  lifecycle {
    prevent_destroy = true
  }
}

resource "artifactory_user" "users" {
  for_each = var.configuration.users

  name                       = each.key
  email                      = each.value.email
  groups                     = each.value.groups
  admin                      = false
  profile_updatable          = true
  internal_password_disabled = each.value.should_disable_internal_password
  disable_ui_access          = each.value.should_disable_ui_access

  depends_on = [artifactory_group.groups]

  lifecycle {
    prevent_destroy = true
  }
}

resource "artifactory_local_generic_repository" "repositories" {
  for_each = var.configuration.local_generic_repositories

  key             = each.key
  description     = each.value.description
  repo_layout_ref = "simple-default"

  lifecycle {
    prevent_destroy = true
  }
}

resource "artifactory_local_docker_v2_repository" "repositories" {
  for_each = var.configuration.local_docker_repositories

  key                   = each.key
  description           = each.value.description
  block_pushing_schema1 = true
  max_unique_tags       = each.value.max_unique_tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "artifactory_virtual_generic_repository" "repositories" {
  for_each = var.configuration.virtual_generic_repositories

  key                     = each.key
  description             = each.value.description
  repo_layout_ref         = "simple-default"
  repositories            = each.value.repositories
  default_deployment_repo = each.value.default_deployment_repo

  depends_on = [artifactory_local_generic_repository.repositories]

  lifecycle {
    prevent_destroy = true
  }
}

resource "artifactory_virtual_docker_repository" "repositories" {
  for_each = var.configuration.virtual_docker_repositories

  key                     = each.key
  description             = each.value.description
  repositories            = each.value.repositories
  default_deployment_repo = each.value.default_deployment_repo

  depends_on = [artifactory_local_docker_v2_repository.repositories]

  lifecycle {
    prevent_destroy = true
  }
}

resource "artifactory_permission_target" "permissions" {
  for_each = var.configuration.permission_targets

  name = each.key

  repo {
    repositories     = each.value.repositories
    includes_pattern = each.value.includes_patterns
    excludes_pattern = each.value.excludes_patterns

    actions {
      dynamic "groups" {
        for_each = each.value.group_permissions
        content {
          name        = groups.key
          permissions = groups.value
        }
      }

      dynamic "users" {
        for_each = each.value.user_permissions
        content {
          name        = users.key
          permissions = users.value
        }
      }
    }
  }

  depends_on = [
    artifactory_group.groups,
    artifactory_user.users,
    artifactory_local_generic_repository.repositories,
    artifactory_local_docker_v2_repository.repositories
  ]
}