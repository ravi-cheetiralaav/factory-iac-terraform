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
* Separate dev, test, and prod configuration and remote state

These modules expose a focused subset of the providers, not every supported
resource. Add capabilities to the relevant module as needed. Vault is not required
or configured today.

## Configuration

Edit [environments/dev/config.json](environments/dev/config.json),
[environments/test/config.json](environments/test/config.json), or
[environments/prod/config.json](environments/prod/config.json).
Replace the example endpoints, names, email addresses, and repository keys before
using them against a real installation.

There are no Terraform variable files. The only root input is `environment`,
provided with `TF_VAR_environment` or `-var=environment=dev`. There is no default
environment. [locals.tf](locals.tf) decodes ordinary JSON:

```hcl
configuration = jsondecode(file("${path.module}/environments/${var.environment}/config.json"))
```

Provider URLs come from this object. Its `gitlab` and `artifactory` objects are
passed to the typed `configuration` input of each child module, where optional
defaults are applied. No conversion script or generated variable file is needed.
Missing files or invalid JSON fail the run.

Every configuration needs these four top-level fields:

```json
{
  "gitlab_base_url": "https://gitlab.example.internal/api/v4/",
  "artifactory_url": "https://jfrog.example.internal/artifactory",
  "gitlab": {},
  "artifactory": {}
}
```

Use `{}` for a service with no managed configuration. Keys identify Terraform
instances: keep them stable. Renaming a key can mean destroy/create; review the
plan and use a `moved` block for a deliberate Terraform address rename. An empty
map is not a pause switch: removing existing entries requests their deletion.

JSON must contain no comments, trailing commas, passwords, or tokens. Check field
names against the module contracts: Terraform object conversion can discard
unknown attributes, so a misspelled optional field may silently use its default.

See [modules/gitlab/README.md](modules/gitlab/README.md) and
[modules/artifactory/README.md](modules/artifactory/README.md) for available fields.

## Prerequisites and Credentials

Use Terraform `>= 1.10.0, < 2.0.0`. Validation used Terraform 1.14.3 and the pinned
providers GitLab 19.5.0 and Artifactory 12.11.14. Verify compatibility with your
installed server versions and licenses before applying.

Configure masked, protected, environment-scoped variables in your existing CI:

| Environment variable | Purpose |
| --- | --- |
| `GITLAB_TOKEN` | GitLab API token with permission for the managed operations |
| `ARTIFACTORY_ACCESS_TOKEN` | JFrog access token with required administration permissions |
| `AWS_ACCESS_KEY_ID` | GDC S3-compatible storage access key |
| `AWS_SECRET_ACCESS_KEY` | GDC S3-compatible storage secret key |
| `AWS_SESSION_TOKEN` | Only if the storage credential mechanism requires it |

Local GitLab user creation requires administrator access. Prefer separate service
identities and credentials for each environment. Trust your internal CA in the
runner and provider processes; use `AWS_CA_BUNDLE` for the backend where needed.
Do not disable TLS verification or print credentials in CI logs.

## Existing CI Commands

The following is a shell command sequence for your existing pipeline, not a new
pipeline definition. Inject credentials beforehand. Use the same checkout,
environment, provider versions, and backend settings for plan and apply.

```bash
export TF_VAR_environment=dev
export TF_DATA_DIR="$PWD/.terraform-data/${TF_VAR_environment}"
terraform init -input=false -reconfigure -lockfile=readonly \
  -backend-config="environments/${TF_VAR_environment}/backend.hcl"
terraform validate
terraform plan -input=false -lock-timeout=5m -out=day2.tfplan
terraform show -no-color day2.tfplan
terraform apply -input=false -lock-timeout=5m day2.tfplan
```

Use `test` or `prod` for the other environments. On PowerShell, set
`$env:TF_VAR_environment = 'dev'` and
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
file, starting with [environments/dev/backend.hcl](environments/dev/backend.hcl).
Each environment uses a distinct state key; separate buckets are preferable for
credential isolation.

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
    include = ["registry.terraform.io/gitlabhq/gitlab", "registry.terraform.io/jfrog/artifactory"]
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
  to = module.gitlab.gitlab_group.groups["engineering"]
  id = "123"
}
```

Select the correct environment/backend, then review the import plan and any
proposed changes. Follow the pinned provider's import documentation for other
resource IDs. Do not assume import is read-only: the same apply can change fields.

Groups, users, GitLab projects, and Artifactory repositories use
`prevent_destroy`. Removing their JSON entries fails planning while their resource
blocks remain. Removing entire resource/module blocks also removes this guard.
Memberships, permissions, and branch protections can be removed normally; review
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

Nine mocked scenarios cover GitLab onboarding, default and enterprise protection,
duplicate group keys, Artifactory permissions, empty inputs, and all three JSON
environments. Tests make no live API calls. Live server compatibility, imports,
password-reset behavior, GDC state access, and locking need environment validation.

The requested Artifactory provider deprecates `artifactory_group` and
`artifactory_permission_target` in favor of the separate JFrog Platform provider.
This implementation keeps the two requested providers. Review these deprecations
and plan resource/state migration before upgrading or adopting that provider.

For future Vault integration, prefer having CI obtain short-lived credentials
from Vault and inject the same environment variables. Add the Vault provider only
when Terraform needs to manage Vault objects or consume its data directly; secrets
read through Terraform data sources may persist in state or plans. No Vault token
belongs in the environment JSON.