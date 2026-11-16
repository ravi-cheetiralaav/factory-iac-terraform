resource "platform_permission" "repositories" {
  count = var.manage_project_permission_targets && length(local.groups_with_permissions) > 0 && (length(local.local_repositories) + length(local.virtual_repositories)) > 0 ? 1 : 0

  name = "${local.project_key}-repositories"

  artifact = {
    actions = {
      groups = [
        for name, group in local.groups_with_permissions : {
          name        = platform_group.this[name].name
          permissions = toset(group.permissions)
        }
      ]
    }
    targets = [
      for key in merge(local.local_repository_resource_keys, local.virtual_repository_resource_keys) : {
        name             = key
        include_patterns = ["**"]
      }
    ]
  }
}
