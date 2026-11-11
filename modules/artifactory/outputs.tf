output "project_keys" {
  description = "JFrog project keys by GitLab configuration key"
  value       = { for key, project in project_project.projects : key => project.key }
}

output "robot_usernames" {
  description = "JFrog robot usernames by GitLab configuration key, without credentials"
  value       = { for key, robot in artifactory_user.robots : key => robot.name }
}

output "repository_keys" {
  description = "Managed repository keys grouped by repository type"
  value = {
    local_generic            = keys(artifactory_local_generic_repository.repositories)
    local_docker             = keys(artifactory_local_docker_v2_repository.repositories)
    local_alpine             = keys(artifactory_local_alpine_repository.repositories)
    local_ansible            = keys(artifactory_local_ansible_repository.repositories)
    local_debian             = keys(artifactory_local_debian_repository.repositories)
    local_helm               = keys(artifactory_local_helm_repository.repositories)
    local_helmoci            = keys(artifactory_local_helmoci_repository.repositories)
    local_oci                = keys(artifactory_local_oci_repository.repositories)
    local_maven              = keys(artifactory_local_maven_repository.repositories)
    local_npm                = keys(artifactory_local_npm_repository.repositories)
    local_nuget              = keys(artifactory_local_nuget_repository.repositories)
    local_pypi               = keys(artifactory_local_pypi_repository.repositories)
    local_rpm                = keys(artifactory_local_rpm_repository.repositories)
    local_terraform_module   = keys(artifactory_local_terraform_module_repository.repositories)
    local_terraform_provider = keys(artifactory_local_terraform_provider_repository.repositories)
    local_terraformbackend   = keys(artifactory_local_terraformbackend_repository.repositories)
    virtual_generic          = keys(artifactory_virtual_generic_repository.repositories)
    virtual_docker           = keys(artifactory_virtual_docker_repository.repositories)
  }
}

output "group_names" {
  description = "Managed Artifactory group names"
  value       = keys(artifactory_group.groups)
}

output "usernames" {
  description = "Managed Artifactory usernames"
  value       = keys(artifactory_user.users)
}