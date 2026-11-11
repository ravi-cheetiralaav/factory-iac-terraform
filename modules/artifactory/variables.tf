variable "configuration" {
  description = "JFrog projects with robot users, Artifactory identities, repositories and permissions"
  type = object({
    mail_server = optional(object({
      host            = string
      port            = number
      should_enable   = optional(bool, false)
      artifactory_url = optional(string)
      from            = optional(string)
      subject_prefix  = optional(string)
      username        = optional(string)
      should_use_ssl  = optional(bool, false)
      should_use_tls  = optional(bool, true)
    }))
    oauth_settings = optional(object({
      should_enable                       = optional(bool, false)
      should_persist_users                = optional(bool, false)
      should_allow_user_to_access_profile = optional(bool, false)
      providers = map(object({
        type          = string
        client_id     = string
        api_url       = string
        auth_url      = string
        token_url     = string
        should_enable = optional(bool, true)
      }))
    }))
    general_security = optional(object({
      should_enable_anonymous_access = optional(bool, false)
      encryption_policy              = optional(string, "SUPPORTED")
    }))
    backups = optional(map(object({
      cron_exp                        = string
      should_enable                   = optional(bool, false)
      retention_period_hours          = optional(number, 168)
      excluded_repositories           = optional(list(string), [])
      should_create_archive           = optional(bool, false)
      should_exclude_new_repositories = optional(bool, false)
      should_send_mail_on_error       = optional(bool, true)
      should_verify_disk_space        = optional(bool, true)
      should_export_mission_control   = optional(bool, false)
    })), {})
    archive_policies = optional(map(object({
      description          = optional(string)
      cron_expression      = optional(string)
      duration_in_minutes  = optional(number)
      project_key          = optional(string)
      should_enable        = optional(bool, false)
      should_skip_trashcan = optional(bool, false)
      search_criteria = object({
        package_types                    = set(string)
        repos                            = set(string)
        included_packages                = set(string)
        included_projects                = set(string)
        should_include_all_projects      = optional(bool, false)
        excluded_packages                = optional(set(string))
        excluded_repos                   = optional(set(string))
        created_before_in_days           = optional(number)
        last_downloaded_before_in_days   = optional(number)
        created_before_in_months         = optional(number)
        last_downloaded_before_in_months = optional(number)
        keep_last_n_versions             = optional(number)
        included_properties              = optional(map(list(string)))
        excluded_properties              = optional(map(list(string)))
      })
    })), {})
    package_cleanup_policies = optional(map(object({
      description          = optional(string)
      cron_expression      = optional(string)
      duration_in_minutes  = optional(number)
      project_key          = optional(string)
      should_enable        = optional(bool, false)
      should_skip_trashcan = optional(bool, false)
      search_criteria = object({
        package_types                    = set(string)
        repos                            = set(string)
        included_packages                = set(string)
        included_projects                = set(string)
        should_include_all_projects      = optional(bool, false)
        excluded_packages                = optional(set(string))
        excluded_repos                   = optional(set(string))
        created_before_in_days           = optional(number)
        last_downloaded_before_in_days   = optional(number)
        created_before_in_months         = optional(number)
        last_downloaded_before_in_months = optional(number)
        keep_last_n_versions             = optional(number)
        included_properties              = optional(map(list(string)))
        excluded_properties              = optional(map(list(string)))
      })
    })), {})
    password_expiration_policy = optional(object({
      name                   = string
      should_enable          = bool
      password_max_age       = number
      should_notify_by_email = bool
    }))
    projects = optional(map(object({
      key          = string
      display_name = string
      robot_email  = string
    })), {})
    groups = optional(map(object({
      description = optional(string)
    })), {})
    users = optional(map(object({
      email                            = string
      groups                           = optional(set(string), [])
      should_disable_internal_password = optional(bool, false)
      should_disable_ui_access         = optional(bool, false)
    })), {})
    local_generic_repositories = optional(map(object({
      description = optional(string)
    })), {})
    local_alpine_repositories = optional(map(object({
      description         = optional(string)
      primary_keypair_ref = optional(string)
    })), {})
    local_ansible_repositories = optional(map(object({
      description         = optional(string)
      primary_keypair_ref = optional(string)
    })), {})
    local_debian_repositories = optional(map(object({
      description               = optional(string)
      primary_keypair_ref       = optional(string)
      secondary_keypair_ref     = optional(string)
      index_compression_formats = optional(set(string), [])
      should_use_trivial_layout = optional(bool, false)
    })), {})
    local_helm_repositories = optional(map(object({
      description                        = optional(string)
      should_force_non_duplicate_chart   = optional(bool)
      should_force_metadata_name_version = optional(bool)
    })), {})
    local_helmoci_repositories = optional(map(object({
      description     = optional(string)
      tag_retention   = optional(number)
      max_unique_tags = optional(number, 0)
    })), {})
    local_oci_repositories = optional(map(object({
      description     = optional(string)
      tag_retention   = optional(number)
      max_unique_tags = optional(number, 0)
    })), {})
    local_maven_repositories = optional(map(object({
      description                            = optional(string)
      checksum_policy_type                   = optional(string, "client-checksums")
      snapshot_version_behavior              = optional(string, "unique")
      max_unique_snapshots                   = optional(number, 0)
      should_handle_releases                 = optional(bool, true)
      should_handle_snapshots                = optional(bool, true)
      should_suppress_pom_consistency_checks = optional(bool, false)
    })), {})
    local_npm_repositories = optional(map(object({
      description = optional(string)
    })), {})
    local_nuget_repositories = optional(map(object({
      description                       = optional(string)
      max_unique_snapshots              = optional(number, 0)
      should_force_nuget_authentication = optional(bool, false)
    })), {})
    local_pypi_repositories = optional(map(object({
      description = optional(string)
    })), {})
    local_rpm_repositories = optional(map(object({
      description                       = optional(string)
      yum_root_depth                    = optional(number, 0)
      should_calculate_yum_metadata     = optional(bool, false)
      should_enable_file_lists_indexing = optional(bool, false)
      yum_group_file_names              = optional(string)
      primary_keypair_ref               = optional(string)
      secondary_keypair_ref             = optional(string)
    })), {})
    local_terraform_module_repositories = optional(map(object({
      description = optional(string)
    })), {})
    local_terraform_provider_repositories = optional(map(object({
      description = optional(string)
    })), {})
    local_terraformbackend_repositories = optional(map(object({
      description = optional(string)
    })), {})
    local_docker_repositories = optional(map(object({
      description     = optional(string)
      max_unique_tags = optional(number, 0)
    })), {})
    virtual_generic_repositories = optional(map(object({
      description             = optional(string)
      repositories            = list(string)
      default_deployment_repo = optional(string)
    })), {})
    virtual_docker_repositories = optional(map(object({
      description             = optional(string)
      repositories            = list(string)
      default_deployment_repo = optional(string)
    })), {})
    permission_targets = optional(map(object({
      repositories      = set(string)
      includes_patterns = optional(set(string), ["**"])
      excludes_patterns = optional(set(string), [])
      group_permissions = optional(map(set(string)), {})
      user_permissions  = optional(map(set(string)), {})
    })), {})
  })
  default = {}
}

variable "secrets" {
  description = "SMTP password and OAuth client secrets keyed by configured OAuth provider name"
  type = object({
    mail_password        = optional(string)
    oauth_client_secrets = optional(map(string), {})
  })
  default   = {}
  sensitive = true
  nullable  = false
}