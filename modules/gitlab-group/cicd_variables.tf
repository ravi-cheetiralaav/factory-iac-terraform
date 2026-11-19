resource "gitlab_group_variable" "this" {
  for_each = local.variables

  group             = tostring(gitlab_group.this[each.value.group_key].id)
  key               = each.value.key
  value             = var.variable_values[each.value.value_ref]
  description       = try(each.value.description, null)
  environment_scope = try(each.value.environment_scope, "*")
  variable_type     = try(each.value.variable_type, "env_var")
  protected         = try(each.value.protected, false)
  masked            = try(each.value.masked, false)
  hidden            = try(each.value.hidden, null)
  raw               = try(each.value.raw, true)
}
