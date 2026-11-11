---
title: GitLab Day-2 Module
description: Groups, users, projects, labels, push rules, approval settings, and deployment policies for self-hosted GitLab
---

## Prerequisites

An existing GitLab instance and a root-configured `gitlabhq/gitlab` provider are
required. The root pins version 19.5.0. Supply `GITLAB_TOKEN` externally. Local user
creation needs an administrator; group and project operations need appropriate
ownership. Check your GitLab server version and license against the provider.

## Input

The single input `configuration` is an optional object defaulting to `{}`.
[variables.tf](variables.tf) is the authoritative field/default contract. The root
normalizes hierarchical JSON into this flat input. Direct module callers still
supply the flat maps below; the module does not load environment JSON itself.

| Field | Content and required entry fields |
| --- | --- |
| `is_enterprise` | Boolean, defaults to false; selects Enterprise branch access-level sets and permits licensed group and project policies |
| `groups` | Map keyed by stable identifier; each needs `name`, `path` |
| `subgroups` | Map with `name`, `path`, `parent_group_key` referencing a managed group |
| `users` | Map keyed by username; each needs `name`, `email` |
| `existing_users` | Array of existing usernames to look up, not create |
| `group_memberships` | Map with `group_key`, `username`, optional `access_level`, `expires_at` |
| `project_memberships` | Map with `project_key`, `username`, optional `access_level`, `expires_at` |
| `projects` | Map with `name`, `path`, `group_key`; settings and protections are optional |

All maps and `existing_users` default to empty. Groups and subgroups share a key
namespace and must use distinct keys. Subgroups support one managed level;
`groups.parent_id` can anchor a group under an existing numeric parent ID.
Membership usernames must exist in `users` or `existing_users`, not both.

Groups default to private, project creation by maintainers, and subgroup creation
by owners. Users are non-admin, cannot create groups or personal projects, and
default to active. Optional user fields include `is_external`,
`should_send_reset_email`, and `state`. Passwords are not module inputs: GitLab
generates a random password and defaults to sending a reset email. Test mail and
identity-provider behavior before onboarding real users.

Projects default to private, branch `main`, README initialization, successful
pipeline and resolved-discussion merge requirements, and source-branch removal.
Use the optional `should_*` fields in the contract to change these settings. A
required successful pipeline can block merging until your existing CI runs.

## JSON Usage

Place this object under the environment JSON's `gitlab` key:

```json
{
  "groups": {
    "engineering": {
      "name": "Engineering",
      "path": "engineering",
      "projects": {
        "application": {
          "name": "Application",
          "path": "application",
          "branch_protections": { "release/*": {} }
        }
      }
    }
  },
  "existing_users": ["alice"],
  "group_memberships": {
    "engineering_alice": {
      "group_key": "engineering",
      "username": "alice",
      "access_level": "developer"
    }
  }
}
```

This example places a project directly under a group. For a subgroup project,
put it under `groups.<group-key>.subgroups.<subgroup-key>.projects`. Each subgroup
needs `name` and `path`. Root locals derive `parent_group_key` and project
`group_key` from their positions. Keep subgroup keys globally unique and project
keys globally unique within the environment, even if their display names repeat.
User and membership maps remain directly under `gitlab`.

## Files

| File | Responsibility |
| --- | --- |
| [groups.tf](groups.tf) | Groups and subgroups |
| [users.tf](users.tf) | Managed users and existing-user lookup |
| [projects.tf](projects.tf) | Projects and merge settings |
| [project-push-rules.tf](project-push-rules.tf) | Opt-in project push rules |
| [project-labels.tf](project-labels.tf) | Project labels keyed by project and label name |
| [project-mr-approvals.tf](project-mr-approvals.tf) | Opt-in project MR approval settings |
| [memberships.tf](memberships.tf) | Group and project memberships |
| [branch-protection.tf](branch-protection.tf) | Protected branches |
| [group-mr-approvals.tf](group-mr-approvals.tf) | Group and subgroup MR approval settings |
| [group-protected-environments.tf](group-protected-environments.tf) | Group and subgroup deployment-tier protection |
| [locals.tf](locals.tf) | ID maps, group/project policies, labels, and merged default/explicit branch rules |
| [variables.tf](variables.tf), [outputs.tf](outputs.tf), [versions.tf](versions.tf) | Input contract, outputs, and provider requirements |

Terraform loads all these files as one module. Splitting files preserves existing
resource addresses; no file-order dependency or state migration is introduced.

## Branch Protection

Every project's configured default branch gets a rule. Additional
`branch_protections` entries are keyed by branch name or pattern. An entry with
the default branch name overrides that rule instead of creating a duplicate.
Defaults disallow direct pushes and force pushes and allow maintainer merges.

Each rule accepts `push_access_level`, `merge_access_level`,
`should_allow_force_push`, and `should_require_code_owner_approval`. Code-owner
approval requires `is_enterprise = true` and a compatible server license; the
module does not enable licensing. Community mode uses scalar access levels;
Enterprise mode uses provider access-level sets.

