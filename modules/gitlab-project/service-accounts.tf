module "service_account" {
  source = "../gitlab-project-service-account"

  project_id = gitlab_project.main.id
  accounts   = try(var.spec.service_accounts, {})
}
