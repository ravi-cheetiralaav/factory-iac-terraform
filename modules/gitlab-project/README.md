---
title: GitLab Project Module
description: Inputs and outputs for the reusable GitLab project Terraform module
---

## GitLab project module

Creates one GitLab project in a catalog-managed group, including configured
memberships, branch protections, CI/CD variables, and project-scoped runner
registrations.

### Inputs

| Name | Description |
| --- | --- |
| `spec` | Decoded configuration from one file under `catalog/gitlab/projects/` |
| `namespace_id` | Numeric ID of the owning GitLab group |
| `variable_values` | Sensitive map of values referenced by project CI/CD variables |

### Outputs

| Name | Description |
| --- | --- |
| `project_id` | GitLab project ID |
| `full_path` | Full GitLab project path |
| `runner_tokens` | Sensitive runner authentication tokens; state contains them |

Branch protection mode is selected in each project YAML file. `legacy` uses
access-level settings for GitLab CE; `enterprise` uses the more granular
Premium/Ultimate attributes.
