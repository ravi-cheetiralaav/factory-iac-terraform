mock_provider "gitlab" {
  mock_resource "gitlab_group" {
    defaults = { id = "101" }
  }
  mock_resource "gitlab_user" {
    defaults = { id = "201" }
  }
  mock_data "gitlab_user" {
    defaults = { id = "202" }
  }
  mock_resource "gitlab_project" {
    defaults = { id = "301" }
  }
}

mock_provider "artifactory" {}
mock_provider "project" {}

variables {
  environment = "lab01"
}

run "gitlab_onboarding_and_protection" {
  command   = apply
  state_key = "gitlab-onboarding"

  module {
    source = "./modules/gitlab"
  }

  variables {
    configuration = {
      groups = {
        engineering = { name = "Engineering", path = "engineering" }
      }
      subgroups = {
        platform = { name = "Platform", path = "platform", parent_group_key = "engineering" }
      }
      users = {
        developer = { name = "Developer", email = "developer@example.invalid" }
      }
      existing_users = ["owner"]
      group_memberships = {
        developer = { group_key = "platform", username = "developer" }
        owner     = { group_key = "engineering", username = "owner", access_level = "owner" }
      }
      project_memberships = {
        owner = { project_key = "application", username = "owner", access_level = "maintainer" }
      }
      projects = {
        application = {
          name           = "Application"
          path           = "application"
          group_key      = "platform"
          default_branch = "trunk"
          labels = {
            bug = { color = "#FF0000" }
          }
          branch_protections = {
            "release/*" = {}
          }
        }
      }
    }
  }

  assert {
    condition = (
      gitlab_group.subgroups["platform"].parent_id == tonumber(gitlab_group.groups["engineering"].id) &&
      gitlab_project.projects["application"].namespace_id == tonumber(output.group_ids["platform"]) &&
      gitlab_group_membership.memberships["owner"].user_id == tonumber(output.user_ids["owner"]) &&
      gitlab_project_membership.memberships["owner"].project == gitlab_project.projects["application"].id
    )
    error_message = "Groups, projects and memberships must resolve managed and existing IDs."
  }

  assert {
    condition = (
      length(gitlab_branch_protection.branches) == 2 &&
      gitlab_branch_protection.branches[jsonencode(["application", "trunk"])].push_access_level == "no one" &&
      gitlab_branch_protection.branches[jsonencode(["application", "trunk"])].merge_access_level == "maintainer" &&
      !gitlab_branch_protection.branches[jsonencode(["application", "trunk"])].allow_force_push
    )
    error_message = "Protect the actual default branch and additional patterns with restrictive defaults."
  }

  assert {
    condition = (
      gitlab_project.projects["application"].visibility_level == "private" &&
      gitlab_project.projects["application"].only_allow_merge_if_pipeline_succeeds &&
      gitlab_user.users["developer"].force_random_password &&
      gitlab_user.users["developer"].reset_password &&
      !gitlab_user.users["developer"].is_admin
    )
    error_message = "Projects must default to private and users must onboard without administrator rights or supplied passwords."
  }
}

