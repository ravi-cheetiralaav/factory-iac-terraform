output "project_id" {
  description = "GitLab project ID"
  value       = gitlab_project.main.id
}

output "full_path" {
  description = "Full path of the GitLab project"
  value       = gitlab_project.main.path_with_namespace
}

output "service_account_ids" {
  description = "Numeric GitLab service account user IDs keyed by catalog identifier"
  value       = module.service_account.service_account_ids
}

output "runner_tokens" {
  description = "Sensitive authentication tokens for project runners"
  value       = { for name, runner in gitlab_user_runner.this : name => runner.token }
  sensitive   = true
}
