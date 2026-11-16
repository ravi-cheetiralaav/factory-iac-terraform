resource "terraform_data" "catalog_checks" {
  input = local.project_key

  lifecycle {
    precondition {
      condition     = can(regex("^[a-z][a-z0-9-]{1,31}$", local.project_key))
      error_message = "Project key must be 2-32 characters, start with a letter, and contain only lowercase letters, digits, and hyphens."
    }

    precondition {
      condition     = local.admin_privileges.manage_resources || !local.admin_privileges.manage_remote_repository
      error_message = "admin_privileges.manage_remote_repository requires manage_resources."
    }

    precondition {
      condition     = length(setintersection(toset(keys(local.local_repositories)), toset(keys(local.virtual_repositories)))) == 0
      error_message = "A local repository and a virtual repository use the same name. They would be created with the same Artifactory key."
    }

    precondition {
      condition = alltrue([
        for repo in local.local_repositories : contains(local.package_types, repo.package_type) && contains(local.environments, repo.environment)
      ])
      error_message = "Local repositories must use a supported package_type and environment DEV or PROD."
    }

    precondition {
      condition = alltrue([
        for repo in local.virtual_repositories : contains(local.package_types, repo.package_type) && contains(local.environments, repo.environment)
      ])
      error_message = "Virtual repositories must use a supported package_type and environment DEV or PROD."
    }

    precondition {
      condition = alltrue([
        for repo in merge(local.local_repositories, local.virtual_repositories) :
        can(regex("^[a-z][a-z0-9-]{1,31}$", repo.name)) && length(repo.key) <= 64
      ])
      error_message = "Repository names must be lowercase letters, digits, and hyphens. The Artifactory key, including the project prefix, must be 64 characters or fewer."
    }

    precondition {
      condition = alltrue([
        for repo in local.local_repositories : !repo.anonymous_read
      ])
      error_message = "Anonymous access is not granted inside projects. Mark anonymous_read on a global local repository instead."
    }

    precondition {
      condition = alltrue([
        for name, group in local.groups : contains(keys(local.roles), group.role)
      ])
      error_message = "A group references a role that is not declared in roles."
    }

    precondition {
      condition = alltrue([
        for role in local.roles : alltrue([
          for environment in role.environments : contains(local.environments, environment)
        ]) && length(role.actions) > 0
      ])
      error_message = "Each role needs at least one action and may only list DEV or PROD until a custom project_environment is added."
    }

    precondition {
      condition = alltrue([
        for member in local.direct_members : alltrue([
          for role in member.roles : contains(keys(local.roles), role)
        ])
      ])
      error_message = "A direct_member references a role that is not declared in roles."
    }

    precondition {
      condition = alltrue([
        for repo in local.virtual_repositories : alltrue([
          for member in repo.repositories :
          contains(keys(local.local_repositories), member) || contains(keys(local.shared_repositories), member)
        ])
      ])
      error_message = "A virtual repository member must be a local repository name from this project or a shared_repositories key."
    }

    precondition {
      condition = alltrue([
        for repo in local.virtual_repositories :
        repo.default_deployment_repository == "" || contains(keys(local.local_repositories), repo.default_deployment_repository)
      ])
      error_message = "default_deployment_repository must be empty or a local repository name from this project."
    }
  }
}
