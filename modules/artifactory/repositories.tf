resource "artifactory_local_generic_repository" "repositories" {
  for_each = var.configuration.local_generic_repositories

  key             = each.key
  description     = each.value.description
  repo_layout_ref = "simple-default"

  lifecycle {
    prevent_destroy = true
  }
}

resource "artifactory_local_docker_v2_repository" "repositories" {
  for_each = var.configuration.local_docker_repositories

  key                   = each.key
  description           = each.value.description
  block_pushing_schema1 = true
  max_unique_tags       = each.value.max_unique_tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "artifactory_local_alpine_repository" "repositories" {
  for_each = var.configuration.local_alpine_repositories

  key                 = each.key
  description         = each.value.description
  primary_keypair_ref = each.value.primary_keypair_ref

  lifecycle {
    prevent_destroy = true
  }
}

resource "artifactory_local_ansible_repository" "repositories" {
  for_each = var.configuration.local_ansible_repositories

  key                 = each.key
  description         = each.value.description
  primary_keypair_ref = each.value.primary_keypair_ref

  lifecycle {
    prevent_destroy = true
  }
}

resource "artifactory_local_debian_repository" "repositories" {
  for_each = var.configuration.local_debian_repositories

  key                       = each.key
  description               = each.value.description
  primary_keypair_ref       = each.value.primary_keypair_ref
  secondary_keypair_ref     = each.value.secondary_keypair_ref
  index_compression_formats = each.value.index_compression_formats
  trivial_layout            = each.value.should_use_trivial_layout

  lifecycle {
    prevent_destroy = true
  }
}

resource "artifactory_local_helm_repository" "repositories" {
  for_each = var.configuration.local_helm_repositories

  key                         = each.key
  description                 = each.value.description
  force_non_duplicate_chart   = each.value.should_force_non_duplicate_chart
  force_metadata_name_version = each.value.should_force_metadata_name_version

  lifecycle {
    prevent_destroy = true
  }
}

resource "artifactory_local_helmoci_repository" "repositories" {
  for_each = var.configuration.local_helmoci_repositories

  key             = each.key
  description     = each.value.description
  tag_retention   = each.value.tag_retention
  max_unique_tags = each.value.max_unique_tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "artifactory_local_oci_repository" "repositories" {
  for_each = var.configuration.local_oci_repositories

  key             = each.key
  description     = each.value.description
  tag_retention   = each.value.tag_retention
  max_unique_tags = each.value.max_unique_tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "artifactory_local_maven_repository" "repositories" {
  for_each = var.configuration.local_maven_repositories

  key                             = each.key
  description                     = each.value.description
  checksum_policy_type            = each.value.checksum_policy_type
  snapshot_version_behavior       = each.value.snapshot_version_behavior
  max_unique_snapshots            = each.value.max_unique_snapshots
  handle_releases                 = each.value.should_handle_releases
  handle_snapshots                = each.value.should_handle_snapshots
  suppress_pom_consistency_checks = each.value.should_suppress_pom_consistency_checks

  lifecycle {
    prevent_destroy = true
  }
}

resource "artifactory_local_npm_repository" "repositories" {
  for_each = var.configuration.local_npm_repositories

  key         = each.key
  description = each.value.description

  lifecycle {
    prevent_destroy = true
  }
}

resource "artifactory_local_nuget_repository" "repositories" {
  for_each = var.configuration.local_nuget_repositories

  key                        = each.key
  description                = each.value.description
  max_unique_snapshots       = each.value.max_unique_snapshots
  force_nuget_authentication = each.value.should_force_nuget_authentication

  lifecycle {
    prevent_destroy = true
  }
}

resource "artifactory_local_pypi_repository" "repositories" {
  for_each = var.configuration.local_pypi_repositories

  key         = each.key
  description = each.value.description

  lifecycle {
    prevent_destroy = true
  }
}

resource "artifactory_local_rpm_repository" "repositories" {
  for_each = var.configuration.local_rpm_repositories

  key                        = each.key
  description                = each.value.description
  yum_root_depth             = each.value.yum_root_depth
  calculate_yum_metadata     = each.value.should_calculate_yum_metadata
  enable_file_lists_indexing = each.value.should_enable_file_lists_indexing
  yum_group_file_names       = each.value.yum_group_file_names
  primary_keypair_ref        = each.value.primary_keypair_ref
  secondary_keypair_ref      = each.value.secondary_keypair_ref

  lifecycle {
    prevent_destroy = true
  }
}

resource "artifactory_local_terraform_module_repository" "repositories" {
  for_each = var.configuration.local_terraform_module_repositories

  key         = each.key
  description = each.value.description

  lifecycle {
    prevent_destroy = true
  }
}

resource "artifactory_local_terraform_provider_repository" "repositories" {
  for_each = var.configuration.local_terraform_provider_repositories

  key         = each.key
  description = each.value.description

  lifecycle {
    prevent_destroy = true
  }
}

resource "artifactory_local_terraformbackend_repository" "repositories" {
  for_each = var.configuration.local_terraformbackend_repositories

  key         = each.key
  description = each.value.description

  lifecycle {
    prevent_destroy = true
  }
}

resource "artifactory_virtual_generic_repository" "repositories" {
  for_each = var.configuration.virtual_generic_repositories

  key                     = each.key
  description             = each.value.description
  repo_layout_ref         = "simple-default"
  repositories            = each.value.repositories
  default_deployment_repo = each.value.default_deployment_repo

  depends_on = [artifactory_local_generic_repository.repositories]

  lifecycle {
    prevent_destroy = true
  }
}

resource "artifactory_virtual_docker_repository" "repositories" {
  for_each = var.configuration.virtual_docker_repositories

  key                     = each.key
  description             = each.value.description
  repositories            = each.value.repositories
  default_deployment_repo = each.value.default_deployment_repo

  depends_on = [artifactory_local_docker_v2_repository.repositories]

  lifecycle {
    prevent_destroy = true
  }
}