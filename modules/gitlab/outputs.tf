output "group_ids" {
  description = "Managed group and subgroup IDs by configuration key"
  value       = local.group_ids
}

output "project_ids" {
  description = "Managed project IDs by configuration key"
  value       = { for key, project in gitlab_project.projects : key => project.id }
}

output "user_ids" {
  description = "Managed and existing user IDs by username"
  value       = local.user_ids
}