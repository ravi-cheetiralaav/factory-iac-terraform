---
title: Artifactory Day-2 Module
description: Groups, users, generic and Docker repositories, and repository permissions
---

## Prerequisites

An existing Artifactory installation and a root-configured `jfrog/artifactory`
provider are required. The root pins version 12.11.14. Supply
`ARTIFACTORY_ACCESS_TOKEN` externally with the permissions required to manage
users, groups, repositories, and permission targets. Verify server version and
license support for the requested repository types and APIs.

## Input

The single input `configuration` is an optional object defaulting to `{}`.
[variables.tf](variables.tf) is the authoritative field/default contract. The root
passes the JSON `artifactory` object to it. All maps default to empty.

| Field | Content and required entry fields |
| --- | --- |
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
remote repositories, build permissions, tokens, and JFrog Projects are not exposed
by this module today.

## Outputs and Lifecycle

| Output | Value |
| --- | --- |
| `repository_keys` | Lists grouped as `local_generic`, `local_docker`, `virtual_generic`, `virtual_docker` |
| `group_names` | Managed group names |
| `usernames` | Managed usernames |

Groups, users, and repositories have `prevent_destroy`. Permission targets do
not; removing them revokes the associated grants. Import existing objects before
applying and review ownership of users and their group lists.

## Provider Deprecations

`artifactory_group` and `artifactory_permission_target` are deprecated in favor of
`platform_group` and `platform_permission` from the separate JFrog Platform
provider. They are retained here to stay within the requested Artifactory provider.
Expect deprecation warnings. A later provider migration needs explicit resource
and state planning; do not rename resource types and assume the state is portable.

For root operation, credentials, and backend setup, see
[../../README.md](../../README.md).