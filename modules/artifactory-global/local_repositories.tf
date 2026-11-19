resource "artifactory_local_docker_v2_repository" "this" {
  for_each = local.locals_by_type["docker"]

  key                      = each.value.key
  description              = each.value.description != "" ? each.value.description : null
  repo_layout_ref          = local.repo_layout["docker"]
  xray_index               = each.value.xray_index
  archive_browsing_enabled = each.value.archive_browsing_enabled
  block_pushing_schema1    = true
  tag_retention            = each.value.tag_retention
  max_unique_tags          = each.value.max_unique_tags
}

resource "artifactory_local_generic_repository" "this" {
  for_each = local.locals_by_type["generic"]

  key                      = each.value.key
  description              = each.value.description != "" ? each.value.description : null
  repo_layout_ref          = local.repo_layout["generic"]
  xray_index               = each.value.xray_index
  archive_browsing_enabled = each.value.archive_browsing_enabled
}

resource "artifactory_local_go_repository" "this" {
  for_each = local.locals_by_type["go"]

  key                      = each.value.key
  description              = each.value.description != "" ? each.value.description : null
  repo_layout_ref          = local.repo_layout["go"]
  xray_index               = each.value.xray_index
  archive_browsing_enabled = each.value.archive_browsing_enabled
}

resource "artifactory_local_helm_repository" "this" {
  for_each = local.locals_by_type["helm"]

  key                      = each.value.key
  description              = each.value.description != "" ? each.value.description : null
  repo_layout_ref          = local.repo_layout["helm"]
  xray_index               = each.value.xray_index
  archive_browsing_enabled = each.value.archive_browsing_enabled
}

resource "artifactory_local_maven_repository" "this" {
  for_each = local.locals_by_type["maven"]

  key                       = each.value.key
  description               = each.value.description != "" ? each.value.description : null
  repo_layout_ref           = local.repo_layout["maven"]
  xray_index                = each.value.xray_index
  archive_browsing_enabled  = each.value.archive_browsing_enabled
  checksum_policy_type      = "client-checksums"
  snapshot_version_behavior = "unique"
  max_unique_snapshots      = 0
  handle_releases           = true
  handle_snapshots          = each.value.handle_snapshots
}

resource "artifactory_local_npm_repository" "this" {
  for_each = local.locals_by_type["npm"]

  key                      = each.value.key
  description              = each.value.description != "" ? each.value.description : null
  repo_layout_ref          = local.repo_layout["npm"]
  xray_index               = each.value.xray_index
  archive_browsing_enabled = each.value.archive_browsing_enabled
}

resource "artifactory_local_nuget_repository" "this" {
  for_each = local.locals_by_type["nuget"]

  key                      = each.value.key
  description              = each.value.description != "" ? each.value.description : null
  repo_layout_ref          = local.repo_layout["nuget"]
  xray_index               = each.value.xray_index
  archive_browsing_enabled = each.value.archive_browsing_enabled
}

resource "artifactory_local_pypi_repository" "this" {
  for_each = local.locals_by_type["pypi"]

  key                      = each.value.key
  description              = each.value.description != "" ? each.value.description : null
  repo_layout_ref          = local.repo_layout["pypi"]
  xray_index               = each.value.xray_index
  archive_browsing_enabled = each.value.archive_browsing_enabled
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
