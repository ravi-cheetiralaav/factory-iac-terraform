resource "xray_security_policy" "this" {
  for_each = local.xray_policies

  name        = each.value.name
  description = each.value.description
  type        = "security"

  dynamic "rule" {
    for_each = each.value.malicious_package ? [1] : []

    content {
      name     = "malicious-package"
      priority = 1

      criteria {
        malicious_package     = true
        fix_version_dependant = false
      }

      actions {
        block_release_bundle_distribution = false
        block_release_bundle_promotion    = false
        fail_build                        = false
        fail_pull_request                 = false
        notify_watch_recipients           = false
        notify_deployer                   = true
        create_ticket_enabled             = false

        block_download {
          active    = true
          unscanned = false
        }
      }
    }
  }

  dynamic "rule" {
    for_each = each.value.min_severity != null ? [each.value.min_severity] : []

    content {
      name     = "minimum-severity"
      priority = 1

      criteria {
        min_severity          = rule.value
        fix_version_dependant = false
      }

      actions {
        block_release_bundle_distribution = false
        block_release_bundle_promotion    = false
        fail_build                        = false
        fail_pull_request                 = false
        notify_watch_recipients           = false
        notify_deployer                   = true
        create_ticket_enabled             = false

        block_download {
          active    = true
          unscanned = false
        }
      }
    }
  }
}

resource "xray_watch" "this" {
  for_each = local.xray_watches

  name        = each.value.name
  description = each.value.description
  active      = true

  dynamic "watch_resource" {
    for_each = toset(each.value.repositories)

    content {
      type       = "repository"
      name       = local.local_repository_resource_keys[watch_resource.value]
      repo_type  = "local"
      bin_mgr_id = "default"

      filter {
        type  = "regex"
        value = ".*"
      }
    }
  }

  dynamic "assigned_policy" {
    for_each = toset(each.value.policies)

    content {
      name = xray_security_policy.this[assigned_policy.value].name
      type = "security"
    }
  }
}
