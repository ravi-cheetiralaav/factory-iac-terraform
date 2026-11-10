output "repository_keys" {
  description = "Managed repository keys grouped by repository type"
  value = {
    local_generic   = keys(artifactory_local_generic_repository.repositories)
    local_docker    = keys(artifactory_local_docker_v2_repository.repositories)
    virtual_generic = keys(artifactory_virtual_generic_repository.repositories)
    virtual_docker  = keys(artifactory_virtual_docker_repository.repositories)
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