resource "terraform_data" "catalog_checks" {
  input = sort(keys(local.projects))

  lifecycle {
    precondition {
      condition = alltrue([
        for project in values(local.projects) :
        contains(keys(local.groups), project.group)
      ])
      error_message = "Each project group must reference a group YAML file."
    }
  }
}
