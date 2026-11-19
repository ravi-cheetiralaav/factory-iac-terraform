mock_provider "gitlab" {}

run "create_project_service_accounts" {
  module {
    source = "../../modules/gitlab-project-service-account"
  }

  variables {
    project_id = "123"
    accounts = {
      release_bot = {
        name = "Release automation"
        membership = {
          access_level = "developer"
          expires_at   = "2099-12-31"
        }
      }
      identity_only = {}
    }
  }

  override_resource {
    target = gitlab_project_service_account.main["release_bot"]
    values = { service_account_id = "42" }
  }

  override_resource {
    target = gitlab_project_service_account.main["identity_only"]
    values = { service_account_id = "43" }
  }

  assert {
    condition = (
      output.service_account_ids["release_bot"] == 42 &&
      output.service_account_ids["identity_only"] == 43 &&
      length(gitlab_project_membership.main) == 1 &&
      gitlab_project_membership.main["release_bot"].project == "123" &&
      gitlab_project_membership.main["release_bot"].user_id == 42 &&
      gitlab_project_membership.main["release_bot"].access_level == "developer" &&
      gitlab_project_membership.main["release_bot"].expires_at == "2099-12-31"
    )
    error_message = "Only the account with explicit membership may get project access, using its GitLab user ID and configured expiry."
  }
}

run "read_service_accounts_from_project_yaml" {
  module {
    source = "../../modules/gitlab-project"
  }

  variables {
    namespace_id = 123
    spec = yamldecode(<<-YAML
      name: Example Project
      service_accounts:
        catalog_bot:
          name: Catalog automation
    YAML
    )
  }

  override_resource {
    target = module.service_account.gitlab_project_service_account.main["catalog_bot"]
    values = { service_account_id = "101" }
  }

  assert {
    condition     = output.service_account_ids["catalog_bot"] == 101
    error_message = "The project module must provision and expose accounts declared in project YAML."
  }
}
