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