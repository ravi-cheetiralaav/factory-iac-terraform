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