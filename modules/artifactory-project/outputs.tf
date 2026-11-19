output "project_key" {
  description = "JFrog project key."
  value       = project_project.this.key
}

output "local_repository_keys" {
  description = "Project local repository keys."
  value       = local.local_repository_resource_keys
}

output "virtual_repository_keys" {
  description = "Project virtual repository keys."
  value       = local.virtual_repository_resource_keys
}

output "group_names" {
  description = "Groups attached to the project."
  value       = sort([for group in project_group.this : group.name])
}

output "role_names" {
  description = "Custom project roles."
  value       = sort([for role in project_role.this : role.name])
}
