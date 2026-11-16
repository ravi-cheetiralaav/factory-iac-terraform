locals {
  permission_repository_keys = merge(
    local.local_repository_resource_keys,
    local.virtual_repository_resource_keys,
  )
}

resource "platform_permission" "this" {
  for_each = local.permissions

  name = each.value.name

  artifact = {
    actions = {
      groups = [
        for group in each.value.groups : {
          name        = platform_group.this[group.name].name
          permissions = toset(group.permissions)
        }
      ]
    }
    targets = [
      for repo in each.value.repositories : {
        name             = local.permission_repository_keys[repo]
        include_patterns = ["**"]
      }
    ]
  }
}

# One permission for every local repository that opts in. Anonymous is not
# copied onto team permissions.
resource "platform_permission" "anonymous_read" {
  for_each = length(local.anonymous_repositories) > 0 ? { this = true } : {}

  name = "global-anonymous-read"

  artifact = {
    actions = {
      users = [
        {
          name        = "anonymous"
          permissions = ["READ"]
        }
      ]
    }
    targets = [
      for name, repo in local.anonymous_repositories : {
        name             = local.local_repository_resource_keys[name]
        include_patterns = ["**"]
      }
    ]
  }
}
