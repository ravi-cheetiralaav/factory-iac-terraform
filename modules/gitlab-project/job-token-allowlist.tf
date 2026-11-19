locals {
  job_token_allowlist = merge({}, try(var.spec.job_token_allowlist, null))
}

resource "gitlab_project_job_token_scope" "project" {
  for_each = toset([
    for id in try(local.job_token_allowlist.project_ids, []) : tostring(tonumber(id))
  ])

  project           = gitlab_project.main.id
  target_project_id = tonumber(each.key)
}

resource "gitlab_project_job_token_scope" "group" {
  for_each = toset([
    for id in try(local.job_token_allowlist.group_ids, []) : tostring(tonumber(id))
  ])

  project         = gitlab_project.main.id
  target_group_id = tonumber(each.key)
}
