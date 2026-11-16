resource "artifactory_local_docker_v2_repository" "this" {
  for_each = local.locals_by_type["docker"]

  key                      = each.value.key
  description              = each.value.description != "" ? each.value.description : null
  repo_layout_ref          = local.repo_layout["docker"]
  xray_index               = each.value.xray_index
  archive_browsing_enabled = each.value.archive_browsing_enabled
  project_environments     = [each.value.environment]
  block_pushing_schema1    = true
  tag_retention            = each.value.tag_retention
  max_unique_tags          = each.value.max_unique_tags

  # project_repository assigns the repo. The provider rewrites project_key
  # after that assignment, so ignore it here or every plan tries to clear it.
  lifecycle {
    ignore_changes = [project_key]
  }
}

resource "artifactory_local_generic_repository" "this" {
  for_each = local.locals_by_type["generic"]

  key                      = each.value.key
  description              = each.value.description != "" ? each.value.description : null
  repo_layout_ref          = local.repo_layout["generic"]
  xray_index               = each.value.xray_index
  archive_browsing_enabled = each.value.archive_browsing_enabled
  project_environments     = [each.value.environment]

  lifecycle {
    ignore_changes = [project_key]
  }
}

resource "artifactory_local_go_repository" "this" {
  for_each = local.locals_by_type["go"]

  key                      = each.value.key
  description              = each.value.description != "" ? each.value.description : null
  repo_layout_ref          = local.repo_layout["go"]
  xray_index               = each.value.xray_index
  archive_browsing_enabled = each.value.archive_browsing_enabled
  project_environments     = [each.value.environment]

  lifecycle {
    ignore_changes = [project_key]
  }
}

resource "artifactory_local_helm_repository" "this" {
  for_each = local.locals_by_type["helm"]

  key                      = each.value.key
  description              = each.value.description != "" ? each.value.description : null
  repo_layout_ref          = local.repo_layout["helm"]
  xray_index               = each.value.xray_index
  archive_browsing_enabled = each.value.archive_browsing_enabled
  project_environments     = [each.value.environment]

  lifecycle {
    ignore_changes = [project_key]
  }
}

resource "artifactory_local_maven_repository" "this" {
  for_each = local.locals_by_type["maven"]

  key                       = each.value.key
  description               = each.value.description != "" ? each.value.description : null
  repo_layout_ref           = local.repo_layout["maven"]
  xray_index                = each.value.xray_index
  archive_browsing_enabled  = each.value.archive_browsing_enabled
  project_environments      = [each.value.environment]
  checksum_policy_type      = "client-checksums"
  snapshot_version_behavior = "unique"
  max_unique_snapshots      = 0
  handle_releases           = true
  handle_snapshots          = each.value.handle_snapshots

  lifecycle {
    ignore_changes = [project_key]
  }
}

resource "artifactory_local_npm_repository" "this" {
  for_each = local.locals_by_type["npm"]

  key                      = each.value.key
  description              = each.value.description != "" ? each.value.description : null
  repo_layout_ref          = local.repo_layout["npm"]
  xray_index               = each.value.xray_index
  archive_browsing_enabled = each.value.archive_browsing_enabled
  project_environments     = [each.value.environment]

  lifecycle {
    ignore_changes = [project_key]
  }
}

resource "artifactory_local_nuget_repository" "this" {
  for_each = local.locals_by_type["nuget"]

  key                      = each.value.key
  description              = each.value.description != "" ? each.value.description : null
  repo_layout_ref          = local.repo_layout["nuget"]
  xray_index               = each.value.xray_index
  archive_browsing_enabled = each.value.archive_browsing_enabled
  project_environments     = [each.value.environment]

  lifecycle {
    ignore_changes = [project_key]
  }
}

resource "artifactory_local_pypi_repository" "this" {
  for_each = local.locals_by_type["pypi"]

  key                      = each.value.key
  description              = each.value.description != "" ? each.value.description : null
  repo_layout_ref          = local.repo_layout["pypi"]
  xray_index               = each.value.xray_index
  archive_browsing_enabled = each.value.archive_browsing_enabled
  project_environments     = [each.value.environment]

  lifecycle {
    ignore_changes = [project_key]
  }
}

locals {
  local_repository_resource_keys = merge(
    { for name, repo in artifactory_local_docker_v2_repository.this : name => repo.key },
    { for name, repo in artifactory_local_generic_repository.this : name => repo.key },
    { for name, repo in artifactory_local_go_repository.this : name => repo.key },
    { for name, repo in artifactory_local_helm_repository.this : name => repo.key },
    { for name, repo in artifactory_local_maven_repository.this : name => repo.key },
    { for name, repo in artifactory_local_npm_repository.this : name => repo.key },
    { for name, repo in artifactory_local_nuget_repository.this : name => repo.key },
    { for name, repo in artifactory_local_pypi_repository.this : name => repo.key },
  )
}

resource "project_repository" "local" {
  for_each = local.local_repositories

  project_key = project_project.this.key
  key         = local.local_repository_resource_keys[each.key]
}
