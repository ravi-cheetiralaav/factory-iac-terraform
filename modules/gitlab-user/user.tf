resource "gitlab_user" "main" {
  for_each = var.users

  username         = each.key
  name             = each.value.name
  email            = each.value.email
  password         = each.value.password_ref == null ? null : lookup(var.passwords, each.value.password_ref, null)
  is_admin         = each.value.is_admin
  projects_limit   = each.value.projects_limit
  can_create_group = each.value.can_create_group
  is_external      = each.value.is_external
  is_auditor       = each.value.is_auditor
  reset_password   = coalesce(each.value.reset_password, each.value.password_ref == null)

  lifecycle {
    precondition {
      condition     = coalesce(each.value.reset_password, each.value.password_ref == null) == (each.value.password_ref == null)
      error_message = "Set password_ref or enable reset_password, but not both."
    }

    precondition {
      condition     = each.value.password_ref == null ? true : try(length(trimspace(var.passwords[each.value.password_ref])) > 0, false)
      error_message = "Each password_ref must have a non-blank value in gitlab_user_passwords."
    }
  }
}
