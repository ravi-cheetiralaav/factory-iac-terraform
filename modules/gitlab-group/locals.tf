locals {
  members = {
    for member in flatten([
      for group_key, group in var.groups : [
        for member in try(group.members, []) :
        merge(member, { group_key = group_key })
      ]
    ]) : "${member.group_key}:${member.user_id}" => member
  }

  variables = {
    for item in flatten([
      for group_key, group in var.groups : [
        for item in try(group.variables, []) :
        merge(item, { group_key = group_key })
      ]
    ]) : "${item.group_key}:${item.key}:${try(item.environment_scope, "*")}" => item
  }

  branch_protections = {
    for protection in flatten([
      for group_key, group in var.groups : [
        for protection in try(group.branch_protections, []) :
        merge(protection, { group_key = group_key })
      ]
    ]) : "${protection.group_key}:${protection.branch}" => protection
  }

  runners = {
    for runner in flatten([
      for group_key, group in var.groups : [
        for runner in try(group.runners, []) :
        merge(runner, { group_key = group_key })
      ]
    ]) : "${runner.group_key}:${runner.name}" => runner
  }
}
