output "group_ids" {
  description = "GitLab group IDs keyed by catalog filename"
  value       = { for key, group in gitlab_group.this : key => group.id }
}

output "runner_tokens" {
  description = "Sensitive authentication tokens for group runners"
  value = {
    for group_key in keys(var.groups) : group_key => {
      for runner_key, runner in gitlab_user_runner.this :
      local.runners[runner_key].name => runner.token
      if local.runners[runner_key].group_key == group_key
    }
  }
  sensitive = true
}
