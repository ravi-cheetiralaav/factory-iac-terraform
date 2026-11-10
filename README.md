---
title: GitLab and Artifactory Day-2 Terraform
description: JSON-driven administration of self-hosted GitLab and Artifactory across air-gapped GDC environments
---

## Scope

One Terraform root manages application configuration in existing GitLab and JFrog
Artifactory installations. It does not install either service, provision GDC
infrastructure, create the state bucket, or create CI pipelines.

* GitLab groups, one level of subgroups, local users, existing-user lookup,
  memberships, projects, merge settings, and protected branches
* Artifactory groups, local users, generic and Docker repositories, virtual
  repositories, and repository permission targets
* One JFrog Project, robot user, publishing role, and membership per GitLab project
* Separate lab01, e01, and w01 remote state, with configuration only in lab01 for now

These modules expose a focused subset of the providers, not every supported
resource. Add capabilities to the relevant module as needed. Vault is not required
or configured today.

## Configuration

Edit [environments/lab01/config.json](environments/lab01/config.json).
The `e01` and `w01` directories contain only backend placeholders for now.
Add an environment-specific `config.json` before planning or applying either one;
there is no fallback to lab01 configuration.
Replace the example endpoints, names, email addresses, and repository keys before
using them against a real installation.

There are no Terraform variable files. The only root input is `environment`,
provided with `TF_VAR_environment` or `-var=environment=lab01`. There is no default
environment. [locals.tf](locals.tf) decodes ordinary JSON:

```hcl
configuration = jsondecode(file("${path.module}/environments/${var.environment}/config.json"))
```

Provider URLs come from this object. Its `gitlab` and `artifactory` objects are
passed to the typed `configuration` input of each child module, with JFrog project
specifications derived from `gitlab.projects` and merged into the Artifactory
input. Optional defaults are applied in the modules. No conversion script or generated variable file is needed.
Missing files or invalid JSON fail the run.

Every configuration needs these five top-level fields:

```json
{
  "gitlab_base_url": "https://gitlab.example.internal/api/v4/",
  "artifactory_url": "https://jfrog.example.internal/artifactory",
  "jfrog_robot_email_domain": "example.internal",
  "gitlab": {},
  "artifactory": {}
}
```

Use `{}` for empty optional configuration. A nonempty `gitlab.projects` map always
creates paired JFrog resources, even when `artifactory` is `{}`. Keys identify Terraform
instances: keep them stable. Renaming a key can mean destroy/create; review the
plan and use a `moved` block for a deliberate Terraform address rename. An empty
map is not a pause switch: removing existing entries requests their deletion.

JSON must contain no comments, trailing commas, passwords, or tokens. Check field
names against the module contracts: Terraform object conversion can discard
unknown attributes, so a misspelled optional field may silently use its default.

See [modules/gitlab/README.md](modules/gitlab/README.md) and
[modules/artifactory/README.md](modules/artifactory/README.md) for available fields.

## Configured Hierarchy

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

The existing Artifactory repository and user examples remain separate from this
hierarchy. Review or remove those examples before the first apply. If an earlier
sample configuration was already applied, replacing its keys is not a migration:
review imports, state moves, and destruction guards before proceeding.

## Automatic Project Defaults

Adding one entry under `gitlab.projects` and applying Terraform creates:

* A private GitLab project initialized with a README and default branch `main`
* Default-branch protection: no direct pushes, no force pushes, Maintainer merges
* Successful-pipeline and resolved-discussion requirements for merging
* A JFrog Project using the JSON map key and GitLab display name
* A non-admin robot named `robot-<jfrog-key>` with project publishing membership

For example, `cap1-non-ec-app1` creates GitLab path
`capability-1/non-ec-apps/app-1`, JFrog Project `cap1-non-ec-app1`, and robot
`robot-cap1-non-ec-app1`. Repeated display names such as App-1 have distinct keys.
The email is `robot-cap1-non-ec-app1@<jfrog_robot_email_domain>`.

JFrog keys must be unique, 2-32 lowercase letters, digits, or hyphens, beginning
with a letter. Optionally set `jfrog_project_key` in a GitLab project entry to use
a different key. Treat it as an identity: changing it can require replacement.
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
Memberships, custom JFrog roles, permissions, and branch protections can be removed normally; review
those deletions carefully. User offboarding should revoke access or block accounts
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

Ten mocked scenarios cover GitLab onboarding, default and enterprise
protection, all 24 diagram projects' baseline protection, duplicate group and
JFrog keys, robot ownership collisions, JFrog project/role/membership wiring,
Artifactory permissions, empty inputs, lab01 configuration, and the absence of
configuration in the other two environments. Tests make
no live API calls. Live server compatibility, imports, robot tokens and publishing,
password-reset behavior, GDC state access, and locking need environment validation.

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