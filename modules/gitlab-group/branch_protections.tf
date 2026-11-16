resource "gitlab_group_branch_protection" "this" {
  for_each = local.branch_protections

  group                        = tostring(gitlab_group.this[each.value.group_key].id)
  branch                       = each.value.branch
  allow_force_push             = try(each.value.allow_force_push, false)
  code_owner_approval_required = try(each.value.code_owner_approval_required, false)
  allowed_to_push              = try(each.value.allowed_to_push, null)
  allowed_to_merge             = try(each.value.allowed_to_merge, null)
  allowed_to_unprotect         = try(each.value.allowed_to_unprotect, null)
}
