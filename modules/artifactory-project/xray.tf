resource "xray_watch" "project" {
  count = local.xray_enabled ? 1 : 0

  name        = "${local.project_key}-repositories"
  description = "Critical and malicious-package watch for project ${local.project_key}."
  active      = true

  watch_resource {
    type = "project"
    name = project_project.this.key
  }

  assigned_policy {
    name = var.xray_security_policy_name
    type = "security"
  }

  dynamic "assigned_policy" {
    for_each = var.xray_malicious_policy_name != "" ? [var.xray_malicious_policy_name] : []

    content {
      name = assigned_policy.value
      type = "security"
    }
  }

  watch_recipients = toset(local.xray_recipients)
}
