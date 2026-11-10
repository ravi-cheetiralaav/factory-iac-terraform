locals {
  configuration   = jsondecode(file("${path.module}/environments/${var.environment}/config.json"))
  gitlab_base_url = local.configuration.gitlab_base_url
  artifactory_url = local.configuration.artifactory_url
  gitlab          = local.configuration.gitlab
  artifactory     = local.configuration.artifactory
  jfrog_projects = {
    for key, project in try(local.gitlab.projects, {}) : key => {
      key          = try(project.jfrog_project_key, key)
      display_name = project.name
      robot_email  = "robot-${try(project.jfrog_project_key, key)}@${local.configuration.jfrog_robot_email_domain}"
    }
  }
}