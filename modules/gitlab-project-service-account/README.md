---
title: GitLab Project Service Account Module
description: Provision project-scoped GitLab automation identities and optional memberships without managing credentials
---

## GitLab project service accounts

Use this module for automation that needs access to one GitLab project. These
accounts cannot manage instance users or replace the separate instance-admin
identity used by the GitLab stack.

Project service accounts are generally available in GitLab 18.11 and later.
The module uses Terraform 1.9 or later and the `gitlabhq/gitlab` provider
19.5.0 or later. The calling provider must have permission to create project
service accounts and, if requested, add project members.

### Usage

For catalog-managed projects, set `service_accounts` in the
[project YAML](../gitlab-project/README.md#project-service-accounts). To use
the module directly from a stack:

```hcl
module "project_service_account" {
  source = "../../modules/gitlab-project-service-account"

  project_id = gitlab_project.example.id
  accounts = {
    release_bot = {
      name = "Release automation"
      membership = {
        access_level = "developer"
      }
    }
  }
}
```

### Inputs and outputs

* `project_id` is the required GitLab project ID.
* `accounts` is a map keyed by a stable identifier. It defaults to an empty
  map. Each entry can set `name`, `username`, or `email`; GitLab supplies
  defaults for omitted values. GitLab may require confirmation for a custom
  email address.
* `membership` is optional. When present, it requires `access_level` and
  accepts `expires_at` in `YYYY-MM-DD` format. When omitted, Terraform creates
  the identity without adding a direct project membership.
* `service_account_ids` maps the configured keys to numeric GitLab user IDs.

### Credentials

Issue and rotate [project service account tokens](https://docs.gitlab.com/api/service_accounts/#create-a-personal-access-token-for-a-project-service-account)
outside Terraform. Use the narrowest scopes and a short expiry, and store the
token in Vault. The module does not create or output tokens.
