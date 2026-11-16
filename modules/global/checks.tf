resource "terraform_data" "catalog_checks" {
  input = sort(tolist(local.catalog_repository_names))

  lifecycle {
    precondition {
      condition = alltrue([
        for repo in local.local_repositories : contains(local.package_types, repo.package_type)
      ])
      error_message = "Unsupported local package_type. Supported types: docker, generic, go, helm, maven, npm, nuget, pypi."
    }

    precondition {
      condition = alltrue([
        for repo in local.virtual_repositories : contains(local.package_types, repo.package_type)
      ])
      error_message = "Unsupported virtual package_type. Supported types: docker, generic, go, helm, maven, npm, nuget, pypi."
    }

    precondition {
      condition = alltrue([
        for repo in local.local_repositories : can(regex("^[a-z][a-z0-9-]{0,62}$", repo.key))
      ])
      error_message = "Global local repository names must start with a letter and contain only lowercase letters, digits, and hyphens."
    }

    precondition {
      condition = alltrue([
        for repo in local.virtual_repositories : alltrue([
          for member in repo.repositories : contains(keys(local.local_repositories), member)
        ])
      ])
      error_message = "A global virtual repository member must be a local repository in this catalog."
    }

    precondition {
      condition = alltrue([
        for repo in local.virtual_repositories :
        repo.default_deployment_repository == "" || contains(keys(local.local_repositories), repo.default_deployment_repository)
      ])
      error_message = "default_deployment_repository must be empty or a global local repository name."
    }

    precondition {
      condition = alltrue([
        for permission in local.permissions : alltrue([
          for repo in permission.repositories : contains(local.catalog_repository_names, repo)
        ])
      ])
      error_message = "A global permission lists a repository that is not in this catalog."
    }

    precondition {
      condition = alltrue([
        for permission in local.permissions : alltrue([
          for group in permission.groups : contains(keys(local.groups), group.name)
        ])
      ])
      error_message = "A global permission references a group that is not declared in groups."
    }

    precondition {
      condition = alltrue([
        for name, group in local.groups : alltrue([
          for member in group.members : contains(local.account_names, member)
        ])
      ])
      error_message = "A group member is not declared under users or service_accounts."
    }

    precondition {
      condition = alltrue([
        for watch in local.xray_watches : alltrue([
          for repo in watch.repositories : contains(keys(local.local_repositories), repo)
        ])
      ])
      error_message = "An Xray watch lists a repository that is not a global local repository."
    }

    precondition {
      condition = alltrue([
        for watch in local.xray_watches : alltrue([
          for policy in watch.policies : contains(keys(local.xray_policies), policy)
        ])
      ])
      error_message = "An Xray watch lists a policy that is not declared under xray.policies."
    }

    precondition {
      condition     = !var.enable_anonymous_access || length(local.anonymous_repositories) > 0
      error_message = "enable_anonymous_access is true but no local repository sets anonymous_read."
    }
  }
}
