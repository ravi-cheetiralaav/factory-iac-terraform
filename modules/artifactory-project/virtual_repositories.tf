resource "artifactory_virtual_docker_repository" "this" {
  for_each = local.virtuals_by_type["docker"]

  key                                                = each.value.key
  description                                        = each.value.description != "" ? each.value.description : null
  repo_layout_ref                                    = local.repo_layout["docker"]
  project_environments                               = [each.value.environment]
  repositories                                       = [for member in each.value.repositories : contains(keys(local.local_repositories), member) ? local.local_repository_resource_keys[member] : member]
  default_deployment_repo                            = each.value.default_deployment_repository != "" ? local.local_repository_resource_keys[each.value.default_deployment_repository] : null
  artifactory_requests_can_retrieve_remote_artifacts = each.value.retrieve_remote_artifacts
  resolve_docker_tags_by_timestamp                   = true

  lifecycle {
    ignore_changes = [project_key]
  }
}

resource "artifactory_virtual_generic_repository" "this" {
  for_each = local.virtuals_by_type["generic"]

  key                                                = each.value.key
  description                                        = each.value.description != "" ? each.value.description : null
  repo_layout_ref                                    = local.repo_layout["generic"]
  project_environments                               = [each.value.environment]
  repositories                                       = [for member in each.value.repositories : contains(keys(local.local_repositories), member) ? local.local_repository_resource_keys[member] : member]
  default_deployment_repo                            = each.value.default_deployment_repository != "" ? local.local_repository_resource_keys[each.value.default_deployment_repository] : null
  artifactory_requests_can_retrieve_remote_artifacts = each.value.retrieve_remote_artifacts

  lifecycle {
    ignore_changes = [project_key]
  }
}

resource "artifactory_virtual_go_repository" "this" {
  for_each = local.virtuals_by_type["go"]

  key                                                = each.value.key
  description                                        = each.value.description != "" ? each.value.description : null
  repo_layout_ref                                    = local.repo_layout["go"]
  project_environments                               = [each.value.environment]
  repositories                                       = [for member in each.value.repositories : contains(keys(local.local_repositories), member) ? local.local_repository_resource_keys[member] : member]
  default_deployment_repo                            = each.value.default_deployment_repository != "" ? local.local_repository_resource_keys[each.value.default_deployment_repository] : null
  artifactory_requests_can_retrieve_remote_artifacts = each.value.retrieve_remote_artifacts

  lifecycle {
    ignore_changes = [project_key]
  }
}

resource "artifactory_virtual_helm_repository" "this" {
  for_each = local.virtuals_by_type["helm"]

  key                                                = each.value.key
  description                                        = each.value.description != "" ? each.value.description : null
  repo_layout_ref                                    = local.repo_layout["helm"]
  project_environments                               = [each.value.environment]
  repositories                                       = [for member in each.value.repositories : contains(keys(local.local_repositories), member) ? local.local_repository_resource_keys[member] : member]
  default_deployment_repo                            = each.value.default_deployment_repository != "" ? local.local_repository_resource_keys[each.value.default_deployment_repository] : null
  artifactory_requests_can_retrieve_remote_artifacts = each.value.retrieve_remote_artifacts

  lifecycle {
    ignore_changes = [project_key]
  }
}

resource "artifactory_virtual_maven_repository" "this" {
  for_each = local.virtuals_by_type["maven"]

  key                                                = each.value.key
  description                                        = each.value.description != "" ? each.value.description : null
  repo_layout_ref                                    = local.repo_layout["maven"]
  project_environments                               = [each.value.environment]
  repositories                                       = [for member in each.value.repositories : contains(keys(local.local_repositories), member) ? local.local_repository_resource_keys[member] : member]
  default_deployment_repo                            = each.value.default_deployment_repository != "" ? local.local_repository_resource_keys[each.value.default_deployment_repository] : null
  artifactory_requests_can_retrieve_remote_artifacts = each.value.retrieve_remote_artifacts

  lifecycle {
    ignore_changes = [project_key]
  }
}

resource "artifactory_virtual_npm_repository" "this" {
  for_each = local.virtuals_by_type["npm"]

  key                                                = each.value.key
  description                                        = each.value.description != "" ? each.value.description : null
  repo_layout_ref                                    = local.repo_layout["npm"]
  project_environments                               = [each.value.environment]
  repositories                                       = [for member in each.value.repositories : contains(keys(local.local_repositories), member) ? local.local_repository_resource_keys[member] : member]
  default_deployment_repo                            = each.value.default_deployment_repository != "" ? local.local_repository_resource_keys[each.value.default_deployment_repository] : null
  artifactory_requests_can_retrieve_remote_artifacts = each.value.retrieve_remote_artifacts

  lifecycle {
    ignore_changes = [project_key]
  }
}

resource "artifactory_virtual_nuget_repository" "this" {
  for_each = local.virtuals_by_type["nuget"]

  key                                                = each.value.key
  description                                        = each.value.description != "" ? each.value.description : null
  repo_layout_ref                                    = local.repo_layout["nuget"]
  project_environments                               = [each.value.environment]
  repositories                                       = [for member in each.value.repositories : contains(keys(local.local_repositories), member) ? local.local_repository_resource_keys[member] : member]
  default_deployment_repo                            = each.value.default_deployment_repository != "" ? local.local_repository_resource_keys[each.value.default_deployment_repository] : null
  artifactory_requests_can_retrieve_remote_artifacts = each.value.retrieve_remote_artifacts

  lifecycle {
    ignore_changes = [project_key]
  }
}

resource "artifactory_virtual_pypi_repository" "this" {
  for_each = local.virtuals_by_type["pypi"]

  key                                                = each.value.key
  description                                        = each.value.description != "" ? each.value.description : null
  repo_layout_ref                                    = local.repo_layout["pypi"]
  project_environments                               = [each.value.environment]
  repositories                                       = [for member in each.value.repositories : contains(keys(local.local_repositories), member) ? local.local_repository_resource_keys[member] : member]
  default_deployment_repo                            = each.value.default_deployment_repository != "" ? local.local_repository_resource_keys[each.value.default_deployment_repository] : null
  artifactory_requests_can_retrieve_remote_artifacts = each.value.retrieve_remote_artifacts

  lifecycle {
    ignore_changes = [project_key]
  }
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

resource "project_repository" "virtual" {
  for_each = local.virtual_repositories

  project_key = project_project.this.key
  key         = local.virtual_repository_resource_keys[each.key]
}
