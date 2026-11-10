---
title: Artifactory Day-2 Module
description: JFrog projects and robot membership, groups, users, repositories, and permissions
---

## Prerequisites

An existing Artifactory installation and root-configured `jfrog/artifactory` and
`jfrog/project` providers are required. The root pins versions 12.11.14 and 1.9.9.
Supply
`ARTIFACTORY_ACCESS_TOKEN` externally with the permissions required to manage
users, groups, repositories, and permission targets. Supply `PROJECT_ACCESS_TOKEN`
for Projects, roles, and membership (or `JFROG_ACCESS_TOKEN`, which takes precedence).
Verify server version and license support for JFrog Projects and the requested APIs.

## Input

The single input `configuration` is an optional object defaulting to `{}`.
[variables.tf](variables.tf) is the authoritative field/default contract. The root
passes the JSON `artifactory` object with `projects` derived from `gitlab.projects`.
All maps default to empty.

| Field | Content and required entry fields |
| --- | --- |
| `projects` | Map keyed by GitLab configuration key; required `key`, `display_name`, `robot_email`; supplied automatically by the root |
| `groups` | Map keyed by group name; optional `description` |
| `users` | Map keyed by username; required `email`, optional `groups` array |
| `local_generic_repositories` | Map keyed by repository key; optional `description` |
| `local_docker_repositories` | Map keyed by repository key; optional `description`, `max_unique_tags` |
| `virtual_generic_repositories` | Map with required `repositories` array, optional `description`, `default_deployment_repo` |
| `virtual_docker_repositories` | Map with required `repositories` array, optional `description`, `default_deployment_repo` |
| `permission_targets` | Map with required `repositories` array and optional action maps/patterns |

Groups are non-admin and do not auto-join users. Users are non-admin, own their
configured group memberships, and can update their profiles. The optional
`should_disable_internal_password` and `should_disable_ui_access` flags default
to false. Only disable internal passwords when a working external authentication
path exists. Do not manage the same memberships through competing automation.

No password input is exposed or supplied to the resource. Establish and test your
reset or external-identity onboarding process inside the air gap. Mock tests do
not verify actual password generation, delivery, or state contents. Treat state
as sensitive regardless of whether configuration contains passwords.

Generic repositories use `simple-default` layout. Docker repositories reject
schema-1 pushes and default `max_unique_tags` to 0 (unlimited), avoiding automatic
tag retention deletion. Virtual repositories can reference managed or existing
repositories by actual key; existing references must already exist. Set
`default_deployment_repo` to an appropriate local member to support publishing.

## Paired Projects and Robots

Each `projects` entry creates `project_project.projects`,
`artifactory_user.robots`, `project_role.ci_publishers`, and `project_user.robots`.
Project keys must be unique. Robot usernames are `robot-<project-key>` and must
not also appear in `users`. The root derives email addresses from the environment's
`jfrog_robot_email_domain` and allows a per-GitLab-project `jfrog_project_key` override.

The custom `ci-publisher` role grants `READ_REPOSITORY`, `ANNOTATE_REPOSITORY`,
`DEPLOY_CACHE_REPOSITORY`, `READ_BUILD`, `ANNOTATE_BUILD`, and `DEPLOY_BUILD` in
JFrog's `DEV` and `PROD` repository classifications. It grants no deletion or
administration actions. Robots are non-admin, have no global group memberships,
and have UI access and profile updates disabled.

Robot passwords are omitted. The pinned provider generates a password without
persisting it in state or returning it. `internal_password_disabled = true`
disables internal-password fallback when external authentication is enabled,
not universally. Use a separately issued, scoped, expiring robot token and keep
it in protected CI secrets or Vault. Token creation and rotation are not managed
here. Verify effective permissions with your server before publishing.

Projects start without repositories and without an enforced storage limit. The
repository resources below are independent and are not automatically attached to
projects. Assign appropriate repositories before expecting project-role grants
to authorize publishing. No GitLab-like group hierarchy is created in JFrog.

## JSON Usage

Place this object under the environment JSON's `artifactory` key:

```json
{
  "groups": { "developers": {} },
  "users": {
    "alice": { "email": "alice@example.internal", "groups": ["developers"] }
  },
  "local_generic_repositories": { "generic-local": {} },
  "virtual_generic_repositories": {
    "generic": {
      "repositories": ["generic-local"],
      "default_deployment_repo": "generic-local"
    }
  },
  "permission_targets": {
    "publish": {
      "repositories": ["generic-local"],
      "group_permissions": { "developers": ["read", "write", "annotate"] }
    }
  }
}
```

Permission targets accept `group_permissions` and `user_permissions`, each mapping
a principal name to an array of API action names. They default to no grants.
`includes_patterns` defaults to `["**"]` and `excludes_patterns` to `[]`.
Use explicit repository keys and least-privilege actions. Other package types,
remote repositories, general build permission targets, and tokens are not exposed
by this module today. The paired robot role does include project-scoped build actions.

## Outputs and Lifecycle

| Output | Value |
| --- | --- |
| `project_keys` | JFrog project keys by GitLab configuration key |
| `robot_usernames` | Robot usernames by GitLab configuration key; no credentials |
| `repository_keys` | Lists grouped as `local_generic`, `local_docker`, `virtual_generic`, `virtual_docker` |
| `group_names` | Managed group names |
| `usernames` | Ordinary managed usernames, excluding automatically paired robots |

Projects, groups, users (including robots), and repositories have `prevent_destroy`.
Project membership, custom roles, and permission targets do not; removing them
revokes the associated grants. Import existing objects before applying and review
ownership of users and their group lists.

## Provider Deprecations

`artifactory_group` and `artifactory_permission_target` are deprecated in favor of
`platform_group` and `platform_permission` from the separate JFrog Platform
provider. They are retained here to stay within the requested Artifactory provider.
Expect deprecation warnings. A later provider migration needs explicit resource
and state planning; do not rename resource types and assume the state is portable.

For root operation, credentials, and backend setup, see
[../../README.md](../../README.md).