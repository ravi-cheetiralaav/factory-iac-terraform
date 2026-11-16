locals {
  package_types = toset(["docker", "generic", "go", "helm", "maven", "npm", "nuget", "pypi"])
  environments  = toset(["DEV", "PROD"])

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

  project_key                = var.spec.key
  display_name               = var.spec.display_name
  description                = try(var.spec.description, "")
  storage_gib                = try(var.spec.storage_gib, 10)
  block_deployments_on_limit = try(var.spec.block_deployments_on_limit, false)
  email_notification         = try(var.spec.email_notification, true)
  xray_enabled               = try(var.spec.xray.enabled, true)
  xray_recipients            = try(var.spec.xray.recipients, [])

  admin_privileges = {
    manage_members           = try(var.spec.admin_privileges.manage_members, true)
    manage_resources         = try(var.spec.admin_privileges.manage_resources, true)
    manage_remote_repository = try(var.spec.admin_privileges.manage_remote_repository, false)
    index_resources          = try(var.spec.admin_privileges.index_resources, true)
  }

  roles = {
    for role in var.spec.roles :
    role.name => {
      name         = role.name
      environments = role.environments
      actions      = role.actions
    }
  }

  groups = {
    for group in var.spec.groups :
    group.name => {
      name        = group.name
      description = group.description
      role        = group.role
      permissions = try(group.permissions, [])
      members = distinct(concat(
        try(group.members, []),
        [for user in var.spec.users : user.name if contains(try(user.groups, []), group.name)],
        [for account in var.spec.service_accounts : account.name if contains(try(account.groups, []), group.name)],
      ))
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

  direct_members = {
    for member in var.direct_members :
    member.name => {
      name  = member.name
      roles = member.roles
    }
  }

  shared_repositories = {
    for repo in var.spec.shared_repositories :
    repo.key => {
      key       = repo.key
      read_only = try(repo.read_only, true)
    }
  }

  local_repositories = {
    for repo in var.spec.local_repositories :
    repo.name => {
      name                     = repo.name
      key                      = "${var.spec.key}-${repo.name}"
      package_type             = repo.package_type
      environment              = repo.environment
      description              = try(repo.description, "")
      xray_index               = try(repo.xray_index, true)
      anonymous_read           = try(repo.anonymous_read, false)
      archive_browsing_enabled = try(repo.archive_browsing_enabled, false)
      tag_retention            = try(repo.tag_retention, null)
      max_unique_tags          = try(repo.max_unique_tags, null)
      handle_snapshots         = try(repo.handle_snapshots, repo.environment == "DEV")
    }
  }

  virtual_repositories = {
    for repo in var.spec.virtual_repositories :
    repo.name => {
      name                          = repo.name
      key                           = "${var.spec.key}-${repo.name}"
      package_type                  = repo.package_type
      environment                   = repo.environment
      description                   = try(repo.description, "")
      repositories                  = repo.repositories
      default_deployment_repository = try(repo.default_deployment_repository, "")
      retrieve_remote_artifacts     = try(repo.retrieve_remote_artifacts, true)
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

  groups_with_permissions = {
    for name, group in local.groups : name => group
    if length(group.permissions) > 0
  }
}