run "gitlab_project_policies" {
  command   = apply
  state_key = "gitlab-project-policies"

  module {
    source = "./modules/gitlab"
  }

  override_resource {
    target = gitlab_project.projects["custom"]
    values = { id = "302" }
  }

  variables {
    configuration = {
      is_enterprise = true
      groups = {
        team = { name = "Team", path = "team" }
      }
      projects = {
        defaults = {
          name         = "Defaults", path = "defaults", group_key = "team"
          mr_approvals = {}
          labels       = { bug = { color = "#FF0000" } }
        }
        custom = {
          name = "Custom", path = "custom", group_key = "team"
          push_rules = {
            author_email_regex             = "@example[.]internal$"
            branch_name_regex              = "^(main|feature/.+)$"
            commit_message_regex           = "^(feat|fix):"
            commit_message_negative_regex  = "WIP"
            file_name_regex                = "[.]pem$"
            max_file_size                  = 10
            should_check_committer_email   = true
            should_check_committer_name    = true
            should_deny_tag_deletion       = true
            should_check_member            = true
            should_prevent_secrets         = true
            should_reject_non_dco_commits  = true
            should_reject_unsigned_commits = false
          }
          mr_approvals = {
            should_allow_author_approval               = true
            should_allow_committer_approval            = true
            should_allow_approver_overrides            = true
            should_reset_approvals_on_push             = false
            should_remove_changed_code_owner_approvals = true
            should_require_reauthentication_to_approve = true
          }
          labels = {
            bug            = { color = "#CC0000", description = "Defect", priority = 0 }
            "needs review" = { color = "blue", priority = 2 }
          }
        }
        omitted = { name = "Omitted", path = "omitted", group_key = "team" }
      }
    }
  }

  assert {
    condition = (
      length(gitlab_project_push_rules.projects) == 1 &&
      length(gitlab_project_level_mr_approvals.projects) == 2 &&
      length(gitlab_project_label.labels) == 3 &&
      gitlab_project_push_rules.projects["custom"].project == "302" &&
      gitlab_project_level_mr_approvals.projects["custom"].project == "302" &&
      gitlab_project_level_mr_approvals.projects["defaults"].project == "301"
    )
    error_message = "Optional project policies must target their own project and remain absent when omitted."
  }

  assert {
    condition = (
      !gitlab_project_level_mr_approvals.projects["defaults"].merge_requests_author_approval &&
      gitlab_project_level_mr_approvals.projects["defaults"].merge_requests_disable_committers_approval &&
      gitlab_project_level_mr_approvals.projects["defaults"].disable_overriding_approvers_per_merge_request &&
      gitlab_project_level_mr_approvals.projects["defaults"].reset_approvals_on_push &&
      !gitlab_project_level_mr_approvals.projects["defaults"].selective_code_owner_removals &&
      gitlab_project_level_mr_approvals.projects["custom"].merge_requests_author_approval &&
      !gitlab_project_level_mr_approvals.projects["custom"].merge_requests_disable_committers_approval &&
      !gitlab_project_level_mr_approvals.projects["custom"].disable_overriding_approvers_per_merge_request &&
      !gitlab_project_level_mr_approvals.projects["custom"].reset_approvals_on_push &&
      gitlab_project_level_mr_approvals.projects["custom"].selective_code_owner_removals &&
      gitlab_project_level_mr_approvals.projects["custom"].require_reauthentication_to_approve
    )
    error_message = "Project MR settings must preserve restrictive defaults and correctly invert the allow flags."
  }

  assert {
    condition = (
      gitlab_project_push_rules.projects["custom"].author_email_regex == "@example[.]internal$" &&
      gitlab_project_push_rules.projects["custom"].branch_name_regex == "^(main|feature/.+)$" &&
      gitlab_project_push_rules.projects["custom"].commit_message_regex == "^(feat|fix):" &&
      gitlab_project_push_rules.projects["custom"].commit_message_negative_regex == "WIP" &&
      gitlab_project_push_rules.projects["custom"].file_name_regex == "[.]pem$" &&
      gitlab_project_push_rules.projects["custom"].max_file_size == 10 &&
      gitlab_project_push_rules.projects["custom"].commit_committer_check &&
      gitlab_project_push_rules.projects["custom"].commit_committer_name_check &&
      gitlab_project_push_rules.projects["custom"].deny_delete_tag &&
      gitlab_project_push_rules.projects["custom"].member_check &&
      gitlab_project_push_rules.projects["custom"].prevent_secrets &&
      gitlab_project_push_rules.projects["custom"].reject_non_dco_commits &&
      !gitlab_project_push_rules.projects["custom"].reject_unsigned_commits
    )
    error_message = "Every configured push-rule field must reach the provider without changing its value."
  }

  assert {
    condition = (
      gitlab_project_label.labels[jsonencode(["defaults", "bug"])].project == "301" &&
      gitlab_project_label.labels[jsonencode(["custom", "bug"])].project == "302" &&
      gitlab_project_label.labels[jsonencode(["custom", "bug"])].name == "bug" &&
      gitlab_project_label.labels[jsonencode(["custom", "bug"])].color == "#CC0000" &&
      gitlab_project_label.labels[jsonencode(["custom", "bug"])].description == "Defect" &&
      gitlab_project_label.labels[jsonencode(["custom", "bug"])].priority == 0 &&
      gitlab_project_label.labels[jsonencode(["custom", "needs review"])].name == "needs review" &&
      gitlab_project_label.labels[jsonencode(["custom", "needs review"])].color == "blue" &&
      gitlab_project_label.labels[jsonencode(["custom", "needs review"])].priority == 2 &&
      var.configuration.projects["defaults"].labels["bug"].priority == null
    )
    error_message = "Labels must retain names, colors, descriptions and priorities without colliding across projects."
  }
}

run "gitlab_project_policies_require_enterprise" {
  command = plan

  module {
    source = "./modules/gitlab"
  }

  variables {
    configuration = {
      groups = { team = { name = "Team", path = "team" } }
      projects = {
        application = {
          name         = "Application", path = "application", group_key = "team"
          push_rules   = {}
          mr_approvals = {}
        }
      }
    }
  }

  expect_failures = [
    gitlab_project_push_rules.projects["application"],
    gitlab_project_level_mr_approvals.projects["application"]
  ]
}

