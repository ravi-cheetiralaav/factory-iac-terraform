---
title: GitLab and Artifactory Day-2 Terraform
description: JSON-driven administration of self-hosted GitLab and Artifactory across air-gapped GDC environments
---

## Scope

One Terraform root manages application configuration in existing GitLab and JFrog
Artifactory installations. It does not install either service, provision GDC
infrastructure, create the state bucket, or create CI pipelines.

* GitLab groups, one level of subgroups, local users, existing-user lookup,
  memberships, projects, labels, push rules, merge settings, protected branches,
  group/project MR approval settings, and group protected deployment tiers
* Artifactory groups, local users, 16 local repository formats, generic/Docker
  virtual repositories, and repository permission targets
* Opt-in Artifactory backups, archive/cleanup policies, general security, SMTP,
  OAuth, and password expiration
* One JFrog Project, robot user, publishing role, and membership per GitLab project
* Separate lab01, e01, and w01 remote state, with configuration only in lab01 for now

These modules expose a focused subset of the providers, not every supported
resource. Add capabilities to the relevant module as needed. Vault is not required
or configured today.

## Configuration

Edit the two lab01 configuration files:

* [environments/lab01/gitlab.json](environments/lab01/gitlab.json) for the GitLab URL, hierarchy, users, memberships, and policies
* [environments/lab01/jfrog.json](environments/lab01/jfrog.json) for the Artifactory URL, robot defaults, access, repositories, and optional administration settings

The `e01` and `w01` directories contain only backend placeholders for now.
Add both environment-specific JSON files before planning or applying either one;
there is no fallback to lab01 configuration.
Replace the example endpoints, names, email addresses, and repository keys before
using them against a real installation.

There are no Terraform variable files. The required root input is `environment`,
provided with `TF_VAR_environment` or `-var=environment=lab01`. There is no default
environment. Optional SMTP/OAuth credentials use the separate sensitive
`artifactory_secrets` input, supplied through `TF_VAR_artifactory_secrets`, never
environment configuration JSON. [locals.tf](locals.tf) decodes and combines ordinary JSON:

```hcl
configuration = merge(
  jsondecode(file("${path.module}/environments/${var.environment}/gitlab.json")),
  jsondecode(file("${path.module}/environments/${var.environment}/jfrog.json"))
)
```

Provider URLs come from this object. Root locals flatten the nested GitLab groups,
subgroups, and projects into the existing typed module inputs. They also normalize
Artifactory access and repository settings and derive paired JFrog Projects from
every GitLab project. Optional defaults are applied in the modules. No conversion
script or generated variable file is needed.
Missing files or invalid JSON fail the run.

The GitLab file needs `gitlab_base_url` and `gitlab`:

```json
{
  "gitlab_base_url": "https://gitlab.example.internal/api/v4/",
  "gitlab": {}
}
```

The JFrog file needs `artifactory_url` and `artifactory`. Set the robot email domain
when configuring projects, unless every project supplies its own robot email:

```json
{
  "artifactory_url": "https://jfrog.example.internal/artifactory",
  "artifactory": {
    "defaults": { "robot_email_domain": "example.internal" }
  }
}
```

Use `{}` for empty optional maps. Every nested GitLab project creates paired JFrog
resources; no separate JFrog project list is needed. Keys identify Terraform
instances: keep them stable. Renaming a key can mean destroy/create; review the
plan and use a `moved` block for a deliberate Terraform address rename. An empty
map is not a pause switch: removing existing entries requests their deletion.

JSON must contain no comments, trailing commas, passwords, or tokens. Check field
names against the hierarchy below and module field contracts: object conversion can discard
unknown attributes, so a misspelled optional field may silently use its default.

See [modules/gitlab/README.md](modules/gitlab/README.md) and
[modules/artifactory/README.md](modules/artifactory/README.md) for available fields.

## Configured Hierarchy

Groups contain `subgroups`, and each subgroup contains `projects`. Projects may
also sit directly under a group's `projects` map. Only one managed subgroup level
is supported. Parent references are derived from nesting; do not repeat
`parent_group_key` or project `group_key` in JSON.

