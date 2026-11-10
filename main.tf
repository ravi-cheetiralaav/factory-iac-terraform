module "gitlab" {
  source = "./modules/gitlab"

  configuration = local.gitlab
}

module "artifactory" {
  source = "./modules/artifactory"

  configuration = local.artifactory
}