run "gitlab_enterprise_protection" {
  command = plan

  module {
    source = "./modules/gitlab"
  }

  variables {
    configuration = {
      is_enterprise = true
      groups = {
        team = { name = "Team", path = "team" }
      }
      projects = {
        application = {
          name      = "Application"
          path      = "application"
          group_key = "team"
          branch_protections = {
            main = { should_require_code_owner_approval = true }
          }
        }
      }
    }
  }

  assert {
    condition = (
      length(gitlab_branch_protection.branches) == 1 &&
      one(gitlab_branch_protection.branches[jsonencode(["application", "main"])].allowed_to_push).access_level == "no one" &&
      one(gitlab_branch_protection.branches[jsonencode(["application", "main"])].allowed_to_merge).access_level == "maintainer" &&
      gitlab_branch_protection.branches[jsonencode(["application", "main"])].code_owner_approval_required
    )
    error_message = "Enterprise protection must use access-level sets and override, not duplicate, the default rule."
  }
}

run "gitlab_group_policies" {
  command   = apply
  state_key = "gitlab-group-policies"

  module {
    source = "./modules/gitlab"
  }

  variables {
    configuration = {
      is_enterprise = true
      groups = {
        engineering = {
          name         = "Engineering"
          path         = "engineering"
          mr_approvals = {}
          protected_environments = {
            production = {
              deploy_access_levels = [{ access_level = "maintainer" }]
              approval_rules       = [{ access_level = "maintainer", required_approvals = 2 }]
            }
          }
        }
        unmanaged = { name = "Unmanaged policies", path = "unmanaged" }
      }
      subgroups = {
        platform = {
          name             = "Platform"
          path             = "platform"
          parent_group_key = "engineering"
          mr_approvals = {
            should_allow_author_approval                              = true
            should_allow_committer_approval                           = true
            should_allow_overrides_to_approver_list_per_merge_request = true
            should_retain_approvals_on_push                           = true
            should_require_reauthentication_to_approve                = true
            should_keep_settings_on_destroy                           = false
          }
          protected_environments = {
            production = {
              deploy_access_levels = [{ user_id = 201 }, { group_id = 501, group_inheritance_type = 1 }]
              approval_rules       = [{ user_id = 201 }, { group_id = 501, group_inheritance_type = 1, required_approvals = 1 }]
            }
            staging = {
              deploy_access_levels = [{ access_level = "developer" }]
            }
          }
        }
      }
    }
  }

  override_resource {
    target = gitlab_group.subgroups["platform"]
    values = { id = "102" }
  }

  assert {
    condition = (
      length(gitlab_group_level_mr_approvals.groups) == 2 &&
      gitlab_group_level_mr_approvals.groups["engineering"].group == "101" &&
      !gitlab_group_level_mr_approvals.groups["engineering"].allow_author_approval &&
      !gitlab_group_level_mr_approvals.groups["engineering"].allow_committer_approval &&
      !gitlab_group_level_mr_approvals.groups["engineering"].allow_overrides_to_approver_list_per_merge_request &&
      !gitlab_group_level_mr_approvals.groups["engineering"].retain_approvals_on_push &&
      gitlab_group_level_mr_approvals.groups["engineering"].keep_settings_on_destroy &&
      gitlab_group_level_mr_approvals.groups["platform"].group == "102" &&
      gitlab_group_level_mr_approvals.groups["platform"].allow_author_approval &&
      gitlab_group_level_mr_approvals.groups["platform"].allow_committer_approval &&
      gitlab_group_level_mr_approvals.groups["platform"].allow_overrides_to_approver_list_per_merge_request &&
      gitlab_group_level_mr_approvals.groups["platform"].retain_approvals_on_push &&
      gitlab_group_level_mr_approvals.groups["platform"].require_reauthentication_to_approve &&
      !gitlab_group_level_mr_approvals.groups["platform"].keep_settings_on_destroy
    )
    error_message = "MR approval policies must be opt-in, resolve root and subgroup IDs and preserve defaults and overrides."
  }

  assert {
    condition = (
      length(gitlab_group_protected_environment.environments) == 3 &&
      gitlab_group_protected_environment.environments[jsonencode(["engineering", "production"])].group == "101" &&
      gitlab_group_protected_environment.environments[jsonencode(["platform", "production"])].group == "102" &&
      gitlab_group_protected_environment.environments[jsonencode(["platform", "staging"])].environment == "staging" &&
      one(gitlab_group_protected_environment.environments[jsonencode(["engineering", "production"])].deploy_access_levels).access_level == "maintainer" &&
      one(gitlab_group_protected_environment.environments[jsonencode(["engineering", "production"])].approval_rules).required_approvals == 2 &&
      length(gitlab_group_protected_environment.environments[jsonencode(["platform", "staging"])].approval_rules) == 0 &&
      anytrue([for rule in gitlab_group_protected_environment.environments[jsonencode(["platform", "production"])].deploy_access_levels : rule.user_id == 201]) &&
      anytrue([for rule in gitlab_group_protected_environment.environments[jsonencode(["platform", "production"])].approval_rules : rule.group_id == 501 && rule.group_inheritance_type == 1 && rule.required_approvals == 1])
    )
    error_message = "Protected deployment tiers must retain distinct group addresses and role, user and group rules."
  }
}

