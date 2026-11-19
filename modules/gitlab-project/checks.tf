resource "terraform_data" "checks" {
  input = {
    name                   = var.spec.name
    branch_protection_mode = try(var.spec.branch_protection_mode, "legacy")
  }

  lifecycle {
    precondition {
      condition = contains(
        ["legacy", "enterprise"],
        try(var.spec.branch_protection_mode, "legacy")
      )
      error_message = "branch_protection_mode must be legacy or enterprise."
    }

    precondition {
      condition = alltrue([
        for item in try(var.spec.variables, []) :
        contains(nonsensitive(keys(var.variable_values)), try(item.value_ref, ""))
      ])
      error_message = "Every project CI/CD variable value_ref must exist in variable_values."
    }
  }
}
