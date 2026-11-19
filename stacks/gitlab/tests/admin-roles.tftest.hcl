mock_provider "gitlab" {}

variables {
  users = {}
}

run "skip_admin_roles_by_default" {
  command = plan

  module {
    source = "../../modules/gitlab-user"
  }

  assert {
    condition     = length(output.admin_role_ids) == 0
    error_message = "The default catalog must not create admin roles."
  }
}

run "create_auditor_role" {
  module {
    source = "../../modules/gitlab-user"
  }

  variables {
    admin_roles = {
      auditor = {
        name        = "Auditor"
        description = "Read-only access to the Admin Area for auditing purposes"
        enabled_permissions = [
          "READ_ADMIN_CICD",
          "READ_ADMIN_GROUPS",
          "READ_ADMIN_MONITORING",
          "READ_ADMIN_PROJECTS",
          "READ_ADMIN_SUBSCRIPTION",
          "READ_ADMIN_USERS",
        ]
      }
    }
  }

  override_resource {
    target = gitlab_admin_role.main["auditor"]
    values = { id = "gid://gitlab/MemberRole/42" }
  }

  assert {
    condition = (
      gitlab_admin_role.main["auditor"].name == "Auditor" &&
      toset(gitlab_admin_role.main["auditor"].enabled_permissions) == toset(var.admin_roles["auditor"].enabled_permissions) &&
      output.admin_role_ids["auditor"] == "gid://gitlab/MemberRole/42"
    )
    error_message = "The Auditor role must keep the requested permissions and expose its ID under the catalog key."
  }
}