run "gitlab_group_policies_require_enterprise" {
  command = plan

  module {
    source = "./modules/gitlab"
  }

  variables {
    configuration = {
      groups = {
        team = {
          name         = "Team"
          path         = "team"
          mr_approvals = {}
          protected_environments = {
            production = { deploy_access_levels = [{ access_level = "maintainer" }] }
          }
        }
      }
    }
  }

  expect_failures = [
    gitlab_group_level_mr_approvals.groups["team"],
    gitlab_group_protected_environment.environments["[\"team\",\"production\"]"]
  ]
}

run "gitlab_reject_duplicate_group_keys" {
  command = plan

  module {
    source = "./modules/gitlab"
  }

  variables {
    configuration = {
      groups = {
        team = { name = "Team", path = "team" }
      }
      subgroups = {
        team = { name = "Child", path = "child", parent_group_key = "team" }
      }
    }
  }

  expect_failures = [gitlab_group.subgroups["team"]]
}

run "artifactory_onboarding_and_permissions" {
  command   = apply
  state_key = "artifactory-onboarding"

  module {
    source = "./modules/artifactory"
  }

  variables {
    secrets = {
      mail_password        = "mock-smtp-password"
      oauth_client_secrets = { internal = "mock-client-secret" }
    }
    configuration = {
      mail_server = { host = "smtp.example.invalid", port = 587, username = "artifactory" }
      oauth_settings = {
        should_enable = true
        providers = {
          internal = {
            type    = "openId", client_id = "artifactory"
            api_url = "https://idp.example.invalid/userinfo", auth_url = "https://idp.example.invalid/authorize", token_url = "https://idp.example.invalid/token"
          }
        }
      }
      password_expiration_policy = {
        name = "internal-passwords", should_enable = true, password_max_age = 120, should_notify_by_email = true
      }
      general_security = { encryption_policy = "REQUIRED" }
      backups = {
        nightly = { cron_exp = "0 0 2 * * ? *", excluded_repositories = ["docker-local"] }
      }
      archive_policies = {
        archive-old = {
          search_criteria = {
            package_types          = ["docker"], repos = ["docker-local"], included_packages = ["**"], included_projects = ["default"]
            created_before_in_days = 180, last_downloaded_before_in_days = 90
          }
        }
      }
      package_cleanup_policies = {
        cleanup-old = {
          search_criteria = {
            package_types          = ["generic"], repos = ["generic-local"], included_packages = ["**"], included_projects = ["default"]
            created_before_in_days = 90, last_downloaded_before_in_days = 30
          }
        }
      }
      groups = { developers = {} }
      projects = {
        application = { key = "test-app", display_name = "Application", robot_email = "robot-test-app@example.invalid" }
      }
      users = {
        developer = { email = "developer@example.invalid", groups = ["developers"] }
      }
      local_generic_repositories = { "generic-local" = {} }
      local_docker_repositories  = { "docker-local" = {} }
      local_alpine_repositories  = { "alpine-local" = { primary_keypair_ref = "rsa-signing" } }
      local_ansible_repositories = { "ansible-local" = { primary_keypair_ref = "rsa-signing" } }
      local_debian_repositories = {
        "debian-local" = { primary_keypair_ref = "gpg-primary", secondary_keypair_ref = "gpg-secondary", index_compression_formats = ["xz"] }
      }
      local_helm_repositories               = { "helm-local" = { should_force_non_duplicate_chart = true, should_force_metadata_name_version = true } }
      local_helmoci_repositories            = { "helmoci-local" = { tag_retention = 3 } }
      local_oci_repositories                = { "oci-local" = { tag_retention = 2 } }
      local_maven_repositories              = { "maven-local" = { should_handle_snapshots = false } }
      local_npm_repositories                = { "npm-local" = {} }
      local_nuget_repositories              = { "nuget-local" = { should_force_nuget_authentication = true } }
      local_pypi_repositories               = { "pypi-local" = {} }
      local_rpm_repositories                = { "rpm-local" = { yum_root_depth = 2, should_calculate_yum_metadata = true, primary_keypair_ref = "gpg-primary" } }
      local_terraform_module_repositories   = { "terraform-module-local" = {} }
      local_terraform_provider_repositories = { "terraform-provider-local" = {} }
      local_terraformbackend_repositories   = { "terraformbackend-local" = {} }
      virtual_generic_repositories = {
        generic = { repositories = ["generic-local"], default_deployment_repo = "generic-local" }
      }
      virtual_docker_repositories = {
        docker = { repositories = ["docker-local"], default_deployment_repo = "docker-local" }
      }
      permission_targets = {
        publish = {
          repositories      = ["generic-local", "docker-local"]
          group_permissions = { developers = ["read", "write"] }
          user_permissions  = { developer = ["read"] }
        }
      }
    }
  }

  assert {
    condition = (
      length(output.repository_keys) == 18 &&
      alltrue([for repositories in values(output.repository_keys) : length(repositories) == 1]) &&
      artifactory_local_alpine_repository.repositories["alpine-local"].primary_keypair_ref == "rsa-signing" &&
      artifactory_local_ansible_repository.repositories["ansible-local"].primary_keypair_ref == "rsa-signing" &&
      artifactory_local_debian_repository.repositories["debian-local"].index_compression_formats == toset(["xz"]) &&
      artifactory_local_debian_repository.repositories["debian-local"].secondary_keypair_ref == "gpg-secondary" &&
      !artifactory_local_debian_repository.repositories["debian-local"].trivial_layout &&
      artifactory_local_helm_repository.repositories["helm-local"].force_non_duplicate_chart &&
      artifactory_local_helm_repository.repositories["helm-local"].force_metadata_name_version &&
      artifactory_local_helmoci_repository.repositories["helmoci-local"].tag_retention == 3 &&
      artifactory_local_helmoci_repository.repositories["helmoci-local"].max_unique_tags == 0 &&
      artifactory_local_oci_repository.repositories["oci-local"].tag_retention == 2 &&
      artifactory_local_oci_repository.repositories["oci-local"].max_unique_tags == 0 &&
      !artifactory_local_maven_repository.repositories["maven-local"].handle_snapshots &&
      artifactory_local_maven_repository.repositories["maven-local"].handle_releases &&
      artifactory_local_maven_repository.repositories["maven-local"].max_unique_snapshots == 0 &&
      artifactory_local_nuget_repository.repositories["nuget-local"].force_nuget_authentication &&
      artifactory_local_nuget_repository.repositories["nuget-local"].max_unique_snapshots == 0 &&
      artifactory_local_rpm_repository.repositories["rpm-local"].calculate_yum_metadata &&
      artifactory_local_rpm_repository.repositories["rpm-local"].yum_root_depth == 2 &&
      artifactory_local_rpm_repository.repositories["rpm-local"].primary_keypair_ref == "gpg-primary"
    )
    error_message = "All sixteen local formats and both virtual formats must preserve their package settings."
  }

  assert {
    condition = (
      !artifactory_mail_server.main["main"].enabled &&
      artifactory_mail_server.main["main"].use_tls &&
      !artifactory_mail_server.main["main"].use_ssl &&
      artifactory_mail_server.main["main"].host == "smtp.example.invalid" &&
      artifactory_mail_server.main["main"].password == var.secrets.mail_password &&
      artifactory_oauth_settings.main["main"].enable &&
      !artifactory_oauth_settings.main["main"].persist_users &&
      !artifactory_oauth_settings.main["main"].allow_user_to_access_profile &&
      one(artifactory_oauth_settings.main["main"].oauth_provider).client_secret == var.secrets.oauth_client_secrets["internal"] &&
      one(artifactory_oauth_settings.main["main"].oauth_provider).name == "internal"
    )
    error_message = "SMTP and OAuth must use external secrets and preserve the configured settings."
  }

  assert {
    condition = (
      artifactory_password_expiration_policy.main["main"].name == "internal-passwords" &&
      artifactory_password_expiration_policy.main["main"].enabled &&
      artifactory_password_expiration_policy.main["main"].password_max_age == 120 &&
      artifactory_password_expiration_policy.main["main"].notify_by_email &&
      !artifactory_general_security.main["main"].enable_anonymous_access &&
      artifactory_general_security.main["main"].encryption_policy == "REQUIRED"
    )
    error_message = "Opt-in password and general security settings must map to the provider fields."
  }

  assert {
    condition = (
      !artifactory_backup.backups["nightly"].enabled &&
      artifactory_backup.backups["nightly"].verify_disk_space &&
      artifactory_backup.backups["nightly"].retention_period_hours == 168 &&
      artifactory_backup.backups["nightly"].excluded_repositories == tolist(["docker-local"]) &&
      !artifactory_archive_policy.policies["archive-old"].enabled &&
      !artifactory_archive_policy.policies["archive-old"].skip_trashcan &&
      artifactory_archive_policy.policies["archive-old"].search_criteria.created_before_in_days == 180 &&
      !artifactory_package_cleanup_policy.policies["cleanup-old"].enabled &&
      !artifactory_package_cleanup_policy.policies["cleanup-old"].skip_trashcan &&
      artifactory_package_cleanup_policy.policies["cleanup-old"].search_criteria.repos == toset(["generic-local"]) &&
      artifactory_package_cleanup_policy.policies["cleanup-old"].search_criteria.last_downloaded_before_in_days == 30
    )
    error_message = "Maintenance must preserve explicit scopes and default to disabled with trashcan protection."
  }

  assert {
    condition = (
      project_project.projects["application"].key == "test-app" &&
      project_user.robots["application"].project_key == project_project.projects["application"].key &&
      project_user.robots["application"].name == artifactory_user.robots["application"].name &&
      project_user.robots["application"].roles == toset([project_role.ci_publishers["application"].name]) &&
      artifactory_user.robots["application"].name == "robot-test-app" &&
      !artifactory_user.robots["application"].admin &&
      !artifactory_user.robots["application"].profile_updatable &&
      artifactory_user.robots["application"].disable_ui_access &&
      artifactory_user.robots["application"].internal_password_disabled &&
      length(artifactory_user.robots["application"].groups) == 0 &&
      project_role.ci_publishers["application"].actions == toset([
        "READ_REPOSITORY", "ANNOTATE_REPOSITORY", "DEPLOY_CACHE_REPOSITORY",
        "READ_BUILD", "ANNOTATE_BUILD", "DEPLOY_BUILD"
      ])
    )
    error_message = "Each project must have an API-only non-admin robot bound to its project-scoped publish role without deletion or administration."
  }

  assert {
    condition = (
      !artifactory_group.groups["developers"].admin_privileges &&
      !artifactory_group.groups["developers"].auto_join &&
      !artifactory_user.users["developer"].admin &&
      toset(artifactory_user.users["developer"].groups) == toset(["developers"])
    )
    error_message = "Onboarding must be non-admin, disable automatic group joining and assign the requested groups."
  }

  assert {
    condition = (
      artifactory_virtual_generic_repository.repositories["generic"].default_deployment_repo == "generic-local" &&
      artifactory_virtual_docker_repository.repositories["docker"].default_deployment_repo == "docker-local" &&
      artifactory_local_docker_v2_repository.repositories["docker-local"].block_pushing_schema1 &&
      artifactory_local_docker_v2_repository.repositories["docker-local"].max_unique_tags == 0
    )
    error_message = "Virtual repositories must target local repositories without enabling automatic artifact deletion."
  }

  assert {
    condition = (
      toset(one(artifactory_permission_target.permissions["publish"].repo).repositories) == toset(["generic-local", "docker-local"]) &&
      toset(one(one(one(artifactory_permission_target.permissions["publish"].repo).actions).groups).permissions) == toset(["read", "write"])
    )
    error_message = "Permissions must be restricted to the named repositories and requested actions."
  }
}

