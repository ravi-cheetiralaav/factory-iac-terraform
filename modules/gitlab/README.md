---
title: GitLab Day-2 Module
description: Groups, users, projects, memberships, and branch protection for self-hosted GitLab
---

## Prerequisites

An existing GitLab instance and a root-configured `gitlabhq/gitlab` provider are
required. The root pins version 19.5.0. Supply `GITLAB_TOKEN` externally. Local user
creation needs an administrator; group and project operations need appropriate
ownership. Check your GitLab server version and license against the provider.

## Input

The single input `configuration` is an optional object defaulting to `{}`.
[variables.tf](variables.tf) is the authoritative field/default contract. The root
passes the JSON `gitlab` object to it.

| Field | Content and required entry fields |
| --- | --- |
| `is_enterprise` | Boolean, defaults to false; selects Enterprise access-level sets |
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
    "engineering": { "name": "Engineering", "path": "engineering" }
  },
  "existing_users": ["alice"],
  "group_memberships": {
    "engineering_alice": {
      "group_key": "engineering",
      "username": "alice",
      "access_level": "developer"
    }
  },
  "projects": {
    "application": {
      "name": "Application",
      "path": "application",
      "group_key": "engineering",
      "branch_protections": { "release/*": {} }
    }
  }
}
```

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

## Outputs and Lifecycle

| Output | Value |
| --- | --- |
| `group_ids` | Group and subgroup IDs keyed by configuration key |
| `project_ids` | Project IDs keyed by configuration key |
| `user_ids` | Managed and looked-up IDs keyed by username |

Groups, subgroups, users, and projects have `prevent_destroy`; memberships and
branch protections do not. Import existing objects before applying and review
all access removals. For root operation and backend setup, see
[../../README.md](../../README.md).