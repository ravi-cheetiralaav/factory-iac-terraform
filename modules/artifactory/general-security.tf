resource "artifactory_general_security" "main" {
  for_each = var.configuration.general_security == null ? {} : { main = var.configuration.general_security }

  enable_anonymous_access = each.value.should_enable_anonymous_access
  encryption_policy       = each.value.encryption_policy
}