run "empty_gitlab" {
  command = plan
  module {
    source = "./modules/gitlab"
  }
  assert {
    condition = (
      length(output.group_ids) == 0 && length(output.project_ids) == 0 && length(output.user_ids) == 0 &&
      length(gitlab_project_push_rules.projects) == 0 && length(gitlab_project_label.labels) == 0 &&
      length(gitlab_project_level_mr_approvals.projects) == 0 &&
      length(gitlab_group_level_mr_approvals.groups) == 0 && length(gitlab_group_protected_environment.environments) == 0
    )
    error_message = "Empty GitLab input must create no resources."
  }
}

run "empty_artifactory" {
  command = plan
  module {
    source = "./modules/artifactory"
  }
  assert {
    condition     = length(output.project_keys) == 0 && length(output.robot_usernames) == 0 && alltrue([for repositories in values(output.repository_keys) : length(repositories) == 0])
    error_message = "Empty Artifactory input must create no projects, robots or repositories."
  }
  assert {
    condition = (
      length(artifactory_password_expiration_policy.main) == 0 &&
      length(artifactory_mail_server.main) == 0 &&
      length(artifactory_oauth_settings.main) == 0 &&
      length(artifactory_general_security.main) == 0 &&
      length(artifactory_backup.backups) == 0 &&
      length(artifactory_archive_policy.policies) == 0 &&
      length(artifactory_package_cleanup_policy.policies) == 0
    )
    error_message = "Omitted security and maintenance configuration must create no resources."
  }
}

