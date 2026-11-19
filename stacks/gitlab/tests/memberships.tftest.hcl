mock_provider "gitlab" {}

run "create_user" {
  module {
    source = "../../modules/gitlab-user"
  }

  variables {
    users = {
      example = {
        name  = "Example User"
        email = "example@example.com"
      }
    }
  }

  override_resource {
    target = gitlab_user.main["example"]
    values = { id = "42" }
  }

  assert {
    condition     = output.user_ids["example"] == 42 && gitlab_user.main["example"].reset_password
    error_message = "The catalog user must get a reset link by default and expose a numeric user ID."
  }
}

run "plan_project_memberships" {
  command = plan

  module {
    source = "../../modules/gitlab-project"
  }

  variables {
    namespace_id = 123
    user_ids     = run.create_user.user_ids
    spec = {
      name = "Example Project"
      members = [
        { username = "example", access_level = "guest", expires_at = "2099-12-31" },
        { user_id = 1337, access_level = "guest" },
      ]
    }
  }

  assert {
    condition = (
      gitlab_project_membership.this["user:example"].user_id == 42 &&
      gitlab_project_membership.this["user:example"].expires_at == "2099-12-31" &&
      gitlab_project_membership.this["1337"].user_id == 1337
    )
    error_message = "The managed user must resolve by username, and the existing numeric membership address must stay unchanged."
  }
}

run "reject_unknown_username" {
  command = plan

  module {
    source = "../../modules/gitlab-project"
  }

  variables {
    namespace_id = 123
    spec = {
      name    = "Example Project"
      members = [{ username = "missing", access_level = "guest" }]
    }
  }

  expect_failures = [gitlab_project_membership.this]
}