```json
{
  "gitlab": {
    "groups": {
      "platform": {
        "name": "Platform Group",
        "path": "platform",
        "subgroups": {
          "platform-environment": {
            "name": "Environment",
            "path": "environment",
            "projects": {
              "platform-iac": {
                "name": "Platform Iac",
                "path": "platform-iac",
                "jfrog": {
                  "key": "platform-iac",
                  "robot": { "email": "robot-platform-iac@example.internal" }
                }
              }
            }
          }
        }
      }
    }
  }
}
```

This is an excerpt of the GitLab file, not a complete environment file. The
project-level `jfrog` block stays with its GitLab project and is optional:
omitting it still creates the paired project and robot with defaults from the JFrog file.
Keep subgroup keys unique across all groups and project keys unique across the
whole environment. Duplicate keys across different parents fail normalization,
rather than silently replacing an entry. Groups and subgroups also cannot share a key.

GitLab `users`, `existing_users`, `group_memberships`, `project_memberships`, and
`is_enterprise` remain directly under `gitlab`. Memberships reference the stable
group or project keys, not their nested JSON paths.

Each group or subgroup can also contain `mr_approvals` and
`protected_environments`. Both are opt-in and require `gitlab.is_enterprise = true`
plus GitLab Premium or Ultimate. Protected-environment keys are deployment tiers
such as `production`, not `lab01`, `e01`, or `w01`. See the
[group policy example and lifecycle rules](modules/gitlab/README.md#group-policies).
These policies are not enabled in the supplied lab01 configuration.

Each project can contain `push_rules`, `labels`, and `mr_approvals`. Push rules and
MR settings are opt-in licensed features guarded by `gitlab.is_enterprise = true`;
ordinary labels do not require this flag. Omitted settings create no additional
resources. See the [project policy JSON example and field reference](modules/gitlab/README.md#project-policies-and-labels).
These additions are also disabled in the supplied lab01 configuration.

JFrog configuration follows its own resource relationships:

| JSON location | Purpose |
| --- | --- |
| Each GitLab project's `jfrog` | Optional JFrog `key` and `robot.email` overrides |
| `artifactory.defaults.robot_email_domain` | Default domain for generated robot email addresses |
| `artifactory.access.groups` | Shared groups keyed by group name |
| `artifactory.access.users` | Shared users with explicit group memberships |
| `artifactory.access.permission_targets` | Grants referencing users, groups, and repositories |
| `artifactory.repositories.local.<format>` | Local repositories keyed by repository name; formats listed below |
| `artifactory.repositories.virtual.generic` and `.docker` | Virtual repositories with member references |
| `artifactory.mail_server` | Optional instance SMTP settings, without the password |
| `artifactory.security.general` | Optional anonymous-access and password-encryption policy |
| `artifactory.security.oauth` | Optional OAuth providers, without client secrets |
| `artifactory.security.password_expiration_policy` | Optional internal-password expiration and email notification |
| `artifactory.maintenance.backups` | Backup definitions keyed by backup name |
| `artifactory.maintenance.archive_policies` | Archive policies keyed by policy name |
| `artifactory.maintenance.package_cleanup_policies` | Cleanup policies keyed by policy name |

Local formats are `alpine`, `ansible`, `debian`, `docker`, `generic`, `helm`,
`helmoci`, `oci`, `maven`, `npm`, `nuget`, `pypi`, `rpm`, `terraform_module`,
`terraform_provider`, and `terraformbackend`. Existing generic/Docker JSON paths
and Terraform addresses are unchanged. Creating a Terraform backend repository
does not change this root's GDC S3 state backend.

All new administrative settings are opt-in and absent from lab01. Omitted/null
singleton objects create no resources; a present object with `should_enable = false`
is still managed. Backups, archive/cleanup policies, SMTP, and OAuth default to
disabled. Removing a previously managed setting can delete/reset it; it does not
merely stop reconciliation. Review instance-wide security changes and destructive
retention behavior before enabling them. See the
[Artifactory configuration examples and compatibility notes](modules/artifactory/README.md#instance-settings-and-maintenance).

Users can belong to several groups and virtual repositories can aggregate several
local repositories, so these use references rather than duplicated child objects.
JFrog Projects remain flat remote resources; JSON nesting does not create a JFrog
group or project hierarchy.

The lab01 configuration implements the supplied diagram: 5 top-level groups, 12
subgroups, and 24 GitLab projects. Organisation is interpreted as the existing
GitLab instance boundary, not an additional managed group.

| Top-level group | Subgroup | Projects |
| --- | --- | --- |
| Platform Group | Environment | Platform Iac, Environment-Config, Ansible Playbooks |
| Platform Group | DevSecOps | DevOps-Iac, Bootstrap Scripts |
| Platform Group | CICD-Templates | gitlab-cicd-templates |
| Platform Group | Security Engineering | Policy-as-code, Compliance-Controls |
| Each of Capability-1 through Capability-4 | Non-EC-apps | App-1, App-2 |
| Each of Capability-1 through Capability-4 | EC-apps | App-1, App-2 |

Only lab01 is configured. When adding e01 and w01, use their own endpoints and
review their access policies. If instances are shared, make group paths, JFrog
keys, and robot names unique before applying; separate state files alone do not
isolate remote objects.

The Artifactory repository and user examples remain under shared `repositories`
and `access` settings. Review or remove those examples before the first apply. If an earlier
sample configuration was already applied, replacing its keys is not a migration:
review imports, state moves, and destruction guards before proceeding.

The hierarchical format replaces the earlier flat environment JSON. Move old
`gitlab.subgroups` and `gitlab.projects` entries under their parents; move
`jfrog_project_key` to each project's `jfrog.key`. Move the old top-level
`jfrog_robot_email_domain` to `artifactory.defaults.robot_email_domain` and the
Artifactory maps to the locations above. Old flat locations are no longer consumed.
The supplied lab01 configuration retains its previous resource keys and parents.
Moving resource blocks between files within the same module does not change
Terraform addresses or require state moves. Review a plan before applying.

## Automatic Project Defaults

Adding a project under a group or subgroup's `projects` map and applying Terraform creates:

* A private GitLab project initialized with a README and default branch `main`
* Default-branch protection: no direct pushes, no force pushes, Maintainer merges
* Successful-pipeline and resolved-discussion requirements for merging
* A JFrog Project using the JSON map key and GitLab display name
* A non-admin robot named `robot-<jfrog-key>` with project publishing membership

For example, `cap1-non-ec-app1` creates GitLab path
`capability-1/non-ec-apps/app-1`, JFrog Project `cap1-non-ec-app1`, and robot
`robot-cap1-non-ec-app1`. Repeated display names such as App-1 have distinct keys.
The email defaults to `robot-cap1-non-ec-app1@<robot_email_domain>`, using
`artifactory.defaults.robot_email_domain`.

JFrog keys must be unique, 2-32 lowercase letters, digits, or hyphens, beginning
with a letter. Optionally set `jfrog.key` in a GitLab project entry to use
a different key, or `jfrog.robot.email` to override its generated email. Treat
the key as an identity: changing it can require replacement.
Do not configure `artifactory.projects`; the root derives and owns that map.
Use `branch_protections` to add patterns or explicitly override the default rule.

The robot's custom `ci-publisher` role grants repository and build read, annotate,
and deploy actions, without delete or administration. Its `DEV` and `PROD`
environments are JFrog repository classifications within the selected instance,
not access to the other Terraform environments. Robots have no global groups,
cannot update their profiles, and cannot sign in to the UI.

> [!IMPORTANT]
> This creates identities and authorization, not usable robot credentials. An
> authorized administrator must issue an expiring, appropriately scoped token
> for each robot and store it in protected CI secrets or your future Vault setup.
> Token issuance and rotation are outside this configuration. No tokens are output.

The pinned Artifactory provider generates an omitted user password without
retaining it in state or making it recoverable. Robots set
`internal_password_disabled`, which disables internal-password fallback when
external authentication is enabled; this is not a universal token-only guarantee.
Validate the account and token behavior against your installation.

JFrog Projects are created without repositories. The current example repositories
are not automatically assigned to them; assign repositories to the appropriate
project before testing robot publishing. No JFrog group hierarchy mirrors GitLab
groups. Pairing runs only for projects declared in JSON, not projects created
outside Terraform. Root outputs `jfrog_project_keys` and `jfrog_robot_usernames`
provide the non-sensitive mapping.

## Prerequisites and Credentials

Use Terraform `>= 1.10.0, < 2.0.0`. Validation used Terraform 1.14.3 and the pinned
providers GitLab 19.5.0, Artifactory 12.11.14, and JFrog Project 1.9.9. The separate
`jfrog/project` provider is required for actual JFrog Projects and membership.
Verify server compatibility and JFrog Projects licensing/API availability before applying.

Configure masked, protected, environment-scoped variables in your existing CI:

| Environment variable | Purpose |
| --- | --- |
| `GITLAB_TOKEN` | GitLab API token with permission for the managed operations |
| `ARTIFACTORY_ACCESS_TOKEN` | JFrog access token with required administration permissions |
| `PROJECT_ACCESS_TOKEN` | JFrog token authorized to administer Projects, roles, and membership |
| `TF_VAR_artifactory_secrets` | Optional JSON object with SMTP password and OAuth client secrets; see module examples |
| `AWS_ACCESS_KEY_ID` | GDC S3-compatible storage access key |
| `AWS_SECRET_ACCESS_KEY` | GDC S3-compatible storage secret key |
| `AWS_SESSION_TOKEN` | Only if the storage credential mechanism requires it |

Local GitLab user creation requires administrator access. Prefer separate service
identities and credentials for each environment. Trust your internal CA in the
runner and provider processes; use `AWS_CA_BUNDLE` for the backend where needed.
Do not disable TLS verification or print credentials in CI logs.

The Project provider also accepts `JFROG_ACCESS_TOKEN`, which takes precedence
over `PROJECT_ACCESS_TOKEN` when both are set. These administration credentials
are separate from the per-project robot tokens. The Project API URL is derived
by removing a trailing slash and `/artifactory` from `artifactory_url`; confirm
that the resulting platform base URL works with your reverse proxy.

SMTP/OAuth secrets are separate from administration tokens. Inject them through
your existing protected secret mechanism; do not put them in environment JSON,
command-line arguments, logs, or source control. Terraform's `sensitive` marking
redacts normal output, but these resource attributes can persist in state and
saved plans. Restrict access to both.

## Existing CI Commands

The following is a shell command sequence for your existing pipeline, not a new
pipeline definition. Inject credentials beforehand. Use the same checkout,
environment, provider versions, and backend settings for plan and apply.

```bash
export TF_VAR_environment=lab01
export TF_DATA_DIR="$PWD/.terraform-data/${TF_VAR_environment}"
terraform init -input=false -reconfigure -lockfile=readonly \
  -backend-config="environments/${TF_VAR_environment}/backend.hcl"
terraform validate
terraform plan -input=false -lock-timeout=5m -out=day2.tfplan
terraform show -no-color day2.tfplan
terraform apply -input=false -lock-timeout=5m day2.tfplan
```

Use `e01` or `w01` only after adding their configuration. On PowerShell, set
`$env:TF_VAR_environment = 'lab01'` and
`$env:TF_DATA_DIR = "$PWD/.terraform-data/$env:TF_VAR_environment"`, then use
`-backend-config="environments/$env:TF_VAR_environment/backend.hcl"` with init.

Gate apply on approval of the saved plan. Treat plans as sensitive artifacts with
restricted access and short retention. Keep the environment selector and backend
file paired; Terraform does not verify that they describe the same environment.
No Terraform workspaces are needed. Never migrate state between environments to
switch targets; use a separate working data directory and reconfigure instead.

## GDC Bucket State

The backend assumes an S3-compatible GDC air-gapped storage endpoint, not public
Google Cloud Storage. Confirm that this is the API exposed by your GDC deployment.
Fill in the bucket, signing region, and endpoint in each environment's backend
file, starting with [environments/lab01/backend.hcl](environments/lab01/backend.hcl).
Each environment uses a distinct state key; separate buckets are preferable for
credential isolation.

The environment rename also changes the example state keys. If an old backend
already contains state, do not apply against a new empty key. Arrange a reviewed
state migration or retain the existing key for the same installation first.

Backend initialization happens before locals and providers are evaluated, so
backend settings must remain in separate backend configuration files. They are
not Terraform variable files. Credentials stay in environment variables.

[backend.tf](backend.tf) enables path-style requests and native S3 lock files,
and disables AWS-specific account/metadata checks. It does not disable TLS.

> [!IMPORTANT]
> Terraform's S3 backend support for non-AWS storage is best effort. GDC endpoint
> compatibility and conditional lock-write semantics have not been tested here.
> Verify locking with concurrent runs against a disposable state key before
> production use. Do not remove locking to work around an incompatible endpoint.

Grant the backend identity bucket listing as required, read/write access to its
state object, and read/write/delete access to its `.tflock` object. Configure
server-side encryption, restricted access, versioning or equivalent recovery, and
audit logging using your storage platform's supported controls. State and saved
plans must be treated as sensitive even when configuration contains no passwords.

## Air-Gapped Provider Installation

Keep [.terraform.lock.hcl](.terraform.lock.hcl) in source control. On an approved
connected staging machine with this checkout, prepare checksums and a mirror for
the actual runner architecture. For a Linux AMD64 runner and Windows development:

```bash
terraform providers lock -platform=linux_amd64 -platform=windows_amd64
terraform providers mirror -platform=linux_amd64 -platform=windows_amd64 ./provider-mirror
```

Review lockfile changes and transfer the mirror through your approved import
process. Do not copy only the Windows provider binaries into a Linux runner.
Make the mirror available locally in the runner and set `TF_CLI_CONFIG_FILE` to
a runner-managed Terraform CLI configuration containing:

```hcl
provider_installation {
  filesystem_mirror {
    path    = "/opt/terraform/provider-mirror"
    include = [
      "registry.terraform.io/gitlabhq/gitlab",
      "registry.terraform.io/jfrog/artifactory",
      "registry.terraform.io/jfrog/project"
    ]
  }
}
```

Omitting `direct` prevents fallback downloads from public registries. Adjust the
path for your runner. Bundle the Terraform executable and internal CA trust too.
The modules are local, so no remote module download is required. Test init using
`-lockfile=readonly` inside the isolated network before enabling CI execution.

## Day-2 Operations

Add or update JSON entries through reviewed changes, run a plan, then apply the
approved plan. Import existing objects before managing them; otherwise Terraform
can attempt duplicate creation. For example, after configuring an existing group,
temporarily add this root import block using its actual numeric ID:

```hcl
import {
  to = module.gitlab.gitlab_group.groups["platform"]
  id = "123"
}
```

Select the correct environment/backend, then review the import plan and any
proposed changes. Follow the pinned provider's import documentation for other
resource IDs. Do not assume import is read-only: the same apply can change fields.

Groups, users (including robots), GitLab and JFrog projects, and Artifactory repositories use
`prevent_destroy`. Removing their JSON entries fails planning while their resource
blocks remain. Removing entire resource/module blocks also removes this guard.
Memberships, custom JFrog roles, permissions, branch protections, and the optional
Artifactory instance settings/maintenance policies can be removed normally; review
those deletions carefully. Singleton removal may reset instance configuration.
User offboarding should revoke access or block accounts
first, with object deletion handled as a separately reviewed operation.

Avoid competing ownership between Terraform and LDAP/SSO synchronization. Test
email delivery and password-reset flows inside the air gap. Provider mocks do not
prove actual onboarding behavior or whether sensitive provider attributes persist
in state.

## Verification and Known Limits

Backend-free local checks, requiring installed or mirrored providers:

```bash
terraform init -backend=false -input=false -lockfile=readonly
terraform fmt -check -recursive
terraform validate
terraform test
```

Fourteen mocked scenarios cover GitLab onboarding, default and enterprise
branch protection, opt-in root/subgroup MR settings and deployment-tier protection,
project push-rule mappings, project MR defaults and overrides, repeated label names
across projects, licensed-policy guards, all 24 diagram projects' baseline protection, duplicate group and
JFrog keys, robot ownership collisions, JFrog project/role/membership wiring,
Artifactory permissions, all 16 local repository formats, SMTP/OAuth secret wiring,
password expiration, general security, backup/retention defaults, empty inputs,
lab01 configuration, and the absence of
configuration in the other two environments. Regression assertions verify every
original hierarchy key and parent, plus normalized JFrog access and repositories. Tests make
no live API calls. Live server compatibility, imports, robot tokens and publishing,
password-reset behavior, SMTP/SSO login, archive/cleanup execution, GDC state access,
and locking need environment validation. Provider support alone does not establish
server-version or license support for these features.

The requested Artifactory provider deprecates `artifactory_group` and
`artifactory_permission_target` in favor of the separate JFrog Platform provider.
This implementation retains those Artifactory resources alongside the Project
provider without adding the Platform provider. Review these deprecations
and plan resource/state migration before upgrading or adopting that provider.

For future Vault integration, prefer having CI obtain short-lived credentials
from Vault and inject the same environment variables. Add the Vault provider only
when Terraform needs to manage Vault objects or consume its data directly; secrets
read through Terraform data sources may persist in state or plans. No Vault token
belongs in the environment JSON.