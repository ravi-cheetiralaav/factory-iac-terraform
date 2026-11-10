locals {
  configuration   = jsondecode(file("${path.module}/environments/${var.environment}/config.json"))
  gitlab_base_url = local.configuration.gitlab_base_url
  artifactory_url = local.configuration.artifactory_url
  gitlab          = local.configuration.gitlab
  artifactory     = local.configuration.artifactory
}