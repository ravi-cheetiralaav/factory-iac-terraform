locals {
  branch_protection_mode = try(var.spec.branch_protection_mode, "legacy")

  members = {
    for member in try(var.spec.members, []) :
    (try(member.user_id, null) != null ? tostring(member.user_id) : try("user:${member.username}", "user:")) => member
  }

  branch_protections = {
    for branch in try(var.spec.branch_protections, []) :
    branch.name => branch
  }

  variables = {
    for item in try(var.spec.variables, []) :
    "${item.key}:${try(item.environment_scope, "*")}" => item
  }

  runners = {
    for runner in try(var.spec.runners, []) :
    runner.name => runner
  }
}
