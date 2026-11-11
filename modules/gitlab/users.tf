resource "gitlab_user" "users" {
  for_each = var.configuration.users

  username              = each.key
  name                  = each.value.name
  email                 = each.value.email
  is_admin              = false
  is_external           = each.value.is_external
  can_create_group      = false
  projects_limit        = 0
  force_random_password = true
  reset_password        = each.value.should_send_reset_email
  skip_confirmation     = false
  state                 = each.value.state

  lifecycle {
    prevent_destroy = true
    precondition {
      condition     = !contains(var.configuration.existing_users, each.key)
      error_message = "A username must be either managed or looked up, not both."
    }
  }
}

data "gitlab_user" "existing" {
  for_each = var.configuration.existing_users
  username = each.key
}