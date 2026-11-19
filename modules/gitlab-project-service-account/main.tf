resource "gitlab_project_service_account" "main" {
  for_each = var.accounts

  project  = var.project_id
  name     = each.value.name
  username = each.value.username
  email    = each.value.email
}

resource "gitlab_project_membership" "main" {
  for_each = {
    for key, account in var.accounts : key => account.membership
    if account.membership != null
  }

  project      = var.project_id
  user_id      = tonumber(gitlab_project_service_account.main[each.key].service_account_id)
  access_level = each.value.access_level
  expires_at   = each.value.expires_at
}
