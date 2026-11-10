module "gitlab" {
  source = "./modules/gitlab"

  configuration = local.gitlab
}

module "artifactory" {
  source = "./modules/artifactory"

  configuration = merge(local.artifactory, { projects = local.jfrog_projects })
}