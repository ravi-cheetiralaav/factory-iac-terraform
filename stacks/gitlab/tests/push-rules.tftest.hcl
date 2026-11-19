mock_provider "gitlab" {}

variables {
  namespace_id = 123
}

run "plan_project_push_rules" {
  command = plan

  module {
    source = "../../modules/gitlab-project"
  }

  override_resource {
    target          = gitlab_project.main
    override_during = plan
    values          = { id = "456" }
  }

  variables {
    spec = yamldecode(<<-YAML
      name: Example Project
      push_rules:
        branch_name_regex: '(feat|fix)\/*'
        commit_message_negative_regex: 'ssh\:\/\/'
        max_file_size: 4
        prevent_secrets: true
        reject_unsigned_commits: false
    YAML
    )
  }

  assert {
    condition = (
      gitlab_project_push_rules.main[0].project == "456" &&
      gitlab_project_push_rules.main[0].branch_name_regex == "(feat|fix)\\/*" &&
      gitlab_project_push_rules.main[0].commit_message_negative_regex == "ssh\\:\\/\\/" &&
      gitlab_project_push_rules.main[0].max_file_size == 4 &&
      gitlab_project_push_rules.main[0].prevent_secrets == true &&
      gitlab_project_push_rules.main[0].reject_unsigned_commits == false
    )
    error_message = "Push rules must preserve the project ID, regex escapes, size limit, and explicit boolean settings."
  }
}

run "omit_project_push_rules" {
  command = plan

  module {
    source = "../../modules/gitlab-project"
  }

  variables {
    spec = { name = "Unchanged Project" }
  }

  assert {
    condition     = length(gitlab_project_push_rules.main) == 0
    error_message = "Terraform must not manage push rules for a project that has not opted in."
  }
}
