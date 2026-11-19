---
title: GitLab User Module
description: Inputs and outputs for managing GitLab users and custom admin roles
---

## GitLab user module

Manages GitLab instance accounts and custom admin roles. The provider needs
admin-level API access on the target GitLab instance.

| Input | Description |
| --- | --- |
| `users` | User settings keyed by username. Each entry requires `name` and `email`. Optional settings include `is_admin`, `projects_limit`, `can_create_group`, `is_external`, `is_auditor`, `reset_password`, and `password_ref`. |
| `passwords` | Sensitive initial passwords keyed by `password_ref`. Defaults to an empty map. |
| `admin_roles` | Custom admin roles keyed by catalog identifier. Each entry requires `name` and `enabled_permissions` and accepts an optional `description`. Defaults to an empty map. |

| Output | Description |
| --- | --- |
| `user_ids` | Numeric GitLab user IDs keyed by username |
| `admin_role_ids` | Global GitLab role IDs (`gid://gitlab/MemberRole/...`) keyed by catalog identifier |

See the [GitLab catalog example](../../README.md#gitlab-users-and-project-memberships)
for password setup and project membership.

Custom admin roles require GitLab Self-Managed Ultimate. This module defines
roles but does not assign them to users. See the
[Auditor catalog example](../../README.md#gitlab-custom-admin-roles).