GitLab can automatically protect a default branch. The provider may unprotect and
reprotect it when adopting the configured rule. Review imports and first applies
in a controlled window. Avoid another Terraform resource or automation managing
the same project/branch rule. If README initialization is disabled, ensure the
default branch exists before configuring it.

## Project Policies and Labels

Each project accepts optional `push_rules`, `labels`, and `mr_approvals` fields.
Put them alongside `name` and `path` in either a group's or subgroup's `projects`
map. Omitted or null push rules and MR settings create no resource; `{}` opts in.
Labels default to an empty map. The supplied lab01 configuration enables none of
these additions, so existing project and branch-protection defaults are unchanged.

Push rules and project MR settings require `gitlab.is_enterprise = true` and a
compatible licensed GitLab server. Push rules require Premium or Ultimate;
check your server's license and version for each approval setting. The flag is
an opt-in guard, not a license check. Ordinary project labels do not require it.
Inherited group or instance restrictions can prevent project-level overrides.

Merge this excerpt into your environment configuration:

```json
{
  "gitlab": {
    "is_enterprise": true,
    "groups": {
      "engineering": {
        "name": "Engineering",
        "path": "engineering",
        "projects": {
          "application": {
            "name": "Application",
            "path": "application",
            "push_rules": {
              "author_email_regex": "@example[.]internal$",
              "max_file_size": 10,
              "should_prevent_secrets": true,
              "should_reject_unsigned_commits": true
            },
            "labels": {
              "bug": { "color": "#CC0000", "description": "Defect", "priority": 0 },
              "needs review": { "color": "blue" }
            },
            "mr_approvals": {}
          }
        }
      }
    }
  }
}
```

### Push Rules

`gitlab_project_push_rules` manages one rule set per opted-in project. All fields
are optional and default to null in the module; provider/server behavior applies
when they are unset. Configure security requirements explicitly rather than
assuming an empty object enables restrictions.

| JSON field | Provider field or meaning |
| --- | --- |
| `author_email_regex` | Author email pattern |
| `branch_name_regex` | Branch name pattern |
| `commit_message_regex` | Required commit message pattern |
| `commit_message_negative_regex` | Rejected commit message pattern |
| `file_name_regex` | Prohibited filename pattern |
| `max_file_size` | Maximum file size in MB |
| `should_check_committer_email` | `commit_committer_check` |
| `should_check_committer_name` | `commit_committer_name_check` |
| `should_deny_tag_deletion` | `deny_delete_tag` |
| `should_check_member` | `member_check` |
| `should_prevent_secrets` | `prevent_secrets` |
| `should_reject_non_dco_commits` | `reject_non_dco_commits` |
| `should_reject_unsigned_commits` | `reject_unsigned_commits` |

Use patterns supported by GitLab and JSON-escape backslashes. Test restrictions
against your existing developer and automation workflows before enforcement.
Do not also manage inline `gitlab_project.push_rules` or use another owner for
the same rule set; this module uses only the standalone resource.

### Labels

`labels` is a map keyed by the exact label name. Each label requires `color`,
either `#RRGGBB` or a supported CSS color name. `description` is optional.
`priority` is an optional non-negative number; null removes priority.
Identical names on different projects are independent resources. Changing a
label map key changes its Terraform address, so review the plan before renaming.

### Project Approval Settings

`gitlab_project_level_mr_approvals` controls approval behavior, not approval counts
or reviewer rules. `mr_approvals: {}` uses these defaults:

| JSON field | Default |
| --- | --- |
| `should_allow_author_approval` | `false` |
| `should_allow_committer_approval` | `false` |
| `should_allow_approver_overrides` | `false` |
| `should_reset_approvals_on_push` | `true` |
| `should_remove_changed_code_owner_approvals` | `false` |
| `should_require_reauthentication_to_approve` | Unset; provider/server behavior applies |

The committer and approver-override allow flags are inverted when mapped to the
provider's `merge_requests_disable_committers_approval` and
`disable_overriding_approvers_per_merge_request` fields. To enable selective
code-owner approval removal, set `should_remove_changed_code_owner_approvals` to
`true` and `should_reset_approvals_on_push` to `false`; the provider requires this
combination. Reauthentication depends on server support. The deprecated
`require_password_to_approve` field is not exposed.

### Project Policy Imports and Removal

Import existing objects before managing them. Use these addresses and import IDs:

| Resource address | Import ID |
| --- | --- |
| `module.gitlab.gitlab_project_push_rules.projects["application"]` | Project ID, for example `42` |
| `module.gitlab.gitlab_project_level_mr_approvals.projects["application"]` | Project ID, for example `42` |
| `module.gitlab.gitlab_project_label.labels["[\"application\",\"bug\"]"]` | `<project-id>:<label-id>`, for example `42:7` |

These resources have no `prevent_destroy` guard. Removing their configuration
requests destruction of the corresponding Terraform resources, not a management
pause. Review provider behavior and the saved plan before removal; do not assume
that earlier remote approval or push-rule settings will be restored. The group
policy `should_keep_settings_on_destroy` option does not apply to project settings.

