---
title: GitLab Project Module
description: Inputs and outputs for the reusable GitLab project Terraform module
---

## GitLab project module

Creates one GitLab project in a catalog-managed group, including configured
memberships, service accounts, branch protections, push rules, merge request
approval rules, CI/CD variables, inbound job token allowlist entries, and
project-scoped runner registrations.

### Inputs

| Name | Description |
| --- | --- |
| `spec` | Decoded configuration from one file under `catalog/gitlab/projects/` |
| `namespace_id` | Numeric ID of the owning GitLab group |
| `user_ids` | Numeric IDs keyed by catalog username, used to resolve project memberships |
| `variable_values` | Sensitive map of values referenced by project CI/CD variables |

### Outputs

| Name | Description |
| --- | --- |
| `project_id` | GitLab project ID |
| `full_path` | Full GitLab project path |
| `service_account_ids` | Numeric service account user IDs keyed by catalog identifier |
| `runner_tokens` | Sensitive runner authentication tokens; state contains them |

Branch protection mode is selected in each project YAML file. `legacy` uses
access-level settings for GitLab CE; `enterprise` uses the more granular
Premium/Ultimate attributes.

### Direct project memberships

Each `members` entry in the project YAML requires `access_level` and exactly
one of `user_id` for an existing user or `username` for a catalog-managed
user. Set `expires_at` in `YYYY-MM-DD` format for temporary access.

### Project service accounts

Add a `service_accounts` map to a project YAML file to provision identities for
automation. Projects without this map are unchanged.

```yaml
service_accounts:
  release_bot:
    name: Release automation
    membership:
      access_level: developer
```

Keep the map key stable to preserve the account's Terraform address. Omit
`membership` to create the account without assigning a project role. The stack
output `project_service_account_ids` groups the account IDs by project catalog
filename stem. See the [service account module](../gitlab-project-service-account/README.md)
for prerequisites, optional fields, and token handling.

### Merge request approval rules

Add `approval_rules` to a project YAML file to require merge request approvals.
This feature requires GitLab Premium or Ultimate. Projects without
`approval_rules` are unchanged.

```yaml
approval_rules:
  - name: Release review
    approvals_required: 2
    user_ids: [101, 102]
    applies_to_all_protected_branches: true
```

Each rule needs a unique `name` and an `approvals_required` count. Specify
eligible approvers using numeric `user_ids` or `group_ids`. To target specific
protected branches instead of all protected branches, use numeric
`protected_branch_ids`, not branch names.

`rule_type` defaults to `regular`. GitLab allows only one `any_approver` rule
per project. The provider normally adopts an existing default `any_approver`
rule if it requires zero approvals. `report_approver` rules require
`report_type: code_coverage`. See the
[provider reference](https://registry.terraform.io/providers/gitlabhq/gitlab/19.5.0/docs/resources/project_approval_rule)
for details.

### Push rules

Add a non-empty `push_rules` map to a project YAML file to manage its push
rules. This feature requires GitLab Premium or Ultimate.

```yaml
push_rules:
  author_email_regex: '@gitlab.com$'
  branch_name_regex: '(feat|fix)\/*'
  commit_committer_check: true
  commit_committer_name_check: true
  commit_message_negative_regex: 'ssh\:\/\/'
  commit_message_regex: '(feat|fix):.*'
  deny_delete_tag: false
  file_name_regex: '(jar|exe)$'
  max_file_size: 4
  member_check: true
  prevent_secrets: true
  reject_unsigned_commits: false
```

Set only the rules you want to enforce. Use single quotes for regular
expressions so YAML preserves backslashes. `max_file_size` is in MB. See the
[provider reference](https://registry.terraform.io/providers/gitlabhq/gitlab/19.5.0/docs/resources/project_push_rules)
for all fields.

Projects that never opt in are unaffected. Removing the map after Terraform
takes ownership deletes the managed push rules on the next apply. Do not
configure the same rules in both this resource and `gitlab_project`.

### Inbound job token allowlist

Set `job_token_allowlist` in the YAML for the project that owns the resources to
be accessed. Use numeric GitLab IDs for the projects or groups where the jobs
run, not catalog filenames. Either list can be omitted.

```yaml
job_token_allowlist:
  project_ids: [123]
  group_ids: [456]
```

GitLab still checks the permissions of the user who triggered the job. Prefer
project IDs when you do not need to allow an entire group.

Terraform manages only the entries you list. Omit the setting to leave
unmanaged entries alone. Removing an entry previously managed by Terraform
removes it from GitLab on apply. Import existing entries before taking them
under Terraform management, and do not use `gitlab_project_job_token_scopes`
for the same project.
