# Artifactory Terraform sample

This is a sample of how to keep a self-hosted JFrog platform in Terraform. It is a pattern, not a full copy of every repository.

You describe what you want in YAML. Terraform creates it. You do not add a new Terraform file for each project or repository.

## How it works

There are three folders.

| Folder | What you do with it |
| --- | --- |
| `catalog/` | Edit this. Plain YAML lists of repositories, people, groups, permissions, and Xray. |
| `modules/` | Leave this alone unless the platform needs a new kind of resource. It turns one YAML file into Artifactory objects. |
| `stacks/platform/` | Run Terraform here. This is the only state file. |

`stacks/platform` reads `catalog/global.yaml` once, then reads every file in `catalog/projects/`. Each of those files becomes one JFrog project.

```text
catalog/global.yaml          ->  quarantine and trusted repositories, platform groups, Xray
catalog/projects/lending.yaml ->  the Lending project
catalog/projects/payments.yaml -> the Payments project
```

A project file is the whole customisation for that project. Payments and Lending already differ: storage quota, repositories, shared trusted repositories, users, and groups. Change the YAML for the project you care about. The module code stays the same.

A global repository key is the name in the YAML, such as `maven-trusted-local`. A project repository key is the project key plus the short name. In `lending.yaml`, `key: lend` and a local named `maven` become `lend-maven`. The virtual repository uses a different short name, `maven-local`, so its key is `lend-maven-local`.

## What a project file contains

`catalog/projects/lending.yaml` is the example to copy.

- Project name, storage quota, and admin privileges.
- Four access levels: `reader`, `annotator`, `engineer`, `admin`. They apply to every repository in that project.
- Groups, people, and one CI robot. `robot-lend-ci` is in `lend-engineers`, and that group has write access, so the robot is how CI uploads to the project locals (`lend-maven`, `lend-generic`).
- `shared_repositories` lists trusted global repositories. The project module creates a `project_share_repository` for each one, with `read_only: true`. Lending shares `maven-trusted-local` and `generic-trusted-local`. The project can read them. It cannot upload to them.
- The project's own local repositories, and virtual repositories that combine those locals with the trusted share. The virtual `lend-maven-local` includes `maven` and `maven-trusted-local`. Its default deployment repository is the project local, so a write through the virtual still lands in `lend-maven`.
- `xray.enabled` is one switch for the whole project. `false` means no Xray watch on that project. It does not pick individual repositories. Indexing is separate: each local repository has its own `xray_index`. Both sample projects leave the project watch off, because a copy into a project comes from trusted, which has already passed quarantine.

Promotion from quarantine to trusted stays in the global file. It is a platform action, not a fifth project role.

## What the global file contains

`catalog/global.yaml` is the intake path. Each package type has a quarantine local and a trusted local. There are no remote repositories.

| Group | Access |
| --- | --- |
| `jfrog-intake-publishers` | read, write, annotate on quarantine repositories |
| `jfrog-artifact-readers` | read on trusted repositories |
| `jfrog-platform-admins` | read, write, annotate, delete, manage on both |

People (`users`) and CI accounts (`service_accounts`) are both Artifactory users. The sample creates `gdc.admin`, `gdc.reader`, `jfrog-intake-sa`, `jfrog-promote-sa`, and `jfrog-ci-reader`.

Terraform does not keep a password. For a person it creates the user and leaves password login available, but the generated password is not saved in state or shown in an output. Set or reset that password in the UI after apply. For a CI account, UI login and password login are both disabled. After apply, an admin creates an access token for that user in the UI or with the Access API. Terraform does not create the token.

Which group an account belongs to is the `groups` list on that account. The module turns those lists into group membership. `jfrog-intake-sa` can upload to quarantine. `jfrog-promote-sa` is a platform admin, so it can copy a package from quarantine to trusted. `jfrog-ci-reader` can read trusted.

Xray has two policies. `gdc-security-critical` blocks download of Critical findings. `gdc-malicious-packages` blocks known malicious packages. Watches are per repository. The sample attaches them to the quarantine repositories for nuget, maven, terraform, ansible, generic, docker, and helm. npm and pypi repositories are created and indexed, and they have no watch yet. Add or remove a repository from a watch in `catalog/global.yaml` under `xray.watches`.

Anonymous read is on for trusted repositories only. Two settings do that. `anonymous_read: true` on each `*-trusted-local` creates one permission, `global-anonymous-read`, that gives the built-in `anonymous` user read on those repositories. `manage_general_security` and `enable_anonymous_access` in `terraform.tfvars` turn anonymous access on for the platform. Quarantine repositories do not set `anonymous_read`. Project repositories cannot use it. Anyone who can reach the trusted repository URL can download. Upload still needs a user.

## One state

`stacks/platform` is one Terraform state for the sample. One plan sees the global repositories and every project, so a trusted repository and a project that shares it stay in step.

Terraform loads every catalog file before it plans. A mistake in one project file stops the whole plan, and nothing is changed. A normal plan also refreshes every resource already in that state.

That is fine while one team applies the platform. If a team later needs to apply only its own project, give that project its own stack and state. The module does not change. Only the entry point changes, and the global stack has to be applied first so the trusted repositories exist.

## Providers

| Provider | Version | Creates |
| --- | --- | --- |
| `jfrog/artifactory` | 12.11.14 | local and virtual repositories, users, CI accounts |
| `jfrog/platform` | 2.2.11 | groups, group membership, permission targets |
| `jfrog/project` | 1.9.9 | projects, the four roles, read-only shares of trusted repositories |
| `jfrog/xray` | 3.1.13 | the two security policies and the quarantine watches |

DEV and PROD are two Artifactory servers that already exist. This repo does not create them. You apply this same stack twice: once with the DEV nginx URL and DEV token, once with the PROD URL and PROD token. Use a separate state file for each server. The `environment: DEV` line inside a project file is a label JFrog stores on that repository. It is not the server you are applying to.

## Apply

```bash
export JFROG_ACCESS_TOKEN="<token>"
cd stacks/platform
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply
```

Set `jfrog_url` in `terraform.tfvars` to the nginx address of the server you are applying to. The example turns anonymous access on. Keep `manage_general_security` and `enable_anonymous_access` true for that.

## Changing the sample

- New project: add `catalog/projects/<name>.yaml`. The next apply picks it up.
- New repository: add an item under `local_repositories` or `virtual_repositories` in the YAML file that owns it.
- New person or CI account: add them under `users` or `service_accounts` and list their groups.