Provider references for the pinned version:

* [Project push rules](https://registry.terraform.io/providers/gitlabhq/gitlab/19.5.0/docs/resources/project_push_rules)
* [Project labels](https://registry.terraform.io/providers/gitlabhq/gitlab/19.5.0/docs/resources/project_label)
* [Project MR approval settings](https://registry.terraform.io/providers/gitlabhq/gitlab/19.5.0/docs/resources/project_level_mr_approvals)

## Group Policies

Both `groups` and `subgroups` accept optional `mr_approvals` and
`protected_environments` fields. Omission creates no policy resources. Set
`gitlab.is_enterprise` to `true` to opt in; this flag does not activate or verify
a license. Both APIs require GitLab Premium or Ultimate and a compatible server.
Use a credential with group ownership and review inherited restrictions before
configuring subgroup policies. The supplied lab01 JSON does not enable these controls.

Merge this excerpt into your environment configuration:

```json
{
  "gitlab": {
    "is_enterprise": true,
    "groups": {
      "engineering": {
        "name": "Engineering",
        "path": "engineering",
        "mr_approvals": {},
        "protected_environments": {
          "production": {
            "deploy_access_levels": [
              { "access_level": "maintainer" }
            ],
            "approval_rules": [
              { "access_level": "maintainer", "required_approvals": 2 }
            ]
          }
        }
      }
    }
  }
}
```

For a subgroup, put these same fields under
`gitlab.groups.<group-key>.subgroups.<subgroup-key>`. Direct module callers place
them in the corresponding flat `configuration.groups` or `configuration.subgroups` entry.

### Merge Request Approval Settings

`mr_approvals: {}` disallows author and committer self-approval, prevents per-MR
approver-list overrides, and resets approvals on push. Available boolean fields:

| Field | Default |
| --- | --- |
| `should_allow_author_approval` | `false` |
| `should_allow_committer_approval` | `false` |
| `should_allow_overrides_to_approver_list_per_merge_request` | `false` |
| `should_retain_approvals_on_push` | `false` |
| `should_require_reauthentication_to_approve` | Unset; provider/server behavior applies |
| `should_keep_settings_on_destroy` | `true` |

Reauthentication requires GitLab 17.1 or later. These settings govern approval
behavior, not the required number of MR approvals or reviewer rules. Ancestor-locked
settings cannot be relaxed in descendants. The pinned provider marks
`gitlab_group_level_mr_approvals` experimental; use only one owner for each group's settings.

By default, removing `mr_approvals` leaves the remote settings intact and stops
managing them. To restore the values captured before resource creation instead,
set `should_keep_settings_on_destroy` to `false`, apply that change, and only then
remove the policy. Review the saved plan before either operation.

### Protected Deployment Tiers

Map keys must be `production`, `staging`, `testing`, `development`, or `other`.
These are GitLab deployment tiers, not Terraform environment names such as `lab01`
or arbitrary CI environment names. Ensure existing CI jobs use the intended
`environment.deployment_tier`; this module does not create environments or pipelines.

Each entry requires a `deploy_access_levels` array; `approval_rules` defaults to
empty. Each rule selects exactly one of `access_level` (`developer` or
`maintainer`), numeric `user_id`, or numeric `group_id`. User IDs must identify
members with Maintainer access or higher; group IDs must identify subgroups of
the protected group. These fields do not resolve usernames or configuration keys.
Configured group memberships are applied before protection resources.

Both rule types accept `group_inheritance_type`: `0` for direct membership
(default), or `1` to include inherited membership. Approval rules can additionally
set `required_approvals`, but not alongside `user_id`. Ensure enough eligible
approvers exist for the requested count.

Parent group protection applies to descendants and cannot be overridden by a
subgroup. When project-level protection also exists, deployment must satisfy both
rulesets. Removing a protected-environment entry unprotects that tier at that group;
there is no `prevent_destroy` guard on these resources.

Import existing policies before managing them. MR settings use the group ID as
the import ID; protected environments use `<group-id>:<tier>`. Resource addresses
are `module.gitlab.gitlab_group_level_mr_approvals.groups["engineering"]` and
`module.gitlab.gitlab_group_protected_environment.environments["[\"engineering\",\"production\"]"]`.

See the [MR approval settings API](https://docs.gitlab.com/api/merge_request_approval_settings/),
[group protected environments API](https://docs.gitlab.com/api/group_protected_environments/),
and [group inheritance rules](https://docs.gitlab.com/ci/environments/protected_environments/#protected-environments-for-groups)
for server-side requirements that provider mocks cannot verify.

## Outputs and Lifecycle

| Output | Value |
| --- | --- |
| `group_ids` | Group and subgroup IDs keyed by configuration key |
| `project_ids` | Project IDs keyed by configuration key |
| `user_ids` | Managed and looked-up IDs keyed by username |

Groups, subgroups, users, and projects have `prevent_destroy`; memberships,
branch protections, labels, and group/project policies do not. Policy removal behavior is
described above. Import existing objects before applying and review
all access removals. For root operation and backend setup, see
[../../README.md](../../README.md).