---
title: Artifactory Day-2 Module
description: JFrog projects and robots, identities, repositories, permissions, and opt-in instance policies
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

The non-secret input `configuration` is an optional object defaulting to `{}`.
[variables.tf](variables.tf) is the authoritative field/default contract. The root
normalizes hierarchical `artifactory` JSON into these flat fields, with `projects`
derived from nested GitLab projects. Direct module callers use the flat contract.
All maps default to empty; instance-setting objects default to null. The optional
sensitive `secrets` object is supplied separately and defaults to `{}`.

| Field | Content and required entry fields |
| --- | --- |
| `projects` | Map keyed by GitLab configuration key; required `key`, `display_name`, `robot_email`; supplied automatically by the root |
| `groups` | Map keyed by group name; optional `description` |
| `users` | Map keyed by username; required `email`, optional `groups` array |
| `local_generic_repositories` | Map keyed by repository key; optional `description` |
| `local_docker_repositories` | Map keyed by repository key; optional `description`, `max_unique_tags` |
| `local_<format>_repositories` | Fourteen further local formats and their options listed below |
| `virtual_generic_repositories` | Map with required `repositories` array, optional `description`, `default_deployment_repo` |
| `virtual_docker_repositories` | Map with required `repositories` array, optional `description`, `default_deployment_repo` |
| `permission_targets` | Map with required `repositories` array and optional action maps/patterns |
| `mail_server` | Optional singleton; required `host`, `port` |
| `oauth_settings` | Optional singleton; required `providers` map with at least one entry |
| `general_security` | Optional singleton; anonymous access defaults false, encryption policy defaults `SUPPORTED` |
| `password_expiration_policy` | Optional singleton; required `name`, `should_enable`, `password_max_age`, `should_notify_by_email` |
| `backups` | Map keyed by backup key; required `cron_exp` |
| `archive_policies`, `package_cleanup_policies` | Maps keyed by policy key; required `search_criteria` |

Groups are non-admin and do not auto-join users. Users are non-admin, own their
configured group memberships, and can update their profiles. The optional
`should_disable_internal_password` and `should_disable_ui_access` flags default
to false. Only disable internal passwords when a working external authentication
path exists. Do not manage the same memberships through competing automation.

