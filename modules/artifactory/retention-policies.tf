resource "artifactory_archive_policy" "policies" {
  for_each = var.configuration.archive_policies

  key                 = each.key
  description         = each.value.description
  cron_expression     = each.value.cron_expression
  duration_in_minutes = each.value.duration_in_minutes
  project_key         = each.value.project_key
  enabled             = each.value.should_enable
  skip_trashcan       = each.value.should_skip_trashcan
  search_criteria = {
    package_types                    = each.value.search_criteria.package_types
    repos                            = each.value.search_criteria.repos
    included_packages                = each.value.search_criteria.included_packages
    included_projects                = each.value.search_criteria.included_projects
    include_all_projects             = each.value.search_criteria.should_include_all_projects
    excluded_packages                = each.value.search_criteria.excluded_packages
    excluded_repos                   = each.value.search_criteria.excluded_repos
    created_before_in_days           = each.value.search_criteria.created_before_in_days
    last_downloaded_before_in_days   = each.value.search_criteria.last_downloaded_before_in_days
    created_before_in_months         = each.value.search_criteria.created_before_in_months
    last_downloaded_before_in_months = each.value.search_criteria.last_downloaded_before_in_months
    keep_last_n_versions             = each.value.search_criteria.keep_last_n_versions
    included_properties              = each.value.search_criteria.included_properties
    excluded_properties              = each.value.search_criteria.excluded_properties
  }

  depends_on = [
    project_project.projects,
    artifactory_local_generic_repository.repositories,
    artifactory_local_docker_v2_repository.repositories,
    artifactory_local_alpine_repository.repositories,
    artifactory_local_ansible_repository.repositories,
    artifactory_local_debian_repository.repositories,
    artifactory_local_helm_repository.repositories,
    artifactory_local_helmoci_repository.repositories,
    artifactory_local_oci_repository.repositories,
    artifactory_local_maven_repository.repositories,
    artifactory_local_npm_repository.repositories,
    artifactory_local_nuget_repository.repositories,
    artifactory_local_pypi_repository.repositories,
    artifactory_local_rpm_repository.repositories,
    artifactory_local_terraform_module_repository.repositories,
    artifactory_local_terraform_provider_repository.repositories,
    artifactory_local_terraformbackend_repository.repositories
  ]
}

resource "artifactory_package_cleanup_policy" "policies" {
  for_each = var.configuration.package_cleanup_policies

  key                 = each.key
  description         = each.value.description
  cron_expression     = each.value.cron_expression
  duration_in_minutes = each.value.duration_in_minutes
  project_key         = each.value.project_key
  enabled             = each.value.should_enable
  skip_trashcan       = each.value.should_skip_trashcan
  search_criteria = {
    package_types                    = each.value.search_criteria.package_types
    repos                            = each.value.search_criteria.repos
    included_packages                = each.value.search_criteria.included_packages
    included_projects                = each.value.search_criteria.included_projects
    include_all_projects             = each.value.search_criteria.should_include_all_projects
    excluded_packages                = each.value.search_criteria.excluded_packages
    excluded_repos                   = each.value.search_criteria.excluded_repos
    created_before_in_days           = each.value.search_criteria.created_before_in_days
    last_downloaded_before_in_days   = each.value.search_criteria.last_downloaded_before_in_days
    created_before_in_months         = each.value.search_criteria.created_before_in_months
    last_downloaded_before_in_months = each.value.search_criteria.last_downloaded_before_in_months
    keep_last_n_versions             = each.value.search_criteria.keep_last_n_versions
    included_properties              = each.value.search_criteria.included_properties
    excluded_properties              = each.value.search_criteria.excluded_properties
  }

  depends_on = [
    project_project.projects,
    artifactory_local_generic_repository.repositories,
    artifactory_local_docker_v2_repository.repositories,
    artifactory_local_alpine_repository.repositories,
    artifactory_local_ansible_repository.repositories,
    artifactory_local_debian_repository.repositories,
    artifactory_local_helm_repository.repositories,
    artifactory_local_helmoci_repository.repositories,
    artifactory_local_oci_repository.repositories,
    artifactory_local_maven_repository.repositories,
    artifactory_local_npm_repository.repositories,
    artifactory_local_nuget_repository.repositories,
    artifactory_local_pypi_repository.repositories,
    artifactory_local_rpm_repository.repositories,
    artifactory_local_terraform_module_repository.repositories,
    artifactory_local_terraform_provider_repository.repositories,
    artifactory_local_terraformbackend_repository.repositories
  ]
}