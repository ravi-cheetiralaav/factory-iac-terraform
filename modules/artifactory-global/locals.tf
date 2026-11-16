locals {
  package_types = toset(["docker", "generic", "go", "helm", "maven", "npm", "nuget", "pypi"])

  repo_layout = {
    docker  = "simple-default"
    generic = "simple-default"
    go      = "simple-default"
    helm    = "simple-default"
    maven   = "maven-2-default"
    npm     = "npm-default"
    nuget   = "nuget-default"
    pypi    = "simple-default"
  }

  local_repositories = {
    for repo in var.spec.local_repositories :
    repo.name => {
      name                     = repo.name
      key                      = repo.name
      package_type             = repo.package_type
      description              = try(repo.description, "")
      xray_index               = try(repo.xray_index, true)
      anonymous_read           = try(repo.anonymous_read, false)
      archive_browsing_enabled = try(repo.archive_browsing_enabled, false)
      tag_retention            = try(repo.tag_retention, null)
      max_unique_tags          = try(repo.max_unique_tags, null)
      handle_snapshots         = try(repo.handle_snapshots, true)
    }
  }

  virtual_repositories = {
    for repo in try(var.spec.virtual_repositories, []) :
    repo.name => {
      name                          = repo.name
      key                           = repo.name
      package_type                  = repo.package_type
      description                   = try(repo.description, "")
      repositories                  = repo.repositories
      default_deployment_repository = try(repo.default_deployment_repository, "")
      retrieve_remote_artifacts     = try(repo.retrieve_remote_artifacts, true)
    }
  }

  users = {
    for user in var.spec.users :
    user.name => {
      name   = user.name
      email  = user.email
      groups = try(user.groups, [])
    }
  }

  service_accounts = {
    for account in var.spec.service_accounts :
    account.name => {
      name   = account.name
      email  = account.email
      groups = try(account.groups, [])
    }
  }

  groups = {
    for group in var.spec.groups :
    group.name => {
      name        = group.name
      description = group.description
      members = distinct(concat(
        try(group.members, []),
        [for user in var.spec.users : user.name if contains(try(user.groups, []), group.name)],
        [for account in var.spec.service_accounts : account.name if contains(try(account.groups, []), group.name)],
      ))
    }
  }

  permissions = {
    for permission in var.spec.permissions :
    permission.name => {
      name         = permission.name
      repositories = permission.repositories
      groups = [
        for group in permission.groups : {
          name        = group.name
          permissions = group.permissions
        }
      ]
    }
  }

  xray_policies = {
    for policy in var.spec.xray.policies :
    policy.name => {
      name              = policy.name
      description       = policy.description
      min_severity      = try(policy.min_severity, null)
      malicious_package = try(policy.malicious_package, false)
    }
  }

  xray_watches = {
    for watch in var.spec.xray.watches :
    watch.name => {
      name         = watch.name
      description  = try(watch.description, watch.name)
      repositories = watch.repositories
      policies     = watch.policies
    }
  }

  locals_by_type = {
    for package_type in local.package_types :
    package_type => {
      for name, repo in local.local_repositories : name => repo
      if repo.package_type == package_type
    }
  }

  virtuals_by_type = {
    for package_type in local.package_types :
    package_type => {
      for name, repo in local.virtual_repositories : name => repo
      if repo.package_type == package_type
    }
  }

  anonymous_repositories = {
    for name, repo in local.local_repositories : name => repo
    if repo.anonymous_read
  }

  catalog_repository_names = setunion(
    toset(keys(local.local_repositories)),
    toset(keys(local.virtual_repositories)),
  )

  account_names = setunion(toset(keys(local.users)), toset(keys(local.service_accounts)))
}
