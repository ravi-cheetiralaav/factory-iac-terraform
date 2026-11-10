output "jfrog_project_keys" {
  description = "Paired JFrog project keys by GitLab configuration key"
  value       = module.artifactory.project_keys
}

output "jfrog_robot_usernames" {
  description = "Paired JFrog robot usernames by GitLab configuration key"
  value       = module.artifactory.robot_usernames
}

output "gitlab_group_ids" {
  description = "GitLab group and subgroup IDs by configuration key"
  value       = module.gitlab.group_ids
}

output "gitlab_project_ids" {
  description = "GitLab project IDs by configuration key"
  value       = module.gitlab.project_ids
}

output "artifactory_repository_keys" {
  description = "Managed Artifactory repository keys grouped by repository type"
  value       = module.artifactory.repository_keys
}