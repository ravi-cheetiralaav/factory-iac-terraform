---
title: GitLab Group Module
description: Inputs and outputs for the reusable GitLab group Terraform module
---

## GitLab group module

Creates GitLab groups and subgroups from the catalog, along with configured
group-level branch protections, direct memberships, CI/CD variables, and
group-scoped runner registrations. The stack passes the decoded group catalog
to this module so parent-child IDs can be resolved within the module.

Group-level branch protections apply to all projects in the group and require
GitLab Premium or Ultimate.

### Inputs

| Name | Description |
| --- | --- |
| `groups` | Decoded group catalog keyed by YAML filename |
| `variable_values` | Sensitive map of values referenced by group CI/CD variables |

### Outputs

| Name | Description |
| --- | --- |
| `group_ids` | GitLab group IDs keyed by catalog filename |
| `runner_tokens` | Sensitive runner authentication tokens; state contains them |

### Group branch protection

Declare `branch_protections` in a group YAML file. Each entry uses a branch
name or wildcard and supports the provider's `allowed_to_push`,
`allowed_to_merge`, `allowed_to_unprotect`, `allow_force_push`, and
`code_owner_approval_required` settings.

```yaml
branch_protections:
  - branch: main
    allow_force_push: false
    allowed_to_push:
      - access_level: maintainer
    allowed_to_merge:
      - access_level: developer
    allowed_to_unprotect:
      - access_level: maintainer
```

Runner registration does not install or configure the GitLab Runner process on a
host. See the repository README for token handling and GitLab plan requirements.
