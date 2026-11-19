output "service_account_ids" {
  description = "Numeric GitLab service account user IDs keyed by catalog identifier"
  value = {
    for key, account in gitlab_project_service_account.main : key => tonumber(account.service_account_id)
  }
}
