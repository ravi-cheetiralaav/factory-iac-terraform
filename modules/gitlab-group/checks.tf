resource "terraform_data" "checks" {
  input = sort(keys(var.groups))

  lifecycle {
    precondition {
      condition = alltrue([
        for key, group in var.groups :
        try(group.parent_group, null) == null || (
          group.parent_group != key && contains(keys(var.groups), group.parent_group)
        )
      ])
      error_message = "Each parent_group must reference another group in the catalog, and a group cannot be its own parent."
    }

    precondition {
      condition = alltrue(flatten([
        for group in values(var.groups) : [
          for item in try(group.variables, []) :
          contains(nonsensitive(keys(var.variable_values)), try(item.value_ref, ""))
        ]
      ]))
      error_message = "Every group CI/CD variable value_ref must exist in variable_values."
    }
  }
}
