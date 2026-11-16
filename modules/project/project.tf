resource "project_project" "this" {
  key          = local.project_key
  display_name = local.display_name
  description  = local.description != "" ? local.description : null

  admin_privileges {
    manage_members           = local.admin_privileges.manage_members
    manage_resources         = local.admin_privileges.manage_resources
    manage_remote_repository = local.admin_privileges.manage_remote_repository
    index_resources          = local.admin_privileges.index_resources
  }

  max_storage_in_gibibytes   = local.storage_gib
  block_deployments_on_limit = local.block_deployments_on_limit
  email_notification         = local.email_notification

  use_project_group_resource      = true
  use_project_repository_resource = true
  use_project_role_resource       = true
  use_project_user_resource       = true
}

resource "project_role" "this" {
  for_each = local.roles

  name         = each.value.name
  type         = "CUSTOM"
  project_key  = project_project.this.key
  environments = toset(each.value.environments)
  actions      = toset(each.value.actions)
}

resource "project_share_repository" "this" {
  for_each = local.shared_repositories

  repo_key           = each.value.key
  target_project_key = project_project.this.key
  read_only          = each.value.read_only
}
