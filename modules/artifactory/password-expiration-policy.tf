resource "artifactory_password_expiration_policy" "main" {
  for_each = var.configuration.password_expiration_policy == null ? {} : { main = var.configuration.password_expiration_policy }

  name             = each.value.name
  enabled          = each.value.should_enable
  password_max_age = each.value.password_max_age
  notify_by_email  = each.value.should_notify_by_email

  depends_on = [artifactory_mail_server.main]
}