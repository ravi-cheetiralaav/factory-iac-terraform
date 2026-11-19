mock_provider "gitlab" {}

variables {
  namespace_id = 123
}

run "plan_inbound_job_token_allowlist" {
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
      name: Artifact source
      job_token_allowlist:
        project_ids: [101, 102, 101]
        group_ids: [101]
    YAML
    )
  }

  assert {
    condition = (
      length(gitlab_project_job_token_scope.project) == 2 &&
      gitlab_project_job_token_scope.project["101"].project == "456" &&
      gitlab_project_job_token_scope.project["101"].target_project_id == 101 &&
      gitlab_project_job_token_scope.project["102"].target_project_id == 102 &&
      length(gitlab_project_job_token_scope.group) == 1 &&
      gitlab_project_job_token_scope.group["101"].project == "456" &&
      gitlab_project_job_token_scope.group["101"].target_group_id == 101
    )
    error_message = "The resource-owning project must allow each configured job source once per resource type."
  }
}

run "omit_job_token_allowlist" {
  command = plan

  module {
    source = "../../modules/gitlab-project"
  }

  variables {
    spec = { name = "Unchanged project" }
  }

  assert {
    condition     = length(gitlab_project_job_token_scope.project) == 0 && length(gitlab_project_job_token_scope.group) == 0
    error_message = "A project with no configured allowlist must not manage any job token scope entries."
  }
}
