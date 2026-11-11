resource "artifactory_backup" "backups" {
  for_each = var.configuration.backups

  key                      = each.key
  cron_exp                 = each.value.cron_exp
  enabled                  = each.value.should_enable
  retention_period_hours   = each.value.retention_period_hours
  excluded_repositories    = each.value.excluded_repositories
  create_archive           = each.value.should_create_archive
  exclude_new_repositories = each.value.should_exclude_new_repositories
  send_mail_on_error       = each.value.should_send_mail_on_error
  verify_disk_space        = each.value.should_verify_disk_space
  export_mission_control   = each.value.should_export_mission_control

  depends_on = [
    artifactory_mail_server.main,
    artifactory_local_generic_repository.repositories,
    artifactory_local_docker_v2_repository.repositories,
    artifactory_local_alpine_repository.repositories,
    artifactory_local_ansible_repository.repositories,
    artifactory_local_debian_repository.repositories,
    artifactory_local_helm_repository.repositories,
    artifactory_local_helmoci_repository.repositories,
    artifactory_local_oci_repository.repositories,
    artifactory_local_maven_repository.repositories,
    artifactory_local_npm_repository.repositories,
    artifactory_local_nuget_repository.repositories,
    artifactory_local_pypi_repository.repositories,
    artifactory_local_rpm_repository.repositories,
    artifactory_local_terraform_module_repository.repositories,
    artifactory_local_terraform_provider_repository.repositories,
    artifactory_local_terraformbackend_repository.repositories,
    artifactory_virtual_generic_repository.repositories,
    artifactory_virtual_docker_repository.repositories
  ]
}