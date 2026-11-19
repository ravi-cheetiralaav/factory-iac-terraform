output "user_ids" {
  description = "GitLab user IDs keyed by username"
  value       = { for username, user in gitlab_user.main : username => tonumber(user.id) }
}

output "admin_role_ids" {
  description = "GitLab global admin role IDs keyed by catalog identifier"
  value       = { for key, role in gitlab_admin_role.main : key => role.id }
}