run "diagram_branch_protection" {
  command = plan

  module {
    source = "./modules/gitlab"
  }

  variables {
    configuration = {
      groups = jsondecode(file("environments/lab01/gitlab.json")).gitlab.groups
      subgroups = { for subgroup in flatten([
        for group_key, group in jsondecode(file("environments/lab01/gitlab.json")).gitlab.groups : [
          for subgroup_key, subgroup in group.subgroups : {
            key   = subgroup_key
            value = merge(subgroup, { parent_group_key = group_key })
          }
        ]
      ]) : subgroup.key => subgroup.value }
      projects = { for project in flatten([
        for group in jsondecode(file("environments/lab01/gitlab.json")).gitlab.groups : [
          for subgroup_key, subgroup in group.subgroups : [
            for project_key, project in subgroup.projects : {
              key   = project_key
              value = merge(project, { group_key = subgroup_key })
            }
          ]
        ]
      ]) : project.key => project.value }
    }
  }

  assert {
    condition = (
      length(gitlab_group.groups) == 5 &&
      length(gitlab_group.subgroups) == 12 &&
      length(gitlab_project.projects) == 24 &&
      length(gitlab_branch_protection.branches) == 24 &&
      alltrue([for key, project in gitlab_project.projects : (
        project.default_branch == "main" &&
        project.initialize_with_readme &&
        project.only_allow_merge_if_pipeline_succeeds &&
        project.only_allow_merge_if_all_discussions_are_resolved &&
        gitlab_branch_protection.branches[jsonencode([key, "main"])].branch == "main" &&
        gitlab_branch_protection.branches[jsonencode([key, "main"])].push_access_level == "no one" &&
        gitlab_branch_protection.branches[jsonencode([key, "main"])].merge_access_level == "maintainer" &&
        !gitlab_branch_protection.branches[jsonencode([key, "main"])].allow_force_push
      )])
    )
    error_message = "All 24 diagram projects must initialize and protect main with no direct or force pushes and Maintainer-only merges."
  }
}

