locals {
  configuration = merge(
    jsondecode(file("${path.module}/environments/${var.environment}/gitlab.json")),
    jsondecode(file("${path.module}/environments/${var.environment}/jfrog.json"))
  )
  gitlab_base_url = local.configuration.gitlab_base_url
  artifactory_url = local.configuration.artifactory_url

  subgroup_entries = flatten([
    for group_key, group in try(local.configuration.gitlab.groups, {}) : [
      for subgroup_key, subgroup in try(group.subgroups, {}) : {
        key   = subgroup_key
        value = merge(subgroup, { parent_group_key = group_key })
      }
    ]
  ])

  project_entries = concat(
    flatten([
      for group_key, group in try(local.configuration.gitlab.groups, {}) : [
        for project_key, project in try(group.projects, {}) : {
          key   = project_key
          value = merge(project, { group_key = group_key })
        }
      ]
    ]),
    flatten([
      for subgroup in local.subgroup_entries : [
        for project_key, project in try(subgroup.value.projects, {}) : {
          key   = project_key
          value = merge(project, { group_key = subgroup.key })
        }
      ]
    ])
  )

  gitlab = merge(local.configuration.gitlab, {
    groups    = try(local.configuration.gitlab.groups, {})
    subgroups = { for subgroup in local.subgroup_entries : subgroup.key => subgroup.value }
    projects  = { for project in local.project_entries : project.key => project.value }
  })

  artifactory = {
    mail_server                           = try(local.configuration.artifactory.mail_server, null)
    oauth_settings                        = try(local.configuration.artifactory.security.oauth, null)
    general_security                      = try(local.configuration.artifactory.security.general, null)
    backups                               = try(local.configuration.artifactory.maintenance.backups, {})
    archive_policies                      = try(local.configuration.artifactory.maintenance.archive_policies, {})
    package_cleanup_policies              = try(local.configuration.artifactory.maintenance.package_cleanup_policies, {})
    password_expiration_policy            = try(local.configuration.artifactory.security.password_expiration_policy, null)
    groups                                = try(local.configuration.artifactory.access.groups, {})
    users                                 = try(local.configuration.artifactory.access.users, {})
    permission_targets                    = try(local.configuration.artifactory.access.permission_targets, {})
    local_generic_repositories            = try(local.configuration.artifactory.repositories.local.generic, {})
    local_alpine_repositories             = try(local.configuration.artifactory.repositories.local.alpine, {})
    local_ansible_repositories            = try(local.configuration.artifactory.repositories.local.ansible, {})
    local_debian_repositories             = try(local.configuration.artifactory.repositories.local.debian, {})
    local_helm_repositories               = try(local.configuration.artifactory.repositories.local.helm, {})
    local_helmoci_repositories            = try(local.configuration.artifactory.repositories.local.helmoci, {})
    local_oci_repositories                = try(local.configuration.artifactory.repositories.local.oci, {})
    local_maven_repositories              = try(local.configuration.artifactory.repositories.local.maven, {})
    local_npm_repositories                = try(local.configuration.artifactory.repositories.local.npm, {})
    local_nuget_repositories              = try(local.configuration.artifactory.repositories.local.nuget, {})
    local_pypi_repositories               = try(local.configuration.artifactory.repositories.local.pypi, {})
    local_rpm_repositories                = try(local.configuration.artifactory.repositories.local.rpm, {})
    local_terraform_module_repositories   = try(local.configuration.artifactory.repositories.local.terraform_module, {})
    local_terraform_provider_repositories = try(local.configuration.artifactory.repositories.local.terraform_provider, {})
    local_terraformbackend_repositories   = try(local.configuration.artifactory.repositories.local.terraformbackend, {})
    local_docker_repositories             = try(local.configuration.artifactory.repositories.local.docker, {})
    virtual_generic_repositories          = try(local.configuration.artifactory.repositories.virtual.generic, {})
    virtual_docker_repositories           = try(local.configuration.artifactory.repositories.virtual.docker, {})
  }

  jfrog_projects = {
    for key, project in local.gitlab.projects : key => {
      key          = try(project.jfrog.key, key)
      display_name = project.name
      robot_email = try(
        project.jfrog.robot.email,
        "robot-${try(project.jfrog.key, key)}@${local.configuration.artifactory.defaults.robot_email_domain}"
      )
    }
  }
}