output "local_repository_keys" {
  description = "Global local repository keys."
  value       = local.local_repository_resource_keys
}

output "virtual_repository_keys" {
  description = "Global virtual repository keys."
  value       = local.virtual_repository_resource_keys
}

output "anonymous_repository_keys" {
  description = "Local repositories granted anonymous read."
  value       = [for name in sort(keys(local.anonymous_repositories)) : local.local_repository_resource_keys[name]]
}

output "security_policy_names" {
  description = "Xray security policy names."
  value       = sort([for policy in xray_security_policy.this : policy.name])
}

output "watch_names" {
  description = "Xray watch names. These cover quarantine repositories only."
  value       = sort([for watch in xray_watch.this : watch.name])
}

output "group_names" {
  description = "Global group names."
  value       = sort(keys(platform_group.this))
}
