resource "platform_group" "this" {
  for_each = local.groups

  name                       = each.value.name
  description                = each.value.description
  auto_join                  = false
  admin_privileges           = false
  use_group_members_resource = true
}

resource "artifactory_user" "person" {
  for_each = local.users

  name                       = each.value.name
  email                      = each.value.email
  admin                      = false
  profile_updatable          = true
  disable_ui_access          = false
  internal_password_disabled = false

  lifecycle {
    ignore_changes = [groups]
  }
}

resource "artifactory_user" "service" {
  for_each = local.service_accounts

  name                       = each.value.name
  email                      = each.value.email
  admin                      = false
  profile_updatable          = false
  disable_ui_access          = true
  internal_password_disabled = true

  lifecycle {
    ignore_changes = [groups]
  }
}

resource "platform_group_members" "this" {
  for_each = {
    for name, group in local.groups : name => group
    if length(group.members) > 0
  }

  name    = platform_group.this[each.key].name
  members = toset(each.value.members)

  depends_on = [artifactory_user.person, artifactory_user.service]
}

resource "project_group" "this" {
  for_each = local.groups

  project_key = project_project.this.key
  name        = platform_group.this[each.key].name
  roles       = [project_role.this[each.value.role].name]
}

resource "project_user" "direct" {
  for_each = local.direct_members

  project_key = project_project.this.key
  name        = each.value.name
  roles       = [for role in each.value.roles : project_role.this[role].name]

  depends_on = [artifactory_user.person, artifactory_user.service]
}
