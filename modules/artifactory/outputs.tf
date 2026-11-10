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