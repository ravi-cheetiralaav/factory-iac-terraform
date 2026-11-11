resource "artifactory_oauth_settings" "main" {
  for_each = var.configuration.oauth_settings == null ? {} : { main = var.configuration.oauth_settings }

  enable                       = each.value.should_enable
  persist_users                = each.value.should_persist_users
  allow_user_to_access_profile = each.value.should_allow_user_to_access_profile

  dynamic "oauth_provider" {
    for_each = each.value.providers

    content {
      name          = oauth_provider.key
      type          = oauth_provider.value.type
      client_id     = oauth_provider.value.client_id
      client_secret = var.secrets.oauth_client_secrets[oauth_provider.key]
      api_url       = oauth_provider.value.api_url
      auth_url      = oauth_provider.value.auth_url
      token_url     = oauth_provider.value.token_url
      enabled       = oauth_provider.value.should_enable
    }
  }
}