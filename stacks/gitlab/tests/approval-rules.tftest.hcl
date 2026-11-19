mock_provider "gitlab" {}

variables {
  namespace_id = 123
}

run "plan_protected_branch_rule" {
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
    spec = {
      name = "Example Project"
      approval_rules = [{
        name                              = "Release review"
        approvals_required                = 2
        user_ids                          = [101, 102]
        group_ids                         = [51]
        applies_to_all_protected_branches = true
      }]
    }
  }

  assert {
    condition = (
      gitlab_project_approval_rule.this["Release review"].project == "456" &&
      gitlab_project_approval_rule.this["Release review"].approvals_required == 2 &&
      toset(gitlab_project_approval_rule.this["Release review"].user_ids) == toset([101, 102]) &&
      toset(gitlab_project_approval_rule.this["Release review"].group_ids) == toset([51]) &&
      gitlab_project_approval_rule.this["Release review"].applies_to_all_protected_branches
    )
    error_message = "The catalog rule must apply the configured approval threshold, approvers, and branch scope to the correct project."
  }
}

run "reject_duplicate_any_approver_rules" {
  command = plan

  module {
    source = "../../modules/gitlab-project"
  }

  variables {
    spec = {
      name = "Example Project"
      approval_rules = [
        { name = "First", approvals_required = 1, rule_type = "any_approver" },
        { name = "Second", approvals_required = 1, rule_type = "any_approver" },
      ]
    }
  }

  expect_failures = [gitlab_project_approval_rule.this]
}