run "jfrog_reject_duplicate_keys" {
  command = plan

  module {
    source = "./modules/artifactory"
  }

  variables {
    configuration = {
      projects = {
        first  = { key = "same-key", display_name = "App-1", robot_email = "robot-same-key@example.invalid" }
        second = { key = "same-key", display_name = "App-1", robot_email = "robot-same-key@example.invalid" }
      }
    }
  }

  expect_failures = [project_project.projects]
}

run "jfrog_reject_duplicate_robot_ownership" {
  command = plan

  module {
    source = "./modules/artifactory"
  }

  variables {
    configuration = {
      projects = {
        application = { key = "test-app", display_name = "App-1", robot_email = "robot-test-app@example.invalid" }
      }
      users = {
        robot-test-app = { email = "other@example.invalid" }
      }
    }
  }

  expect_failures = [artifactory_user.robots]
}

run "lab01_environment_configuration" {
  command = plan

  assert {
    condition = (
      local.gitlab_base_url == "https://gitlab.lab01.example.internal/api/v4/" &&
      local.artifactory_url == "https://jfrog.lab01.example.internal/artifactory" &&
      toset(output.artifactory_repository_keys.local_generic) == toset(["platform-lab01-generic-local"])
    )
    error_message = "The lab01 selector must load lab01 endpoints and resource configuration."
  }

  assert {
    condition = (
      length(fileset(path.root, "environments/*/config.json")) == 0 &&
      fileset(path.root, "environments/*/gitlab.json") == toset(["environments/lab01/gitlab.json"]) &&
      fileset(path.root, "environments/*/jfrog.json") == toset(["environments/lab01/jfrog.json"]) &&
      fileset(path.root, "environments/*/backend.hcl") == toset([
        "environments/lab01/backend.hcl", "environments/e01/backend.hcl", "environments/w01/backend.hcl"
      ])
    )
    error_message = "Only lab01 must have split GitLab and JFrog configuration with no combined config.json; lab01, e01 and w01 must each have a backend file."
  }

  assert {
    condition = (
      length(local.gitlab.groups) == 5 &&
      length(local.gitlab.subgroups) == 12 &&
      length(output.gitlab_project_ids) == 24 &&
      length(distinct(values(output.jfrog_project_keys))) == 24 &&
      length(distinct(values(output.jfrog_robot_usernames))) == 24 &&
      alltrue([for key, project in local.jfrog_projects : project.key == key && project.robot_email == "robot-${key}@example.internal"])
    )
    error_message = "The diagram must yield 5 groups, 12 subgroups and 24 uniquely paired projects and robots."
  }

  assert {
    condition = (
      toset(keys(local.gitlab.groups)) == toset(["platform", "capability-1", "capability-2", "capability-3", "capability-4"]) &&
      tomap({ for key, subgroup in local.gitlab.subgroups : key => subgroup.parent_group_key }) == tomap({
        platform-environment = "platform"
        platform-devsecops   = "platform"
        platform-cicd        = "platform"
        platform-security    = "platform"
        cap1-non-ec          = "capability-1"
        cap1-ec              = "capability-1"
        cap2-non-ec          = "capability-2"
        cap2-ec              = "capability-2"
        cap3-non-ec          = "capability-3"
        cap3-ec              = "capability-3"
        cap4-non-ec          = "capability-4"
        cap4-ec              = "capability-4"
      }) &&
      tomap({ for key, project in local.gitlab.projects : key => project.group_key }) == tomap({
        platform-iac          = "platform-environment"
        environment-config    = "platform-environment"
        ansible-playbooks     = "platform-environment"
        devops-iac            = "platform-devsecops"
        bootstrap-scripts     = "platform-devsecops"
        gitlab-cicd-templates = "platform-cicd"
        policy-as-code        = "platform-security"
        compliance-controls   = "platform-security"
        cap1-non-ec-app1      = "cap1-non-ec"
        cap1-non-ec-app2      = "cap1-non-ec"
        cap1-ec-app1          = "cap1-ec"
        cap1-ec-app2          = "cap1-ec"
        cap2-non-ec-app1      = "cap2-non-ec"
        cap2-non-ec-app2      = "cap2-non-ec"
        cap2-ec-app1          = "cap2-ec"
        cap2-ec-app2          = "cap2-ec"
        cap3-non-ec-app1      = "cap3-non-ec"
        cap3-non-ec-app2      = "cap3-non-ec"
        cap3-ec-app1          = "cap3-ec"
        cap3-ec-app2          = "cap3-ec"
        cap4-non-ec-app1      = "cap4-non-ec"
        cap4-non-ec-app2      = "cap4-non-ec"
        cap4-ec-app1          = "cap4-ec"
        cap4-ec-app2          = "cap4-ec"
      })
    )
    error_message = "Hierarchical JSON must preserve every original group, subgroup and project key and derive the same parent relationships."
  }

  assert {
    condition = (
      local.artifactory.groups == local.configuration.artifactory.access.groups &&
      local.artifactory.users == local.configuration.artifactory.access.users &&
      local.artifactory.permission_targets == local.configuration.artifactory.access.permission_targets &&
      toset(output.artifactory_repository_keys.local_docker) == toset(["platform-lab01-docker-local"]) &&
      toset(output.artifactory_repository_keys.virtual_generic) == toset(["platform-lab01-generic"]) &&
      toset(output.artifactory_repository_keys.virtual_docker) == toset(["platform-lab01-docker"]) &&
      local.artifactory.virtual_generic_repositories["platform-lab01-generic"].default_deployment_repo == "platform-lab01-generic-local" &&
      local.artifactory.virtual_docker_repositories["platform-lab01-docker"].repositories == ["platform-lab01-docker-local"]
    )
    error_message = "Nested JFrog access and repository configuration must retain the existing identities, grants and repository relationships."
  }

  assert {
    condition     = toset(keys(output.jfrog_project_keys)) == toset(keys(output.gitlab_project_ids)) && toset(keys(output.jfrog_robot_usernames)) == toset(keys(output.gitlab_project_ids))
    error_message = "Every GitLab project must derive exactly one paired JFrog project."
  }

  assert {
    condition     = toset(keys(output.gitlab_project_ids)) == toset(keys(try(local.gitlab.projects, {})))
    error_message = "Every environment project must be wired through the root module."
  }

  assert {
    condition     = toset(output.artifactory_repository_keys.local_generic) == toset(keys(try(local.artifactory.local_generic_repositories, {})))
    error_message = "Every environment generic repository must be wired through the root module."
  }
}
