resource "artifactory_general_security" "this" {
  count = var.manage_general_security ? 1 : 0

  enable_anonymous_access = var.enable_anonymous_access
  encryption_policy       = var.encryption_policy
}
