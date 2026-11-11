resource "artifactory_group" "groups" {
  for_each = var.configuration.groups

  name             = each.key
  description      = each.value.description
  admin_privileges = false
  auto_join        = false

  lifecycle {
    prevent_destroy = true
  }
}

resource "artifactory_user" "users" {
  for_each = var.configuration.users

  name                       = each.key
  email                      = each.value.email
  groups                     = each.value.groups
  admin                      = false
  profile_updatable          = true
  internal_password_disabled = each.value.should_disable_internal_password
  disable_ui_access          = each.value.should_disable_ui_access

  depends_on = [artifactory_group.groups]

  lifecycle {
    prevent_destroy = true
  }
}