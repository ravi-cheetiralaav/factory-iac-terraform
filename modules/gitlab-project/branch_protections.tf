resource "gitlab_branch_protection" "this" {
  for_each = local.branch_protections

  project                      = gitlab_project.main.id
  branch                       = each.value.name
  allow_force_push             = try(each.value.allow_force_push, false)
  merge_access_level           = local.branch_protection_mode == "legacy" ? try(each.value.merge_access_level, "maintainer") : null
  push_access_level            = local.branch_protection_mode == "legacy" ? try(each.value.push_access_level, "no one") : null
  allowed_to_merge             = local.branch_protection_mode == "enterprise" ? try(each.value.allowed_to_merge, null) : null
  allowed_to_push              = local.branch_protection_mode == "enterprise" ? try(each.value.allowed_to_push, null) : null
  allowed_to_unprotect         = local.branch_protection_mode == "enterprise" ? try(each.value.allowed_to_unprotect, null) : null
  code_owner_approval_required = local.branch_protection_mode == "enterprise" ? try(each.value.code_owner_approval_required, false) : null
}