No user password input is exposed or supplied to the user resource. Establish and test your
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
`artifactory.defaults.robot_email_domain`. Each nested GitLab project may supply
`jfrog.key` and `jfrog.robot.email` overrides; neither is required when a default
email domain is set. Omitting the `jfrog` block does not disable pairing.

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
  "defaults": { "robot_email_domain": "example.internal" },
  "access": {
    "groups": { "developers": {} },
    "users": {
      "alice": { "email": "alice@example.internal", "groups": ["developers"] }
    },
    "permission_targets": {
      "publish": {
        "repositories": ["generic-local"],
        "group_permissions": { "developers": ["read", "write", "annotate"] }
      }
    }
  },
  "repositories": {
    "local": {
      "generic": { "generic-local": {} }
    },
    "virtual": {
      "generic": {
        "generic": {
          "repositories": ["generic-local"],
          "default_deployment_repo": "generic-local"
        }
      }
    }
  }
}
```

Docker maps use `repositories.local.docker` and `repositories.virtual.docker`.
Groups and users stay separate because users can have multiple group memberships.
Repositories stay separate from paired projects; this grouping does not assign
repositories to JFrog Projects. Do not add a second `artifactory.projects` list.

Permission targets accept `group_permissions` and `user_permissions`, each mapping
a principal name to an array of API action names. They default to no grants.
`includes_patterns` defaults to `["**"]` and `excludes_patterns` to `[]`.
Use explicit repository keys and least-privilege actions. Remote repositories,
general build permission targets, and tokens are not exposed
by this module today. The paired robot role does include project-scoped build actions.

## Local Repository Formats

Under `artifactory.repositories.local`, each format is a map keyed by the actual
repository name. Keep names unique across all formats and virtual repositories.
Every entry accepts an optional `description`. `{}` creates a repository with
defaults. For direct module callers, the input name is `local_<format>_repositories`.

| JSON format | Additional entry fields |
| --- | --- |
| `generic` | None; uses `simple-default` layout |
| `docker` | `max_unique_tags` (0); schema-1 pushes are always blocked |
| `alpine`, `ansible` | `primary_keypair_ref` |
| `debian` | `primary_keypair_ref`, `secondary_keypair_ref`, `index_compression_formats` ([]), `should_use_trivial_layout` (false) |
| `helm` | `should_force_non_duplicate_chart`, `should_force_metadata_name_version` (both omitted by default) |
| `helmoci`, `oci` | `tag_retention` (omitted), `max_unique_tags` (0) |
| `maven` | `checksum_policy_type` (`client-checksums`), `snapshot_version_behavior` (`unique`), `max_unique_snapshots` (0), `should_handle_releases` (true), `should_handle_snapshots` (true), `should_suppress_pom_consistency_checks` (false) |
| `npm`, `pypi` | None |
| `nuget` | `max_unique_snapshots` (0), `should_force_nuget_authentication` (false) |
| `rpm` | `yum_root_depth` (0), `should_calculate_yum_metadata` (false), `should_enable_file_lists_indexing` (false), `yum_group_file_names`, `primary_keypair_ref`, `secondary_keypair_ref` |
| `terraform_module`, `terraform_provider`, `terraformbackend` | None |

The fourteen new formats use the pinned provider's package-specific layout
defaults. Other common provider attributes are not exposed. Signing key references
must name keys already installed in Artifactory; this module does not create keys.
Debian compression values are `bz2`, `lzma`, and `xz`. Its trivial layout is a
legacy option. Omit unused RPM group filenames rather than supplying an empty
string; when supplied, use comma-separated XML filenames.

Helm's two enforcement flags require Artifactory 7.104.0+ and cannot be changed
after being set according to the provider docs. Review replacement plans against
`prevent_destroy`. Positive snapshot/tag limits can delete older artifacts;
0 means unlimited for `max_unique_snapshots` and `max_unique_tags`.
`tag_retention` controls retention of overwritten Helm OCI/OCI tags by digest.

Example excerpt to merge into the existing `artifactory.repositories.local` object:

```json
{
  "alpine": { "alpine-local": {} },
  "ansible": { "ansible-local": {} },
  "debian": { "debian-local": { "index_compression_formats": ["xz"] } },
  "docker": { "docker-local": {} },
  "generic": { "generic-local": {} },
  "helm": { "helm-local": {} },
  "helmoci": { "helmoci-local": {} },
  "oci": { "oci-local": {} },
  "maven": { "maven-local": { "should_handle_snapshots": false } },
  "npm": { "npm-local": {} },
  "nuget": { "nuget-local": { "should_force_nuget_authentication": true } },
  "pypi": { "pypi-local": {} },
  "rpm": { "rpm-local": { "should_calculate_yum_metadata": true } },
  "terraform_module": { "terraform-module-local": {} },
  "terraform_provider": { "terraform-provider-local": {} },
  "terraformbackend": { "terraformbackend-local": {} }
}
```

The Terraform backend repository is an application repository only. It does not
replace this root's GDC S3 backend or configure Terraform clients to use it.
Virtual formats remain limited to generic and Docker.

## Instance Settings and Maintenance

The following objects are optional and are not enabled in the supplied lab01
configuration. Omitted/null singleton objects create no resources. Present objects
manage their singleton even when `should_enable` is false. Use only one Terraform
state to own each instance-wide setting, especially when environments share a server.
Backups and retention policies are keyed collections, not singletons.

| Environment JSON path under `artifactory` | Direct module field | Behavior |
| --- | --- | --- |
| `mail_server` | `mail_server` | Disabled by default; TLS true and SSL false; optional `username`, `from`, `subject_prefix`, `artifactory_url` |
| `security.oauth` | `oauth_settings` | Disabled by default; user persistence and profile access false |
| `security.general` | `general_security` | `should_enable_anonymous_access` false; `encryption_policy` is `SUPPORTED`, `REQUIRED`, or `UNSUPPORTED` |
| `security.password_expiration_policy` | `password_expiration_policy` | Explicit enable/notification flags and password maximum age in days |
| `maintenance.backups` | `backups` | Disabled by default; 168-hour retention and disk-space verification enabled |
| `maintenance.archive_policies` | `archive_policies` | Disabled by default; explicit search scope required |
| `maintenance.package_cleanup_policies` | `package_cleanup_policies` | Disabled by default; explicit search scope required |

General security uses self-hosted-only undocumented endpoints. `encryption_policy`
controls acceptance of encrypted/clear-text passwords, not network TLS.
`REQUIRED` accepts only encrypted passwords; `UNSUPPORTED` accepts clear-text
passwords. Review authentication impact before changing it. Password expiration
applies to internal users, not external IdP policy; its `name` is an import identifier.
Email notifications require a working mail server, managed here or configured already.

Merge selected objects into the environment's `artifactory` object; this excerpt
does not include existing access/repository configuration. All enable flags are
false so the example does not schedule work or enable authentication changes:

```json
{
  "mail_server": {
    "host": "smtp.example.internal",
    "port": 587,
    "username": "artifactory",
    "from": "artifactory@example.internal",
    "should_enable": false
  },
  "security": {
    "general": {
      "should_enable_anonymous_access": false,
      "encryption_policy": "SUPPORTED"
    },
    "password_expiration_policy": {
      "name": "internal-passwords",
      "should_enable": false,
      "password_max_age": 120,
      "should_notify_by_email": false
    },
    "oauth": {
      "should_enable": false,
      "providers": {
        "internal": {
          "type": "openId",
          "client_id": "artifactory",
          "api_url": "https://idp.example.internal/userinfo",
          "auth_url": "https://idp.example.internal/authorize",
          "token_url": "https://idp.example.internal/token"
        }
      }
    }
  },
  "maintenance": {
    "backups": {
      "nightly": {
        "cron_exp": "0 0 2 * * ? *",
        "should_enable": false
      }
    },
    "archive_policies": {
      "archive-old": {
        "should_enable": false,
        "search_criteria": {
          "package_types": ["docker"],
          "repos": ["docker-local"],
          "included_packages": ["**"],
          "included_projects": ["default"],
          "created_before_in_days": 180,
          "last_downloaded_before_in_days": 90
        }
      }
    },
    "package_cleanup_policies": {
      "cleanup-old": {
        "should_enable": false,
        "search_criteria": {
          "package_types": ["generic"],
          "repos": ["generic-local"],
          "included_packages": ["**"],
          "included_projects": ["default"],
          "created_before_in_days": 90,
          "last_downloaded_before_in_days": 30
        }
      }
    }
  }
}
```

Adding disabled settings still changes managed server configuration. Import
existing settings first; do not paste the whole example into a running instance.

### SMTP and OAuth Secrets

Supply `TF_VAR_artifactory_secrets` through your existing protected secret injection.
Its JSON shape is shown below with placeholders, not actual credentials. This is
the value of an environment variable, not part of environment configuration JSON:

```json
{
  "mail_password": "<injected SMTP password>",
  "oauth_client_secrets": {
    "internal": "<injected OAuth client secret>"
  }
}
```

The root forwards it to the module's sensitive `secrets` input. OAuth secret keys
must match `providers` keys exactly. Each configured OAuth provider needs a secret,
even when OAuth is disabled. `mail_password` can be omitted for an SMTP server
that does not require password authentication. Do not pass real secrets through
command arguments, checked-in files, or chat. No Vault provider is added.

OAuth provider entries require `type`, `client_id`, `api_url`, `auth_url`, and
`token_url`; their `should_enable` defaults true. Instance-level
`should_persist_users` and `should_allow_user_to_access_profile` default false.
Use internal IdP endpoints reachable inside the air gap and verify login before
disabling an existing authentication path. For implicit SMTP TLS, review the
port and explicitly select `should_use_ssl`/`should_use_tls` appropriately.

SMTP passwords and OAuth client secrets are not returned by the server, so import
can show credential drift. Supply the intended values and review the plan.
Sensitive marking redacts normal CLI output but does not keep these attributes
out of state or saved plans. Apply backend access controls and encryption.

### Backups and Retention Safety

Backups use `cron_exp`, a seven-field Quartz expression, not Unix crontab syntax.
Use `?` for either day-of-month or day-of-week. Optional backup fields include
`retention_period_hours`, `excluded_repositories`, `should_create_archive`,
`should_exclude_new_repositories`, `should_send_mail_on_error`,
`should_verify_disk_space`, and `should_export_mission_control`. Error email and
disk checks default true; archive creation, new-repository exclusion, and Mission
Control export default false. Validate backup storage capacity and restore procedures.

Archive and cleanup policies accept optional `description`, `cron_expression`,
`duration_in_minutes`, `project_key`, and `should_skip_trashcan`. Without a cron
expression, policies are for manual execution. Terraform configures policies;
this module does not invoke a cleanup or archive run. The two policy resources
have independent maps and can coexist.

`search_criteria` requires `package_types`, `repos`, `included_packages`, and
`included_projects`. Use only one package name/pattern in `included_packages`.
`["default"]` selects repositories not assigned to a Project. Optional
`should_include_all_projects` defaults false. Omit unused `excluded_packages`
and `excluded_repos`; the provider rejects explicit empty exclusion arrays.

Provide a valid positive age condition, `keep_last_n_versions`, or
`included_properties`. Day and month variants cannot be mixed. Keep-last counts
cannot be combined with age or included-property criteria and are unsupported
for some formats, including generic. Property filters use an object containing
one property key with one value in its array. `excluded_properties` is also
available. Provider validation enforces these combinations.

Project-level cleanup policy keys must start with `<project_key>-`, use
`included_projects: []`, and leave `should_include_all_projects` false. Archive
documentation instead shows the project key in `included_projects` for project
policies; check the pinned provider documentation for the selected policy type.
Referenced repositories/Projects outside this module must already exist.

> [!WARNING]
> `should_skip_trashcan = true` permits permanent deletion. It defaults false,
> but trash retention also requires Artifactory's global Trash Can to be enabled.
> Review matched packages and retention conditions before enabling either policy.
> Repository `prevent_destroy` does not prevent deletion of artifacts by policies.

Cleanup is documented for self-hosted Artifactory 7.98.7+ with Enterprise+;
EntX support starts at 7.146. Day-based criteria require 7.111.2+, and combined
time/property matching requires 7.129+. Package-specific support varies.
Confirm archive licensing and archive storage setup on your deployment before
enabling archive policies. Mocks do not verify these server capabilities. Use
the pinned [cleanup reference](https://github.com/jfrog/terraform-provider-artifactory/blob/v12.11.14/docs/resources/package_cleanup_policy.md)
and [archive reference](https://github.com/jfrog/terraform-provider-artifactory/blob/v12.11.14/docs/resources/archive_policy.md)
for the complete compatibility matrix and criteria rules.

### Imports and Removal

Configure the intended values, select the correct environment/backend, and import
existing objects before applying. Singleton settings use the instance key `main`:

| Root resource address | Import ID |
| --- | --- |
| `module.artifactory.artifactory_general_security.main["main"]` | `security` |
| `module.artifactory.artifactory_mail_server.main["main"]` | An identifier such as `mailserver` |
| `module.artifactory.artifactory_oauth_settings.main["main"]` | `oauth_settings` |
| `module.artifactory.artifactory_password_expiration_policy.main["main"]` | Configured policy `name` |
| `module.artifactory.artifactory_backup.backups["nightly"]` | Backup key, such as `nightly` |
| `module.artifactory.artifactory_archive_policy.policies["archive-old"]` | Policy key; project-level format is `policy-key:project-key` |
| `module.artifactory.artifactory_package_cleanup_policy.policies["cleanup-old"]` | Policy key; project-level format is `policy-key:project-key` |
| `module.artifactory.artifactory_local_npm_repository.repositories["npm-local"]` | Repository key, such as `npm-local` |

Other local repositories follow the same address pattern with their provider
resource type; `docker` uses `artifactory_local_docker_v2_repository`. Import does
not guarantee a no-change plan. Review default values, credentials, and ownership.
These seven administrative resources have no `prevent_destroy`: removing their
configuration requests provider deletion/reset behavior, not a pause. To disable
a managed policy, keep it configured and set `should_enable` false. Review removal
plans and provider behavior before relinquishing instance settings.

## Files

| File | Responsibility |
| --- | --- |
| [projects.tf](projects.tf) | Paired JFrog Projects |
| [robots.tf](robots.tf) | Robot users, publishing roles, and project memberships |
| [identities.tf](identities.tf) | Shared groups and ordinary users |
| [repositories.tf](repositories.tf) | Sixteen local formats and generic/Docker virtual repositories |
| [permissions.tf](permissions.tf) | Repository permission targets |
| [backups.tf](backups.tf) | Backup schedules |
| [retention-policies.tf](retention-policies.tf) | Archive and package cleanup policies |
| [general-security.tf](general-security.tf) | Instance-wide general security |
| [mail-server.tf](mail-server.tf) | SMTP settings |
| [oauth-settings.tf](oauth-settings.tf) | OAuth providers |
| [password-expiration-policy.tf](password-expiration-policy.tf) | Internal-password expiration |
| [variables.tf](variables.tf), [outputs.tf](outputs.tf), [versions.tf](versions.tf) | Input contract, outputs, and provider requirements |

Terraform loads all these files as one module. Existing resource labels and keys
are unchanged, so the file split does not require state moves.

## Outputs and Lifecycle

| Output | Value |
| --- | --- |
| `project_keys` | JFrog project keys by GitLab configuration key |
| `robot_usernames` | Robot usernames by GitLab configuration key; no credentials |
| `repository_keys` | Lists keyed by `local_<format>` for all 16 formats plus `virtual_generic` and `virtual_docker`; existing keys preserved |
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