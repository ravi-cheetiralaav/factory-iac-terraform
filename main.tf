module "gitlab" {
  source = "./modules/gitlab"

  configuration = local.gitlab
}

# module "artifactory" {
#   count  = var.should_manage_artifactory ? 1 : 0
#   source = "./modules/artifactory"

#   configuration = merge(local.artifactory, { projects = local.jfrog_projects })
#   secrets       = var.artifactory_secrets
# }

# moved {
#   from = module.artifactory
#   to   = module.artifactory[0]
# }

import {
  to = module.gitlab.gitlab_group.groups["platform"]
  id = "147438511"
}