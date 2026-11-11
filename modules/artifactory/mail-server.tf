resource "artifactory_mail_server" "main" {
  for_each = var.configuration.mail_server == null ? {} : { main = var.configuration.mail_server }

  enabled         = each.value.should_enable
  host            = each.value.host
  port            = each.value.port
  artifactory_url = each.value.artifactory_url
  from            = each.value.from
  subject_prefix  = each.value.subject_prefix
  username        = each.value.username
  password        = var.secrets.mail_password
  use_ssl         = each.value.should_use_ssl
  use_tls         = each.value.should_use_tls
}