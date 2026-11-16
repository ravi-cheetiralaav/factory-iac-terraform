locals {
  # Virtual members are concrete repositories. Keeping virtual keys out of this
  # map avoids a dependency cycle between virtual repositories.
  member_repository_resource_keys = local.local_repository_resource_keys
}

resource "artifactory_virtual_docker_repository" "this" {
  for_each = local.virtuals_by_type["docker"]

  key                                                = each.value.key
  description                                        = each.value.description != "" ? each.value.description : null
  repo_layout_ref                                    = local.repo_layout["docker"]
  repositories                                       = [for member in each.value.repositories : local.member_repository_resource_keys[member]]
  default_deployment_repo                            = each.value.default_deployment_repository != "" ? local.local_repository_resource_keys[each.value.default_deployment_repository] : null
  artifactory_requests_can_retrieve_remote_artifacts = each.value.retrieve_remote_artifacts
  resolve_docker_tags_by_timestamp                   = true
}

resource "artifactory_virtual_generic_repository" "this" {
  for_each = local.virtuals_by_type["generic"]

  key                                                = each.value.key
  description                                        = each.value.description != "" ? each.value.description : null
  repo_layout_ref                                    = local.repo_layout["generic"]
  repositories                                       = [for member in each.value.repositories : local.member_repository_resource_keys[member]]
  default_deployment_repo                            = each.value.default_deployment_repository != "" ? local.local_repository_resource_keys[each.value.default_deployment_repository] : null
  artifactory_requests_can_retrieve_remote_artifacts = each.value.retrieve_remote_artifacts
}

resource "artifactory_virtual_go_repository" "this" {
  for_each = local.virtuals_by_type["go"]

  key                                                = each.value.key
  description                                        = each.value.description != "" ? each.value.description : null
  repo_layout_ref                                    = local.repo_layout["go"]
  repositories                                       = [for member in each.value.repositories : local.member_repository_resource_keys[member]]
  default_deployment_repo                            = each.value.default_deployment_repository != "" ? local.local_repository_resource_keys[each.value.default_deployment_repository] : null
  artifactory_requests_can_retrieve_remote_artifacts = each.value.retrieve_remote_artifacts
}

resource "artifactory_virtual_helm_repository" "this" {
  for_each = local.virtuals_by_type["helm"]

  key                                                = each.value.key
  description                                        = each.value.description != "" ? each.value.description : null
  repo_layout_ref                                    = local.repo_layout["helm"]
  repositories                                       = [for member in each.value.repositories : local.member_repository_resource_keys[member]]
  default_deployment_repo                            = each.value.default_deployment_repository != "" ? local.local_repository_resource_keys[each.value.default_deployment_repository] : null
  artifactory_requests_can_retrieve_remote_artifacts = each.value.retrieve_remote_artifacts
}

resource "artifactory_virtual_maven_repository" "this" {
  for_each = local.virtuals_by_type["maven"]

  key                                                = each.value.key
  description                                        = each.value.description != "" ? each.value.description : null
  repo_layout_ref                                    = local.repo_layout["maven"]
  repositories                                       = [for member in each.value.repositories : local.member_repository_resource_keys[member]]
  default_deployment_repo                            = each.value.default_deployment_repository != "" ? local.local_repository_resource_keys[each.value.default_deployment_repository] : null
  artifactory_requests_can_retrieve_remote_artifacts = each.value.retrieve_remote_artifacts
}

resource "artifactory_virtual_npm_repository" "this" {
  for_each = local.virtuals_by_type["npm"]

  key                                                = each.value.key
  description                                        = each.value.description != "" ? each.value.description : null
  repo_layout_ref                                    = local.repo_layout["npm"]
  repositories                                       = [for member in each.value.repositories : local.member_repository_resource_keys[member]]
  default_deployment_repo                            = each.value.default_deployment_repository != "" ? local.local_repository_resource_keys[each.value.default_deployment_repository] : null
  artifactory_requests_can_retrieve_remote_artifacts = each.value.retrieve_remote_artifacts
}

resource "artifactory_virtual_nuget_repository" "this" {
  for_each = local.virtuals_by_type["nuget"]

  key                                                = each.value.key
  description                                        = each.value.description != "" ? each.value.description : null
  repo_layout_ref                                    = local.repo_layout["nuget"]
  repositories                                       = [for member in each.value.repositories : local.member_repository_resource_keys[member]]
  default_deployment_repo                            = each.value.default_deployment_repository != "" ? local.local_repository_resource_keys[each.value.default_deployment_repository] : null
  artifactory_requests_can_retrieve_remote_artifacts = each.value.retrieve_remote_artifacts
}

resource "artifactory_virtual_pypi_repository" "this" {
  for_each = local.virtuals_by_type["pypi"]

  key                                                = each.value.key
  description                                        = each.value.description != "" ? each.value.description : null
  repo_layout_ref                                    = local.repo_layout["pypi"]
  repositories                                       = [for member in each.value.repositories : local.member_repository_resource_keys[member]]
  default_deployment_repo                            = each.value.default_deployment_repository != "" ? local.local_repository_resource_keys[each.value.default_deployment_repository] : null
  artifactory_requests_can_retrieve_remote_artifacts = each.value.retrieve_remote_artifacts
}

locals {
  virtual_repository_resource_keys = merge(
    { for name, repo in artifactory_virtual_docker_repository.this : name => repo.key },
    { for name, repo in artifactory_virtual_generic_repository.this : name => repo.key },
    { for name, repo in artifactory_virtual_go_repository.this : name => repo.key },
    { for name, repo in artifactory_virtual_helm_repository.this : name => repo.key },
    { for name, repo in artifactory_virtual_maven_repository.this : name => repo.key },
    { for name, repo in artifactory_virtual_npm_repository.this : name => repo.key },
    { for name, repo in artifactory_virtual_nuget_repository.this : name => repo.key },
    { for name, repo in artifactory_virtual_pypi_repository.this : name => repo.key },
  )
}
