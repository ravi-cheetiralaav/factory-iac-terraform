output "project_id" {
  description = "GitLab project ID"
  value       = gitlab_project.main.id
}

output "full_path" {
  description = "Full path of the GitLab project"
  value       = gitlab_project.main.path_with_namespace
}

output "runner_tokens" {
  description = "Sensitive authentication tokens for project runners"
  value       = { for name, runner in gitlab_user_runner.this : name => runner.token }
  sensitive   = true
}
