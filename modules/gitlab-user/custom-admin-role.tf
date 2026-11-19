resource "gitlab_admin_role" "main" {
  for_each = var.admin_roles

  name                = each.value.name
  description         = each.value.description
  enabled_permissions = each.value.enabled_permissions
}
